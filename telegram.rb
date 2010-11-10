set :root, File.dirname(__FILE__)
set :haml, :format => :html5

enable :sessions

configure do
  mongoid_config = File.join(File.dirname(__FILE__), "config", "mongoid.yml")
  mongoid_settings = YAML.load(ERB.new(File.new(mongoid_config).read).result)
  Mongoid.configure do |config|
    config.from_hash(mongoid_settings[ENV['RACK_ENV']])
  end
end

# Models

class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :title
  field :permalink
  field :summary
  field :keywords
  field :content
  field :published_at, :type => DateTime
  field :published, :type => Boolean, :default => false
  
  before_save :ensure_permalink
  before_save :set_published
  
  validates_presence_of   :title
  validates_uniqueness_of :permalink
  
  def ensure_permalink
    permalink = self.permalink.blank? ? self.title : self.permalink
    permalink = I18n.transliterate(ActiveSupport::Multibyte::Unicode.normalize(ActiveSupport::Multibyte::Unicode.tidy_bytes(permalink), :c), :replacement => "-")
    permalink.gsub!(/[^a-z0-9\-_]+/i, "-")
    permalink.gsub!(/\-{2,}/, "-") # Only one - in a row
    permalink.gsub!(/^\-|\-$/i, '') # Remove leading/trailing -
    self.permalink = permalink.downcase
  end
  
  def set_published
    if self.published?
      self.published_at = Time.now if self.published_at.blank?
    else
      self.published_at = nil
    end
  end
end

class Setting
  include Mongoid::Document
  
  field :site_name,       :default => 'Telegram CMS'
  field :meta_description,:default => 'Please change me to decribe your site in 160 characters or less.'
  field :meta_keywords,   :default => 'your, site, keywords'
  field :username,        :default => 'admin'
  field :password,        :default => 'change_me'
  field :author,          :default => 'Me'
  field :google_analytics_id
  field :feed_url
  field :template_layout
  field :template_index
  field :template_post
  field :template_css
  field :template_js
  
  before_save :ensure_templates
  
  def ensure_templates
    self.template_layout = IO.read(File.dirname(__FILE__)+'/templates/layout.haml') if self.template_layout.blank?
    self.template_index  = IO.read(File.dirname(__FILE__)+'/templates/index.haml') if self.template_index.blank?
    self.template_post   = IO.read(File.dirname(__FILE__)+'/templates/post.haml') if self.template_post.blank?
    self.template_css    = IO.read(File.dirname(__FILE__)+'/templates/application.css') if self.template_css.blank?
    self.template_js     = IO.read(File.dirname(__FILE__)+'/templates/application.js') if self.template_js.blank?
  end
end 

helpers do
  def protected!
    if authorized?
      set_admin_cookie
    else
      response['WWW-Authenticate'] = %(Basic realm="Authentication")
      throw(:halt, [401, "Not authorized\n"])
    end
  end
  
  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [@settings.username, @settings.password]
  end
  
  def rfc_3339(timestamp)
    timestamp.strftime("%Y-%m-%dT%H:%M:%SZ")
  end
  
  def base_url
    if request.port == 80
      "http://#{request.host}/"
    else
      "http://#{request.host}:#{request.port}/"
    end
  end
  
  def post_url(post)
    "#{base_url}#{post.permalink}"
  end
  
  def default_feed_url
    "#{base_url}feed"
  end
  
  def feed_url
    @settings.feed_url.blank? ? default_feed_url : @settings.feed_url
  end
  
  def convert_md(content)
    markdown(content)
  end
  
  def cache_me(length="300")
    response.headers['Cache-Control'] = "public, max-age=#{length}"
  end
  
  def set_admin_cookie
    response.set_cookie('tga', :path => '/', :value => Digest::MD5.hexdigest(@settings.username + @settings.password), :expires => (Time.now + (3600*24)))
  end
  
  def delete_admin_cookie
    response.set_cookie('tga', :path => '/', :expires => (Time.now - (3600*24)))
  end
  
  def meta_description
    @post.blank? ? @settings.meta_description.to_s : @post.summary.to_s
  end

  def meta_keywords
    @post.blank? ? @settings.meta_keywords.to_s : @post.keywords.to_s
  end
  
  def title
    if @title.blank?
      @post.blank? ? @settings.site_name.to_s : "#{@post.title} - #{@settings.site_name.to_s}"
    else
      "#{@title} - #{@settings.site_name.to_s}"
    end
  end
end

before do
  @settings = Setting.first || Setting.create!
  template :layout do
    @settings.template_layout.to_s
  end
end

before '/posts*' do
  protected!
end

before '/settings' do
  protected!
end

get '/' do
  cache_me
  @posts = Post.where(:published => true).desc(:published_at)
  haml @settings.template_index.to_s
end

get '/feed' do
  cache_me
  @posts = Post.where(:published => true).desc(:published_at)
  last_modified @posts.first.published_at rescue Time.now
  content_type :atom, :charset => 'utf-8'
  builder :feed, :layout => false
end

get '/sitemap.xml' do
  cache_me
  @posts = Post.where(:published => true)
  builder :sitemap, :layout => false
end

get '/application.js' do
  cache_me
  content_type :js, :charset => 'utf-8'
  @settings.template_js.to_s
end

get '/application.css' do
  cache_me
  content_type :css, :charset => 'utf-8'
  @settings.template_css.to_s
end

# Post Editing

get '/posts' do
  @title = "All Posts"
  @drafts = Post.where(:published => false).desc(:created_at)
  @posts  = Post.where(:published => true).desc(:published_at)
  haml :'posts/index'
end

get '/posts/new' do
  @title = "New Post"
  @post = Post.new
  haml :'posts/new'
end

get '/posts/:id' do
  @post = Post.find(params[:id])
  @title = "Preview Post (#{@post.title})"
  haml @settings.template_post.to_s
end

get '/posts/:id/edit' do
  @title = "Edit Post"
  @post = Post.find(params[:id])
  haml :'posts/edit'
end

post '/posts' do
  @post = Post.new params[:post]
  if @post.save
    if @post.published?
      redirect "/#{@post.permalink}"
    else
      redirect "/posts/#{@post.id}/edit"
    end
  else
    haml :'posts/new'
  end
end

put '/posts/:id' do
  @post = Post.find(params[:id])
  params[:post][:published] = false if params[:post][:published].nil? #checkboxes aren't submitted if they aren't checked
  if @post.update_attributes(params[:post])
    if @post.published?
      redirect "/#{@post.permalink}"
    else
      redirect "/posts/#{@post.id}/edit"
    end
  else
    haml :'posts/edit'
  end
end

delete '/posts/:id' do
  @post = Post.find(params[:id])
  @post.destroy
  redirect '/posts'
end

# Settings

get '/settings' do
  @title = "Settings"
  begin
    haml :'settings/index'
  rescue => Haml::SyntaxError
    haml :'settings/index', :layout => false
  end
end

put '/settings' do
  @settings = Setting.first
  if @settings.update_attributes(params[:setting])
    redirect '/settings'
  else
    haml :'settings/index'
  end
end

get '/logout' do
  delete_admin_cookie
  redirect '/'
end

# This one must be last to get the really short url's

get '/:permalink' do
  cache_me
  @post = Post.first(:conditions => {:permalink => params[:permalink]})
  haml @settings.template_post.to_s
end

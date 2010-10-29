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
  field :username,        :default => 'admin'
  field :password,        :default => 'change_me'
  field :author,          :default => 'Me'
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
    unless authorized?
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
  
  def cache_me
    response.headers['Cache-Control'] = 'public, max-age=300'
  end
end

before do
  @settings = Setting.first || Setting.create!
  template :layout do
    @settings.template_layout.to_s
  end
end

before '/posts/*' do
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

get '/posts/drafts' do
  @posts = Post.where(:published => false).asc(:created_at)
  haml :'posts/drafts'
end

get '/posts/new' do
  @post = Post.new
  haml :'posts/new'
end

post '/posts' do
  @post = Post.new params[:post]
  if @post.save
    redirect '/'
  else
    haml :'posts/new'
  end
end

get '/posts/:id/edit' do
  @post = Post.find(params[:id])
  haml :'posts/edit'
end

put '/posts/:id' do
  @post = Post.find(params[:id])
  params[:post][:published] = false if params[:post][:published].nil? #checkboxes aren't submitted if they aren't checked
  if @post.update_attributes(params[:post])
    redirect '/'
  else
    haml :'posts/edit'
  end
end

delete '/posts/:id' do
  @post = Post.find(params[:id])
  @post.destroy
  redirect '/'
end

# Settings

get '/settings' do
  haml :'settings/index'
end

put '/settings' do
  @settings = Setting.first
  if @settings.update_attributes(params[:setting])
    redirect '/settings'
  else
    haml :'settings/index'
  end
end

# This one must be last to get the really short url's

get '/:permalink' do
  cache_me
  @post = Post.first(:conditions => {:permalink => params[:permalink]})
  haml @settings.template_post.to_s
end

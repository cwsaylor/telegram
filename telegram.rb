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

class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :title
  field :permalink
  field :summary
  field :keywords
  field :content
  field :published_at, :type => DateTime
  field :published, :type => Boolean
  
  before_save :ensure_permalink
  before_save :set_published
  
  def ensure_permalink
    permalink = self.permalink.blank? ? self.title : self.permalink
    permalink = I18n.transliterate(ActiveSupport::Multibyte::Unicode.normalize(ActiveSupport::Multibyte::Unicode.tidy_bytes(permalink), :c), :replacement => "-")
    permalink.gsub!(/[^a-z0-9\-_]+/i, "-")
    permalink.gsub!(/\-{2,}/, "-") # Only one - in a row
    permalink.gsub!(/^\-|\-$/i, '') # Remove leading/trailing -
    self.permalink = permalink.downcase
  end
  
  def set_published
    if self.attribute_changed?("published") && self.published_at.nil?
      self.published_at = Time.now
    end
  end
end

class Setting
  include Mongoid::Document
  
  field :username,        :default => 'admin'
  field :password,        :default => 'change_me'
  field :author,          :default => 'Me'
  field :feed_url
  field :template_layout, :default => IO.read(File.dirname(__FILE__)+'/templates/layout.haml')
  field :template_index,  :default => IO.read(File.dirname(__FILE__)+'/templates/index.haml')
  field :template_post,   :default => IO.read(File.dirname(__FILE__)+'/templates/post.haml')
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
    "#{base_url}feed.atom"
  end
  
  def feed_url
    @settings.feed_url.nil? ? default_feed_url : @settings.feed_url
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
  response.headers['Cache-Control'] = 'public, max-age=300'
  @posts = Post.where(:published => true).desc(:published_at)
  haml @settings.template_index.to_s
end

get '/feed.atom' do
  @posts = Post.where(:published => true).desc(:published_at)
  last_modified @posts.first.published_at  
  content_type 'application/atom+xml', :charset => 'utf-8'
  builder :feed
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
  @post = Post.find(params[:id]).asc(:id)
  @post.delete
  redirect '/'
end

# Settings

get '/settings' do
  haml :'settings/index'
end

put '/settings' do
  @settings = Setting.first
  if @settings.update_attributes(params[:setting])
    redirect '/'
  else
    haml :'settings/index'
  end
end

# This one must be last to get the really short url's

get '/:permalink' do
  response.headers['Cache-Control'] = 'public, max-age=300'
  @post = Post.first(:conditions => {:permalink => params[:permalink]})
  haml @settings.template_post.to_s
end

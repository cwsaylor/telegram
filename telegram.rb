set :root, File.dirname(__FILE__)
set :haml, :format => :html5

configure do
  file_name = File.join(File.dirname(__FILE__), "config", "mongoid.yml")
  @mongoid_settings = YAML.load(ERB.new(File.new(file_name).read).result)

  Mongoid.configure do |config|
    config.from_hash(@mongoid_settings[ENV['RACK_ENV']])
  end
end

class Post
  include Mongoid::Document
  field :title
  field :permalink
  field :summary
  field :keywords
  field :content
  field :published_at, :type => DateTime
  field :published, :type => Boolean
  
  before_save :ensure_permalink
  
  def ensure_permalink
    permalink = self.permalink.blank? ? self.title : self.permalink
    permalink = I18n.transliterate(ActiveSupport::Multibyte::Unicode.normalize(ActiveSupport::Multibyte::Unicode.tidy_bytes(permalink), :c), :replacement => "-")
    permalink.gsub!(/[^a-z0-9\-_]+/i, "-")
    permalink.gsub!(/\-{2,}/, "-") # Only one - in a row
    permalink.gsub!(/^\-|\-$/i, '') # Remove leading/trailing -
    self.permalink = permalink.downcase
  end
end

get '/' do
  response.headers['Cache-Control'] = 'public, max-age=300'
  @posts = Post.all
  haml :index
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
  @post.delete(params[:post])
  redirect '/'
end

get '/:permalink' do
  response.headers['Cache-Control'] = 'public, max-age=300'
  @post = Post.first(:conditions => {:permalink => params[:permalink]})
  haml :'posts/show'
end

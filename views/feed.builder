xml.instruct! :xml, :version => '1.0'
xml.feed :'xml:lang' => 'en-US', :xmlns => 'http://www.w3.org/2005/Atom' do
  xml.id base_url
  xml.link :type => 'text/html', 
           :href => base_url, 
           :rel => 'alternate'
  xml.link :type => 'application/atom+xml', 
           :href => base_url + "feed.atom", 
           :rel => 'self'
  xml.title 'Telegram CMS'
  xml.updated(rfc_3339(@posts.first.published_at))
  @posts.each do |post|
    xml.entry do |entry|
      entry.id post_url(post)
      entry.link :type => 'text/html', 
                 :href => post_url(post), 
                 :rel => 'alternate'
      entry.updated rfc_3339(post.published_at)
      entry.title post.title
      entry.author do |author|
        author.name @settings.author.to_s
      end
      entry.content markdown(post.content), :type => 'html'
    end
  end
end

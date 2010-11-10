xml.instruct!
xml.urlset "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation" => "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd", 
  "xmlns" => "http://www.google.com/schemas/sitemap/0.9" do

  xml.url do
    xml.loc base_url
    xml.priority 1.0
  end
  
  @posts.each do |post|
    xml.url do
      xml.loc post_url(post)
      xml.lastmod post.updated_at.to_date
    end
  end
  
end
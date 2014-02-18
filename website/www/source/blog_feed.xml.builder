xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title "Vagrant Blog"
  xml.subtitle "Release announcements, how-to guides, and more for Vagrant."
  xml.id "http://www.vagrantup.com/blog.html"
  xml.link "href" => "http://www.vagrantup.com/blog.html"
  xml.link "href" => "http://www.vagrantup.com/blog_feed.xml", "rel" => "self"
  xml.updated blog.articles.first.date.to_time.iso8601
  xml.author { xml.name "Vagrant" }

  blog.articles[0..5].each do |article|
    xml.entry do
      xml.title article.title
      xml.link "rel" => "alternate", "href" => "http://www.vagrantup.com#{article.url}"
      xml.id article.url
      xml.published article.date.to_time.iso8601
      xml.updated article.date.to_time.iso8601
      xml.author { xml.name article.data.author }
      xml.summary article.summary, "type" => "html"
      xml.content article.body, "type" => "html"
    end
  end
end

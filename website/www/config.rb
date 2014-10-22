require File.expand_path("../helpers/download_helpers", __FILE__)

page "/blog_feed.xml", layout: false
ignore "/download-archive-single.html"

# Archived download pages
$vagrant_versions.each do |version|
  proxy "/download-archive/v#{version}.html", "/download-archive-single.html",
    locals: { version: version }, ignore: true
end

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

# Use the RedCarpet Markdown engine
set :markdown_engine, :redcarpet
set :markdown,
    fenced_code_blocks: true,
    with_toc_data: true

# Enable the blog and set the time zone so that post times appear
# correctly.
Time.zone = "America/Los_Angeles"

activate :blog do |b|
  b.layout = "blog_post"
  b.permalink = ":title.html"
  b.prefix = "blog"
end

# Build-specific configuration
configure :build do
  activate :asset_hash
  activate :minify_css
  activate :minify_html do |html|
    html.remove_quotes = false
    html.remove_script_attributes = false
    html.remove_multi_spaces = false
    html.remove_http_protocol = false
    html.remove_https_protocol = false
  end
  activate :minify_javascript
end

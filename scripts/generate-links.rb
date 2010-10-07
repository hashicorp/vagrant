#!/usr/bin/env ruby
require 'rubygems'
require 'active_support/all'

a = %{
<li><a href="/docs/getting-started/index.html">Overview</a></li>
<li><a href="/docs/getting-started/why.html">Why Vagrant?</a></li>
<li><a href="/docs/getting-started/introduction.html">Introduction</a></li>
<li><a href="/docs/getting-started/setup.html">Project Setup</a></li>
<li><a href="/docs/getting-started/boxes.html">Boxes</a></li>
<li><a href="/docs/getting-started/ssh.html">SSH</a></li>
<li><a href="/docs/getting-started/provisioning.html">Provisioning</a></li>
<li><a href="/docs/getting-started/ports.html">Port Forwarding</a></li>
<li><a href="/docs/getting-started/packaging.html">Packaging</a></li>
<li><a href="/docs/getting-started/teardown.html">Teardown</a></li>
<li><a href="/docs/getting-started/rebuild.html">Rebuild Instantly</a></li>
}.split("\n").grep(/href/)

Page = Struct.new(:number, :url, :title)
number = 0
pages = a.map do |line|
  line =~ /href="(.*?)"/
  url = $1
  line =~ /">(.*?)<\/a/
  title = $1
  page = Page.new number, url, title
  number += 1
  page
end

###################################################
# generates the list of linkes
###################################################
# pages.each do |page|
#   puts %{
# {% if page.url == '#{page.url}' %}
#   <li>#{page.title}</li>
# {% else %}
#   <li><a href="#{page.url}">#{page.title}</a></li>
# {% endif %}
#   }.strip
# end

###################################################
# generates the prev/next linkss
###################################################
# pages.each do |page|
#   para = []
#   unless page.number == 0
#     prev_page = pages[page.number-1]
#     para << "[&larr; #{prev_page.title}](#{prev_page.url}) &middot; "
#   end
#   para << page.title
#   unless page.number == pages.length-1
#     next_page = pages[page.number+1]
#     para << " &middot; [#{next_page.title} &rarr;](#{next_page.url})"
#   end
#   puts para.join
# end

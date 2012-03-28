---
layout: contribute
title: Contribute Documentation - Update the Site

section: docs
current: Update the Site
---
# Update the Site With Your Changes

## Changing a Page

To change an existing page, find that page in the source. This is
really easy to do by simply looking at the URL of the page you're
trying to modify. For example, the URL for this page is
`http://vagrantup.com/contribute/documentation/update.html`. To
modify this page, you would modify the file `contribute/documentation/update.md`.

All pages of the Vagrant website are [Markdown](http://daringfireball.net/projects/markdown/syntax).
If you're unfamiliar with Markdown, the syntax is very simple
and quick to pick up.

Once the contents of the file are updated, you can view your
changes by running the site. Note that if you have been running
the site, the change to the file typically take around 30 to
60 seconds to take effect, so please be patient.

## Adding a New Page

Adding a new page is just as easy as changing an existing page.
Just create a new markdown file somewhere, and Jekyll will
automatically turn that into a new HTML page. For example,
if you create the file `foo/bar/hello.md`, then the page
will be available at `/foo/bar/hello.html`. Simple!

## Changing the Layout

If instead of modifying specific page content you're modifying
a part of the layout (a part of the page that is consistent
across multiple pages, like the navigation bar on the top),
then you'll probably need to modify HTML directly.

The layouts are available in the `_layouts` directory, and
the exact layout for a page can be found by reading the
value of the `layout` directive at the top of any markdown
page source. Note that the layouts often include other pages.
These pages can be found in the `_includes` directory.

Just as any other page, simply modify these files as you
see fit, save them, and wait a minute or so to see the
changes appear in your browser for your locally run site.

## Additional Help

If you're trying to do something particularly advanced or require
additional help, I recommend viewing other pages of the Vagrant
website. Most of what is possible with Jekyll is done at some
point on the Vagrant website, so reading the source of other
pages of the Vagrant website will teach you tons!

Of course, you can use the typical [Vagrant support channels](/support.html)
if you need to as well.

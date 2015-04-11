---
page_title: "HTTP Sharing - Vagrant Share"
sidebar_current: "share-http"
---

# HTTP Sharing

Vagrant Share can create a publicly accessible URL endpoint to access an
HTTP server running in your Vagrant environment. This is known as "HTTP
sharing," and is enabled by default when `vagrant share` is used.

Because this mode of sharing creates a publicly accessible URL, the accessing
party does not need to have Vagrant installed in order to view your environment.

This has a number of useful use cases: you can test webhooks by exposing
your Vagrant environment to the internet, you can show your work to clients,
teammates, or managers, etc.

## Usage

To use HTTP sharing, simply run `vagrant share`:

```
$ vagrant share
==> default: Detecting network information for machine...
    default: Local machine address: 192.168.163.152
    default: Local HTTP port: 4567
    default: Local HTTPS port: disabled
==> default: Checking authentication and authorization...
==> default: Creating Vagrant Share session...
    default: Share will be at: ghastly-wombat-4051
==> default: Your Vagrant Share is running!
    default: Name: ghastly-wombat-4051
==> default: URL: http://ghastly-wombat-4051.vagrantshare.com
```

Vagrant detects where your HTTP server is running in your Vagrant environment
and outputs the endpoint that can be used to access this share. Just give
this URL to anyone you want to share it with, and they'll be able to access
your Vagrant environment!

If Vagrant has trouble detecting the port of your servers in your environment,
use the `--http` and/or `--https` flags to be more explicit.

The share will be accessible for the duration that `vagrant share` is running.
Press `Ctrl-C` to quit the sharing session.

<div class="alert alert-block alert-warn">
<strong>Warning:</strong> This URL is accessible by <em>anyone</em>
who knows it, so be careful if you're sharing sensitive information.
</div>

## Disabling

If you want to disable the creation of the publicly accessible endpoint,
run `vagrant share` with the `--disable-http` flag. This will share your
environment using one of the other methods available, and will not create
the URL endpoint.

## Missing Assets

Shared web applications must use **relative paths** for loading any
local assets such as images, stylesheets, javascript.

The web application under development will be accessed remotely. This means
that if you have any hardcoded asset (images, stylesheets, etc.) URLs
such as `<img src="http://127.0.0.1/header.png">`, then they won't load
for people accessing your share.

Most web frameworks or toolkits have settings or helpers to generate
relative paths. For example, if you're a WordPress developer, the
[Root Relative URLs](http://wordpress.org/plugins/root-relative-urls/) plugin
will automatically do this for you.

Relative URLs to assets is generally a best practice in general, so you
should do this anyways!

## HTTPS (SSL)

Vagrant Share can also expose an SSL port that can be accessed over
SSL. For example, instead of accessing `http://foo.vagrantshare.com`, it
could be accessed at `https://foo.vagrantshare.com`.

`vagrant share` by default looks for any SSL traffic on port 443 in your
development environment. If it can't find any, then SSL is disabled by
default.

You can force SSL by setting the `--https` flag to point to the accessible
SSL port.

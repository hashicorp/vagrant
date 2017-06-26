---
layout: "docs"
page_title: "HTTP Sharing - Vagrant Share"
sidebar_current: "share-http"
description: |-
  Vagrant Share can create a publicly accessible URL endpoint to access an
  HTTP server running in your Vagrant environment. This is known as "HTTP
  sharing," and is enabled by default when "vagrant share" is used.
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
default: Local machine address: 192.168.84.130
default: Local HTTP port: 9999
default: Local HTTPS port: disabled
==> default: Creating Vagrant Share session...
==> default: HTTP URL: http://b1fb1f3f.ngrok.io
```

Vagrant detects where your HTTP server is running in your Vagrant environment
and outputs the endpoint that can be used to access this share. Just give
this URL to anyone you want to share it with, and they will be able to access
your Vagrant environment!

If Vagrant has trouble detecting the port of your servers in your environment,
use the `--http` and/or `--https` flags to be more explicit.

The share will be accessible for the duration that `vagrant share` is running.
Press `Ctrl-C` to quit the sharing session.

<div class="alert alert-warning">
  <strong>Warning:</strong> This URL is accessible by <em>anyone</em>
  who knows it, so be careful if you are sharing sensitive information.
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
such as `<img src="http://127.0.0.1/header.png">`, then they will not load
for people accessing your share.

Most web frameworks or toolkits have settings or helpers to generate
relative paths. For example, if you are a WordPress developer, the
[Root Relative URLs](http://wordpress.org/plugins/root-relative-urls/) plugin
will automatically do this for you.

Relative URLs to assets is generally a best practice in general, so you
should do this anyways!

## HTTPS (SSL)

Vagrant Share can also expose an SSL port that can be accessed over
SSL. Creating an HTTPS share requires a non-free ngrok account.

`vagrant share` by default looks for any SSL traffic on port 443 in your
development environment. If it cannot find any, then SSL is disabled by
default.

The HTTPS share can be explicitly disabled using the `--disable-https` flag.

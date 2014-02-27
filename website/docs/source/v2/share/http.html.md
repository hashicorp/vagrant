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

This has a number of useful use cases: you can test webooks by exposing
your Vagrant environment to the internet, you can show your work to clients,
teammates, or managers, etc.

## Usage

To use HTTP sharing, simply run `vagrant share`:

```
TODO
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

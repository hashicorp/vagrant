---
layout: "docs"
page_title: "Vagrant Push - FTP & SFTP Strategy"
sidebar_current: "push-ftp"
description: |-
  Vagrant Push FTP and SFTP strategy pushes the code in your Vagrant development
  environment to a remote FTP or SFTP server.
---

# Vagrant Push

## FTP & SFTP Strategy

Vagrant Push FTP and SFTP strategy pushes the code in your Vagrant development
environment to a remote FTP or SFTP server.

The Vagrant Push FTP And SFTP strategy supports the following configuration
options:

- `host` - The address of the remote (S)FTP server. If the (S)FTP server is
  running on a non-standard port, you can specify the port after the address
  (`host:port`).

- `username` - The username to use for authentication with the (S)FTP server.

- `password` - The password to use for authentication with the (S)FTP server.

- `passive` - Use passive FTP (default is true).

- `secure` - Use secure (SFTP) (default is false).

- `destination` - The root destination on the target system to sync the files
  (default is `/`).

- `exclude` - Add a file or file pattern to exclude from the upload, relative to
  the `dir`. This value may be specified multiple times and is additive.
  `exclude` take precedence over `include` values.

- `include` - Add a file or file pattern to include in the upload, relative to
  the `dir`. This value may be specified multiple times and is additive.

- `dir` - The base directory containing the files to upload. By default this is
  the same directory as the Vagrantfile, but you can specify this if you have
  a `src` folder or `bin` folder or some other folder you want to upload.


### Usage

The Vagrant Push FTP and SFTP strategy is defined in the `Vagrantfile` using the
`ftp` key:

```ruby
config.push.define "ftp" do |push|
  push.host = "ftp.company.com"
  push.username = "username"
  push.password = "password"
end
```

And then push the application to the FTP or SFTP server:

```shell
$ vagrant push
```

---
page_title: "Vagrant Push - Atlas Strategy"
sidebar_current: "push-atlas"
description: |-
  Atlas is HashiCorp's commercial offering to bring your Vagrant development
  environments to production. The Vagrant Push Atlas strategy pushes your
  application's code to HashiCorp's Atlas service.
---

# Vagrant Push

## Atlas Strategy

[Atlas][] is HashiCorp's commercial offering to bring your Vagrant development
environments to production. You can read more about HashiCorp's Atlas and all
its features on [the Atlas homepage][Atlas]. The Vagrant Push Atlas strategy
pushes your application's code to HashiCorp's Atlas service.

The Vagrant Push Atlas strategy supports the following configuration options:

- `app` - The name of the application in [HashiCorp's Atlas][Atlas]. If the
  application does not exist, it will be created with user confirmation.

- `exclude` - Add a file or file pattern to exclude from the upload, relative to
  the `dir`. This value may be specified multiple times and is additive.
  `exclude` take precedence over `include` values.

- `include` - Add a file or file pattern to include in the upload, relative to
  the `dir`. This value may be specified multiple times and is additive.

- `dir` - The base directory containing the files to upload. By default this is
  the same directory as the Vagrantfile, but you can specify this if you have
  a `src` folder or `bin` folder or some other folder you want to upload.

- `vcs` - If set to true, Vagrant will automatically use VCS data to determine
  the files to upload. Uncommitted changes will not be deployed.


### Usage

The Vagrant Push Atlas strategy is defined in the `Vagrantfile` using the
`atlas` key:

```ruby
config.push.define "atlas" do |push|
  push.app = "username/application"
end
```

And then push the application to Atlas:

```shell
$ vagrant push
```

[Atlas]: https://atlas.hashicorp.com/  "HashiCorp's Atlas Service"

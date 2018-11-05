# Running vagrant-spec

## Requirements

- vagrant installed (from source, or from packages)
- vagrant vmware plugin
- ![vagrant](https://github.com/hashicorp/vagrant) repo
- ![vagrant-spec](https://github.com/hashicorp/vagrant-spec) repo

## How to run

First, we need to build vagrant-spec:

```
cd vagrant-spec
gem build *.gemspec
cp vagrant-spec-0.0.1.gem /path/to/vagrant/vagrant-spec.gem
```

Next, make a decision as to which host and guest boxes will be used to run the tests.

From the root dir of the `vagrant` project, run the following command:

```shell
VAGRANT_CLOUD_TOKEN=REAL_TOKEN_HERE VAGRANT_HOST_BOXES=hashicorp-vagrant/centos-7.4 VAGRANT_GUEST_BOXES=hashicorp-vagrant/windows-10 VAGRANT_CWD=test/vagrant-spec/ VAGRANT_VAGRANTFILE=Vagrantfile.spec vagrant up
```

If you are running windows, you must give your host box more memory than the default. That can be done through the environment variable `VAGRANT_HOST_MEMORY`

```shell
VAGRANT_HOST_MEMORY=10000 VAGRANT_CLOUD_TOKEN=REAL_TOKEN_HERE VAGRANT_HOST_BOXES=hashicorp-vagrant/centos-7.4 VAGRANT_GUEST_BOXES=hashicorp-vagrant/windows-10 VAGRANT_CWD=test/vagrant-spec/ VAGRANT_VAGRANTFILE=Vagrantfile.spec vagrant up
```


## Relevant environment variables:

- VAGRANT_CLOUD_TOKEN
  + Token to use if fetching a private box (like windows)
- VAGRANT_HOST_BOXES
  - Vagrant box to use to host and run tests
- VAGRANT_GUEST_BOXES
  - Vagrant box to use to run tests on
- VAGRANT_CWD
  - Directory location of vagrant-spec Vagrantfile
- VAGRANT_VAGRANTFILE
  - Vagrantfile to use for running vagrant-spec
- VAGRANT_HOST_MEMORY
  - Set how much memory your host will use (defaults to 2048)

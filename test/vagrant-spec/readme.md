# Running vagrant-spec

The vagrant-spec project is where Vagrant acceptance tests live.
__NOTE:__ You must use a hypervisor that allows for nested virtualization to run these tests.
So for the _vagrant_ project, it uses the vagrant vmware plugin as a host. If you
want to test this locally, please keep in mind that you will need this hypervisor
to properly run the tests.

## Requirements

- vagrant installed (from source, or from packages)
- vagrant vmware plugin
- ![vagrant](https://github.com/hashicorp/vagrant) repo
- ![vagrant-spec](https://github.com/hashicorp/vagrant-spec) repo

## Relevant environment variables:

Below are some environment variables used for running vagrant-spec. Many of
these are required for defining which hosts and guests to run the tests on.

- VAGRANT_CLOUD_TOKEN
  + Token to use if fetching a private box (like windows). This does not have to be explicitly
    set if you log into Vagrant cloud with `vagrant cloud login`.
- VAGRANT_HOST_BOXES
  - Vagrant box to use as a host for installing VirtualBox and bringing up Vagrant guests to test
- VAGRANT_GUEST_BOXES
  - Vagrant box to use as a guest to run tests on
- VAGRANT_CWD
  - Directory location of vagrant-spec Vagrantfile inside of the Vagrant source repo
- VAGRANT_VAGRANTFILE
  - Vagrantfile to use for running vagrant-spec. Unless changed, this should be set as `Vagrantfile.spec`.
- VAGRANT_HOST_MEMORY
  - Set how much memory your host will use (defaults to 2048)
- VAGRANT_SPEC_ARGS
  - Specific arguments to pass along to the vagrant-spec gem, such as running specific tests instead of the whole suite
  - Example: `--component cli`

## How to run

First, we need to build vagrant-spec and copy the built gem into the Vagrant source repo:

```
cd vagrant-spec
gem build *.gemspec
cp vagrant-spec-0.0.1.gem /path/to/vagrant/vagrant-spec.gem
```

Next, make a decision as to which host and guest boxes will be used to run the tests.
A list of valid hosts and guests can be found in the `Vagrantfile.spec` adjacent
to this readme.

From the root dir of the `vagrant` project, run the following command:

```shell
VAGRANT_CLOUD_TOKEN=REAL_TOKEN_HERE VAGRANT_HOST_BOXES=hashicorp-vagrant/centos-7.4 VAGRANT_GUEST_BOXES=hashicorp-vagrant/windows-10 VAGRANT_CWD=test/vagrant-spec/ VAGRANT_VAGRANTFILE=Vagrantfile.spec vagrant up --provider vmware_desktop
```

If you are running windows, you must give your host box more memory than the default. That can be done through the environment variable `VAGRANT_HOST_MEMORY`

```shell
VAGRANT_HOST_MEMORY=10000 VAGRANT_CLOUD_TOKEN=REAL_TOKEN_HERE VAGRANT_HOST_BOXES=hashicorp-vagrant/centos-7.4 VAGRANT_GUEST_BOXES=hashicorp-vagrant/windows-10 VAGRANT_CWD=test/vagrant-spec/ VAGRANT_VAGRANTFILE=Vagrantfile.spec vagrant up --provider vmware_desktop
```

__Note:__ It is not required that you invoke Vagrant directly in the source repo, so
if you wish to run it else where, be sure to properly set the `VAGRANT_CWD` environment
variable to point to the proper test directory inside of the Vagrant source.

### How to run specific tests

Sometimes when debugging, it's useful to only run a small subset of tests, instead of
waiting for evetything to run. This can be achieved by passing along arugments
using the `VAGRANT_SPEC_ARGS` environment variable:

For example, here is what you could set to only run cli tests

```shell
VAGRANT__SPEC_ARGS="--component cli"
```

Or with the full command....

```shell
VAGRANT_SPEC_ARGS="--component cli" VAGRANT_CLOUD_TOKEN=REAL_TOKEN_HERE VAGRANT_HOST_BOXES=hashicorp-vagrant/centos-7.4 VAGRANT_GUEST_BOXES=hashicorp-vagrant/windows-10 VAGRANT_CWD=test/vagrant-spec/ VAGRANT_VAGRANTFILE=Vagrantfile.spec vagrant up --provider vmware_desktop
```

### About Vagrantfile.spec

This Vagrantfile expects the box used to end in a specific "platform", so that it can associate
a provision script with the correct plaform. Because some boxes might not end in
their platform (like `hashicorp-vagrant/ubuntu-16.04` versus `hashicorp/bionic64`),
there is a hash defined called `PLATFORM_SCRIPT_MAPPING` that will tell vagrant
which platform script to provision with rather than relying on the box ending with
the name of the platform.

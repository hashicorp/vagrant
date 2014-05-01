---
page_title: "Vagrant 1.5 Feature Preview: Boxes 2.0"
title: "Feature Preview: Boxes 2.0"
author: Mitchell Hashimoto
author_url: https://github.com/mitchellh
---

Vagrant 1.5 will feature a revamped system for finding, downloading,
and using boxes. With Vagrant 1.5 boxes will be easier than ever to
find, build, use, update, and share. For new users, Vagrant becomes
much easier to use, and for existing users, the box system becomes much
more powerful with new features to help teams using Vagrant.

Here are some quick highlights of the new box system: box names are
now as simple as `hashicorp/precise64`, which acts as both the address
for the box as well as the name. A single box address can represent a
box for multiple providers, so you no longer need to special-case
box URLs depending on the provider in use. Boxes are now versionable,
so you can deploy box updates and users of that box are notified when
updates are available. And finally, we're launching a public service to
share, discover, and build boxes.

And, we're also happy to say that the new system is fully backwards
compatible. All old CLI commands, box files, and Vagrantfiles continue to
behave exactly the way they have before.

Read on to learn more about how all these new features work as well
as to learn some of the motivation behind the features.

READMORE

### Motivation

The box system that is in place in Vagrant 1.4 and earlier has been
mostly untouched since the first release of Vagrant. While the format
of boxes and commands were modified slightly for Vagrant 1.1 to accommodate
multiple providers, the general use has not changed at all in over four years.

During this time, we've learned a lot about how people use Vagrant and
the box system:

* Users want an easier way to find boxes, both for specific operating systems
  as well as complete development environments.

* Beginners are often confused about the existing separation of the
  logical name of the box from its URL. For example, what is the `<name>` in
  `vagrant box add <name> <url>` used for?

* With the introduction of multiple providers, boxes (specifically URLs to
  boxes) becoming specific to a provider caused confusion and some level
  of frustration.

* Box creators and organizations using Vagrant want a way to update boxes
  and notify Vagrant users of these updates. The idea of only using a
  configuration management system to keep boxes up to date doesn't always
  align with what the user of Vagrant really wants.

* Box creators want a way to share the box they've made. Additionally, box
  hosting has always been a bit of a challenge.

We believe we've successfully addressed all of this feedback for Vagrant
1.5, building a powerful new box system while retaining complete backwards
compatibility.

### Box Discovery and Sharing

For years, the only way to find other boxes has been through word of
mouth or community-powered listings of boxes. We've been grateful to
those in the community who have helped Vagrant users discovery boxes,
but we felt it was time to make discovery and sharing more official.

Coinciding with the release of Vagrant 1.5, we'll be launching a
website to find and share boxes. This website supports all of the
upcoming features of boxes such as shortnames, versions, multiple
providers, changelogs, and more.

Users will able to sign up and share their own boxes. Boxes don't have
to be physically hosted on the service. If you prefer to keep the physical
box file on your own network, we're happy to simply host the metadata.
Of course, we'll also allow you to upload the box files directly to us.

And for those with private boxes, you can create private boxes that are
only available to people or organizations you designate. More details about
all the features of this website will emerge in the coming weeks.

The availability of this resource will make it trivially easy for beginners
to find a box with the technology they're looking for. Much like the existence
of a library helps speed up development, the existence of pre-made environments
for various technologies should speed up getting started with Vagrant.

And for existing users of Vagrant, it is now easier than ever to share and
update your environments.

<div class="alert alert-block alert-info">
<strong>Interested in early access?</strong> We're looking for some
people interested in early access to begin populating the site prior
to launch. If you have boxes you'd like to share, please contact
hello@hashicorp.com for more details..
</div>

### Box Shortnames

Adding a box prior to Vagrant 1.5 required two pieces of information:
a logical name and a URL to the box itself. The logical name would then
be used as a parameter to `config.vm.box` in your Vagrantfile to map it
to the proper box.

This caused some friction for new users because the reason for having
a logical name in addition to the URL wasn't immediately clear. And for teams
heavily using Vagrant, it was sometimes complicated to maintain a unique
name across the entire team, especially since users were able to assign
arbitrary names to downloaded boxes.

With Vagrant 1.5, there is now only one thing you need to know to use
a box: the box name. For example, the precise64 box that we provide is
now named `hashicorp/precise64`. Using this name is easier than ever:

<pre class="prettyprint">
$ vagrant box add hashicorp/precise64
...
</pre>

And in your Vagrantfile:

<pre class="prettyprint">
config.vm.box = "hashicorp/precise64"
</pre>

This one name can represent a box that supports multiple providers.
You no longer need to maintain a list of differing URLs for each
provider you want to use. Below shows what it is like to add a box
that supports multiple providers:

```
$ vagrant box add hashicorp/precise64
This box can work with multiple providers! The providers
that it can work with are listed below. Please review
the list and choose the provider you will be working
with.

1.) virtualbox
2.) vmware

Enter your choice: _
```

The name is looked up in the directory of Vagrant boxes, the same
website we're launching for discovery and sharing. This results in a
nice, simple one-to-one mapping between the name in the directory
and the name actually used with Vagrant. Also, while by default it
points to our publicly hosted directory, you're able to customize
this lookup location, as well.

Of course, you're still able to host boxes at a specific URL and the
server-side component is _completely_ optional. And, as mentioned
previously, old boxes and the old usage of the CLI is still fully
supported and works the exact same way.

### Box Versions

Perhaps one of the most requested features of the past year or more
has been the ability to _update boxes_ in some way.

Whether you use bare boxes like precise64 or you use a box with everything
pre-installed on it, there comes a time when the box must be updated to
fix issues or add features. Prior to Vagrant 1.5, you had to manually
notify any users of a box that there has been an update, and these users
had no way of knowing what has changed or how many updates there have been
since they last downloaded the box. And once they updated, they had no
way of going to a past version unless they saved the box file.

Vagrant 1.5 fixes all of these problems. Boxes now have a version number,
Vagrantfiles can constrain the box version they use, and Vagrant can
automatically check for updates.

#### Constraints

By default, when adding a box (whether using `vagrant box add` or
as part of a `vagrant up`) Vagrant will always download and use the
latest version of a box. However, you can specify a version constraint
if you want to use another version or you wish to protect against a future
version breaking your development environment.

Box version constraints are simple and yet can be chained together
to form arbitrarily complex constraints. For example, to lock to a specific
version, the constraint might be `= 1.2.3`. Or, perhaps you want to make
sure the major version doesn't change, in which case the constraint can
be `>= 1.2.3, < 2.0.0`.

A box constraint can be specified when adding a box using the `--box-version`
flag, and can also be specified in the Vagrantfile using `config.vm.box_version`.

Vagrant itself can store multiple versions of a box on disk, so different
Vagrant environments can use different versions of a box at the same time
without issue.

#### Updating

Before updating, you need to know whether the box you're using is outdated
or not. There are two methods of determining if a box is outdated.

The first way is to call `vagrant box outdated`. This will check your current
Vagrant environment if it is using an outdated box. While we provide this
command, we don't actually expect it to be used very often compared to the
other method.

Instead, the other way to check for a box being outdated is simply to
run `vagrant up`. Any `vagrant up`, whether it is creating a new environment
or resuming an existing one, will check if the box it is using is out of date.
If it is, it will notify the user.

Vagrant itself won't automatically download the new box or update an
existing environment to use the new box. An existing environment might have
important state so it isn't safe for Vagrant to automatically upgrade it,
and downloading a new box could take several minutes and we won't want to
disrupt your workflow that much if you don't actually want it to download.

Instead, once you've determind your box is outdated, you can update it
by calling `vagrant box update`. This will download the new box. To use
the new box, you'll have to destroy and recreate your Vagrant environment.
When calling `vagrant up` on an uncreated Vagrant environment, Vagrant will
always automatically use the box with the latest version that satisfies
the constraints in the Vagrantfile.

But how does Vagrant know if a box has updates or where to download
these boxes? This detail is a bit out of scope for this feature preview,
but is covered
[in-depth in the upcoming documentation](https://github.com/mitchellh/vagrant/blob/master/website/docs/source/v2/boxes/versioning.html.md).

### What's Next?

The revamp to the box system is a huge feature that includes changes
to many different components of Vagrant. We're proud to be able to ship
such a large change while maintaining complete backwards compatibility.
To learn about all the details all the new box system, please
[browse the upcoming documentation for it](https://github.com/mitchellh/vagrant/blob/master/website/docs/source/v2/boxes/versioning.html.md)
which is already complete.

And that concludes the second Vagrant 1.5 feature preview blog post.
We have more on the way and I must say that this isn't even the
biggest feature coming to Vagrant 1.5! There are many more surprises
on the way, so keep an eye out for future blog posts.

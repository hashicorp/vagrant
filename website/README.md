# Vagrant Website

This subdirectory contains the entire source for the [Vagrant Website][vagrant].
This is a [Middleman][middleman] project, which builds a static site from these
source files.

## Contributions Welcome!

If you find a typo or you feel like you can improve the HTML, CSS, or
JavaScript, we welcome contributions. Feel free to open issues or pull requests
like any normal GitHub project, and we'll merge it in.

See also the [Vagrant Contributing Guide](https://github.com/hashicorp/vagrant/blob/master/.github/CONTRIBUTING.md) for more details.

## Running the Site Locally

Running the site locally is simple. Clone this repo and run `make website`.

Then open up `http://localhost:4567`. Note that some URLs you may need to append
".html" to make them work (in the navigation).

[middleman]: https://www.middlemanapp.com
[vagrant]: https://www.vagrantup.com

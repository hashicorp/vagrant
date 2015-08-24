# VagrantUp.com

This is the repository for the [Vagrant website](https://www.vagrantup.com).

This is a [Middleman](http://middlemanapp.com) project, which builds a static
site from these source files. The site is hosted on [Heroku](http://heroku.com)
and then fronted by [Fastly](http://fastly.com).

## Contributions Welcome!

If you find a typo or you feel like you can improve the HTML, CSS, or
JavaScript, we welcome contributions. Feel free to open issues or pull
requests like any normal GitHub project, and we'll merge it in.

## Running the Site Locally

Running the site locally is simple. Clone this repo and run the following
commands:

```
$ bundle
$ bundle exec middleman server
```

Then open up `localhost:4567`. Note that some URLs you may need to append
".html" to make them work (in the navigation and such).

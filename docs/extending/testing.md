---
layout: extending
title: Extending Vagrant - Testing
---
# Testing

Ruby is a very test-driven community. As such, simply providing a plugin
API wouldn't satisfy anyone, so Vagrant also provides test helpers to
make automated testing much easier. These helpers are provided in the
module `Vagrant::TestHelpers` and are test-framework agnostic, meaning
they'll work with `Test::Unit`, `RSpec`, `Shoulda`, etc.

The test helpers provide a way to do the following:

* Create custom Vagrantfile contents
* Create a `Vagrant::Environment` based on the custom Vagrantfiles
* Create Vagrant boxes
* Create action environments to test middlewares

Some more test helpers are planned, but these helpers come a long way
in making testing a breeze.

## Example: Testing Configuration

TODO

## Example: Testing a Middleware

TODO

## Example: Testing a Command

TODO

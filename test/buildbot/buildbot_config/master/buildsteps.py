"""
Contains various buildsteps that the build master uses.
"""

import os

from buildbot.steps.shell import ShellCommand

class Bundler(ShellCommand):
    """
    Runs bundler to get the dependencies for a Ruby project.
    """

    name = "bundler"
    description = "bundle install"
    descriptionDone = "bundler install complete"
    command = ["bundle", "install"]
    flunkOnFailure = True
    haltOnFailure = True

class UnitTests(ShellCommand):
    """
    Runs the unit tests via a rake command.
    """

    name = "unit tests"
    description = "unit tests"
    descriptionDone = "passed unit tests"
    command = ["rake", "test:unit"]
    flunkOnFailure = True
    haltOnFailure = True

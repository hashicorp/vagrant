"""
Contains various buildsteps that the build master uses.
"""

import os

from buildbot.steps.shell import ShellCommand
from buildbot.process.properties import WithProperties

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

class AcceptanceConfig(ShellCommand):
    """
    Creates the acceptance test configuration on the slave
    and sets a property ``acceptance_config_path`` so that
    future steps can use this for various purposes.
    """

    name = "acceptance test configuration"
    description = "create acceptance test configuration"
    descriptionDone = description
    flunkOnFailure = True
    haltOnFailure = True

    # TODO:
    #  * Generate the YAML object, download the YAML object as a file
    #    onto the slave
    #  * Store the final path into the "acceptance_config_path"
    #    property.

class AcceptanceTests(ShellCommand):
    """
    Runs the acceptance tests on the slave and knows how to
    parse the output to provide reasonable metrics and output
    on the status of the run since acceptance tests take so
    long.
    """

    name = "acceptance tests"
    description = "run acceptance tests"
    descriptionDone = description
    flunkOnFailure = True
    haltOnFailure = True

    # TODO:
    #  * Run the tests using a given file
    #  * Read the test output to provide metrics

class AcceptanceBoxes(ShellCommand):
    """
    This step will download all the boxes required for the tests.
    """

    name = "acceptance test boxes"
    description = "downloading required boxes"
    descriptionDone = description
    flunkOnFailure = True
    haltOnFailure = True

    # Make some of our variables renderable with build properties
    renderables = ShellCommand.renderables + ["box_dir"]

    def __init__(self, **kwargs):
        self.box_dir = WithProperties("%(workdir)s/boxes")
        ShellCommand.__init__(self, **kwargs)

    def start(self):
        # Set the property of the box directory so that later steps
        # can use it.
        self.setProperty("box_dir", self.box_dir, self.name)

        # Set the command to be correct
        self.setCommand(["rake", "acceptance:boxes[%s]" % self.box_dir])

        # Run the actual start method
        ShellCommand.start(self)

class AcceptanceConfig(ShellCommand):
    """
    This step generates the configuration for the acceptance test.
    """

    name = "acceptance test config"
    description = "generating config"
    descriptionDone = "config generated"
    command = ["rake", WithProperties("acceptance:config[%(box_dir)s]")]
    flunkOnFailure = True
    haltOnFailure = True

    def commandComplete(self, cmd):
        # Set a property with the location of the config file
        config_path = os.path.join(self.getProperty("workdir"),
                                   self.getWorkdir(), "acceptance_config.yml")
        self.setProperty("acceptance_config_path", config_path, self.name)

        ShellCommand.commandComplete(self, cmd)

class AcceptanceTests(ShellCommand):
    """
    This step runs the actual acceptance tests.
    """

    name = "acceptance tests"
    description = "running"
    descriptionDone = "done"
    command = ["rake", "test:acceptance"]
    flunkOnFailure = True
    haltOnFailure = True

    def __init__(self, **kwargs):
        # Make sure that the proper environment variables for the test
        # get passed through to the slave
        kwargs["env"] = { "ACCEPTANCE_CONFIG": WithProperties("%(acceptance_config_path)s") }
        ShellCommand.__init__(self, **kwargs)

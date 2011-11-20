"""
This module contains the logic to create and return the various builders
that this buildmaster supports. The builders are responsible for taking
a set of changes and giving the steps necessary to build the project.
"""

from buildbot.config import BuilderConfig
from buildbot.process.factory import BuildFactory
from buildbot.process.properties import WithProperties
from buildbot.steps.source.git import Git

from buildbot_config.master import buildsteps

def get_builders(slaves):
    """
    This returns a list of builder configurations for the given
    slaves.
    """
    return get_vagrant_builders("master", slaves)

def get_vagrant_builders(branch, slaves):
    """
    This returns a list of the builders that represent the entire
    chain for a given branch (unit, acceptance, packaging builds).
    """
    platforms = ["linux", "osx", "win"]
    builders = []

    for platform in platforms:
        platform_slaves = [s.slavename for s in slaves if platform in s.slavename]

        if len(platform_slaves) > 0:
            unit = BuilderConfig(
                name="%s-%s-unit" % (platform, branch),
                slavenames=platform_slaves,
                factory=make_vagrant_unit_factory(branch))

            acceptance = BuilderConfig(
                name="%s-%s-acceptance" % (platform, branch),
                slavenames=platform_slaves,
                factory=make_vagrant_acceptance_factory(branch))

            builders.extend([unit, acceptance])

    return builders

def make_vagrant_unit_factory(branch):
    """
    This returns the factory that runs the Vagrant unit tests.
    """
    f = BuildFactory()
    f.addStep(Git(repourl="git://github.com/mitchellh/vagrant.git",
                  branch=branch,
                  mode="full",
                  method="fresh",
                  shallow=True))
    f.addStep(buildsteps.Bundler())
    f.addStep(buildsteps.UnitTests())

    return f

def make_vagrant_acceptance_factory(branch):
    """
    This returns a build factory that knows how to run the Vagrant
    acceptance tests.
    """
    f = BuildFactory()
    f.addStep(Git(repourl="git://github.com/mitchellh/vagrant.git",
                  branch=branch,
                  mode="full",
                  method="fresh",
                  shallow=True))
    f.addStep(buildsteps.Bundler())
    f.addStep(buildsteps.AcceptanceBoxes())
    f.addStep(buildsteps.AcceptanceConfig())
    f.addStep(buildsteps.AcceptanceTests())

    return f

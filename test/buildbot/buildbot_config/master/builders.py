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
    f = BuildFactory()
    # TODO

    return [BuilderConfig(
            name="vagrant-master",
            slavenames=[s.slavename for s in slaves],
            factory=f)
        ]

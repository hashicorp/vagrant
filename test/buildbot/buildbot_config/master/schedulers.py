"""
This module contains the logic which returns the set of
schedulers to use for the build master.
"""

from buildbot.changes.filter import ChangeFilter
from buildbot.schedulers.basic import (
    Dependent,
    SingleBranchScheduler)

def get_schedulers(builders):
    platforms = ["linux", "osx", "win"]
    schedulers = []

    for platform in platforms:
        platform_builders = [b for b in builders if platform in b.name]

        # Unit tests for this platform
        unit_builders = [b.name for b in platform_builders if "unit" in b.name]
        master_unit = SingleBranchScheduler(name="%s-master-unit" % platform,
                                            change_filter=ChangeFilter(branch="master"),
                                            treeStableTimer=60,
                                            builderNames=unit_builders)

        acceptance_builders = [b.name for b in platform_builders if "acceptance" in b.name]
        master_acceptance = Dependent(name="%s-master-acceptance" % platform,
                                      upstream=master_unit,
                                      builderNames=acceptance_builders)

        schedulers.extend([master_unit, master_acceptance])

    return schedulers

"""
This module contains the logic which returns the set of
schedulers to use for the build master.
"""

from buildbot.changes.filter import ChangeFilter
from buildbot.schedulers.basic import (
    Dependent,
    SingleBranchScheduler)

def get_schedulers(builders):
    # Run the unit tests for master
    unit_builders = [b.name for b in builders if "unit" in b.name]
    master_unit = SingleBranchScheduler(name="master-unit",
                                 change_filter=ChangeFilter(branch="master"),
                                 treeStableTimer=60,
                                 builderNames=unit_builders)

    acceptance_builders = [b.name for b in builders if "acceptance" in b.name]
    master_acceptance = Dependent(name="master-acceptance",
                                  upstream=master_unit,
                                  builderNames=acceptance_builders)

    return [master_unit, master_acceptance]

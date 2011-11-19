"""
This module contains the logic which returns the set of
schedulers to use for the build master.
"""

from buildbot.changes.filter import ChangeFilter
from buildbot.schedulers.basic import (
    Dependent,
    SingleBranchScheduler)

def get_schedulers():
    # Run the unit tests for master
    master_unit = SingleBranchScheduler(name="master-unit",
                                 change_filter=ChangeFilter(branch="master"),
                                 treeStableTimer=60,
                                 builderNames=["vagrant-master-unit"])

    master_acceptance = Dependent(name="master-acceptance",
                                  upstream=master_unit,
                                  builderNames=["vagrant-master-acceptance"])

    return [master_unit, master_acceptance]

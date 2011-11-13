"""
This module contains the logic which returns the set of
schedulers to use for the build master.
"""

from buildbot.changes.filter import ChangeFilter
from buildbot.schedulers.basic import SingleBranchScheduler

def get_schedulers():
    # Run the unit tests for master
    master_unit = SingleBranchScheduler(name="full",
                                 change_filter=ChangeFilter(branch="master"),
                                 treeStableTimer=60,
                                 builderNames=["vagrant-master-unit"])

    return [master_unit]

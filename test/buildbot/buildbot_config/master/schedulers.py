"""
This module contains the logic which returns the set of
schedulers to use for the build master.
"""

from buildbot.changes.filter import ChangeFilter
from buildbot.schedulers.basic import SingleBranchScheduler

def get_schedulers():
    full = SingleBranchScheduler(name="full",
                                 change_filter=ChangeFilter(branch="master"),
                                 treeStableTimer=60,
                                 builderNames=["vagrant-master"])
    return [full]

"""
This module returns the given status handlers to enable for the
buildbot master.
"""

from buildbot.status import html
from buildbot.status.web.authz import Authz

def get_status(options):
    """
    Returns a list of status targets for the build master.
    """
    authz = Authz(
        gracefulShutdown = True,
        forceBuild = True,
        forceAllBuilds = True,
        pingBuilder = True,
        stopBuild = True,
        stopAllBuilds = True,
        cancelPendingBuild = True,
        stopChange = True,
        cleanShutdown= True
        )

    web_status = html.WebStatus(
        http_port = options.web_port,
        authz = authz,
        order_console_by_time = True,
        change_hook_dialects=dict(github=True)
        )

    return [web_status]

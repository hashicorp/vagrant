"""
This module returns the given status handlers to enable for the
buildbot master.
"""

from buildbot.status import html, words
from buildbot.status.web.authz import Authz
from buildbot.status.web.auth import BasicAuth

def get_status(options):
    """
    Returns a list of status targets for the build master.
    """
    # Load the users that are allowed to perform authenticated
    # actions from the configuration
    auth_users = []
    if options.http_users is not None:
        for pair in options.http_users.split(","):
            user, password = pair.split(":")
            auth_users.append((user, password))

    # Setup the rules for who can do what to the WebStatus
    authz = Authz(
        auth = BasicAuth(auth_users),
        gracefulShutdown = False,
        forceBuild = 'auth',
        forceAllBuilds = 'auth',
        pingBuilder = True,
        stopBuild = 'auth',
        stopAllBuilds = 'auth',
        cancelPendingBuild = 'auth',
        stopChange = 'auth',
        cleanShutdown= False
        )

    # The web status gives us the nice web interface to our buildbot
    web_status = html.WebStatus(
        http_port = options.web_port,
        authz = authz,
        order_console_by_time = True,
        change_hook_dialects=dict(github=True)
        )

    # Hook up an IRC bot into our channel
    irc = words.IRC("irc.freenode.net", "vagrant-ci",
                    channels=[{"channel": "#vagrant"}],
                    notify_events={
                        'exception': 1,
                        'successToFailure': 1,
                        'failureToSuccess': 1})

    return [web_status, irc]

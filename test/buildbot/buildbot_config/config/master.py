"""
This module contains the choices definition for settings required
for the build master to run.
"""

from choices import Choices

from loader import load_settings

#----------------------------------------------------------------------
# Define the Settings
#----------------------------------------------------------------------
c = Choices()
c.define('title', type=str, help="Buildmaster title")
c.define('title_url', type=str, help="URL for title page")
c.define('buildbot_url', type=str, help="URL to the buildbot master.")
c.define('slaves', type=str, help="A list of the slave machines. The format should be name:password,name:password,...")
c.define('web_port', type=int, help="Port to listen on for web service.")
c.define('http_users', type=str, help="username:password list of users.")

#----------------------------------------------------------------------
# Load the Settings
#----------------------------------------------------------------------
options = load_settings(c, "master")

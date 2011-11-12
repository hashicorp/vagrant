"""
This module contains the choices definition for settings required for the
build slave to run.
"""

from choices import Choices

from loader import load_settings

#----------------------------------------------------------------------
# Define the Settings
#----------------------------------------------------------------------
c = Choices()
c.define("master_host", type=str, help="Host of the build master.")
c.define("master_port", type=int, help="Port that is listening or build masters.")
c.define("name", type=str, help="Name of the slave machine.")
c.define("password", type=str, help="Password for the slave machine to communicate with the master.")

#----------------------------------------------------------------------
# Load the Settings
#----------------------------------------------------------------------
options = load_settings(c, "slave")

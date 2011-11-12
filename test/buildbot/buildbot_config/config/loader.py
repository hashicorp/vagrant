"""
This module contains the configuration loader for a specific
choices instance. This is used internally to load the settings.
"""

import os

from choices import ConfigFileLoader

def load_settings(choices, type):
    """
    This will load the proper settings for the given choices
    instance.

    :Parameters:
      - `choices`: The choices instance to load.
      - `type`: The type of configuration, either "master" or
        "slave"
    """
    if "BUILDBOT_CONFIG" not in os.environ:
        raise ValueError, "BUILDBOT_CONFIG must be set to point to where the configuration file is."

    choices.add_loader(ConfigFileLoader(os.environ["BUILDBOT_CONFIG"], type))
    return choices.load()

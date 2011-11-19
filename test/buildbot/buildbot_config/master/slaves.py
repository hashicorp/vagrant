"""
This module contains the classes and methods which help load the
list of available build slaves based on the configuration.
"""

from buildbot.buildslave import BuildSlave

class BuildSlavesFromSlaveConfigs(list):
    """
    This object turns the ``SlaveConfig`` objects into actual
    ``BuildSlave`` objects. This list can be directly used as the
    setting.
    """

    def __init__(self, configs):
        for config in configs:
            self.append(BuildSlave(config.name, config.password))

class SlaveListFromConfig(list):
    """
    This object knows how to parse the slave configuration settings
    and load them into ``SlaveConfig`` value objects. The results
    can be read directly from this list.
    """

    def __init__(self, config):
        for config in self._slave_configs(config):
            self.append(config)

    def _slave_configs(self, config):
        """
        Returns an array of all the slaves that were configured
        with the given configuration string.
        """
        results = []
        for single in config.split(","):
            results.append(SlaveConfig(*single.split(":")))

        return results

class SlaveConfig(object):
    """
    This is a value class, meant to be immutable, representing
    the configuration of a single slave.
    """

    def __init__(self, name, password):
        self.name = name
        self.password = password

    def __eq__(self, other):
        """
        Provides equality tests for slave configurations, specifically
        for tests.
        """
        return self.__dict__ == other.__dict__

# Shortcut methods to make things a bit nicer
def get_slaves_from_config(config):
    return BuildSlavesFromSlaveConfigs(SlaveListFromConfig(config))

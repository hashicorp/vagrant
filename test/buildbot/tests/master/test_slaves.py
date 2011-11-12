from buildbot.buildslave import BuildSlave

from buildbot_config.master.slaves import (
    BuildSlavesFromSlaveConfigs,
    SlaveConfig,
    SlaveListFromConfig)

class TestSlaveListFromConfig(object):
    Klass = SlaveListFromConfig

    def test_parse_single(self):
        """
        Tests that the config parser can parse a single
        slave.
        """
        instance = self.Klass("foo:bar")
        assert 1 == len(instance)
        assert SlaveConfig("foo", "bar") == instance[0]

    def test_parse_multiple(self):
        """
        Tests that the config parser can parse multiple
        slaves.
        """
        instance = self.Klass("foo:bar,bar:baz")
        expected = [SlaveConfig("foo", "bar"), SlaveConfig("bar", "baz")]

        assert 2 == len(instance)
        assert expected == instance

class TestBuildSlavesFromSlaveConfig(object):
    Klass = BuildSlavesFromSlaveConfigs

    def test_returns_build_slaves(self):
        """
        Tests that build slaves are properly returned for each
        slave configuration.
        """
        instance = self.Klass([SlaveConfig("foo", "bar")])
        assert 1 == len(instance)
        assert isinstance(instance[0], BuildSlave)

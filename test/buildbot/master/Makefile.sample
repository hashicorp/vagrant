# -*- makefile -*-

# This is a simple makefile which lives in a buildmaster
# directory (next to the buildbot.tac file). It allows you to start/stop the
# master by doing 'make start' or 'make stop'.

# The 'reconfig' target will tell a buildmaster to reload its config file.

start:
	twistd --no_save -y buildbot.tac

stop:
	if [ -e twistd.pid ]; \
	then kill `cat twistd.pid`; \
	else echo "Nothing to stop."; \
	fi

reconfig:
	if [ -e twistd.pid ]; \
	then kill -HUP `cat twistd.pid`; \
	else echo "Nothing to reconfig."; \
	fi

log:
	if [ -e twistd.log ]; \
	then tail -f twistd.log; \
	else echo "Nothing to tail."; \
	fi

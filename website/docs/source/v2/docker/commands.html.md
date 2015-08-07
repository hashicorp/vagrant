---
page_title: "Commands - Docker Provider"
sidebar_current: "docker-commands"
---

# Docker Commands

The Docker provider exposes some additional Vagrant commands that are
useful for interacting with Docker containers. This helps with your
workflow on top of Vagrant so that you have full access to Docker
underneath.

### docker-logs

`vagrant docker-logs` can be used to see the logs of a running container.
Because most Docker containers are single-process, this is used to see
the logs of that one process. Additionally, the logs can be tailed.

### docker-run

`vagrant docker-run` can be used to run one-off commands against
a Docker container. The one-off Docker container that is started shares
all the volumes, links, etc. of the original Docker container. An
example is shown below:

<pre class="prettyprint">
$ vagrant docker-run app -- rake db:migrate
</pre>

The above would run `rake db:migrate` in the context of an `app` container.

### docker-exec

`vagrant docker-exec` can be used to run one-off commands against
a Docker container that is currently running, or if the container
is not running the container will be started and remain running
after the command has completed.

<pre class="prettyprint">
$ vagrant docker-exec app -- rake db:migrate
</pre>

The above would run `rake db:migrate` in the context of an `app` container.

### docker-shell

`vagrant docker-shell` can be used open an interactive bash shell for a running
container. If the container is not running, and new container will be started
and will remain running after the shell has been terminated. This command is a 
shortcut for `vagrant docker-exec -t app -- bash` An example is shown below:

<pre class="prettyprint">
$ vagrant docker-shell app
</pre>

The above would open an interactive bash shell to the `app` container.

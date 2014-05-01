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

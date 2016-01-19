---
layout: "docs"
page_title: "Machine Readable Output - Command-Line Interface"
sidebar_current: "cli-machinereadable"
description: |-
  Almost all commands in Vagrant accept a --machine-readable flag to enable
  machine-readable output mode.
---

# Machine Readable Output

Every Vagrant command accepts a `--machine-readable` flag which enables
machine readable output mode. In this mode, the output to the terminal
is replaced with machine-friendly output.

This mode makes it easy to programmatically execute Vagrant and read data
out of it. This output format is protected by our
[backwards compatibility](/docs/installation/backwards-compatibility.html)
policy. Until Vagrant 2.0 is released, however, the machine readable output
may change as we determine more use cases for it. But the backwards
compatibility promise should make it safe to write client libraries to
parse the output format.

<div class="alert alert-warning">
  <strong>Advanced topic!</strong> This is an advanced topic for use only if
  you want to programmatically execute Vagrant. If you are just getting started
  with Vagrant, you may safely skip this section.
</div>

## Work-In-Progress

The machine-readable output is very new (released as part of Vagrant 1.4).
We're still gathering use cases for it and building up the output for each
of the commands. It is likely that what you may want to achieve with
the machine-readable output is not possible due to missing information.

In this case, we ask that you please
[open an issue](https://github.com/mitchellh/vagrant/issues)
requesting that certain information become available. We will most likely add
it!

## Format

The machine readable format is a line-oriented, comma-delimeted text format.
This makes it extremely easy to parse using standard Unix tools such as awk or
grep in addition to full programming languages like Ruby or Python.

The format is:

```
timestamp,target,type,data...
```

Each component is explained below:

* **timestamp** is a Unix timestamp in UTC of when the message was printed.

* **target** is the target of the following output. This is empty if the
  message is related to Vagrant globally. Otherwise, this is generally a machine
  name so you can relate output to a specific machine when multi-VM is in use.

* **type** is the type of machine-readable message being outputted. There are
  a set of standard types which are covered later.

* **data** is zero or more comma-separated values associated with the prior
  type. The exact amount and meaning of this data is type-dependent, so you
  must read the documentation associated with the type to understand fully.

Within the format, if data contains a comma, it is replaced with
`%!(VAGRANT_COMMA)`. This was preferred over an escape character such as \'
because it is more friendly to tools like awk.

Newlines within the format are replaced with their respective standard escape
sequence. Newlines become a literal `\n` within the output. Carriage returns
become a literal `\r`.

## Types

This section documents all the available types that may be outputted
with the machine-readable output.

<table class="table table-hover table-bordered mr-types">
<thead>
<tr>
<th class="mr-type">Type</th>
<th>Description</th>
</tr>
</thead>

<tr>
<td>box-name</td>
<td>
  Name of a box installed into Vagrant.
</td>
</tr>

<tr>
<td>box-provider</td>
<td>
  Provider for an installed box.
</td>
</tr>

<tr>
<td>cli-command</td>
<td>
  A subcommand of <code>vagrant</code> that is available.
</td>
</tr>

<tr>
<td>error-exit</td>
<td>
  An error occurred that caused Vagrant to exit. This contains that
  error. Contains two data elements: type of error, error message.
</td>
</tr>

<tr>
<td>provider-name</td>
<td>
  The provider name of the target machine.
  <span class="label">targeted</span>
</td>
</tr>

<tr>
<td>ssh-config</td>
<td>
  The OpenSSH compatible SSH config for a machine. This is usually
    the result of the "ssh-config" command.
  <span class="label">targeted</span>
</td>
</tr>

<tr>
<td>state</td>
<td>
  The state ID of the target machine.
  <span class="label">targeted</span>
</td>
</tr>

<tr>
<td>state-human-long</td>
<td>
  Human-readable description of the state of the machine. This is the
  long version, and may be a paragraph or longer.
  <span class="label">targeted</span>
</td>
</tr>

<tr>
<td>state-human-short</td>
<td>
  Human-readable description of the state of the machine. This is the
  short version, limited to at most a sentence.
  <span class="label">targeted</span>
</td>
</tr>

</table>

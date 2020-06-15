---
name: Vagrant Bug Report
about: For when Vagrant is not working as expected or you have encountered a bug

---

Please note that the Vagrant issue tracker is in priority reserved for bug reports and enhancements. For general usage questions, please use
HashiCorp Discuss: https://discuss.hashicorp.com/c/vagrant/24 Thank you!

When submitting a bug report, please provide the minimal configuration and required information necessary to reliably reproduce the issue. It
should include a basic Vagrantfile that only contains settings to reproduce the described behavior.

**Tip:** Before submitting your issue, don't hesitate to remove the above introductory text, possible empty sections (e.g. References), and this tip.

### Vagrant version

Run `vagrant -v` to show the version. If you are not running the latest version
of Vagrant, please upgrade before submitting an issue.

### Host operating system

This is the operating system that you run locally.

### Guest operating system

This is the operating system you run in the virtual machine.

### Vagrantfile

```ruby
# Copy-paste your Vagrantfile here (but don't include sensitive information such as passwords, authentication tokens, or email addresses)
```

Please ensure the Vagrantfile provided is a minimal Vagrantfile which contains
only the required configuration to reproduce the behavior. Please note that if
your Vagrantfile contains an excess of configuration unrelated the the reported
issue, or is in a different format, we may be unable to assist with your issue.
Always start with a minimal Vagrantfile and include only the relevant configuration
to reproduce the reported behavior.

### Debug output

Provide a link to a GitHub Gist containing the complete debug output:
https://www.vagrantup.com/docs/other/debugging.html. The debug output should
be very long. Do NOT paste the debug output in the issue, just paste the
link to the Gist.

### Expected behavior

What should have happened?

### Actual behavior

What actually happened?

### Steps to reproduce

1.
2.
3.

### References

Are there any other GitHub issues (open or closed) that should be linked here?
For example:
- GH-1234
- ...

# How to contribute

We like to encourage you to contribute to the repository.
This should be as easy as possible for you but there are a few things to consider when contributing.
The following guidelines for contribution should be followed if you want to submit a pull request.

## How to prepare

* You need a [GitHub account](https://github.com/signup/free)
* Submit an [issue ticket](https://github.com/mitchellh/vagrant/issues) for your issue if there is not one yet.
	* Describe the issue and include steps to reproduce when it's a bug.
	* Ensure to mention the earliest version that you know is affected.
  * If you plan on submitting a bug report, please submit debug-level logs along
    with the report using [gist](https://gist.github.com/) or some other paste
    service by prepending `VAGRANT_LOG=debug` to your `vagrant` commands.
* Fork the repository on GitHub

## Make Changes

* In your forked repository, create a topic branch for your upcoming patch.
	* Usually this is based on the master branch.
	* Create a branch based on master; `git branch
	fix/master/my_contribution master` then checkout the new branch with `git
	checkout fix/master/my_contribution`.  Please avoid working directly on the `master` branch.
* Make commits of logical units and describe them properly.
* Check for unnecessary whitespace with `git diff --check` before committing.

* If possible, submit tests to your patch / new feature so it can be tested easily.
* Assure nothing is broken by running all the tests.

## Submit Changes

* Push your changes to a topic branch in your fork of the repository.
* Open a pull request to the original repository and choose the right original branch you want to patch.
* If not done in commit messages (which you really should do) please reference and update your issue with the code changes.
* Even if you have write access to the repository, do not directly push or merge pull-requests. Let another team member review your pull request and approve.

# Additional Resources

* [General GitHub documentation](https://help.github.com/)
* [GitHub pull request documentation](https://help.github.com/send-pull-requests/)

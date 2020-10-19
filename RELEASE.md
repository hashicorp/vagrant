# Releasing Vagrant

This documents how to release Vagrant. Various steps in this document will
require privileged access to private systems, so this document is only
targeted at Vagrant core members who have the ability to cut a release.

1. Update `version.txt` to the version you want to release.

1. Update `CHANGELOG.md` to have a header with the release version and date.

1. Commit those changes and also tag the release with the version:

    ```
    $ git tag vX.Y.Z
    $ git push --tags
    ```

1. This will automatically trigger an installer creation, upload the artifacts,
  and publish the release.

1. After the release has been published update the `website/config.rb` to point
  to the latest version, commit, and push.

1. Publish the webiste by deleting the `stable-website` branch, recreate the branch,
  and force push. From the `main` branch, run:

   ```
   $ git branch -D stable-website
   $ git branch -b stable-website
   $ git push -f origin stable-website
   ```

1. Update `version.txt` to append `.dev` and add a new blank entry in the
  CHANGELOG, commit, and push.

1. Update [Checkpoint](https://checkpoint.hashicorp.com/control) with the new
  version.

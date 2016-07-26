# Releasing Vagrant

This documents how to release Vagrant. Various steps in this document will
require privileged access to private systems, so this document is only
targetted at Vagrant core members who have the ability to cut a release.

1. Update `version.txt` to the version you want to release.

1. Update `CHANGELOG.md` to have a header with the release version and date.

1. Commit those changes and also tag the release with the version:

    ```
    $ git tag vX.Y.Z
    $ git push --tags
    ```

1. Trigger an installer creation run within the HashiCorp Bamboo installation.
  This will take around 45 minutes.

1. Download all the resulting artifacts into the `pkg/dist` folder relative to
  the Vagrant repository on your local machine.

1. Run `./scripts/sign.sh` with the version that is being created. This must be
    run from the Vagrant repo root. This will GPG sign and checksum the files.

1. Run the following command to upload the binaries to the releases site:

    ```
    $ hc-releases upload pkg/dist
    ```

1. Publish the new index files to the releases site:

    ```
    $ hc-releases publish
    ```

1. Update `website/config.rb` to point to the latest version, commit, and push.

1. Tell HashiBot to deploy in ``#deploys`

    ```
    hashibot deploy vagrant
    ```

1. Update `version.txt` to append `.dev` and add a new blank entry in the
  CHANGELOG, commit, and push.

1. Update [Checkpoint](https://checkpoint.hashicorp.com/control) with the new
  version.

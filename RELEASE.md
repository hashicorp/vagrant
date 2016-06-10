# Releasing Vagrant

This documents how to release Vagrant. Various steps in this document will
require privileged access to private systems, so this document is only
targetted at Vagrant core members who have the ability to cut a release.

  1. Update `version.txt` to the version you want to release.

  1. Update `CHANGELOG.md` to have a header with the release version and date.

  1. Commit those changes and also tag the release with the version:
     `git tag vX.Y.Z`. Push them.

  1. Trigger an installer creation run within the HashiCorp Bamboo
     installation. This will take around 45 minutes.

  1. Download all the resulting artifacts into the `pkg/dist` folder
     relative to the Vagrant repository.

  1. Run the awkwardly-named `./scripts/bintray_upload.sh` with the version
     that is being created. This must be run from the Vagrant repo root.
     This will GPG sign and checksum the files.

  1. Run `hc-releases -upload pkg/dist` to upload the releases to S3.

  1. Update `website/config.rb` to point to the latest version. Commit and push.

  1. Use Atlas `hashicorp/vagrant-www` to deploy the site by queueing a build.

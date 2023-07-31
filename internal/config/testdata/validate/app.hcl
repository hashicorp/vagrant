# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

project = "foo"

app "foo" {
    build {
      use "docker" {}
    }

    deploy {
      use "docker" {}
    }
}

app "relative_above_root" {
    path = "../nope"

    build {
      use "docker" {}
    }

    deploy {
      use "docker" {}
    }
}

app "system_label" {
    labels = {
        "vagrant/foo" = "bar"
    }

    build {
      use "docker" {}
    }

    deploy {
      use "docker" {}
    }
}

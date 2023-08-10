# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

project = "foo"

app "test" {
    build {
        labels = {
            "foo" = "bar"
        }

        registry {
            use "docker" {}
        }
    }
}

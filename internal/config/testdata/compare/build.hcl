# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

project = "foo"

app "test" {
    build {
        labels = {
            "foo" = "bar"
        }
    }
}

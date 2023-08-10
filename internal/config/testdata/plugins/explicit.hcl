# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

project = "hello"

plugin "go1" {
    type {
        mapper = true
    }
}

plugin "go2" {
    type {
        registry = true
    }
}

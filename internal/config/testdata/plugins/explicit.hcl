# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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

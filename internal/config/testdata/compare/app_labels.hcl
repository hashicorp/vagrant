# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

project = "foo"

app "bar" {
    path = "./bar"

    labels = {
        "pwd": path.pwd,
        "project": path.project,
        "app": path.app,
    }
}

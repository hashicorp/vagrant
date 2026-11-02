// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

// Package core exposes a high-level API for the expected operations of
// the project. This can be consumed by the CLI, web APIs, etc. This is the
// safest set of APIs to use.
//
// The entrypoint for core is Project initialized with NewProject. All
// further APIs and operations hang off of this struct. For example, to
// initiate a build for an app in a project you could use Project.App.Build().
//
// Eventually this package will also contain UI abstractions or hooks so that
// you can build a more responsive UI around the long-running operations of
// this package.
package core

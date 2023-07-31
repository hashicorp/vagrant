// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package version

import (
	"bytes"
	"fmt"
	"regexp"
)

var (
	// The git commit that was compiled. This will be filled in by the compiler.
	GitCommit   string
	GitDescribe string

	Version           = "3.0.0"
	VersionPrerelease = ""
	VersionMetadata   = ""
)

// VersionInfo
type VersionInfo struct {
	Revision          string
	Version           string
	VersionPrerelease string
	VersionMetadata   string
	GitDescribe       string
}

func GetVersion() *VersionInfo {
	ver := Version
	rel := VersionPrerelease
	md := VersionMetadata
	desc := GitDescribe
	if desc != "" {
		// git describe is based off tags which always start with v, but
		// Vagrant has always reported its version number w/o a leading v in
		// the CLI, so we'll remove it here
		re := regexp.MustCompile(`^v`)
		ver = re.ReplaceAllString(desc, "")
	} else {
		ver = fmt.Sprintf("%s", ver)
	}
	if desc == "" && rel == "" && VersionPrerelease != "" {
		rel = "dev"
	}

	return &VersionInfo{
		Revision:          GitCommit,
		Version:           ver,
		VersionPrerelease: rel,
		VersionMetadata:   md,
		GitDescribe:       desc,
	}
}

func (c *VersionInfo) VersionNumber() string {
	if Version == "unknown" && VersionPrerelease == "unknown" {
		return "(version unknown)"
	}

	version := c.Version

	if c.VersionPrerelease != "" && c.GitDescribe == "" {
		version = fmt.Sprintf("%s-%s", c.Version, c.VersionPrerelease)
	}

	if c.VersionMetadata != "" {
		version = fmt.Sprintf("%s+%s", c.Version, c.VersionMetadata)
	}

	return version
}

func (c *VersionInfo) FullVersionNumber(rev bool) string {
	var versionString bytes.Buffer

	if Version == "unknown" && VersionPrerelease == "unknown" {
		return "Vagrant (version unknown)"
	}

	fmt.Fprintf(&versionString, "Vagrant %s", c.Version)
	if c.VersionPrerelease != "" && c.GitDescribe == "" {
		fmt.Fprintf(&versionString, "-%s", c.VersionPrerelease)
	}

	if c.VersionMetadata != "" {
		fmt.Fprintf(&versionString, "+%s", c.VersionMetadata)
	}

	if rev && c.Revision != "" {
		fmt.Fprintf(&versionString, " (%s)", c.Revision)
	}

	return versionString.String()
}

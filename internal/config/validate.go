// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package config

import (
	"fmt"
	"regexp"
	"strings"
)

// TODO(spox): match back up with waypoint validation implementation
// once we actually get proper configuration going
func (c *Config) Validate() error {
	return nil
}

// ValidateLabels validates a set of labels. This ensures that labels are
// set according to our requirements:
//
//   * key and value length can't be greater than 255 characters each
//   * keys must be in hostname format (RFC 952)
//   * keys can't be prefixed with "waypoint/" which is reserved for system use
//
func ValidateLabels(labels map[string]string) []error {
	var errs []error
	for k, v := range labels {
		name := fmt.Sprintf("label[%s]", k)

		if strings.HasPrefix(k, "waypoint/") {
			errs = append(errs, fmt.Errorf("%s: prefix 'waypoint/' is reserved for system use", name))
		}

		if len(k) > 255 {
			errs = append(errs, fmt.Errorf("%s: key must be less than or equal to 255 characters", name))
		}

		if !hostnameRegexRFC952.MatchString(strings.SplitN(k, "/", 2)[0]) {
			errs = append(errs, fmt.Errorf("%s: key before '/' must be a valid hostname (RFC 952)", name))
		}

		if len(v) > 255 {
			errs = append(errs, fmt.Errorf("%s: value must be less than or equal to 255 characters", name))
		}
	}

	return errs
}

var hostnameRegexRFC952 = regexp.MustCompile(`^[a-zA-Z]([a-zA-Z0-9\-]+[\.]?)*[a-zA-Z0-9]$`)

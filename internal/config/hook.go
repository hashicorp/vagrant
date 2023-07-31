// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package config

// Hook is the configuration for a hook that runs at specified times.
type Hook struct {
	When      string   `hcl:"when,attr"`
	Command   []string `hcl:"command,attr"`
	OnFailure string   `hcl:"on_failure,optional"`
}

func (h *Hook) ContinueOnFailure() bool {
	return h.OnFailure == "continue"
}

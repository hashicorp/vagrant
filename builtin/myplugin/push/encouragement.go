// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package push

import (
	"encoding/json"
	"fmt"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"google.golang.org/protobuf/types/known/structpb"
)

// Encouragement is a push strategy that provides encouragement for the code
// you push. Everybody could use some encouragement sometimes!
type Encouragement struct{}

func (e *Encouragement) PushFunc() interface{} {
	return e.Push
}

// Push runs this is the first ever Golang push plugin!
func (e *Encouragement) Push(ui terminal.UI, proj core.Project) error {
	ui.Output("You've invoked a push plugin written in Go! Great work!")

	pushConfig, err := findPushConfig(proj, "myplugin")
	if err != nil {
		return err
	}

	if pushConfig != nil {
		ui.Output("Look a this nice config you sent along too!")
		ui.Output("We'll print it as JSON for fun:")

		config, err := unpackConfig(pushConfig)
		if err != nil {
			return err
		}

		jsonConfig, err := json.MarshalIndent(config, "  ", "\t")
		if err != nil {
			return err
		}
		ui.Output("  %s", jsonConfig)
	}

	return nil
}

// findPushConfig finds the relevant PushConfig for the name given.
//
// For now, there are no config related helpers, so each push plugin needs to
// walk its way down to its relevant config in the Vagrantfile.
func findPushConfig(proj core.Project, name string) (*vagrant_plugin_sdk.Vagrantfile_PushConfig, error) {
	return nil, fmt.Errorf("unimplemented")
	// v, err := proj.Config()
	// if err != nil {
	// 	return nil, err
	// }
	// for _, p := range v.GetPushConfigs() {
	// 	if p.GetName() == name {
	// 		return p, nil
	// 	}
	// }
	// return nil, nil
}

// unpackConfig takes a PushConfig and unpack the underlying map of config
//
// For now, there are no config related helpers, so each push plugin needs to
// unpack from a generic struct into whatever types it might need. For this
// demo plugin we're just leaving it untyped.
func unpackConfig(pc *vagrant_plugin_sdk.Vagrantfile_PushConfig) (map[string]interface{}, error) {
	gc := pc.GetConfig()
	s := &structpb.Struct{}
	err := gc.GetConfig().UnmarshalTo(s)
	if err != nil {
		return nil, err
	}
	return s.AsMap(), nil
}

var (
	_ component.Push = (*Encouragement)(nil)
)

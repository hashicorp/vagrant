package push

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

// This is a push strategy that provides encouragement for the code you push
type Encouragement struct{}

func (e *Encouragement) PushFunc() interface{} {
	return e.Push
}

func (e *Encouragement) Push(ui terminal.UI, proj core.Project) error {
	ui.Output("You've invoked a push plugin written in Go! Great work!")
	return nil
}

var (
	_ component.Push = (*Encouragement)(nil)
)

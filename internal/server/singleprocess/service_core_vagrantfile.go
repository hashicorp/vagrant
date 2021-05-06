package singleprocess

import (
	"context"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
)

func (s *service) GetVagrantfile(
	ctx context.Context,
	in *vagrant_plugin_sdk.Vagrantfile_GetVagrantfileRequest,
) (result *vagrant_plugin_sdk.Vagrantfile_GetVagrantfileResponse, err error) {
	return nil, nil
}

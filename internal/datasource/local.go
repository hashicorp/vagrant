// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package datasource

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/hcl/v2"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type LocalSource struct{}

func newLocalSource() Sourcer { return &LocalSource{} }

func (s *LocalSource) ProjectSource(body hcl.Body, ctx *hcl.EvalContext) (*vagrant_server.Job_DataSource, error) {
	// Return the data source
	return &vagrant_server.Job_DataSource{
		Source: &vagrant_server.Job_DataSource_Local{
			Local: &vagrant_server.Job_Local{},
		},
	}, nil
}

func (s *LocalSource) Override(raw *vagrant_server.Job_DataSource, m map[string]string) error {
	if len(m) > 0 {
		return fmt.Errorf("overrides not allowed for local data source")
	}

	return nil
}

func (s *LocalSource) Get(
	ctx context.Context,
	log hclog.Logger,
	ui terminal.UI,
	raw *vagrant_server.Job_DataSource,
	baseDir string,
) (string, func() error, error) {
	pwd, err := os.Getwd()
	if err == nil && !filepath.IsAbs(pwd) {
		// This should never happen because os.Getwd I believe always
		// returns an absolute path but we want to be absolutely sure
		// so we'll make it abs here.
		pwd, err = filepath.Abs(pwd)
	}

	return pwd, nil, err
}

var _ Sourcer = (*LocalSource)(nil)

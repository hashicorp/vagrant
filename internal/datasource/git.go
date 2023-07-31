// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package datasource

import (
	"bytes"
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/gohcl"
	"github.com/mitchellh/mapstructure"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type GitSource struct{}

func newGitSource() Sourcer { return &GitSource{} }

func (s *GitSource) ProjectSource(body hcl.Body, ctx *hcl.EvalContext) (*vagrant_server.Job_DataSource, error) {
	// Decode
	var cfg gitConfig
	if diag := gohcl.DecodeBody(body, ctx, &cfg); len(diag) > 0 {
		return nil, diag
	}

	// Return the data source
	return &vagrant_server.Job_DataSource{
		Source: &vagrant_server.Job_DataSource_Git{
			Git: &vagrant_server.Job_Git{
				Url:  cfg.Url,
				Path: cfg.Path,
			},
		},
	}, nil
}

func (s *GitSource) Override(raw *vagrant_server.Job_DataSource, m map[string]string) error {
	src := raw.Source.(*vagrant_server.Job_DataSource_Git).Git

	var md mapstructure.Metadata
	if err := mapstructure.DecodeMetadata(m, src, &md); err != nil {
		return err
	}

	if len(md.Unused) > 0 {
		return fmt.Errorf("invalid override keys: %v", md.Unused)
	}

	return nil
}

func (s *GitSource) Get(
	ctx context.Context,
	log hclog.Logger,
	ui terminal.UI,
	raw *vagrant_server.Job_DataSource,
	baseDir string,
) (string, func() error, error) {
	source := raw.Source.(*vagrant_server.Job_DataSource_Git)

	// Some quick validation
	if p := source.Git.Path; p != "" {
		if filepath.IsAbs(p) {
			return "", nil, status.Errorf(codes.FailedPrecondition,
				"git path must be relative")
		}

		for _, part := range filepath.SplitList(p) {
			if part == ".." {
				return "", nil, status.Errorf(codes.FailedPrecondition,
					"git path may not contain '..'")
			}
		}
	}

	// Create a temporary directory where we will store the cloned data.
	td, err := ioutil.TempDir(baseDir, "vagrant")
	if err != nil {
		return "", nil, err
	}
	closer := func() error {
		return os.RemoveAll(td)
	}

	// Output
	ui.Output("Cloning data from Git", terminal.WithHeaderStyle())
	ui.Output("URL: %s", source.Git.Url, terminal.WithInfoStyle())
	if source.Git.Ref != "" {
		ui.Output("Ref: %s", source.Git.Ref, terminal.WithInfoStyle())
	}

	// Clone
	var output bytes.Buffer
	cmd := exec.CommandContext(ctx, "git", "clone", source.Git.Url, td)
	cmd.Stdout = &output
	cmd.Stderr = &output
	cmd.Stdin = nil
	if err := cmd.Run(); err != nil {
		closer()
		return "", nil, status.Errorf(codes.Aborted,
			"Git clone failed: %s", output.String())
	}

	// Checkout if we have a ref. If we don't have a ref we use the
	// default of whatever we got.
	if ref := source.Git.Ref; ref != "" {
		output.Reset()
		cmd := exec.CommandContext(ctx, "git", "checkout", ref)
		cmd.Dir = td
		cmd.Stdout = &output
		cmd.Stderr = &output
		cmd.Stdin = nil
		if err := cmd.Run(); err != nil {
			closer()
			return "", nil, status.Errorf(codes.Aborted,
				"Git checkout failed: %s", output.String())
		}
	}

	// If we have a path, set it.
	result := td
	if p := source.Git.Path; p != "" {
		result = filepath.Join(result, p)
	}

	return result, closer, nil
}

type gitConfig struct {
	Url  string `hcl:"url,attr"`
	Path string `hcl:"path,optional"`
}

var _ Sourcer = (*GitSource)(nil)

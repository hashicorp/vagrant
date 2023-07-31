// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package runner

import (
	"context"

	"github.com/hashicorp/go-hclog"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/core"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (r *Runner) executeDocsOp(
	ctx context.Context,
	log hclog.Logger,
	job *vagrant_server.Job,
	project *core.Project,
) (*vagrant_server.Job_Result, error) {
	_, ok := job.Operation.(*vagrant_server.Job_Docs)
	if !ok {
		// this shouldn't happen since the call to this function is gated
		// on the above type match.
		panic("operation not expected type")
	}

	cs, err := project.Components(ctx)
	if err != nil {
		return nil, err
	}
	for _, c := range cs {
		defer c.Close()
	}

	var results []*vagrant_server.Job_DocsResult_Result
	for _, c := range cs {
		info := c.Info
		if info == nil {
			// Should never happen
			continue
		}

		L := log.With("type", info.Type.String(), "name", info.Name)
		L.Debug("getting docs")

		docs, err := component.Documentation(c)
		if err != nil {
			return nil, err
		}

		if docs == nil {
			L.Debug("no docs for component", "name", info.Name, "type", hclog.Fmt("%T", c))
			continue
		}

		// Start building our result. We append it right away. Since we're
		// appending a pointer we can keep modifying it.
		var result vagrant_server.Job_DocsResult_Result
		results = append(results, &result)
		result.Component = info

		var pbdocs vagrant_server.Documentation
		dets := docs.Details()
		pbdocs.Description = dets.Description
		pbdocs.Example = dets.Example
		pbdocs.Input = dets.Input
		pbdocs.Output = dets.Output
		pbdocs.Fields = make(map[string]*vagrant_server.Documentation_Field)

		fields := docs.Fields()

		L.Debug("docs on component", "fields", len(fields))

		for _, f := range docs.Fields() {
			var pbf vagrant_server.Documentation_Field

			pbf.Name = f.Field
			pbf.Type = f.Type
			pbf.Optional = f.Optional
			pbf.Synopsis = f.Synopsis
			pbf.Summary = f.Summary
			pbf.Default = f.Default
			pbf.EnvVar = f.EnvVar

			pbdocs.Fields[f.Field] = &pbf
		}

		for _, m := range dets.Mappers {
			pbdocs.Mappers = append(pbdocs.Mappers, &vagrant_server.Documentation_Mapper{
				Input:       m.Input,
				Output:      m.Output,
				Description: m.Description,
			})
		}

		result.Docs = &pbdocs
	}

	return &vagrant_server.Job_Result{
		Docs: &vagrant_server.Job_DocsResult{
			Results: results,
		},
	}, nil
}

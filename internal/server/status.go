// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package server

import (
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// NewStatus returns a new Status message with the given initial state.
func NewStatus(init vagrant_server.Status_State) *vagrant_server.Status {
	return &vagrant_server.Status{
		State:     init,
		StartTime: timestamppb.Now(),
	}
}

// StatusSetError sets the error state on the status and marks the
// completion time.
func StatusSetError(s *vagrant_server.Status, err error) {
	st, ok := status.FromError(err)
	if !ok {
		st = status.Newf(codes.Internal, "Non-status error %T: %s", err, err)
	}

	s.State = vagrant_server.Status_ERROR
	s.Error = st.Proto()
	s.CompleteTime = timestamppb.Now()
}

// StatusSetSuccess sets state of the status to success and marks the
// completion time.
func StatusSetSuccess(s *vagrant_server.Status) {
	s.State = vagrant_server.Status_SUCCESS
	s.CompleteTime = timestamppb.Now()
}

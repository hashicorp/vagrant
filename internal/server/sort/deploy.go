// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package sort

// import (
// 	"sort"

// 	"google.golang.org/protobuf/ptypes"

// 	pb "github.com/hashicorp/vagrant/internal/server/gen"
// )

// // DeploymentStartDesc sorts deployments by start time descending.
// type DeploymentStartDesc []*pb.Deployment

// func (s DeploymentStartDesc) Len() int      { return len(s) }
// func (s DeploymentStartDesc) Swap(i, j int) { s[i], s[j] = s[j], s[i] }
// func (s DeploymentStartDesc) Less(i, j int) bool {
// 	t1, err := ptypes.Timestamp(s[i].Status.StartTime)
// 	if err != nil {
// 		return false
// 	}

// 	t2, err := ptypes.Timestamp(s[j].Status.StartTime)
// 	if err != nil {
// 		return false
// 	}

// 	return t2.Before(t1)
// }

// // DeploymentCompleteDesc sorts deployments by completion time descending.
// type DeploymentCompleteDesc []*pb.Deployment

// func (s DeploymentCompleteDesc) Len() int      { return len(s) }
// func (s DeploymentCompleteDesc) Swap(i, j int) { s[i], s[j] = s[j], s[i] }
// func (s DeploymentCompleteDesc) Less(i, j int) bool {
// 	t1, err := ptypes.Timestamp(s[i].Status.CompleteTime)
// 	if err != nil {
// 		return false
// 	}

// 	t2, err := ptypes.Timestamp(s[j].Status.CompleteTime)
// 	if err != nil {
// 		return false
// 	}

// 	return t2.Before(t1)
// }

// var (
// 	_ sort.Interface = (DeploymentStartDesc)(nil)
// 	_ sort.Interface = (DeploymentCompleteDesc)(nil)
// )

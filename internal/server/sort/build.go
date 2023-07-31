// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package sort

// import (
// 	"sort"

// 	"google.golang.org/protobuf/ptypes"

// 	pb "github.com/hashicorp/vagrant/internal/server/gen"
// )

// // BuildStartDesc sorts builds by start time descending (most recent first).
// // For the opposite, use sort.Reverse.
// type BuildStartDesc []*pb.Build

// func (s BuildStartDesc) Len() int      { return len(s) }
// func (s BuildStartDesc) Swap(i, j int) { s[i], s[j] = s[j], s[i] }
// func (s BuildStartDesc) Less(i, j int) bool {
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

// var (
// 	_ sort.Interface = (BuildStartDesc)(nil)
// )

// Copyright IBM Corp. 2010, 2025
// SPDX-License-Identifier: BUSL-1.1

package myplugin

import (
	pb "github.com/hashicorp/vagrant/builtin/myplugin/proto"
	"github.com/mitchellh/mapstructure"
	"google.golang.org/protobuf/types/known/structpb"
)

func StructToCommunincatorOptions(in *structpb.Struct) (*pb.CommunicatorOptions, error) {
	var result pb.CommunicatorOptions
	return &result, mapstructure.Decode(in.AsMap(), &result)
}

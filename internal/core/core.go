package core

import (
	"github.com/hashicorp/go-plugin"
	"google.golang.org/grpc"
)

type closer interface {
	Closer(func() error)
}

type closes interface {
	Close() error
}

package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"strings"
	"unicode"

	"github.com/hashicorp/go-hclog"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant/internal/ceb"
	"github.com/hashicorp/vagrant/internal/pkg/signalcontext"
)

func main() {
	os.Exit(realMain())
}

func realMain() int {
	flag.Usage = usage
	flag.Parse()

	args := flag.Args()
	if len(args) == 0 {
		usage()
		return 1
	}

	// TODO(mitchellh): proper log setup
	log := hclog.L()
	hclog.L().SetLevel(hclog.Trace)

	// Create a context that is cancelled on interrupt
	ctx, closer := signalcontext.WithInterrupt(context.Background(), log)
	defer closer()

	// Run our core logic
	err := ceb.Run(ctx,
		ceb.WithEnvDefaults(),
		ceb.WithExec(args))
	if err != nil {
		fmt.Fprintf(flag.CommandLine.Output(),
			"Error initializing Vagrant entrypoint: %s\n", formatError(err))
		return 1
	}

	return 0
}

func formatError(err error) string {
	if s, ok := status.FromError(err); ok {
		return s.Message()
	}

	return err.Error()
}

func usage() {
	fmt.Fprintf(flag.CommandLine.Output(),
		strings.TrimLeftFunc(usageText, unicode.IsSpace),
		os.Args[0])
	flag.PrintDefaults()
}

const usageText = `
Usage: %[1]s [cmd] [args...]

    This the custom entrypoint to support Vagrant. It will re-execute any
    command given after configuring the environment for usage with Vagrant.

`

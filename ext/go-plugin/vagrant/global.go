package vagrant

import (
	hclog "github.com/hashicorp/go-hclog"
)

var GlobalIOServer *IOServer

var defaultLogger = hclog.Default().Named("vagrant")

func DefaultLogger() hclog.Logger {
	return defaultLogger
}

func SetDefaultLogger(l hclog.Logger) {
	defaultLogger = l
}

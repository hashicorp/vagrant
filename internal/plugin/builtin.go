package plugin

import (
	"context"
	"fmt"
	"strings"
	"sync"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	"github.com/oklog/run"

	"github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/pluginclient"
)

type Builtin struct {
	group   run.Group
	servers map[string]*plugin.ReattachConfig
	log     hclog.Logger
	cancel  context.CancelFunc
	ctx     context.Context
	mu      sync.Mutex
}

func NewBuiltins(ctx context.Context, log hclog.Logger) *Builtin {
	ctx, cancel := context.WithCancel(ctx)
	return &Builtin{
		log:     log.Named("builtins"),
		cancel:  cancel,
		ctx:     ctx,
		servers: map[string]*plugin.ReattachConfig{},
	}
}

func (b *Builtin) ConnectInfo(name string) (*plugin.ReattachConfig, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	r, ok := b.servers[name]
	if !ok {
		b.log.Error("failed to locate plugin", "name", name, "servers", b.servers)
		return nil, fmt.Errorf("unknown builtin plugin %s", name)
	}
	return r, nil
}

func (b *Builtin) Add(name string, opts ...sdk.Option) (err error) {
	clCh := make(chan struct{})
	reCh := make(chan *plugin.ReattachConfig)
	cfg := &plugin.ServeTestConfig{
		Context:          b.ctx,
		ReattachConfigCh: reCh,
		CloseCh:          clCh,
	}

	// Add our options to keep it running in process
	opts = append(opts, sdk.InProcess(cfg), sdk.WithLogger(b.log))

	// Spin off a new go routine to get the reattach config
	go func() {
		rc := <-reCh
		b.mu.Lock()
		defer b.mu.Unlock()
		b.servers[name] = rc
	}()

	// Add the plugin server to our group
	b.group.Add(func() error {
		sdk.Main(opts...)
		return nil
	}, func(err error) {
		b.log.Warn("builtin group has exited", "error", err)
		b.cancel()
	})
	return
}

func (b *Builtin) Start() {
	go b.group.Run()
}

func (b *Builtin) Close() {
	b.cancel()
}

func (b *Builtin) Factory(name string, typ component.Type) interface{} {
	return func(hclog.Logger) (interface{}, error) {
		r, err := b.ConnectInfo(name)
		if err != nil {
			return nil, err
		}
		config := pluginclient.ClientConfig(b.log.Named(name))
		config.Logger = b.log.Named(name)
		config.Reattach = r
		config.Plugins = config.VersionedPlugins[1]
		client := plugin.NewClient(config)
		rpcClient, err := client.Client()
		if err != nil {
			b.log.Error("failed to create rpc client for builtin", "name", name, "error", err)
			rpcClient.Close()
			return nil, err
		}

		var raw interface{}
		if typ != component.MapperType {
			raw, err = rpcClient.Dispense(strings.ToLower(typ.String()))
			if err != nil {
				rpcClient.Close()
				return nil, err
			}
		}

		mappers, err := pluginclient.Mappers(client)
		if err != nil {
			rpcClient.Close()
			return nil, err
		}

		return &Instance{
			Component: raw,
			Mappers:   mappers,
			Close:     func() {},
		}, nil
	}
}

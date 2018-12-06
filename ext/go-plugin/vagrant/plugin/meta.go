package plugin

import (
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
)

type Meta interface {
	Init()
	vagrant.IOServer
}

type GRPCCoreClient struct{}

func (c *GRPCCoreClient) Init()                                 {}
func (c *GRPCCoreClient) Streams() (s map[string]chan (string)) { return }

type Core struct {
	vagrant.IOServer
	io vagrant.StreamIO
}

func (c *Core) Init() {
	if c.io == nil {
		c.io = &vagrant.IOSrv{
			map[string]chan (string){
				"stdout": make(chan string),
				"stderr": make(chan string),
			},
		}
	}
}

func (c *Core) Read(target string) (string, error) {
	return c.io.Read(target)
}

func (c *Core) Write(content, target string) (int, error) {
	return c.io.Write(content, target)
}

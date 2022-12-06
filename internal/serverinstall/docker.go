package serverinstall

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/docker/distribution/reference"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/api/types/network"
	"github.com/docker/docker/client"
	"github.com/docker/docker/pkg/jsonmessage"
	"github.com/docker/go-connections/nat"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/clicontext"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverconfig"
)

func InstallDocker(
	ctx context.Context, ui terminal.UI, scfg *Config) (
	*clicontext.Config, *vagrant_server.ServerConfig_AdvertiseAddr, string, error,
) {
	sg := ui.StepGroup()
	defer sg.Wait()

	s := sg.Add("Initializing Docker client...")
	defer func() { s.Abort() }()

	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		return nil, nil, "", err
	}
	cli.NegotiateAPIVersion(ctx)

	s.Update("Checking for existing installation...")

	containers, err := cli.ContainerList(ctx, types.ContainerListOptions{
		Filters: filters.NewArgs(filters.KeyValuePair{
			Key:   "label",
			Value: "vagrant-type=server",
		}),
	})
	if err != nil {
		return nil, nil, "", err
	}

	grpcPort := "9701"
	httpPort := "9702"

	var (
		clicfg   clicontext.Config
		addr     vagrant_server.ServerConfig_AdvertiseAddr
		httpAddr string
	)

	clicfg.Server = serverconfig.Client{
		Address:       "localhost:" + grpcPort,
		Tls:           true,
		TlsSkipVerify: true,
	}

	addr.Addr = "vagrant-server:" + grpcPort
	addr.Tls = true
	addr.TlsSkipVerify = true

	httpAddr = "localhost:" + httpPort

	// If we already have a server, bolt.
	if len(containers) > 0 {
		s.Update("Detected existing Vagrant server.")
		s.Status(terminal.StatusWarn)
		s.Done()
		return &clicfg, &addr, "", nil
	}

	s.Update("Checking for Docker image: %s", scfg.ServerImage)

	imageRef, err := reference.ParseNormalizedNamed(scfg.ServerImage)
	if err != nil {
		return nil, nil, "", fmt.Errorf("Error parsing Docker image: %s", err)
	}

	imageList, err := cli.ImageList(ctx, types.ImageListOptions{
		Filters: filters.NewArgs(filters.KeyValuePair{
			Key:   "reference",
			Value: reference.FamiliarString(imageRef),
		}),
	})
	if err != nil {
		return nil, nil, "", err
	}

	if len(imageList) == 0 {
		s.Update("Pulling image: %s", scfg.ServerImage)

		resp, err := cli.ImagePull(ctx, reference.FamiliarString(imageRef), types.ImagePullOptions{})
		if err != nil {
			return nil, nil, "", err
		}
		defer resp.Close()

		stdout, _, err := ui.OutputWriters()
		if err != nil {
			return nil, nil, "", err
		}

		var termFd uintptr
		if f, ok := stdout.(*os.File); ok {
			termFd = f.Fd()
		}

		err = jsonmessage.DisplayJSONMessagesStream(resp, s.TermOutput(), termFd, true, nil)
		if err != nil {
			return nil, nil, "", fmt.Errorf("unable to stream pull logs to the terminal: %s", err)
		}

		s.Done()
		s = sg.Add("")
	}

	s.Update("Creating vagrant network...")

	nets, err := cli.NetworkList(ctx, types.NetworkListOptions{
		Filters: filters.NewArgs(filters.Arg("label", "use=vagrant")),
	})
	if err != nil {
		return nil, nil, "", err
	}

	if len(nets) == 0 {
		_, err = cli.NetworkCreate(ctx, "vagrant", types.NetworkCreate{
			Driver:         "bridge",
			CheckDuplicate: true,
			Internal:       false,
			Attachable:     true,
			Labels: map[string]string{
				"use": "vagrant",
			},
		})

		if err != nil {
			return nil, nil, "", err
		}

	}

	npGRPC, err := nat.NewPort("tcp", grpcPort)
	if err != nil {
		return nil, nil, "", err
	}

	npHTTP, err := nat.NewPort("tcp", httpPort)
	if err != nil {
		return nil, nil, "", err
	}

	s.Update("Installing Vagrant server to docker")

	cfg := container.Config{
		AttachStdout: true,
		AttachStderr: true,
		AttachStdin:  true,
		OpenStdin:    true,
		StdinOnce:    true,
		Image:        scfg.ServerImage,
		ExposedPorts: nat.PortSet{npGRPC: struct{}{}, npHTTP: struct{}{}},
		Env:          []string{"PORT=" + grpcPort},
		Cmd:          []string{"server", "run", "-accept-tos", "-vvv", "-db=/data/data.db", "-listen-grpc=0.0.0.0:9701", "-listen-http=0.0.0.0:9702"},
	}

	bindings := nat.PortMap{}
	bindings[npGRPC] = []nat.PortBinding{
		{
			HostPort: grpcPort,
		},
	}
	bindings[npHTTP] = []nat.PortBinding{
		{
			HostPort: httpPort,
		},
	}
	hostconfig := container.HostConfig{
		Binds:        []string{"vagrant-server:/data"},
		PortBindings: bindings,
	}

	netconfig := network.NetworkingConfig{
		EndpointsConfig: map[string]*network.EndpointSettings{
			"vagrant": {},
		},
	}

	cfg.Labels = map[string]string{
		"vagrant-type": "server",
	}

	cr, err := cli.ContainerCreate(ctx, &cfg, &hostconfig, &netconfig, "vagrant-server")
	if err != nil {
		return nil, nil, "", err
	}

	err = cli.ContainerStart(ctx, cr.ID, types.ContainerStartOptions{})
	if err != nil {
		return nil, nil, "", err
	}

	// KLUDGE: There isn't a way to find out if the container is up or not,
	// so we just give it 5 seconds to normalize before trying to use it.
	time.Sleep(5 * time.Second)

	s.Done()
	s = sg.Add("Server container started!")
	s.Done()

	return &clicfg, &addr, httpAddr, nil
}

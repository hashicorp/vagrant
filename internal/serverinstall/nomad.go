package serverinstall

import (
	"context"
	"fmt"
	"time"

	"github.com/hashicorp/nomad/api"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/clicontext"
	"github.com/hashicorp/vagrant/internal/pkg/flag"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverconfig"
)

var (
	nomadRegionF         string
	nomadDatacentersF    []string
	nomadNamespaceF      string
	nomadPolicyOverrideF bool
)

// InstallNomad registers a vagrant-server job with a Nomad cluster
func InstallNomad(
	ctx context.Context, ui terminal.UI, scfg *Config) (
	*clicontext.Config, *vagrant_server.ServerConfig_AdvertiseAddr, string, error,
) {
	sg := ui.StepGroup()
	defer sg.Wait()

	s := sg.Add("Initializing Nomad client...")
	defer func() { s.Abort() }()

	// Build api client from environment
	client, err := api.NewClient(api.DefaultConfig())
	if err != nil {
		return nil, nil, "", err
	}

	s.Update("Checking for existing Vagrant server...")

	// Check if vagrant-server has already been deployed
	jobs, _, err := client.Jobs().PrefixList("vagrant-server")
	if err != nil {
		return nil, nil, "", err
	}
	var serverDetected bool
	for _, j := range jobs {
		if j.Name == "vagrant-server" {
			serverDetected = true
			break
		}
	}

	var (
		clicfg   clicontext.Config
		addr     vagrant_server.ServerConfig_AdvertiseAddr
		httpAddr string
	)

	clicfg.Server = serverconfig.Client{
		Tls:           true,
		TlsSkipVerify: true,
	}

	addr.Tls = true
	addr.TlsSkipVerify = true

	if serverDetected {
		allocs, _, err := client.Jobs().Allocations("vagrant-server", false, nil)
		if err != nil {
			return nil, nil, "", err
		}
		if len(allocs) == 0 {
			return nil, nil, "", fmt.Errorf("vagrant-server job found but no running allocations available")
		}
		serverAddr, err := getAddrFromAllocID(allocs[0].ID, client)
		if err != nil {
			return nil, nil, "", err
		}

		s.Update("Detected existing Vagrant server")
		s.Status(terminal.StatusWarn)
		s.Done()

		clicfg.Server.Address = serverAddr
		addr.Addr = serverAddr
		httpAddr = serverAddr
		return &clicfg, &addr, httpAddr, nil
	}

	s.Update("Installing Vagrant server to Nomad")
	job := vagrantNomadJob(scfg)
	jobOpts := &api.RegisterOptions{
		PolicyOverride: nomadPolicyOverrideF,
	}

	resp, _, err := client.Jobs().RegisterOpts(job, jobOpts, nil)
	if err != nil {
		return nil, nil, "", err
	}

	s.Update("Waiting for allocation to be scheduled")
EVAL:
	qopts := &api.QueryOptions{
		WaitIndex: resp.EvalCreateIndex,
	}

	eval, meta, err := client.Evaluations().Info(resp.EvalID, qopts)
	if err != nil {
		return nil, nil, "", err
	}
	qopts.WaitIndex = meta.LastIndex
	switch eval.Status {
	case "pending":
		goto EVAL
	case "complete":
		s.Update("Nomad allocation created")
	case "failed", "canceled", "blocked":
		s.Update("Nomad failed to schedule the vagrant-server")
		s.Status(terminal.StatusError)
		return nil, nil, "", fmt.Errorf("nomad evaluation did not transition to 'complete'")
	default:
		return nil, nil, "", fmt.Errorf("unknown eval status: %q", eval.Status)
	}

	var allocID string

	for {
		allocs, qmeta, err := client.Evaluations().Allocations(eval.ID, qopts)
		if err != nil {
			return nil, nil, "", err
		}
		qopts.WaitIndex = qmeta.LastIndex
		if len(allocs) == 0 {
			return nil, nil, "", fmt.Errorf("no allocations found after evaluation completed")
		}

		switch allocs[0].ClientStatus {
		case "running":
			allocID = allocs[0].ID
			s.Update("Nomad allocation running")
		case "pending":
			s.Update(fmt.Sprintf("Waiting for allocation %q to start", allocs[0].ID))
			// retry
		default:
			return nil, nil, "", fmt.Errorf("allocation failed")

		}

		if allocID != "" {
			break
		}

		select {
		case <-time.After(500 * time.Millisecond):
		case <-ctx.Done():
			return nil, nil, "", ctx.Err()
		}
	}

	serverAddr, err := getAddrFromAllocID(allocID, client)
	if err != nil {
		return nil, nil, "", err
	}
	hAddr, err := getHTTPFromAllocID(allocID, client)
	if err != nil {
		return nil, nil, "", err
	}
	httpAddr = hAddr
	addr.Addr = serverAddr
	clicfg = clicontext.Config{
		Server: serverconfig.Client{
			Address:       addr.Addr,
			Tls:           true,
			TlsSkipVerify: true, // always for now
		},
	}

	s.Update("Nomad allocation ready")
	s.Done()

	return &clicfg, &addr, httpAddr, nil
}

func vagrantNomadJob(scfg *Config) *api.Job {
	job := api.NewServiceJob("vagrant-server", "vagrant-server", nomadRegionF, 50)
	job.Namespace = &nomadNamespaceF
	job.Datacenters = nomadDatacentersF
	job.Meta = scfg.ServiceAnnotations
	tg := api.NewTaskGroup("vagrant-server", 1)
	tg.Networks = []*api.NetworkResource{
		{
			Mode: "host",
			DynamicPorts: []api.Port{
				{
					Label: "server",
					To:    9701,
				},
			},
			// currently set to static; when ui command can be dynamic - update this
			ReservedPorts: []api.Port{
				{
					Label: "ui",
					Value: 9702,
					To:    9702,
				},
			},
		},
	}
	job.AddTaskGroup(tg)

	task := api.NewTask("server", "docker")
	task.Config = map[string]interface{}{
		"image": scfg.ServerImage,
		"ports": []string{"server", "ui"},
		"args":  []string{"server", "run", "-accept-tos", "-vvv", "-db=/alloc/data.db", "-listen-grpc=0.0.0.0:9701", "-listen-http=0.0.0.0:9702"},
	}
	task.Env = map[string]string{
		"PORT": "9701",
	}
	tg.AddTask(task)

	return job
}

func getAddrFromAllocID(allocID string, client *api.Client) (string, error) {
	alloc, _, err := client.Allocations().Info(allocID, nil)
	if err != nil {
		return "", err
	}

	for _, port := range alloc.AllocatedResources.Shared.Ports {
		if port.Label == "server" {
			return fmt.Sprintf("%s:%d", port.HostIP, port.Value), nil
		}
	}

	return "", nil
}

func getHTTPFromAllocID(allocID string, client *api.Client) (string, error) {
	alloc, _, err := client.Allocations().Info(allocID, nil)
	if err != nil {
		return "", err
	}

	for _, port := range alloc.AllocatedResources.Shared.Ports {
		if port.Label == "ui" {
			return fmt.Sprintf(port.HostIP + ":9702"), nil
		}
	}

	return "", nil
}

// NomadFlags config values for Nomad
func NomadFlags(f *flag.Set) {
	f.StringVar(&flag.StringVar{
		Name:    "nomad-region",
		Target:  &nomadRegionF,
		Default: "global",
		Usage:   "Nomad region to install to if using Nomad platform",
	})

	f.StringSliceVar(&flag.StringSliceVar{
		Name:    "nomad-dc",
		Target:  &nomadDatacentersF,
		Default: []string{"dc1"},
		Usage:   "Nomad datacenters to install to if using Nomad platform",
	})

	f.StringVar(&flag.StringVar{
		Name:    "nomad-namespace",
		Target:  &nomadNamespaceF,
		Default: "default",
		Usage:   "Nomad namespace to install to if using Nomad platform",
	})

	f.BoolVar(&flag.BoolVar{
		Name:    "nomad-policy-override",
		Target:  &nomadPolicyOverrideF,
		Default: false,
		Usage:   "Override the Nomad sentinel policy if using enterprise Nomad platform",
	})
}

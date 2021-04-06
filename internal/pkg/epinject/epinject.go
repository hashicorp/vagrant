package epinject

import (
	"archive/tar"
	"bytes"
	"context"
	"crypto/rand"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/network"
	"github.com/docker/docker/client"
	"github.com/hashicorp/go-hclog"
	"github.com/oklog/ulid"
)

func dockerClient(ctx context.Context) (*client.Client, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		return nil, err
	}

	cli.NegotiateAPIVersion(ctx)

	return cli, nil
}

// To remove the entrypoint and reset it back to the docker default, return
// this value for Entrypoint. The docker commit API recognizes this value specially
// to reset the entrypoint.
var DockerDefaultEntrypoint = []string{""}

type NewEntrypoint struct {
	NewImage    string
	Entrypoint  []string
	InjectFiles map[string]InjectFile
}

type InjectFile struct {
	Reader io.Reader
	Info   os.FileInfo
}

func AlterEntrypoint(ctx context.Context, image string, f func(cur []string) (*NewEntrypoint, error)) (string, error) {
	dc, err := dockerClient(ctx)
	if err != nil {
		return "", err
	}

	L := hclog.FromContext(ctx)

	L.Debug("altering entrypoint of docker image", "image", image)

	info, _, err := dc.ImageInspectWithRaw(ctx, image)
	if err != nil {
		return "", err
	}

	icfg := info.Config

	L.Debug("extracted existing entrypoint", "image", image, "entrypoint", icfg.Entrypoint)

	newEp, err := f(icfg.Entrypoint)
	if err != nil {
		return "", err
	}

	if newEp.Entrypoint != nil {
		icfg.Entrypoint = newEp.Entrypoint
	}

	if newEp.NewImage == "" {
		newEp.NewImage = image
	}

	u, err := ulid.New(ulid.Now(), rand.Reader)
	if err != nil {
		return "", err
	}

	name := "epinject-" + u.String()

	var (
		cfg        = container.Config{Image: image}
		hostCfg    = container.HostConfig{}
		networkCfg = network.NetworkingConfig{}
	)

	body, err := dc.ContainerCreate(ctx, &cfg, &hostCfg, &networkCfg, name)
	if err != nil {
		return "", err
	}

	// Force a cleanup of our temporary container
	defer dc.ContainerRemove(ctx, body.ID, types.ContainerRemoveOptions{Force: true})

	var buf bytes.Buffer

	for container, f := range newEp.InjectFiles {
		buf.Reset()

		tw := tar.NewWriter(&buf)

		hdr, err := tar.FileInfoHeader(f.Info, "")
		if err != nil {
			return "", err
		}

		hdr.Name = filepath.Base(container)

		tw.WriteHeader(hdr)
		io.Copy(tw, f.Reader)

		err = dc.CopyToContainer(ctx, body.ID, filepath.Dir(container), &buf, types.CopyToContainerOptions{})
		if err != nil {
			return "", err
		}

		L.Debug("injected file into new image", "container", container)
	}

	if newEp.NewImage == image {
		L.Debug("overwriting existing image with new image", "image", image)
	} else {
		L.Debug("creating new image", "image", newEp.NewImage)
	}

	idr, err := dc.ContainerCommit(ctx, body.ID, types.ContainerCommitOptions{
		Reference: newEp.NewImage,
		Comment:   fmt.Sprintf("Alter image '%s' to modify entrypoint", image),
		Config:    icfg,
	})

	if err != nil {
		return "", err
	}

	return idr.ID, nil
}

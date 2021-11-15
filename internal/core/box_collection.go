package core

import (
	"archive/tar"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"google.golang.org/protobuf/types/known/emptypb"
)

const (
	TempPrefix   = "vagrant-box-add-temp-"
	VagrantSlash = "-VAGRANTSLASH-"
	VagrantColon = "-VAGRANTCOLON-"
)

type BoxCollection struct {
	basis     *Basis
	directory string
	logger    hclog.Logger
}

// This adds a new box to the system.
// There are some exceptional cases:
// * BoxAlreadyExists - The box you're attempting to add already exists.
// * BoxProviderDoesntMatch - If the given box provider doesn't match the
// 	actual box provider in the untarred box.
// * BoxUnpackageFailure - An invalid tar file.
func (b *BoxCollection) Add(path, name, version, metadataURL string, force bool, providers ...string) (box core.Box, err error) {
	if _, err := os.Stat(path); err != nil {
		return nil, fmt.Errorf("Could not add box, unable to find path %s", path)
	}
	exists, err := b.Find(name, version, providers...)
	if err != nil {
		return nil, err
	}

	if exists != nil && !force {
		return nil, fmt.Errorf("Box already exits, can't add %s v%s", name, version)
	} else {
		if exists != nil {
			// If the box already exists but force is enabled, then delete the box
			exists.Destroy()
		}
	}

	tempDir := b.basis.dir.TempDir().String()
	// delete tempdir when finished
	defer os.RemoveAll(tempDir)
	b.logger.Debug("Unpacking box")
	boxFile, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	reader := tar.NewReader(boxFile)
	for {
		header, err := reader.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
		if header == nil {
			continue
		}
		dest := filepath.Join(tempDir, header.Name)
		switch header.Typeflag {
		case tar.TypeDir:
			// create directory if it doesn't already exist
			if fi, _ := os.Stat(dest); fi != nil {
				err = os.MkdirAll(dest, 0755)
				if err != nil {
					return nil, err
				}
			}
		case tar.TypeReg:
			if _, err := os.Stat(filepath.Dir(dest)); err != nil {
				err = os.MkdirAll(filepath.Dir(dest), 0755)
				if err != nil {
					return nil, err
				}
			}
			// copy the file
			f, err := os.OpenFile(dest, os.O_CREATE|os.O_RDWR, os.FileMode(header.Mode))
			if err != nil {
				return nil, err
			}
			if _, err := io.Copy(f, reader); err != nil {
				return nil, err
			}
			f.Close()
		}
	}

	newBox, err := NewBox(
		BoxWithBasis(b.basis),
		BoxWithBox(&vagrant_server.Box{
			Name:      name,
			Version:   version,
			Directory: tempDir,
		}),
	)
	if err != nil {
		return nil, err
	}
	provider := newBox.box.Provider

	if providers != nil {
		foundProvider := false
		for _, p := range providers {
			if p == provider {
				foundProvider = true
				break
			}
		}
		if !foundProvider {
			return nil, fmt.Errorf("could not add box %s, provider '%s' does not match the expected providers %s", path, provider, providers)
		}
	}

	destDir := filepath.Join(b.directory, b.generateDirectoryName(name), version, provider)
	b.logger.Debug("Box directory: %s", destDir)
	os.MkdirAll(destDir, 0755)
	// Copy the contents of the tempdir to the final dir
	err = filepath.Walk(tempDir, func(path string, info os.FileInfo, erro error) (err error) {
		// TODO: only copy in the files that were extracted into the tempdir
		destPath := filepath.Join(destDir, info.Name())
		if info.IsDir() {
			err = os.MkdirAll(destPath, info.Mode())
			return err
		} else {
			data, err := os.Open(path)
			if err != nil {
				return err
			}
			defer data.Close()
			dest, err := os.Create(destPath)
			if err != nil {
				return err
			}
			defer dest.Close()
			if err != nil {
				return err
			}
			if _, err := io.Copy(dest, data); err != nil {
				return err
			}
		}
		return
	})

	newBox, err = NewBox(
		BoxWithBasis(b.basis),
		BoxWithBox(&vagrant_server.Box{
			Name:      name,
			Version:   version,
			Directory: destDir,
			Provider:  provider,
		}),
	)
	newBox.Save()
	return newBox, nil
}

// This returns an array of all the boxes on the system
func (b *BoxCollection) All() (boxes []core.Box, err error) {
	resp, err := b.basis.client.ListBoxes(
		b.basis.ctx,
		&emptypb.Empty{},
	)
	boxes = []core.Box{}
	for _, boxRef := range resp.Boxes {
		box, err := NewBox(
			BoxWithBasis(b.basis),
			BoxWithRef(boxRef, b.basis.ctx),
		)
		if err != nil {
			return nil, err
		}
		boxes = append(boxes, box)
	}

	return
}

// Find a box in the collection with the given name, version and provider.
func (b *BoxCollection) Find(name, version string, providers ...string) (box core.Box, err error) {
	// If no providers are spcified then search for any provider
	if len(providers) == 0 {
		providers = append(providers, "")
	}
	for _, provider := range providers {
		resp, err := b.basis.client.FindBox(
			b.basis.ctx,
			&vagrant_server.FindBoxRequest{
				Box: &vagrant_plugin_sdk.Ref_Box{
					Name: name, Version: version, Provider: provider,
				},
			},
		)
		if err != nil {
			return nil, err
		}
		if resp.Box != nil {
			// Return the first box that is found
			return NewBox(
				BoxWithBasis(b.basis),
				BoxWithBox(resp.Box),
			)
		}
	}
	return
}

// Cleans the directory for a box by removing the folders that are
// empty.
func (b *BoxCollection) Clean(name string) (err error) {
	path := filepath.Join(b.directory, name)
	return os.RemoveAll(path)
}

func (b *BoxCollection) generateDirectoryName(path string) (out string) {
	out = strings.ReplaceAll(path, ":", VagrantColon)
	return strings.ReplaceAll(out, "/", VagrantSlash)
}

var _ core.BoxCollection = (*BoxCollection)(nil)

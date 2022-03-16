package core

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/h2non/filetype"
	"github.com/hashicorp/go-getter"
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

func NewBoxCollection(basis *Basis, dir string, logger hclog.Logger) (bc *BoxCollection, err error) {
	bc = &BoxCollection{
		basis:     basis,
		directory: dir,
		logger:    logger,
	}
	err = bc.RecoverBoxes()
	return
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

	tempDir := filepath.Join(b.basis.dir.TempDir().String(), "box-extractor")
	err = os.MkdirAll(tempDir, 0755)
	if err != nil {
		return nil, err
	} // delete tempdir when finished
	defer os.RemoveAll(tempDir)
	b.logger.Debug("Unpacking box")
	boxFile, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	buffer := make([]byte, 512)
	n, err := boxFile.Read(buffer)
	if err != nil && err != io.EOF {
		return nil, err
	}
	io.MultiReader(bytes.NewBuffer(buffer[:n]), boxFile)
	typ, err := filetype.Match(buffer)
	ext := typ.Extension
	if typ.Extension == "gz" {
		ext = "tar.gz"
	}
	decompressor := getter.Decompressors[ext]
	err = decompressor.Decompress(tempDir, path, true, os.ModeDir)
	if err != nil {
		return nil, err
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
		destPath, err := validateNewPath(filepath.Join(destDir, info.Name()), destDir)
		if err != nil {
			return err
		}
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
			Name:        name,
			Version:     version,
			Directory:   destDir,
			Provider:    provider,
			MetadataUrl: metadataURL,
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

func (b *BoxCollection) RecoverBoxes() (err error) {
	resp, err := b.basis.client.ListBoxes(
		b.basis.ctx,
		&emptypb.Empty{},
	)
	if err != nil {
		return err
	}
	// Ensure that each box exists
	for _, boxRef := range resp.Boxes {
		box, erro := b.basis.client.GetBox(b.basis.ctx, &vagrant_server.GetBoxRequest{Box: boxRef})
		// If the box directory does not exist, then the box doesn't exist.
		if _, err := os.Stat(box.Box.Directory); err != nil {
			// Remove the box
			_, erro := b.basis.client.DeleteBox(b.basis.ctx, &vagrant_server.DeleteBoxRequest{Box: boxRef})
			if erro != nil {
				return erro
			}
		}
		if erro != nil {
			return erro
		}
	}

	return
}

func (b *BoxCollection) generateDirectoryName(path string) (out string) {
	out = strings.ReplaceAll(path, ":", VagrantColon)
	return strings.ReplaceAll(out, "/", VagrantSlash)
}

func validateNewPath(path string, parentPath string) (newPath string, err error) {
	newPath, err = filepath.Abs(path)
	if err != nil {
		return "", err
	}
	// Ensure that the newPath is within the parentPath
	if !strings.HasPrefix(newPath, parentPath) {
		return "", fmt.Errorf("could not add box outside of box directory %s", parentPath)
	}
	return
}

var _ core.BoxCollection = (*BoxCollection)(nil)

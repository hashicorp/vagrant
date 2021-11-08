package core

import (
	"errors"
	"os"
	"time"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-version"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// Number of seconds to wait between checks for box updates
const BoxUpdateCheckInterval = 3600

type Box struct {
	box    *vagrant_server.Box
	logger hclog.Logger
}

func (b *Box) loadMetadata() (metadata core.BoxMetadata) {
	// TODO: need box metadata implementation
	return
}

func (b *Box) matches(box core.Box) (bool, error) {
	name, err := box.Name()
	if err != nil {
		return false, err
	}
	version, err := box.Version()
	if err != nil {
		return false, err
	}
	provider, err := box.Provider()
	if err != nil {
		return false, err
	}
	if b.box.Name == name &&
		b.box.Version == version &&
		b.box.Provider == provider {
		return true, nil
	}
	return false, nil
}

// Check if a box update check is allowed. Returns true if the
// BOX_UPDATE_CHECK_INTERVAL has passed.
func (b *Box) AutomaticUpdateCheckAllowed() (allowed bool, err error) {
	now := time.Now()
	lastUpdate := b.box.LastUpdate.AsTime()
	if lastUpdate.Add(BoxUpdateCheckInterval * time.Second).After(now) {
		return false, nil
	}
	b.box.LastUpdate = timestamppb.Now()
	b.Save()
	return true, nil
}

// This deletes the box. This is NOT undoable.
func (b *Box) Destroy() (err error) {
	return os.RemoveAll(b.box.Directory)
}

func (b *Box) Directory() (path string, err error) {
	return b.box.Directory, nil
}

// Checks if the box has an update and returns the metadata, version,
// and provider. If the box doesn't have an update that satisfies the
// constraints, it will return nil.
func (b *Box) HasUpdate(version string) (updateAvailable bool, err error) {
	// TODO: need box metadata
	return
}

// Checks if this box is in use according to the given machine
// index and returns the entries that appear to be using the box.
func (b *Box) InUse(index core.TargetIndex) (inUse bool, err error) {
	targets, err := index.All()
	if err != nil {
		return false, err
	}
	for _, t := range targets {
		m, err := t.Specialize((*core.Machine)(nil))
		if err != nil {
			continue
		}
		machineBox, err := m.(*Machine).Box()
		if err != nil {
			return false, err
		}
		ok, err := b.matches(machineBox)
		if err != nil {
			return false, err
		}
		if ok {
			return true, nil
		}
	}
	return false, nil
}

func (b *Box) Metadata() (metadata core.BoxMetadataMap, err error) {
	// TODO
	return
}

func (b *Box) MetadataURL() (url string, err error) {
	return b.box.MetadataUrl, nil
}

func (b *Box) Name() (name string, err error) {
	return b.box.Name, nil
}

func (b *Box) Provider() (name string, err error) {
	return b.box.Provider, nil
}

// This repackages this box and outputs it to the given path.
func (b *Box) Repackage(path string) (err error) {
	// TODO
	return
}

func (b *Box) Version() (version string, err error) {
	return b.box.Version, nil
}

func (b *Box) Compare(box core.Box) (int, error) {
	name, err := box.Name()
	if err != nil {
		return 0, err
	}
	ver, err := box.Version()
	if err != nil {
		return 0, err
	}
	provider, err := box.Provider()
	if err != nil {
		return 0, err
	}

	if b.box.Name == name && b.box.Provider == provider {
		boxVersion, err := version.NewVersion(b.box.Version)
		if err != nil {
			return 0, nil
		}
		otherVersion, err := version.NewVersion(ver)
		if err != nil {
			return 0, nil
		}

		res := otherVersion.Compare(boxVersion)
		return res, nil
	}
	return 0, errors.New("Box name and provider does not match, can't compare")
}

func (b *Box) Save() error {
	// TODO:
	return nil
}

var _ core.Box = (*Box)(nil)

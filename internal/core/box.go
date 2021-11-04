package core

import (
	"github.com/hashicorp/vagrant-plugin-sdk/core"
)

type Box struct {
}

func (m *Box) AutomaticUpdateCheckAllowed() (allowed bool, err error) {
	return
}

func (m *Box) Destroy() (err error) {
	return
}

func (m *Box) Directory() (path string, err error) {
	return
}

func (m *Box) HasUpdate(version string) (updateAvailable bool, err error) {
	return
}

func (m *Box) InUse(index core.TargetIndex) (inUse bool, err error) {
	return
}

func (m *Box) LoadMetadata() (metadata core.BoxMetadata, err error) {
	return
}

func (m *Box) Metadata() (metadata core.BoxMetadataMap, err error) {
	return
}

func (m *Box) MetadataURL() (url string, err error) {
	return
}

func (m *Box) Name() (name string, err error) {
	return
}

func (m *Box) Provider() (name string, err error) {
	return
}

func (m *Box) Repackage() (err error) {
	return
}

func (m *Box) Version() (version string, err error) {
	return
}

var _ core.Box = (*Box)(nil)

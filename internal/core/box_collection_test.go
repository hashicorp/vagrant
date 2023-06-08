package core

import (
	"archive/tar"
	"context"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/stretchr/testify/require"
)

func seedDB(t *testing.T, basis *Basis) {
	box1 := newFullBox(t, hashicorpBionicBoxData(), basis)
	box1.Save()
	box2 := newFullBox(t, testboxBoxData(), basis)
	box2.Save()
}

func newBoxCollection(t *testing.T) *BoxCollection {
	pluginManager := plugin.NewManager(
		context.Background(),
		nil,
		hclog.New(&hclog.LoggerOptions{}),
	)
	basis := TestBasis(t, WithPluginManager(pluginManager))
	seedDB(t, basis)
	td, err := ioutil.TempDir(basis.dir.DataDir().String(), "boxes")
	t.Cleanup(func() { os.RemoveAll(td) })
	require.NoError(t, err)
	return &BoxCollection{
		basis:     basis,
		directory: td,
		logger:    hclog.New(&hclog.LoggerOptions{}),
	}
}

func generateTestBox(t *testing.T, path string, basis *Basis) string {
	metafile := filepath.Join(path, "box", "metadata.json")
	os.Mkdir(filepath.Dir(metafile), 0755)
	data := []byte("{\"provider\":\"virtualbox\"}")
	err := os.WriteFile(metafile, data, 0644)
	require.NoError(t, err)
	outputPath := filepath.Join(path, "output", "box")
	os.Mkdir(filepath.Dir(outputPath), 0755)

	tarFile, err := os.Create(outputPath)
	require.NoError(t, err)
	defer tarFile.Close()
	tw := tar.NewWriter(tarFile)
	defer tw.Close()
	file, err := os.Open(metafile)
	require.NoError(t, err)
	defer file.Close()
	info, err := file.Stat()
	require.NoError(t, err)
	header, err := tar.FileInfoHeader(info, info.Name())
	require.NoError(t, err)
	err = tw.WriteHeader(header)
	require.NoError(t, err)
	_, err = io.Copy(tw, file)
	require.NoError(t, err)

	return outputPath
}

func TestAddErrors(t *testing.T) {
	bc := newBoxCollection(t)

	td, err := ioutil.TempDir("/tmp", "box")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })

	_, err = bc.Add(path.NewPath("/path/that/doesntexist"), "test", "1.2.3", "", true)
	require.Error(t, err)

	_, err = bc.Add(path.NewPath(td), "test/box", "1.2.3", "", false)
	require.Error(t, err)
}

func TestAddNoProviders(t *testing.T) {
	bc := newBoxCollection(t)

	td, err := ioutil.TempDir("/tmp", "box")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })

	testBoxPath := generateTestBox(t, td, bc.basis)
	box, err := bc.Add(path.NewPath(testBoxPath), "test/box", "1.2.3", "", true)
	require.NoError(t, err)
	require.NotNil(t, box)
}

func TestAddWithProviders(t *testing.T) {
	bc := newBoxCollection(t)

	td, err := ioutil.TempDir("/tmp", "box")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })

	testBoxPath := generateTestBox(t, td, bc.basis)
	box, err := bc.Add(path.NewPath(testBoxPath), "test/box", "1.2.3", "", true, "virtualbox", "vmware")
	require.NoError(t, err)
	require.NotNil(t, box)
}

func TestAddBadProviders(t *testing.T) {
	bc := newBoxCollection(t)

	td, err := ioutil.TempDir("/tmp", "box")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })

	testBoxPath := generateTestBox(t, td, bc.basis)
	_, err = bc.Add(path.NewPath(testBoxPath), "test/box", "1.2.4", "", true, "vmware")
	require.Error(t, err)
}

func TestAll(t *testing.T) {
	bc := newBoxCollection(t)
	boxes, err := bc.All()
	require.NoError(t, err)
	require.Equal(t, len(boxes), 2)
}

func TestFind(t *testing.T) {
	bc := newBoxCollection(t)

	boxes, err := bc.Find("test/box", "1.2.3")
	require.NoError(t, err)
	require.NotNil(t, boxes)

	boxes, err = bc.Find("test/box", "1.2.3", "virtualbox")
	require.NoError(t, err)
	require.NotNil(t, boxes)

	boxes, err = bc.Find("test/box", "1.2.3", "idontexist")
	require.NoError(t, err)
	require.Nil(t, boxes)

	boxes, err = bc.Find("test/box", "9.9.9", "virtualbox")
	require.NoError(t, err)
	require.Nil(t, boxes)

	boxes, err = bc.Find("test/box", "9.9.9")
	require.NoError(t, err)
	require.Nil(t, boxes)

	boxes, err = bc.Find("test/box", "1.2.3", "vmware", "virtualbox")
	require.NoError(t, err)
	require.NotNil(t, boxes)
}

func TestRemoveMissingBox(t *testing.T) {
	// Create initial box collection
	bc := newBoxCollection(t)
	td, err := ioutil.TempDir("/tmp", "box")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })
	testBoxPath := generateTestBox(t, td, bc.basis)
	// Insert test box into the collection
	box, err := bc.Add(path.NewPath(testBoxPath), "test/box", "1.2.3", "", true)
	require.NoError(t, err)
	boxPath, _ := box.Directory()
	require.NoError(t, err)
	require.NotNil(t, box)

	// Create new box collection to verify test box is still accessible
	bc, err = NewBoxCollection(bc.basis, bc.directory, bc.logger)
	require.NoError(t, err)
	boxes, err := bc.Find("test/box", "1.2.3")
	require.NoError(t, err)
	require.NotNil(t, boxes)

	// Remove box
	os.RemoveAll(boxPath.String())

	// Create new box collection to verify test box is no longer accessible
	bc, err = NewBoxCollection(bc.basis, bc.directory, bc.logger)
	require.NoError(t, err)
	boxes, err = bc.Find("test/box", "1.2.3")
	require.NoError(t, err)
	require.Nil(t, boxes)
}

package core

import (
	"context"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/structpb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func hashicorpBionicBoxData() *vagrant_server.Box {
	testMetadata, _ := structpb.NewStruct(make(map[string]interface{}))
	return &vagrant_server.Box{
		ResourceId:  "123",
		Provider:    "virtualbox",
		Version:     "0.0.282",
		Directory:   "/tmp/boxes",
		Metadata:    testMetadata,
		MetadataUrl: "https://app.vagrantup.com/hashicorp/boxes/bionic64.json",
		Name:        "hashicorp/bionic64",
		LastUpdate:  timestamppb.Now(),
	}
}
func testboxBoxData() *vagrant_server.Box {
	testMetadata, _ := structpb.NewStruct(make(map[string]interface{}))
	return &vagrant_server.Box{
		ResourceId:  "123",
		Provider:    "virtualbox",
		Version:     "1.2.3",
		Directory:   "/tmp/boxes",
		Metadata:    testMetadata,
		MetadataUrl: "http://idontexist",
		Name:        "test/box",
		LastUpdate:  timestamppb.Now(),
	}
}

func newTestBox() *Box {
	return &Box{
		box: testboxBoxData(),
	}
}

func hashicorpBionicTestBox() *Box {
	return &Box{
		box: hashicorpBionicBoxData(),
	}
}

func newFullBox(t *testing.T, boxData *vagrant_server.Box, testBasis *Basis) *Box {
	basis := testBasis
	if basis == nil {
		pluginManager := plugin.NewManager(
			context.Background(),
			nil,
			hclog.New(&hclog.LoggerOptions{}),
		)
		basis = TestBasis(t, WithPluginManager(pluginManager))
	}
	td, err := ioutil.TempDir("", "box-metadata")
	require.NoError(t, err)
	data := []byte("{\"provider\":\"virtualbox\", \"nested\":{\"key\":\"val\"}}")
	err = os.WriteFile(filepath.Join(td, "metadata.json"), data, 0644)
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })
	// Change the box directory to the temp dir
	boxData.Directory = td
	box, err := NewBox(
		BoxWithBasis(basis),
		BoxWithBox(boxData),
	)
	require.NoError(t, err)
	return box
}

func TestNewBox(t *testing.T) {
	box := newFullBox(t, testboxBoxData(), nil)
	require.NotNil(t, box)
	require.Equal(t, "test/box", box.box.Name)
}

func TestBoxAutomaticUpdateCheckAllowed(t *testing.T) {
	testBox := newFullBox(t, testboxBoxData(), nil)
	// just did automated check
	testBox.box.LastUpdate = timestamppb.Now()
	allowed1, err := testBox.AutomaticUpdateCheckAllowed()
	if err != nil {
		t.Errorf("Failed to check automatic update")
	}
	require.False(t, allowed1)

	// did automated check a while ado
	testBox.box.LastUpdate = timestamppb.New(time.Now().Add(-(60 * time.Minute)))
	allowed2, err := testBox.AutomaticUpdateCheckAllowed()
	if err != nil {
		t.Errorf("Failed to check automatic update")
	}
	require.True(t, allowed2)
}

func TestCompare(t *testing.T) {
	testBox := newTestBox()
	otherBox := newTestBox()

	// Same box
	res1, err := testBox.Compare(otherBox)
	if err != nil {
		t.Errorf("Failed to compare boxes")
	}
	require.Equal(t, 0, res1)

	// Same box, higher version
	otherBox.box.Version = "2.0.0"
	res2, err := testBox.Compare(otherBox)
	if err != nil {
		t.Errorf("Failed to compare boxes")
	}
	require.Equal(t, 1, res2)

	// Same box, lower version
	otherBox.box.Version = "0.1.0"
	res3, err := testBox.Compare(otherBox)
	if err != nil {
		t.Errorf("Failed to compare boxes")
	}
	require.Equal(t, -1, res3)

	// Different provider
	otherBox.box.Provider = "notthesame"
	_, err = testBox.Compare(otherBox)
	require.Error(t, err)
}

func TestHasUpdate(t *testing.T) {
	box := hashicorpBionicTestBox()

	// Older box
	box.box.Version = "0.0.282"
	result, err := box.HasUpdate("")
	if err != nil {
		t.Errorf("Failed to check for update")
	}
	require.True(t, result)

	// Newer box
	box.box.Version = "99.9.282"
	result2, err := box.HasUpdate("")
	if err != nil {
		t.Errorf("Failed to check for update")
	}
	require.False(t, result2)
}

func TestMetadata(t *testing.T) {
	box := hashicorpBionicTestBox()
	result, err := box.Metadata()
	if err != nil {
		t.Errorf("Failed to get metadata")
	}
	require.NotNil(t, result)
	require.Equal(t, "hashicorp/bionic64", result.BoxName())
}

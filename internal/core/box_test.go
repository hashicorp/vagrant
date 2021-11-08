package core

import (
	"testing"
	"time"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func newTestBox() *Box {
	return &Box{
		box: &vagrant_server.Box{
			Id:          "123",
			Provider:    "virtualbox",
			Version:     "1.2.3",
			Directory:   "/tmp/boxes",
			Metadata:    map[string]string{},
			MetadataUrl: "http://idontexist",
			Name:        "test/box",
			LastUpdate:  timestamppb.Now(),
		},
	}
}

func TestBoxAutomaticUpdateCheckAllowed(t *testing.T) {
	testBox := newTestBox()
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

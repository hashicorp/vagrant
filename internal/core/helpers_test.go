package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/plugin"
)

func testBoxConfig(name string) *component.ConfigData {
	return &component.ConfigData{
		Data: map[string]interface{}{
			"vm": &component.ConfigData{
				Data: map[string]interface{}{
					"box": name,
				},
			},
		},
	}
}

type testSyncedFolder struct {
	source      string
	destination string
	kind        string
}

func testSyncedFolderConfig(folders []*testSyncedFolder) *component.ConfigData {
	f := map[interface{}]interface{}{}
	for _, tf := range folders {
		f[tf.destination] = map[interface{}]interface{}{
			"hostpath":  tf.source,
			"guestpath": tf.destination,
			"type":      tf.kind,
		}
	}

	return &component.ConfigData{
		Data: map[string]interface{}{
			"vm": &component.ConfigData{
				Data: map[string]interface{}{
					"__synced_folders": f,
				},
			},
		},
	}
}

func testGuestConfig(name string) *component.ConfigData {
	return &component.ConfigData{
		Data: map[string]interface{}{
			"vm": &component.ConfigData{
				Data: map[string]interface{}{
					"guest": name,
				},
			},
		},
	}
}

func syncedFolderPlugin(t *testing.T, name string) *plugin.Plugin {
	return plugin.TestPlugin(t,
		BuildTestSyncedFolderPlugin(""),
		plugin.WithPluginName(name),
		plugin.WithPluginTypes(component.SyncedFolderType),
	)
}

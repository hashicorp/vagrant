package plugin

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/adrg/xdg"
	"github.com/mitchellh/go-homedir"

	"github.com/hashicorp/vagrant/internal/config"
)

// Discover finds the given plugin and returns the command for it. The command
// can subsequently be used with Factory to build a factory for a specific
// plugin type. If the plugin is not found `(nil, nil)` is returned.
//
// The plugin binary must have the form "vagrant-plugin-<name>" (with a
// ".exe" extension on Windows).
//
// This will search the paths given. You can use DefaultPaths() to get
// the default set of paths.
//
func Discover(cfg *config.Plugin, paths []string) (*exec.Cmd, error) {
	// Expected filename
	expected := "vagrant-plugin-" + cfg.Name
	if runtime.GOOS == "windows " {
		expected += ".exe"
	}

	// Search our paths
	for _, path := range paths {
		path = filepath.Join(path, expected)

		_, err := os.Stat(path)
		if err != nil {
			if os.IsNotExist(err) {
				continue
			}

			return nil, err
		}

		// If the checksum is set we validate it.
		if cfg.Checksum != "" {
			actual, err := checksum(path)
			if err != nil {
				return nil, err
			}

			if strings.ToLower(actual) != strings.ToLower(cfg.Checksum) {
				return nil, fmt.Errorf(
					"plugin %q checksum mismatch. got: %s",
					cfg.Name, actual)
			}
		}

		cmd := exec.Command(path)
		return cmd, nil
	}

	return nil, nil
}

// DefaultPaths returns the default search paths for plugins. These are:
//
//   * pwd given
//   * "$pwd/.vagrant/plugins"
//   * "$XDG_CONFIG_DIR/vagrant/plugins"
//
func DefaultPaths(pwd string) ([]string, error) {
	xdgPath, err := xdg.ConfigFile("vagrant/plugins/.ignore")
	if err != nil {
		return nil, err
	}

	// We also allow plugins in $HOME/.config/vagrant/plugins. This is
	// usually the same as xdgPath but on some systems (macOS) without
	// XDG env vars set, it defaults to a ~/Library path which can be weird.
	// We just hardcode this path as well.
	hd, err := homedir.Dir()
	if err != nil {
		return nil, err
	}

	return []string{
		pwd,
		filepath.Join(pwd, ".vagrant", "plugins"),
		filepath.Dir(xdgPath),
		filepath.Join(hd, ".config", ".vagrant", "plugins"),
	}, nil
}

func checksum(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()

	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}

	return hex.EncodeToString(h.Sum(nil)), nil
}

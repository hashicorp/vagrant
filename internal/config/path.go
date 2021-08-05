package config

import (
	"os"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
)

// Filename is the default filename for the Vagrant configuration.
const Filename = "Vagrantfile"

func GetVagrantfileName() string {
	if f := os.Getenv("VAGRANT_VAGRANTFILE"); f != "" {
		return f
	}
	return Filename
}

// FindPath looks for our configuration file starting at "start" and
// traversing parent directories until it is found. If it is found, the
// path is returned. If it is not found, an empty string is returned.
// Error will be non-nil only if an error occurred.
//
// If start is empty, start will be the current working directory. If
// filename is empty, it will default to the Filename constant.
func FindPath(dir path.Path, filename string) (p path.Path, err error) {
	if dir == nil {
		cwd, err := os.Getwd()
		if err != nil {
			return nil, err
		}
		dir = path.NewPath(cwd)
	}

	if filename == "" {
		filename = GetVagrantfileName()
	}

	for {
		p = dir.Join(filename)
		if _, err = os.Stat(p.String()); err == nil || !os.IsNotExist(err) {
			return
		}
		if p.String() == p.Parent().String() {
			return nil, nil
		}
		p = p.Parent()
	}
}

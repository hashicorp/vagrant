package none

import (
	"errors"
	"io"
	"os"
	"time"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/communicator"
)

type Communicator struct {
	config string
}

// Creates a null vagrant.Communicator implementation. This takes
// an already existing configuration.
func New(config string) (result *Communicator, err error) {
	// Establish an initial connection and connect
	result = &Communicator{
		config: config,
	}

	return
}

func (c *Communicator) Connect() (err error) {
	return
}

func (c *Communicator) Disconnect() (err error) {
	return
}

func (c *Communicator) Start(cmd *communicator.Cmd) (err error) {
	cmd.Init()
	cmd.SetExitStatus(0, nil)
	return
}

func (c *Communicator) Upload(path string, input io.Reader, fi *os.FileInfo) error {
	return errors.New("Upload is not implemented when communicator = 'none'")
}

func (c *Communicator) UploadDir(dst string, src string, excl []string) error {
	return errors.New("UploadDir is not implemented when communicator = 'none'")
}

func (c *Communicator) Download(path string, output io.Writer) error {
	return errors.New("Download is not implemented when communicator = 'none'")
}

func (c *Communicator) DownloadDir(dst string, src string, excl []string) error {
	return errors.New("DownloadDir is not implemented when communicator = 'none'")
}

func (c *Communicator) Timeout() time.Duration {
	return 0
}

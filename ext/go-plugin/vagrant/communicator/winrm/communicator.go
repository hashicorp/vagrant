package winrm

import (
	"encoding/base64"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/communicator"
	"github.com/masterzen/winrm"
	"github.com/packer-community/winrmcp/winrmcp"
)

var logger = vagrant.DefaultLogger().Named("communicator.winrm")

// Communicator represents the WinRM communicator
type Communicator struct {
	config   *Config
	client   *winrm.Client
	endpoint *winrm.Endpoint
}

// New creates a new communicator implementation over WinRM.
func New(config *Config) (*Communicator, error) {
	endpoint := &winrm.Endpoint{
		Host:     config.Host,
		Port:     config.Port,
		HTTPS:    config.Https,
		Insecure: config.Insecure,

		/*
			TODO
			HTTPS:    connInfo.HTTPS,
			Insecure: connInfo.Insecure,
			CACert:   connInfo.CACert,
		*/
	}

	// Create the client
	params := *winrm.DefaultParameters

	if config.TransportDecorator != nil {
		params.TransportDecorator = config.TransportDecorator
	}

	params.Timeout = formatDuration(config.Timeout)
	client, err := winrm.NewClientWithParameters(
		endpoint, config.Username, config.Password, &params)
	if err != nil {
		return nil, err
	}

	return &Communicator{
		config:   config,
		client:   client,
		endpoint: endpoint,
	}, nil
}

func (c *Communicator) Connect() (err error) {
	// Create the shell to verify the connection
	logger.Debug("connecting to remote shell")
	shell, err := c.client.CreateShell()
	if err != nil {
		logger.Error("connection failure", "error", err)
		return
	}
	if err = shell.Close(); err != nil {
		logger.Error("connection close failure", "error", err)
	}
	return
}

// Start implementation of communicator.Communicator interface
func (c *Communicator) Start(rc *communicator.Cmd) error {
	shell, err := c.client.CreateShell()
	if err != nil {
		return err
	}

	logger.Info("starting remote command", "commmand", rc.Command)

	rc.Init()
	cmd, err := shell.Execute(rc.Command)
	if err != nil {
		return err
	}

	go runCommand(shell, cmd, rc)
	return nil
}

func runCommand(shell *winrm.Shell, cmd *winrm.Command, rc *communicator.Cmd) {
	defer shell.Close()
	var wg sync.WaitGroup

	copyFunc := func(w io.Writer, r io.Reader) {
		defer wg.Done()
		io.Copy(w, r)
	}

	if rc.Stdout != nil && cmd.Stdout != nil {
		wg.Add(1)
		go copyFunc(rc.Stdout, cmd.Stdout)
	} else {
		logger.Warn("failed to read stdout", "command", rc.Command)
	}

	if rc.Stderr != nil && cmd.Stderr != nil {
		wg.Add(1)
		go copyFunc(rc.Stderr, cmd.Stderr)
	} else {
		logger.Warn("failed to read stderr", "command", rc.Command)
	}

	cmd.Wait()
	wg.Wait()

	code := cmd.ExitCode()
	logger.Info("command complete", "exitcode", code, "command", rc.Command)
	rc.SetExitStatus(code, nil)
}

// Upload implementation of communicator.Communicator interface
func (c *Communicator) Upload(path string, input io.Reader, fi *os.FileInfo) error {
	wcp, err := c.newCopyClient()
	if err != nil {
		return fmt.Errorf("Was unable to create winrm client: %s", err)
	}
	if strings.HasSuffix(path, `\`) {
		// path is a directory
		path += filepath.Base((*fi).Name())
	}
	logger.Info("uploading file", "path", path)
	return wcp.Write(path, input)
}

// UploadDir implementation of communicator.Communicator interface
func (c *Communicator) UploadDir(dst string, src string, exclude []string) error {
	if !strings.HasSuffix(src, "/") {
		dst = fmt.Sprintf("%s\\%s", dst, filepath.Base(src))
	}
	logger.Info("uploading directory", "source", src, "destination", dst)
	wcp, err := c.newCopyClient()
	if err != nil {
		return err
	}
	return wcp.Copy(src, dst)
}

func (c *Communicator) Download(src string, dst io.Writer) error {
	client, err := c.newWinRMClient()
	if err != nil {
		return err
	}

	encodeScript := `$file=[System.IO.File]::ReadAllBytes("%s"); Write-Output $([System.Convert]::ToBase64String($file))`

	base64DecodePipe := &Base64Pipe{w: dst}

	cmd := winrm.Powershell(fmt.Sprintf(encodeScript, src))
	_, err = client.Run(cmd, base64DecodePipe, ioutil.Discard)

	return err
}

func (c *Communicator) DownloadDir(src string, dst string, exclude []string) error {
	return fmt.Errorf("WinRM doesn't support download dir.")
}

func (c *Communicator) getClientConfig() *winrmcp.Config {
	return &winrmcp.Config{
		Auth: winrmcp.Auth{
			User:     c.config.Username,
			Password: c.config.Password,
		},
		Https:                 c.config.Https,
		Insecure:              c.config.Insecure,
		OperationTimeout:      c.config.Timeout,
		MaxOperationsPerShell: 15, // lowest common denominator
		TransportDecorator:    c.config.TransportDecorator,
	}
}

func (c *Communicator) newCopyClient() (*winrmcp.Winrmcp, error) {
	addr := fmt.Sprintf("%s:%d", c.endpoint.Host, c.endpoint.Port)
	clientConfig := c.getClientConfig()
	return winrmcp.New(addr, clientConfig)
}

func (c *Communicator) newWinRMClient() (*winrm.Client, error) {
	conf := c.getClientConfig()

	// Shamelessly borrowed from the winrmcp client to ensure
	// that the client is configured using the same defaulting behaviors that
	// winrmcp uses even we we aren't using winrmcp. This ensures similar
	// behavior between upload, download, and copy functions. We can't use the
	// one generated by winrmcp because it isn't exported.
	var endpoint *winrm.Endpoint
	endpoint = &winrm.Endpoint{
		Host:          c.endpoint.Host,
		Port:          c.endpoint.Port,
		HTTPS:         conf.Https,
		Insecure:      conf.Insecure,
		TLSServerName: conf.TLSServerName,
		CACert:        conf.CACertBytes,
		Timeout:       conf.ConnectTimeout,
	}
	params := winrm.NewParameters(
		winrm.DefaultParameters.Timeout,
		winrm.DefaultParameters.Locale,
		winrm.DefaultParameters.EnvelopeSize,
	)

	params.TransportDecorator = conf.TransportDecorator
	params.Timeout = "PT3M"

	client, err := winrm.NewClientWithParameters(
		endpoint, conf.Auth.User, conf.Auth.Password, params)
	return client, err
}

type Base64Pipe struct {
	w io.Writer // underlying writer (file, buffer)
}

func (d *Base64Pipe) ReadFrom(r io.Reader) (int64, error) {
	b, err := ioutil.ReadAll(r)
	if err != nil {
		return 0, err
	}

	var i int
	i, err = d.Write(b)

	if err != nil {
		return 0, err
	}

	return int64(i), err
}

func (d *Base64Pipe) Write(p []byte) (int, error) {
	dst := make([]byte, base64.StdEncoding.DecodedLen(len(p)))

	decodedBytes, err := base64.StdEncoding.Decode(dst, p)
	if err != nil {
		return 0, err
	}

	return d.w.Write(dst[0:decodedBytes])
}

package communicator

import (
	"fmt"
	"io"
	"strings"
	"sync"
	"unicode"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/mitchellh/iochan"
)

// CmdDisconnect is a sentinel value to indicate a RemoteCmd
// exited because the remote side disconnected us.
const CmdDisconnect int = 2300218

// Cmd represents a remote command being prepared or run.
type Cmd struct {
	// Command is the command to run remotely. This is executed as if
	// it were a shell command, so you are expected to do any shell escaping
	// necessary.
	Command string

	// Stdin specifies the process's standard input. If Stdin is
	// nil, the process reads from an empty bytes.Buffer.
	Stdin io.Reader

	// Stdout and Stderr represent the process's standard output and
	// error.
	//
	// If either is nil, it will be set to ioutil.Discard.
	Stdout io.Writer
	Stderr io.Writer

	// Once Wait returns, his will contain the exit code of the process.
	exitStatus int

	// Internal fields
	exitCh chan struct{}

	// err is used to store any error reported by the Communicator during
	// execution.
	err error

	// This thing is a mutex, lock when making modifications concurrently
	sync.Mutex
}

// Init must be called by the Communicator before executing the command.
func (c *Cmd) Init() {
	c.Lock()
	defer c.Unlock()

	c.exitCh = make(chan struct{})
}

// SetExitStatus stores the exit status of the remote command as well as any
// communicator related error. SetExitStatus then unblocks any pending calls
// to Wait.
// This should only be called by communicators executing the remote.Cmd.
func (c *Cmd) SetExitStatus(status int, err error) {
	c.Lock()
	defer c.Unlock()

	c.exitStatus = status
	c.err = err

	close(c.exitCh)
}

// StartWithUi runs the remote command and streams the output to any
// configured Writers for stdout/stderr, while also writing each line
// as it comes to a Ui.
func (r *Cmd) StartWithUi(c Communicator, ui vagrant.Ui) error {
	stdout_r, stdout_w := io.Pipe()
	stderr_r, stderr_w := io.Pipe()
	defer stdout_w.Close()
	defer stderr_w.Close()

	// Retain the original stdout/stderr that we can replace back in.
	originalStdout := r.Stdout
	originalStderr := r.Stderr
	defer func() {
		r.Lock()
		defer r.Unlock()

		r.Stdout = originalStdout
		r.Stderr = originalStderr
	}()

	// Set the writers for the output so that we get it streamed to us
	if r.Stdout == nil {
		r.Stdout = stdout_w
	} else {
		r.Stdout = io.MultiWriter(r.Stdout, stdout_w)
	}

	if r.Stderr == nil {
		r.Stderr = stderr_w
	} else {
		r.Stderr = io.MultiWriter(r.Stderr, stderr_w)
	}

	// Start the command
	if err := c.Start(r); err != nil {
		return err
	}

	// Create the channels we'll use for data
	exitCh := make(chan struct{})
	stdoutCh := iochan.DelimReader(stdout_r, '\n')
	stderrCh := iochan.DelimReader(stderr_r, '\n')

	// Start the goroutine to watch for the exit
	go func() {
		defer close(exitCh)
		defer stdout_w.Close()
		defer stderr_w.Close()
		r.Wait()
	}()

	// Loop and get all our output
OutputLoop:
	for {
		select {
		case output := <-stderrCh:
			if output != "" {
				ui.Say(r.cleanOutputLine(output))
			}
		case output := <-stdoutCh:
			if output != "" {
				ui.Say(r.cleanOutputLine(output))
			}
		case <-exitCh:
			break OutputLoop
		}
	}

	// Make sure we finish off stdout/stderr because we may have gotten
	// a message from the exit channel before finishing these first.
	for output := range stdoutCh {
		ui.Say(r.cleanOutputLine(output))
	}

	for output := range stderrCh {
		ui.Say(r.cleanOutputLine(output))
	}

	return nil
}

// Wait waits for the remote command to complete.
// Wait may return an error from the communicator, or an ExitError if the
// process exits with a non-zero exit status.
func (c *Cmd) Wait() error {
	<-c.exitCh

	c.Lock()
	defer c.Unlock()

	if c.err != nil || c.exitStatus != 0 {
		return &ExitError{
			Command:    c.Command,
			ExitStatus: c.exitStatus,
			Err:        c.err,
		}
	}

	return nil
}

// cleanOutputLine cleans up a line so that '\r' don't muck up the
// UI output when we're reading from a remote command.
func (r *Cmd) cleanOutputLine(line string) string {
	// Trim surrounding whitespace
	line = strings.TrimRightFunc(line, unicode.IsSpace)

	// Trim up to the first carriage return, since that text would be
	// lost anyways.
	idx := strings.LastIndex(line, "\r")
	if idx > -1 {
		line = line[idx+1:]
	}

	return line
}

// ExitError is returned by Wait to indicate and error executing the remote
// command, or a non-zero exit status.
type ExitError struct {
	Command    string
	ExitStatus int
	Err        error
}

func (e *ExitError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("error executing %q: %v", e.Command, e.Err)
	}
	return fmt.Sprintf("%q exit status: %d", e.Command, e.ExitStatus)
}

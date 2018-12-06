package vagrant

import (
	"bufio"
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/signal"
	"runtime"
	"strings"
	"sync"
	"syscall"
	"time"
	"unicode"
)

type UiColor uint

const (
	UiColorRed     UiColor = 31
	UiColorGreen           = 32
	UiColorYellow          = 33
	UiColorBlue            = 34
	UiColorMagenta         = 35
	UiColorCyan            = 36
)

type UiChannel uint

const (
	UiOutput UiChannel = 1
	UiError            = 2
)

var logger = DefaultLogger().Named("ui")

type Options struct {
	Channel UiChannel
	NewLine bool
}

var defaultOptions = &Options{
	Channel: UiOutput,
	NewLine: true,
}

// The Ui interface handles all communication for Vagrant with the outside
// world. This sort of control allows us to strictly control how output
// is formatted and various levels of output.
type Ui interface {
	Ask(string) (string, error)
	Detail(string)
	Info(string)
	Error(string)
	Machine(string, ...string)
	Message(string, *Options)
	Output(string)
	Say(string)
	Success(string)
	Warn(string)
}

// The BasicUI is a UI that reads and writes from a standard Go reader
// and writer. It is safe to be called from multiple goroutines. Machine
// readable output is simply logged for this UI.
type BasicUi struct {
	Reader      io.Reader
	Writer      io.Writer
	ErrorWriter io.Writer
	l           sync.Mutex
	interrupted bool
	scanner     *bufio.Scanner
}

var _ Ui = new(BasicUi)

func (rw *BasicUi) Ask(query string) (string, error) {
	rw.l.Lock()
	defer rw.l.Unlock()

	if rw.interrupted {
		return "", errors.New("interrupted")
	}

	if rw.scanner == nil {
		rw.scanner = bufio.NewScanner(rw.Reader)
	}
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)
	defer signal.Stop(sigCh)

	logger.Info("ask", query)
	if query != "" {
		if _, err := fmt.Fprint(rw.Writer, query+" "); err != nil {
			return "", err
		}
	}

	result := make(chan string, 1)
	go func() {
		var line string
		if rw.scanner.Scan() {
			line = rw.scanner.Text()
		}
		if err := rw.scanner.Err(); err != nil {
			logger.Error("scan failure", "error", err)
			return
		}
		result <- line
	}()

	select {
	case line := <-result:
		return line, nil
	case <-sigCh:
		// Print a newline so that any further output starts properly
		// on a new line.
		fmt.Fprintln(rw.Writer)

		// Mark that we were interrupted so future Ask calls fail.
		rw.interrupted = true

		return "", errors.New("interrupted")
	}
}

func (rw *BasicUi) Detail(message string)  { rw.Say(message) }
func (rw *BasicUi) Info(message string)    { rw.Say(message) }
func (rw *BasicUi) Output(message string)  { rw.Say(message) }
func (rw *BasicUi) Success(message string) { rw.Say(message) }
func (rw *BasicUi) Warn(message string)    { rw.Say(message) }

func (rw *BasicUi) Say(message string) {
	rw.Message(message, nil)
}

func (rw *BasicUi) Message(message string, opts *Options) {
	rw.l.Lock()
	defer rw.l.Unlock()

	if opts == nil {
		opts = &Options{Channel: UiOutput, NewLine: true}
	}

	logger.Debug("write message", "content", message, "options", opts)
	target := rw.Writer
	if opts.Channel == UiError {
		if rw.ErrorWriter == nil {
			logger.Error("error writer unset using writer")
		} else {
			target = rw.ErrorWriter
		}
	}
	suffix := ""
	if opts.NewLine {
		suffix = "\n"
	}

	_, err := fmt.Fprint(target, message+suffix)
	if err != nil {
		logger.Error("write failure", "error", err)
	}
}

func (rw *BasicUi) Error(message string) {
	rw.Message(message, &Options{Channel: UiError, NewLine: true})
}

func (rw *BasicUi) Machine(t string, args ...string) {
	logger.Info("machine readable", "category", t, "args", args)
}

// MachineReadableUi is a UI that only outputs machine-readable output
// to the given Writer.
type MachineReadableUi struct {
	Writer io.Writer
}

var _ Ui = new(MachineReadableUi)

func (u *MachineReadableUi) Ask(query string) (string, error) {
	return "", errors.New("machine-readable UI can't ask")
}

func (u *MachineReadableUi) Detail(message string) {
	u.Machine("ui", "detail", message)
}

func (u *MachineReadableUi) Info(message string) {
	u.Machine("ui", "info", message)
}

func (u *MachineReadableUi) Output(message string) {
	u.Machine("ui", "output", message)
}

func (u *MachineReadableUi) Success(message string) {
	u.Machine("ui", "success", message)
}

func (u *MachineReadableUi) Warn(message string) {
	u.Machine("ui", "warn", message)
}

func (u *MachineReadableUi) Say(message string) {
	u.Machine("ui", "say", message)
}

func (u *MachineReadableUi) Message(message string, opts *Options) {
	u.Machine("ui", "message", message)
}

func (u *MachineReadableUi) Error(message string) {
	u.Machine("ui", "error", message)
}

// TODO: Do we want to update this to match Vagrant machine style?
func (u *MachineReadableUi) Machine(category string, args ...string) {
	now := time.Now().UTC()

	// Determine if we have a target, and set it
	target := ""
	commaIdx := strings.Index(category, ",")
	if commaIdx > -1 {
		target = category[0:commaIdx]
		category = category[commaIdx+1:]
	}

	// Prepare the args
	for i, v := range args {
		args[i] = strings.Replace(v, ",", "%!(VAGRANT_COMMA)", -1)
		args[i] = strings.Replace(args[i], "\r", "\\r", -1)
		args[i] = strings.Replace(args[i], "\n", "\\n", -1)
	}
	argsString := strings.Join(args, ",")

	_, err := fmt.Fprintf(u.Writer, "%d,%s,%s,%s\n", now.Unix(), target, category, argsString)
	if err != nil {
		if err == syscall.EPIPE || strings.Contains(err.Error(), "broken pipe") {
			// Ignore epipe errors because that just means that the file
			// is probably closed or going to /dev/null or something.
		} else {
			panic(err)
		}
	}
}

type NoopUi struct{}

var _ Ui = new(NoopUi)

func (*NoopUi) Ask(string) (string, error) { return "", errors.New("this is a noop ui") }
func (*NoopUi) Detail(string)              { return }
func (*NoopUi) Info(string)                { return }
func (*NoopUi) Error(string)               { return }
func (*NoopUi) Machine(string, ...string)  { return }
func (*NoopUi) Message(string, *Options)   { return }
func (*NoopUi) Output(string)              { return }
func (*NoopUi) Say(string)                 { return }
func (*NoopUi) Success(string)             { return }
func (*NoopUi) Warn(string)                { return }

// ColoredUi is a UI that is colored using terminal colors.
type ColoredUi struct {
	Color        UiColor
	ErrorColor   UiColor
	SuccessColor UiColor
	WarnColor    UiColor
	Ui           Ui
}

var _ Ui = new(ColoredUi)

func (u *ColoredUi) Ask(query string) (string, error) {
	return u.Ui.Ask(u.colorize(query, u.Color, true))
}

func (u *ColoredUi) Detail(message string) {
	u.Say(message)
}

func (u *ColoredUi) Info(message string) {
	u.Say(message)
}

func (u *ColoredUi) Error(message string) {
	color := u.ErrorColor
	if color == 0 {
		color = UiColorRed
	}

	u.Ui.Error(u.colorize(message, color, true))
}

func (u *ColoredUi) Machine(t string, args ...string) {
	// Don't colorize machine-readable output
	u.Ui.Machine(t, args...)
}

func (u *ColoredUi) Message(message string, opts *Options) {
	u.Ui.Message(u.colorize(message, u.Color, false), opts)
}

func (u *ColoredUi) Output(message string) {
	u.Say(message)
}

func (u *ColoredUi) Say(message string) {
	u.Ui.Say(u.colorize(message, u.Color, true))
}

func (u *ColoredUi) Success(message string) {
	u.Ui.Say(u.colorize(message, u.SuccessColor, true))
}

func (u *ColoredUi) Warn(message string) {
	u.Ui.Say(u.colorize(message, u.WarnColor, true))
}

func (u *ColoredUi) colorize(message string, color UiColor, bold bool) string {
	if !u.supportsColors() {
		return message
	}

	attr := 0
	if bold {
		attr = 1
	}

	return fmt.Sprintf("\033[%d;%dm%s\033[0m", attr, color, message)
}

func (u *ColoredUi) supportsColors() bool {
	// Never use colors if we have this environmental variable
	if os.Getenv("VAGRANT_NO_COLOR") != "" {
		return false
	}

	// For now, on non-Windows machine, just assume it does
	if runtime.GOOS != "windows" {
		return true
	}

	// On Windows, if we appear to be in Cygwin, then it does
	cygwin := os.Getenv("CYGWIN") != "" ||
		os.Getenv("OSTYPE") == "cygwin" ||
		os.Getenv("TERM") == "cygwin"

	return cygwin
}

// TargetedUi is a UI that wraps another UI implementation and modifies
// the output to indicate a specific target. Specifically, all Say output
// is prefixed with the target name. Message output is not prefixed but
// is offset by the length of the target so that output is lined up properly
// with Say output. Machine-readable output has the proper target set.
type TargetedUi struct {
	Target string
	Ui     Ui
}

var _ Ui = new(TargetedUi)

func (u *TargetedUi) Ask(query string) (string, error) {
	return u.Ui.Ask(u.prefixLines(true, query))
}

func (u *TargetedUi) Detail(message string) {
	u.Ui.Detail(u.prefixLines(true, message))
}

func (u *TargetedUi) Info(message string) {
	u.Ui.Info(u.prefixLines(true, message))
}

func (u *TargetedUi) Output(message string) {
	u.Ui.Output(u.prefixLines(true, message))
}

func (u *TargetedUi) Success(message string) {
	u.Ui.Success(u.prefixLines(true, message))
}

func (u *TargetedUi) Warn(message string) {
	u.Ui.Warn(u.prefixLines(true, message))
}

func (u *TargetedUi) Say(message string) {
	u.Ui.Say(u.prefixLines(true, message))
}

func (u *TargetedUi) Message(message string, opts *Options) {
	u.Ui.Message(u.prefixLines(false, message), opts)
}

func (u *TargetedUi) Error(message string) {
	u.Ui.Error(u.prefixLines(true, message))
}

func (u *TargetedUi) Machine(t string, args ...string) {
	// Prefix in the target, then pass through
	u.Ui.Machine(fmt.Sprintf("%s,%s", u.Target, t), args...)
}

func (u *TargetedUi) prefixLines(arrow bool, message string) string {
	arrowText := "==>"
	if !arrow {
		arrowText = strings.Repeat(" ", len(arrowText))
	}

	var result bytes.Buffer

	for _, line := range strings.Split(message, "\n") {
		result.WriteString(fmt.Sprintf("%s %s: %s\n", arrowText, u.Target, line))
	}

	return strings.TrimRightFunc(result.String(), unicode.IsSpace)
}

// TimestampedUi is a UI that wraps another UI implementation and prefixes
// prefixes each message with an RFC3339 timestamp
type TimestampedUi struct {
	Ui Ui
}

var _ Ui = new(TimestampedUi)

func (u *TimestampedUi) Ask(query string) (string, error) {
	return u.Ui.Ask(query)
}

func (u *TimestampedUi) Detail(message string) {
	u.Ui.Detail(u.timestampLine(message))
}

func (u *TimestampedUi) Info(message string) {
	u.Ui.Info(u.timestampLine(message))
}

func (u *TimestampedUi) Output(message string) {
	u.Ui.Output(u.timestampLine(message))
}

func (u *TimestampedUi) Success(message string) {
	u.Ui.Success(u.timestampLine(message))
}

func (u *TimestampedUi) Warn(message string) {
	u.Ui.Warn(u.timestampLine(message))
}

func (u *TimestampedUi) Say(message string) {
	u.Ui.Say(u.timestampLine(message))
}

func (u *TimestampedUi) Message(message string, opts *Options) {
	u.Ui.Message(u.timestampLine(message), opts)
}

func (u *TimestampedUi) Error(message string) {
	u.Ui.Error(u.timestampLine(message))
}

func (u *TimestampedUi) Machine(message string, args ...string) {
	u.Ui.Machine(message, args...)
}

func (u *TimestampedUi) timestampLine(string string) string {
	return fmt.Sprintf("%v: %v", time.Now().Format(time.RFC3339), string)
}

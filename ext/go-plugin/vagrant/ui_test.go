package vagrant

import (
	"bytes"
	"os"
	"strings"
	"testing"
)

// This reads the output from the bytes.Buffer in our test object
// and then resets the buffer.
func readWriter(ui *BasicUi) (result string) {
	buffer := ui.Writer.(*bytes.Buffer)
	result = buffer.String()
	buffer.Reset()
	return
}

// Reset the input Reader then add some input to it.
func writeReader(ui *BasicUi, input string) {
	buffer := ui.Reader.(*bytes.Buffer)
	buffer.WriteString(input)
}

func readErrorWriter(ui *BasicUi) (result string) {
	buffer := ui.ErrorWriter.(*bytes.Buffer)
	result = buffer.String()
	buffer.Reset()
	return
}

func testUi() *BasicUi {
	return &BasicUi{
		Reader:      new(bytes.Buffer),
		Writer:      new(bytes.Buffer),
		ErrorWriter: new(bytes.Buffer),
	}
}

func TestColoredUi(t *testing.T) {
	bufferUi := testUi()
	ui := &ColoredUi{UiColorBlue, UiColorRed, UiColorGreen,
		UiColorYellow, bufferUi}

	if !ui.supportsColors() {
		t.Skip("skipping for ui without color support")
	}

	ui.Say("foo")
	result := readWriter(bufferUi)
	if result != "\033[1;34mfoo\033[0m\n" {
		t.Fatalf("invalid output: %s", result)
	}

	ui.Message("foo", nil)
	result = readWriter(bufferUi)
	if result != "\033[0;34mfoo\033[0m\n" {
		t.Fatalf("invalid output: %s", result)
	}

	ui.Error("foo")
	result = readWriter(bufferUi)
	if result != "" {
		t.Fatalf("invalid output: %s", result)
	}

	result = readErrorWriter(bufferUi)
	if result != "\033[1;31mfoo\033[0m\n" {
		t.Fatalf("invalid output: %s", result)
	}
}

func TestColoredUi_noColorEnv(t *testing.T) {
	bufferUi := testUi()
	ui := &ColoredUi{UiColorBlue, UiColorRed, UiColorGreen,
		UiColorYellow, bufferUi}

	// Set the env var to get rid of the color
	oldenv := os.Getenv("VAGRANT_NO_COLOR")
	os.Setenv("VAGRANT_NO_COLOR", "1")
	defer os.Setenv("VAGRANT_NO_COLOR", oldenv)

	ui.Say("foo")
	result := readWriter(bufferUi)
	if result != "foo\n" {
		t.Fatalf("invalid output: %s", result)
	}

	ui.Message("foo", nil)
	result = readWriter(bufferUi)
	if result != "foo\n" {
		t.Fatalf("invalid output: %s", result)
	}

	ui.Error("foo")
	result = readErrorWriter(bufferUi)
	if result != "foo\n" {
		t.Fatalf("invalid output: %s", result)
	}
}

func TestTargetedUi(t *testing.T) {
	bufferUi := testUi()
	targetedUi := &TargetedUi{
		Target: "foo",
		Ui:     bufferUi,
	}

	var actual, expected string
	targetedUi.Say("foo")
	actual = readWriter(bufferUi)
	expected = "==> foo: foo\n"
	if actual != expected {
		t.Fatalf("bad: %#v", actual)
	}

	targetedUi.Message("foo", nil)
	actual = readWriter(bufferUi)
	expected = "    foo: foo\n"
	if actual != expected {
		t.Fatalf("bad: %#v", actual)
	}

	targetedUi.Error("bar")
	actual = readErrorWriter(bufferUi)
	expected = "==> foo: bar\n"
	if actual != expected {
		t.Fatalf("bad: %#v", actual)
	}

	targetedUi.Say("foo\nbar")
	actual = readWriter(bufferUi)
	expected = "==> foo: foo\n==> foo: bar\n"
	if actual != expected {
		t.Fatalf("bad: %#v", actual)
	}
}

func TestColoredUi_ImplUi(t *testing.T) {
	var raw interface{}
	raw = &ColoredUi{}
	if _, ok := raw.(Ui); !ok {
		t.Fatalf("ColoredUi must implement Ui")
	}
}

func TestTargetedUi_ImplUi(t *testing.T) {
	var raw interface{}
	raw = &TargetedUi{}
	if _, ok := raw.(Ui); !ok {
		t.Fatalf("TargetedUi must implement Ui")
	}
}

func TestBasicUi_ImplUi(t *testing.T) {
	var raw interface{}
	raw = &BasicUi{}
	if _, ok := raw.(Ui); !ok {
		t.Fatalf("BasicUi must implement Ui")
	}
}

func TestBasicUi_Error(t *testing.T) {
	bufferUi := testUi()

	var actual, expected string
	bufferUi.Error("foo")
	actual = readErrorWriter(bufferUi)
	expected = "foo\n"
	if actual != expected {
		t.Fatalf("bad: %#v", actual)
	}

	bufferUi.ErrorWriter = nil
	bufferUi.Error("5")
	actual = readWriter(bufferUi)
	expected = "5\n"
	if actual != expected {
		t.Fatalf("bad: %#v", actual)
	}
}

func TestBasicUi_Say(t *testing.T) {
	bufferUi := testUi()

	var actual, expected string

	bufferUi.Say("foo")
	actual = readWriter(bufferUi)
	expected = "foo\n"
	if actual != expected {
		t.Fatalf("bad: %#v", actual)
	}

	bufferUi.Say("5")
	actual = readWriter(bufferUi)
	expected = "5\n"
	if actual != expected {
		t.Fatalf("bad: %#v", actual)
	}
}

func TestBasicUi_Ask(t *testing.T) {

	var actual, expected string
	var err error

	var testCases = []struct {
		Prompt, Input, Answer string
	}{
		{"[c]ontinue or [a]bort", "c\n", "c"},
		{"[c]ontinue or [a]bort", "c", "c"},
		// Empty input shouldn't give an error
		{"Name", "Joe Bloggs\n", "Joe Bloggs"},
		{"Name", "Joe Bloggs", "Joe Bloggs"},
		{"Name", "\n", ""},
	}

	for _, testCase := range testCases {
		// Because of the internal bufio we can't easily reset the input, so create a new one each time
		bufferUi := testUi()
		writeReader(bufferUi, testCase.Input)

		actual, err = bufferUi.Ask(testCase.Prompt)
		if err != nil {
			t.Fatal(err)
		}

		if actual != testCase.Answer {
			t.Fatalf("bad answer: %#v", actual)
		}

		actual = readWriter(bufferUi)
		expected = testCase.Prompt + " "
		if actual != expected {
			t.Fatalf("bad prompt: %#v", actual)
		}
	}

}

func TestMachineReadableUi_ImplUi(t *testing.T) {
	var raw interface{}
	raw = &MachineReadableUi{}
	if _, ok := raw.(Ui); !ok {
		t.Fatalf("MachineReadableUi must implement Ui")
	}
}

func TestMachineReadableUi(t *testing.T) {
	var data, expected string

	buf := new(bytes.Buffer)
	ui := &MachineReadableUi{Writer: buf}

	// No target
	ui.Machine("foo", "bar", "baz")
	data = strings.SplitN(buf.String(), ",", 2)[1]
	expected = ",foo,bar,baz\n"
	if data != expected {
		t.Fatalf("bad: %s", data)
	}

	// Target
	buf.Reset()
	ui.Machine("mitchellh,foo", "bar", "baz")
	data = strings.SplitN(buf.String(), ",", 2)[1]
	expected = "mitchellh,foo,bar,baz\n"
	if data != expected {
		t.Fatalf("bad: %s", data)
	}

	// Commas
	buf.Reset()
	ui.Machine("foo", "foo,bar")
	data = strings.SplitN(buf.String(), ",", 2)[1]
	expected = ",foo,foo%!(VAGRANT_COMMA)bar\n"
	if data != expected {
		t.Fatalf("bad: %s", data)
	}

	// New lines
	buf.Reset()
	ui.Machine("foo", "foo\n")
	data = strings.SplitN(buf.String(), ",", 2)[1]
	expected = ",foo,foo\\n\n"
	if data != expected {
		t.Fatalf("bad: %#v", data)
	}
}

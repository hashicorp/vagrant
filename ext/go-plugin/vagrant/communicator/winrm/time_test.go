package winrm

import (
	"testing"
	"time"
)

func TestFormatDuration(t *testing.T) {
	// Test complex duration with hours, minutes, seconds
	d := time.Duration(3701) * time.Second
	s := formatDuration(d)
	if s != "PT1H1M41S" {
		t.Fatalf("bad ISO 8601 duration string: %s", s)
	}

	// Test only minutes duration
	d = time.Duration(20) * time.Minute
	s = formatDuration(d)
	if s != "PT20M" {
		t.Fatalf("bad ISO 8601 duration string for 20M: %s", s)
	}

	// Test only seconds
	d = time.Duration(1) * time.Second
	s = formatDuration(d)
	if s != "PT1S" {
		t.Fatalf("bad ISO 8601 duration string for 1S: %s", s)
	}

	// Test negative duration (unsupported)
	d = time.Duration(-1) * time.Second
	s = formatDuration(d)
	if s != "PT0S" {
		t.Fatalf("bad ISO 8601 duration string for negative: %s", s)
	}
}

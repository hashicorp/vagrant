package winrm

import (
	"fmt"
	"time"
)

// formatDuration formats the given time.Duration into an ISO8601
// duration string.
func formatDuration(duration time.Duration) string {
	// We're not supporting negative durations
	if duration.Seconds() <= 0 {
		return "PT0S"
	}

	h := int(duration.Hours())
	m := int(duration.Minutes()) - (h * 60)
	s := int(duration.Seconds()) - (h*3600 + m*60)

	res := "PT"
	if h > 0 {
		res = fmt.Sprintf("%s%dH", res, h)
	}
	if m > 0 {
		res = fmt.Sprintf("%s%dM", res, m)
	}
	if s > 0 {
		res = fmt.Sprintf("%s%dS", res, s)
	}

	return res
}

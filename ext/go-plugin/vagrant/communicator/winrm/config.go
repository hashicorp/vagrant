package winrm

import (
	"time"

	"github.com/masterzen/winrm"
)

// Config is used to configure the WinRM connection
type Config struct {
	Host               string
	Port               int
	Username           string
	Password           string
	Timeout            time.Duration
	Https              bool
	Insecure           bool
	TransportDecorator func() winrm.Transporter
}

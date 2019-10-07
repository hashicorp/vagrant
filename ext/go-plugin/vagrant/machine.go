package vagrant

import (
	"encoding/json"
	"io"
	"os"
)

type Machine struct {
	Box             Box                    `json:"box"`
	Config          map[string]interface{} `json:"config"`
	DataDir         string                 `json:"data_dir,omitempty"`
	Env             Environment            `json:"environment"`
	ID              string                 `json:"id,omitempty"`
	Name            string                 `json:"name,omitempty"`
	ProviderConfig  map[string]interface{} `json:"provider_config"`
	ProviderName    string                 `json:"provider_name,omitempty"`
	ProviderOptions map[string]string      `json:"provider_options"`
	UI              Ui                     `json:"-"`
}

func DumpMachine(m *Machine) (s string, err error) {
	DefaultLogger().Debug("dumping machine to serialized data")
	b, err := json.Marshal(m)
	if err != nil {
		DefaultLogger().Debug("machine dump failure", "error", err)
		return
	}
	s = string(b)
	return
}

func LoadMachine(mdata string, ios IOServer) (m *Machine, err error) {
	DefaultLogger().Debug("loading machine from serialized data")
	m = &Machine{}
	err = json.Unmarshal([]byte(mdata), m)
	if err != nil {
		return
	}
	var stdout io.Writer
	var stderr io.Writer
	if ios == nil {
		stdout = os.Stdout
		stderr = os.Stderr
	} else {
		stdout = &IOWriter{target: "stdout", srv: ios}
		stderr = &IOWriter{target: "stderr", srv: ios}
	}
	m.UI = &TargetedUi{
		Target: m.Name,
		Ui: &ColoredUi{
			ErrorColor: UiColorRed,
			Ui: &BasicUi{
				Reader:      os.Stdin,
				Writer:      stdout,
				ErrorWriter: stderr},
		}}
	return
}

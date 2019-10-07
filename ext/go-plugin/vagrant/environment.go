package vagrant

import (
	"encoding/json"
	"io"
	"os"
)

type Environment struct {
	ActiveMachines        map[string]string `json:"active_machines,omitempty"`
	AliasesPath           string            `json:"aliases_path,omitempty"`
	BoxesPath             string            `json:"boxes_path,omitempty"`
	CWD                   string            `json:"cwd,omitempty"`
	DataDir               string            `json:"data_dir,omitempty"`
	DefaultPrivateKeyPath string            `json:"default_private_key_path,omitempty"`
	GemsPath              string            `json:"gems_path,omitempty"`
	HomePath              string            `json:"home_path,omitempty"`
	LocalDataPath         string            `json:"local_data_path,omitempty"`
	MachineNames          []string          `json:"machine_names,omitempty"`
	PrimaryMachineName    string            `json:"primary_machine_name,omitempty"`
	RootPath              string            `json:"root_path,omitempty"`
	TmpPath               string            `json:"tmp_path,omitempty"`
	VagrantfileName       string            `json:"vagrantfile_name,omitempty"`
	UI                    Ui                `json:"-"`
}

func DumpEnvironment(e *Environment) (s string, err error) {
	DefaultLogger().Debug("dumping environment to serialized data")
	b, err := json.Marshal(e)
	if err != nil {
		DefaultLogger().Error("environment dump failure", "error", err)
		return
	}
	s = string(b)
	return
}

func LoadEnvironment(edata string, ios IOServer) (e *Environment, err error) {
	DefaultLogger().Debug("loading environment from serialized data")
	e = &Environment{}
	err = json.Unmarshal([]byte(edata), e)
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
	e.UI = &TargetedUi{
		Target: "vagrant",
		Ui: &ColoredUi{
			ErrorColor: UiColorRed,
			Ui: &BasicUi{
				Reader:      os.Stdin,
				Writer:      stdout,
				ErrorWriter: stderr},
		}}
	return
}

package vagrant

type MachineState struct {
	Id        string `json:"id"`
	ShortDesc string `json:"short_description"`
	LongDesc  string `json:"long_description"`
}

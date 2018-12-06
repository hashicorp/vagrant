package vagrant

type Box struct {
	Name        string            `json:"name"`
	Provider    string            `json:"provider"`
	Version     string            `json:"version"`
	Directory   string            `json:"directory"`
	Metadata    map[string]string `json:"metadata"`
	MetadataURL string            `json:"metadata_url"`
}

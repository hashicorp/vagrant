package vagrant

type SshInfo struct {
	Host           string `json:"host"`
	Port           int64  `json:"port"`
	Username       string `json:"username"`
	PrivateKeyPath string `json:"private_key_path"`
}

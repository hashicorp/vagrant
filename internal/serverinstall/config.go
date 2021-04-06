package serverinstall

// Config is the configuration for the Kubernetes installation template.
type Config struct {
	Namespace          string
	ServiceName        string
	ServerName         string
	ServerImage        string
	ServiceAnnotations map[string]string
	ImagePullSecret    string
	ImagePullPolicy    string
	OpenShift          bool
	Replicas           int32
	CPULimit           string
	MemLimit           string
	CPURequest         string
	MemRequest         string
	StorageRequest     string
}

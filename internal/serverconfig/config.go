package serverconfig

// Client configures a client to connect to a server.
type Client struct {
	Address string `hcl:"address,attr"`

	// Tls, if true, will connect to the server with TLS. If TlsSkipVerify
	// is true, the certificate presented by the server will not be validated.
	Tls           bool `hcl:"tls,optional"`
	TlsSkipVerify bool `hcl:"tls_skip_verify,optional"`

	// AddressInternal is a temporary config to work with local deployments
	// on platforms such as Docker for Mac. We need to discuss a more
	// long term approach to this.
	AddressInternal string `hcl:"address_internal,optional"`

	// Indicates that we need to present a token to connect to this server.
	RequireAuth bool `hcl:"require_auth,optional"`

	// AuthToken is the token to use to authenticate to the server.
	// Note this will be stored plaintext on disk. You can also use the
	// WAYPOINT_SERVER_TOKEN env var.
	AuthToken string `hcl:"auth_token,optional"`
}

// Config is the configuration for the built-in server.
type Config struct {
	// DBPath is the path to the database file, including the filename.
	DBPath string `hcl:"db_path,attr"`

	// GRPC is the grpc service listening configuration. This is required.
	GRPC Listener `hcl:"grpc,block"`

	// HTTP is the listening configuration for the HTTP service for grpc-web.
	HTTP Listener `hcl:"http,block"`

	// URL configures a server to use a URL service.
	URL *URL `hcl:"url,block"`
}

type Listener struct {
	Addr        string `hcl:"address,attr"`
	TLSDisable  bool   `hcl:"tls_disable,optional"`
	TLSCertFile string `hcl:"tls_cert_file,optional"`
	TLSKeyFile  string `hcl:"tls_key_file,optional"`
}

// URL is the configuration for the URL service.
type URL struct {
	Enabled              bool   `hcl:"enabled,optional"`
	APIAddress           string `hcl:"api_address,optional"`
	APIInsecure          bool   `hcl:"api_insecure,optional"`
	APIToken             string `hcl:"api_token,optional"`
	ControlAddress       string `hcl:"control_address,optional"`
	AutomaticAppHostname bool   `hcl:"automatic_app_hostname,optional"`
}

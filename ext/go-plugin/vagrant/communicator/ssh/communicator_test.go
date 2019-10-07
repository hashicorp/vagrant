// +build !race

package ssh

import (
	"bytes"
	"fmt"
	"net"
	"testing"
	"time"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/communicator"
	"golang.org/x/crypto/ssh"
)

// private key for mock server
const testServerPrivateKey = `-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA19lGVsTqIT5iiNYRgnoY1CwkbETW5cq+Rzk5v/kTlf31XpSU
70HVWkbTERECjaYdXM2gGcbb+sxpq6GtXf1M3kVomycqhxwhPv4Cr6Xp4WT/jkFx
9z+FFzpeodGJWjOH6L2H5uX1Cvr9EDdQp9t9/J32/qBFntY8GwoUI/y/1MSTmMiF
tupdMODN064vd3gyMKTwrlQ8tZM6aYuyOPsutLlUY7M5x5FwMDYvnPDSeyT/Iw0z
s3B+NCyqeeMd2T7YzQFnRATj0M7rM5LoSs7DVqVriOEABssFyLj31PboaoLhOKgc
qoM9khkNzr7FHVvi+DhYM2jD0DwvqZLN6NmnLwIDAQABAoIBAQCGVj+kuSFOV1lT
+IclQYA6bM6uY5mroqcSBNegVxCNhWU03BxlW//BE9tA/+kq53vWylMeN9mpGZea
riEMIh25KFGWXqXlOOioH8bkMsqA8S7sBmc7jljyv+0toQ9vCCtJ+sueNPhxQQxH
D2YvUjfzBQ04I9+wn30BByDJ1QA/FoPsunxIOUCcRBE/7jxuLYcpR+JvEF68yYIh
atXRld4W4in7T65YDR8jK1Uj9XAcNeDYNpT/M6oFLx1aPIlkG86aCWRO19S1jLPT
b1ZAKHHxPMCVkSYW0RqvIgLXQOR62D0Zne6/2wtzJkk5UCjkSQ2z7ZzJpMkWgDgN
ifCULFPBAoGBAPoMZ5q1w+zB+knXUD33n1J+niN6TZHJulpf2w5zsW+m2K6Zn62M
MXndXlVAHtk6p02q9kxHdgov34Uo8VpuNjbS1+abGFTI8NZgFo+bsDxJdItemwC4
KJ7L1iz39hRN/ZylMRLz5uTYRGddCkeIHhiG2h7zohH/MaYzUacXEEy3AoGBANz8
e/msleB+iXC0cXKwds26N4hyMdAFE5qAqJXvV3S2W8JZnmU+sS7vPAWMYPlERPk1
D8Q2eXqdPIkAWBhrx4RxD7rNc5qFNcQWEhCIxC9fccluH1y5g2M+4jpMX2CT8Uv+
3z+NoJ5uDTXZTnLCfoZzgZ4nCZVZ+6iU5U1+YXFJAoGBANLPpIV920n/nJmmquMj
orI1R/QXR9Cy56cMC65agezlGOfTYxk5Cfl5Ve+/2IJCfgzwJyjWUsFx7RviEeGw
64o7JoUom1HX+5xxdHPsyZ96OoTJ5RqtKKoApnhRMamau0fWydH1yeOEJd+TRHhc
XStGfhz8QNa1dVFvENczja1vAoGABGWhsd4VPVpHMc7lUvrf4kgKQtTC2PjA4xoc
QJ96hf/642sVE76jl+N6tkGMzGjnVm4P2j+bOy1VvwQavKGoXqJBRd5Apppv727g
/SM7hBXKFc/zH80xKBBgP/i1DR7kdjakCoeu4ngeGywvu2jTS6mQsqzkK+yWbUxJ
I7mYBsECgYB/KNXlTEpXtz/kwWCHFSYA8U74l7zZbVD8ul0e56JDK+lLcJ0tJffk
gqnBycHj6AhEycjda75cs+0zybZvN4x65KZHOGW/O/7OAWEcZP5TPb3zf9ned3Hl
NsZoFj52ponUM6+99A2CmezFCN16c4mbA//luWF+k3VVqR6BpkrhKw==
-----END RSA PRIVATE KEY-----`

var serverConfig = &ssh.ServerConfig{
	PasswordCallback: func(c ssh.ConnMetadata, pass []byte) (*ssh.Permissions, error) {
		if c.User() == "user" && string(pass) == "pass" {
			return nil, nil
		}
		return nil, fmt.Errorf("password rejected for %q", c.User())
	},
}

func init() {
	// Parse and set the private key of the server, required to accept connections
	signer, err := ssh.ParsePrivateKey([]byte(testServerPrivateKey))
	if err != nil {
		panic("unable to parse private key: " + err.Error())
	}
	serverConfig.AddHostKey(signer)
}

func newMockLineServer(t *testing.T) string {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("Unable to listen for connection: %s", err)
	}

	go func() {
		defer l.Close()
		c, err := l.Accept()
		if err != nil {
			t.Errorf("Unable to accept incoming connection: %s", err)
		}
		defer c.Close()
		conn, chans, _, err := ssh.NewServerConn(c, serverConfig)
		if err != nil {
			t.Logf("Handshaking error: %v", err)
		}
		t.Log("Accepted SSH connection")
		for newChannel := range chans {
			channel, _, err := newChannel.Accept()
			if err != nil {
				t.Errorf("Unable to accept channel.")
			}
			t.Log("Accepted channel")

			go func(channelType string) {
				defer channel.Close()
				conn.OpenChannel(channelType, nil)
			}(newChannel.ChannelType())
		}
		conn.Close()
	}()

	return l.Addr().String()
}

func newMockBrokenServer(t *testing.T) string {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("Unable tp listen for connection: %s", err)
	}

	go func() {
		defer l.Close()
		c, err := l.Accept()
		if err != nil {
			t.Errorf("Unable to accept incoming connection: %s", err)
		}
		defer c.Close()
		// This should block for a period of time longer than our timeout in
		// the test case. That way we invoke a failure scenario.
		t.Log("Block on handshaking for SSH connection")
		time.Sleep(5 * time.Second)
	}()

	return l.Addr().String()
}

func TestCommIsCommunicator(t *testing.T) {
	var raw interface{}
	raw = &Communicator{}
	if _, ok := raw.(communicator.Communicator); !ok {
		t.Fatalf("Communicator must be a communicator")
	}
}

func TestNew_Invalid(t *testing.T) {
	clientConfig := &ssh.ClientConfig{
		User: "user",
		Auth: []ssh.AuthMethod{
			ssh.Password("i-am-invalid"),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	address := newMockLineServer(t)
	conn := func() (net.Conn, error) {
		conn, err := net.Dial("tcp", address)
		if err != nil {
			t.Errorf("Unable to accept incoming connection: %v", err)
		}
		return conn, err
	}

	config := &Config{
		Connection: conn,
		SSHConfig:  clientConfig,
	}

	comm, err := New(address, config)
	if err != nil {
		t.Fatalf("Failed to setup communicator: %s", err)
	}
	err = comm.Connect()
	if err == nil {
		t.Fatal("should have had an error connecting")
	}
}

func TestStart(t *testing.T) {
	clientConfig := &ssh.ClientConfig{
		User: "user",
		Auth: []ssh.AuthMethod{
			ssh.Password("pass"),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	address := newMockLineServer(t)
	conn := func() (net.Conn, error) {
		conn, err := net.Dial("tcp", address)
		if err != nil {
			t.Fatalf("unable to dial to remote side: %s", err)
		}
		return conn, err
	}

	config := &Config{
		Connection: conn,
		SSHConfig:  clientConfig,
	}

	client, err := New(address, config)
	if err != nil {
		t.Fatalf("error connecting to SSH: %s", err)
	}

	cmd := &communicator.Cmd{
		Command: "echo foo",
		Stdout:  new(bytes.Buffer),
	}

	client.Start(cmd)
}

func TestHandshakeTimeout(t *testing.T) {
	clientConfig := &ssh.ClientConfig{
		User: "user",
		Auth: []ssh.AuthMethod{
			ssh.Password("pass"),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	address := newMockBrokenServer(t)
	conn := func() (net.Conn, error) {
		conn, err := net.Dial("tcp", address)
		if err != nil {
			t.Fatalf("unable to dial to remote side: %s", err)
		}
		return conn, err
	}

	config := &Config{
		Connection:       conn,
		SSHConfig:        clientConfig,
		HandshakeTimeout: 50 * time.Millisecond,
	}

	comm, err := New(address, config)
	if err != nil {
		t.Fatalf("Failed to setup communicator: %s", err)
	}
	err = comm.Connect()
	if err != ErrHandshakeTimeout {
		// Note: there's another error that can come back from this call:
		//   ssh: handshake failed: EOF
		// This should appear in cases where the handshake fails because of
		// malformed (or no) data sent back by the server, but should not happen
		// in a timeout scenario.
		t.Fatalf("Expected handshake timeout, got: %s", err)
	}
}

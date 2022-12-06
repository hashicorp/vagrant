package epinject

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/hashicorp/go-hclog"
	"github.com/oklog/ulid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestEPInject(t *testing.T) {
	t.Run("can alter the entrypoint of a docker image", func(t *testing.T) {
		_, err := exec.LookPath("docker")
		if err != nil {
			t.Skip("docker isn't available to test with")
		}

		// Use the nginx image for this

		out, err := exec.Command("docker", "pull", "nginx").CombinedOutput()
		require.NoError(t, err, string(out))

		var inspectOut []struct {
			Config struct {
				Entrypoint []string `json:"entrypoint"`
			} `json:"Config"`
		}

		out, err = exec.Command("docker", "inspect", "nginx").CombinedOutput()
		require.NoError(t, err, string(out))

		err = json.Unmarshal(out, &inspectOut)
		require.NoError(t, err)

		ctx := context.Background()

		u, err := ulid.New(ulid.Now(), rand.Reader)
		require.NoError(t, err)

		origEp := inspectOut[0].Config.Entrypoint

		testImage := strings.ToLower("epinject-test-" + u.String() + ":latest")

		// Be sure we cleanup our test image
		defer exec.Command("docker", "rmi", "-f", testImage).Run()

		L := hclog.New(&hclog.LoggerOptions{Level: hclog.Trace})

		ctx = hclog.WithContext(ctx, L)

		injectF, err := os.Open("./testdata/cowsay")
		require.NoError(t, err)
		defer injectF.Close()
		injectFI, err := injectF.Stat()
		require.NoError(t, err)

		_, err = AlterEntrypoint(ctx, "nginx:latest", func(cur []string) (*NewEntrypoint, error) {
			assert.Equal(t, origEp, cur)

			ep := &NewEntrypoint{
				NewImage:   testImage,
				Entrypoint: append([]string{"/bin/cowsay"}, cur...),
				InjectFiles: map[string]InjectFile{
					"/bin/cowsay": {
						Reader: injectF,
						Info:   injectFI,
					},
				},
			}

			return ep, nil
		})
		require.NoError(t, err)

		out, err = exec.Command("docker", "inspect", testImage).Output()
		require.NoError(t, err)

		inspectOut = nil

		err = json.Unmarshal(out, &inspectOut)
		require.NoError(t, err)

		assert.Equal(t, "/bin/cowsay", inspectOut[0].Config.Entrypoint[0])
		assert.Equal(t, origEp, inspectOut[0].Config.Entrypoint[1:])

		// Check for cowsay

		out, err = exec.Command("docker", "run", "--rm", testImage, "/bin/cowsay").Output()
		require.NoError(t, err)

		assert.Equal(t, "moooooo\n", string(out))

	})
}

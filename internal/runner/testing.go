package runner

// import (
// 	"io/ioutil"
// 	"os"

// 	"github.com/mitchellh/go-testing-interface"
// 	"github.com/stretchr/testify/require"

// 	configpkg "github.com/hashicorp/vagrant/internal/config"
// 	"github.com/hashicorp/vagrant/internal/server/singleprocess"
// )

// // TestRunner returns an initialized runner pointing to an in-memory test
// // server. This will close automatically on test completion.
// //
// // This will also change the working directory to a temporary directory
// // so that any side effect file creation doesn't impact the real working
// // directory. If you need to use your working directory, query it before
// // calling this.
// func TestRunner(t testing.T, opts ...Option) *Runner {
// 	require := require.New(t)
// 	client := singleprocess.TestServer(t)

// 	// Initialize our runner
// 	runner, err := New(append([]Option{
// 		WithClient(client),
// 	}, opts...)...)
// 	require.NoError(err)
// 	t.Cleanup(func() { runner.Close() })

// 	// Move into a temporary directory
// 	td := testTempDir(t)
// 	testChdir(t, td)

// 	// Create a valid vagrant configuration file
// 	configpkg.TestConfigFile(t, configpkg.TestSource(t))

// 	return runner
// }

// func testChdir(t testing.T, dir string) {
// 	pwd, err := os.Getwd()
// 	require.NoError(t, err)
// 	require.NoError(t, os.Chdir(dir))
// 	t.Cleanup(func() { require.NoError(t, os.Chdir(pwd)) })
// }

// func testTempDir(t testing.T) string {
// 	dir, err := ioutil.TempDir("", "vagrant-test")
// 	require.NoError(t, err)
// 	t.Cleanup(func() { os.RemoveAll(dir) })
// 	return dir
// }

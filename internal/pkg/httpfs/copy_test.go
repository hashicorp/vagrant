package httpfs

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestCopy_file(t *testing.T) {
	require := require.New(t)

	td, err := ioutil.TempDir("", "httpfs")
	require.NoError(err)
	defer os.RemoveAll(td)

	path := filepath.Join(td, "file.txt")
	require.NoError(Copy(AssetFile(), path, "dir/hello.txt"))

	data, err := ioutil.ReadFile(path)
	require.NoError(err)
	require.Equal("Hello\n", string(data))
}

func TestCopy_dir(t *testing.T) {
	require := require.New(t)

	td, err := ioutil.TempDir("", "httpfs")
	require.NoError(err)
	defer os.RemoveAll(td)

	require.NoError(Copy(AssetFile(), td, "dir"))

	{
		data, err := ioutil.ReadFile(filepath.Join(td, "hello.txt"))
		require.NoError(err)
		require.Equal("Hello\n", string(data))
	}

	{
		data, err := ioutil.ReadFile(filepath.Join(td, "subdir", "child.txt"))
		require.NoError(err)
		require.Equal("Child\n", string(data))
	}
}

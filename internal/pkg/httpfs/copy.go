package httpfs

import (
	"io"
	"net/http"
	"os"
	"path/filepath"
)

// Copy copies the file src to dst from the filesystem fs. If src is
// a directory, then all contents in the directory will be copied into the
// directory dst. If src is a file, then it will be copied directly to dst.
func Copy(fs http.FileSystem, dst, src string) error {
	f, err := fs.Open(src)
	if err != nil {
		return err
	}
	defer f.Close()

	fi, err := f.Stat()
	if err != nil {
		return err
	}

	// If this is a file, then copy the file as-is to the destination path
	// and we're done.
	if !fi.IsDir() {
		dstF, err := os.OpenFile(dst, os.O_RDWR|os.O_CREATE|os.O_TRUNC, mode(fi))
		if err != nil {
			return err
		}
		defer dstF.Close()

		_, err = io.Copy(dstF, f)
		return err
	}

	// Create this directory
	if _, err := os.Stat(dst); err != nil {
		if !os.IsNotExist(err) {
			return err
		}

		if err := os.Mkdir(dst, mode(fi)); err != nil {
			return err
		}
	}

	// We want to copy all the files
	fis, err := f.Readdir(-1)
	if err != nil {
		return err
	}
	for _, fi := range fis {
		// fi.Name is in the format "src/filename" where src is the
		// value of src. We need to get the relative path so that we can
		// determine the proper target destination.
		rel, err := filepath.Rel(src, fi.Name())
		if err != nil {
			return err
		}

		// Recurse!
		if err := Copy(fs, filepath.Join(dst, rel), fi.Name()); err != nil {
			return err
		}
	}

	return nil
}

// mode returns the proper mode to use for creating files
func mode(fi os.FileInfo) os.FileMode {
	if fi.IsDir() {
		// We always return this. We don't use fi.Mode because go-bindata
		// sets it to non-executable.
		return 0755
	}

	mode := fi.Mode()
	if mode > 0 {
		return mode
	}

	return 0644
}

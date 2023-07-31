// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

// Code generated for package locales by go-bindata DO NOT EDIT. (@generated)
// sources:
// locales/assets/en.json
// locales/assets/es.json
package locales

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func bindataRead(data []byte, name string) ([]byte, error) {
	gz, err := gzip.NewReader(bytes.NewBuffer(data))
	if err != nil {
		return nil, fmt.Errorf("Read %q: %v", name, err)
	}

	var buf bytes.Buffer
	_, err = io.Copy(&buf, gz)
	clErr := gz.Close()

	if err != nil {
		return nil, fmt.Errorf("Read %q: %v", name, err)
	}
	if clErr != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

type asset struct {
	bytes []byte
	info  os.FileInfo
}

type bindataFileInfo struct {
	name    string
	size    int64
	mode    os.FileMode
	modTime time.Time
}

// Name return file name
func (fi bindataFileInfo) Name() string {
	return fi.name
}

// Size return file size
func (fi bindataFileInfo) Size() int64 {
	return fi.size
}

// Mode return file mode
func (fi bindataFileInfo) Mode() os.FileMode {
	return fi.mode
}

// Mode return file modify time
func (fi bindataFileInfo) ModTime() time.Time {
	return fi.modTime
}

// IsDir return file whether a directory
func (fi bindataFileInfo) IsDir() bool {
	return fi.mode&os.ModeDir != 0
}

// Sys return file is sys mode
func (fi bindataFileInfo) Sys() interface{} {
	return nil
}

var _localesAssetsEnJson = []byte("\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff\xaa\xe6\x52\x50\x50\x4a\xc9\x2f\xc9\xc8\xcc\x4b\x57\xb2\x52\x50\x0a\x29\xca\x4c\xce\x4e\x4d\x51\xa8\x4c\x54\x54\xf0\x54\x48\x4c\x2e\x29\x4d\xcc\xc9\xa9\x54\x48\xc9\x57\xc8\x83\x28\x52\xb0\x0a\x50\xe2\xaa\xe5\x02\x04\x00\x00\xff\xff\xae\xf3\xa3\xbd\x38\x00\x00\x00")

func localesAssetsEnJsonBytes() ([]byte, error) {
	return bindataRead(
		_localesAssetsEnJson,
		"locales/assets/en.json",
	)
}

func localesAssetsEnJson() (*asset, error) {
	bytes, err := localesAssetsEnJsonBytes()
	if err != nil {
		return nil, err
	}

	info := bindataFileInfo{name: "locales/assets/en.json", size: 56, mode: os.FileMode(420), modTime: time.Unix(1651259149, 0)}
	a := &asset{bytes: bytes, info: info}
	return a, nil
}

var _localesAssetsEsJson = []byte("\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\xff\xaa\xe6\x52\x50\x50\x4a\xc9\x2f\xc9\xc8\xcc\x4b\x57\xb2\x52\x50\x3a\xb4\x30\x24\x55\x21\x35\x2f\x3d\xf1\xf0\xc6\xc3\x2b\x15\x15\x52\xf3\x14\x8a\x52\x13\x73\x32\x53\x12\x53\x14\xf2\xf2\x15\x32\x12\xd3\xf3\x15\xf2\x12\x53\x12\x15\xac\x02\x94\xb8\x6a\xb9\x00\x01\x00\x00\xff\xff\xe5\x85\x54\x9c\x3e\x00\x00\x00")

func localesAssetsEsJsonBytes() ([]byte, error) {
	return bindataRead(
		_localesAssetsEsJson,
		"locales/assets/es.json",
	)
}

func localesAssetsEsJson() (*asset, error) {
	bytes, err := localesAssetsEsJsonBytes()
	if err != nil {
		return nil, err
	}

	info := bindataFileInfo{name: "locales/assets/es.json", size: 62, mode: os.FileMode(420), modTime: time.Unix(1651262545, 0)}
	a := &asset{bytes: bytes, info: info}
	return a, nil
}

// Asset loads and returns the asset for the given name.
// It returns an error if the asset could not be found or
// could not be loaded.
func Asset(name string) ([]byte, error) {
	cannonicalName := strings.Replace(name, "\\", "/", -1)
	if f, ok := _bindata[cannonicalName]; ok {
		a, err := f()
		if err != nil {
			return nil, fmt.Errorf("Asset %s can't read by error: %v", name, err)
		}
		return a.bytes, nil
	}
	return nil, fmt.Errorf("Asset %s not found", name)
}

// MustAsset is like Asset but panics when Asset would return an error.
// It simplifies safe initialization of global variables.
func MustAsset(name string) []byte {
	a, err := Asset(name)
	if err != nil {
		panic("asset: Asset(" + name + "): " + err.Error())
	}

	return a
}

// AssetInfo loads and returns the asset info for the given name.
// It returns an error if the asset could not be found or
// could not be loaded.
func AssetInfo(name string) (os.FileInfo, error) {
	cannonicalName := strings.Replace(name, "\\", "/", -1)
	if f, ok := _bindata[cannonicalName]; ok {
		a, err := f()
		if err != nil {
			return nil, fmt.Errorf("AssetInfo %s can't read by error: %v", name, err)
		}
		return a.info, nil
	}
	return nil, fmt.Errorf("AssetInfo %s not found", name)
}

// AssetNames returns the names of the assets.
func AssetNames() []string {
	names := make([]string, 0, len(_bindata))
	for name := range _bindata {
		names = append(names, name)
	}
	return names
}

// _bindata is a table, holding each asset generator, mapped to its name.
var _bindata = map[string]func() (*asset, error){
	"locales/assets/en.json": localesAssetsEnJson,
	"locales/assets/es.json": localesAssetsEsJson,
}

// AssetDir returns the file names below a certain
// directory embedded in the file by go-bindata.
// For example if you run go-bindata on data/... and data contains the
// following hierarchy:
//     data/
//       foo.txt
//       img/
//         a.png
//         b.png
// then AssetDir("data") would return []string{"foo.txt", "img"}
// AssetDir("data/img") would return []string{"a.png", "b.png"}
// AssetDir("foo.txt") and AssetDir("notexist") would return an error
// AssetDir("") will return []string{"data"}.
func AssetDir(name string) ([]string, error) {
	node := _bintree
	if len(name) != 0 {
		cannonicalName := strings.Replace(name, "\\", "/", -1)
		pathList := strings.Split(cannonicalName, "/")
		for _, p := range pathList {
			node = node.Children[p]
			if node == nil {
				return nil, fmt.Errorf("Asset %s not found", name)
			}
		}
	}
	if node.Func != nil {
		return nil, fmt.Errorf("Asset %s not found", name)
	}
	rv := make([]string, 0, len(node.Children))
	for childName := range node.Children {
		rv = append(rv, childName)
	}
	return rv, nil
}

type bintree struct {
	Func     func() (*asset, error)
	Children map[string]*bintree
}

var _bintree = &bintree{nil, map[string]*bintree{
	"locales": &bintree{nil, map[string]*bintree{
		"assets": &bintree{nil, map[string]*bintree{
			"en.json": &bintree{localesAssetsEnJson, map[string]*bintree{}},
			"es.json": &bintree{localesAssetsEsJson, map[string]*bintree{}},
		}},
	}},
}}

// RestoreAsset restores an asset under the given directory
func RestoreAsset(dir, name string) error {
	data, err := Asset(name)
	if err != nil {
		return err
	}
	info, err := AssetInfo(name)
	if err != nil {
		return err
	}
	err = os.MkdirAll(_filePath(dir, filepath.Dir(name)), os.FileMode(0755))
	if err != nil {
		return err
	}
	err = ioutil.WriteFile(_filePath(dir, name), data, info.Mode())
	if err != nil {
		return err
	}
	err = os.Chtimes(_filePath(dir, name), info.ModTime(), info.ModTime())
	if err != nil {
		return err
	}
	return nil
}

// RestoreAssets restores an asset under the given directory recursively
func RestoreAssets(dir, name string) error {
	children, err := AssetDir(name)
	// File
	if err != nil {
		return RestoreAsset(dir, name)
	}
	// Dir
	for _, child := range children {
		err = RestoreAssets(dir, filepath.Join(name, child))
		if err != nil {
			return err
		}
	}
	return nil
}

func _filePath(dir, name string) string {
	cannonicalName := strings.Replace(name, "\\", "/", -1)
	return filepath.Join(append([]string{dir}, strings.Split(cannonicalName, "/")...)...)
}

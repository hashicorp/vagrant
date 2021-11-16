package core

import (
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

const VagrantCloudUrl = "http://app.vagrantup.com"

func downloadBox(url string, destination string) (err error) {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	out, err := os.Create(destination)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	return
}

func constructMetadataUrl(username, boxname string) string {
	url := VagrantCloudUrl + "/" + username + "/boxes/" + boxname + ".json"
	return url
}

func addBox(name, provider string, basis *Basis) (box *Box, err error) {
	// Assume the name is of for <user>/<box>
	s := strings.Split(name, "/")
	metadataUrl := constructMetadataUrl(s[0], s[1])

	// Download the metadata
	resp, err := http.Get(metadataUrl)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	raw, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	metadata, err := LoadBoxMetadata(raw)
	if err != nil {
		return nil, err
	}
	versions, _ := metadata.ListVersions(&BoxVersionProvider{Name: provider})
	// latest version is first
	version, _ := metadata.Version(versions[0], &BoxVersionProvider{Name: provider})
	providerMeta, err := version.Provider(provider)
	downloadUrl := providerMeta.Url

	boxTempName := s[0] + "-" + s[1] + "-" + strconv.FormatInt(time.Now().Unix(), 10) + ".box"
	boxDownloadPath := filepath.Join(basis.dir.TempDir().String(), boxTempName)

	// Download the box
	err = downloadBox(downloadUrl, boxDownloadPath)
	if err != nil {
		return nil, err
	}
	// Delete the downloaded file when done
	defer os.RemoveAll(boxDownloadPath)

	// Add the box to the box collection
	boxes, _ := basis.Boxes()
	returnBox, err := boxes.Add(boxDownloadPath, name, version.Version, metadataUrl, false, provider)
	if err != nil {
		return nil, err
	}
	returnBox.(*Box).Save()
	return returnBox.(*Box), nil
}

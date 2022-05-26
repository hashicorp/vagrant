package downloader

import (
	"io/ioutil"
	"net/http"
	"os"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
)

type Downloader struct {
	config DownloaderConfig
}

type DownloaderConfig struct {
	Src     string
	Dest    string
	Headers http.Header
}

// Config implements Configurable
func (d *Downloader) Config() (interface{}, error) {
	return &d.config, nil
}

func (d *Downloader) DownloadFunc() interface{} {
	return d.Download
}

func (d *Downloader) Download() (err error) {
	client := &http.Client{}
	req, err := http.NewRequest("GET", d.config.Src, nil)
	req.Header = d.config.Headers
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	err = os.WriteFile(d.config.Dest, data, 0644)
	return
}

var (
	_ component.Downloader   = (*Downloader)(nil)
	_ component.Configurable = (*Downloader)(nil)
)

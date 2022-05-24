package downloader

import (
	"net/http"
	"time"

	"github.com/hashicorp/go-getter"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
)

type Downloader struct {
	config DownloaderConfig
}

type DownloaderConfig struct {
	src     string
	dest    string
	headers http.Header
}

func (d *Downloader) DownloadFunc() interface{} {
	return d.Download
}

func (d *Downloader) Download() (err error) {
	err = getter.Get(d.config.dest, d.config.src, getter.WithGetters(
		map[string]getter.Getter{
			"http": &getter.HttpGetter{
				Netrc:            false,
				HeadFirstTimeout: 10 * time.Second,
				Header:           d.config.headers,
				ReadTimeout:      30 * time.Second,
				MaxBytes:         500000000, // 500 MB
			},
			"file": &getter.FileGetter{
				Copy: true,
			},
		},
	))
	return
}

var (
	_ component.Downloader = (*Downloader)(nil)
)

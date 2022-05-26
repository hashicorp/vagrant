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
	httpGetter := &getter.HttpGetter{
		Netrc:            false,
		HeadFirstTimeout: 10 * time.Second,
		Header:           d.config.Headers,
		ReadTimeout:      30 * time.Second,
		MaxBytes:         500000000, // 500 MB
	}
	err = getter.Get(d.config.Dest, d.config.Src, getter.WithGetters(
		map[string]getter.Getter{
			"https": httpGetter,
			"http":  httpGetter,
		},
	))
	return
}

var (
	_ component.Downloader   = (*Downloader)(nil)
	_ component.Configurable = (*Downloader)(nil)
)

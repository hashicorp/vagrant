// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package downloader

import (
	"bytes"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/hashicorp/go-retryablehttp"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
)

// Type is an enum of all the available http methods
type HTTPMethod int64

const (
	GET HTTPMethod = iota
	DELETE
	HEAD
	POST
	PUT
)

type Downloader struct {
	config DownloaderConfig
}

type DownloaderConfig struct {
	Dest           string
	Headers        http.Header
	Method         HTTPMethod
	RetryCount     int
	RequestBody    []byte
	Src            string
	UrlQueryParams map[string]string
}

func (d *Downloader) InitFunc() any {
	return d.Init
}

func (d *Downloader) Init(in *component.ConfigData) (*component.ConfigData, error) {
	return in, nil
}

func (d *Downloader) StructFunc() any {
	return d.Struct
}

func (d *Downloader) MergeFunc() any {
	return d.Merge
}

func (d *Downloader) FinalizeFunc() any {
	return d.Finalize
}

func (d *Downloader) Struct() *DownloaderConfig {
	return &DownloaderConfig{}
}

func (d *Downloader) Merge(val *component.ConfigMerge) *component.ConfigData {
	return val.Base
}

func (d *Downloader) Finalize(val *component.ConfigData) *component.ConfigData {
	return val
}

func (d *Downloader) Register() (*component.ConfigRegistration, error) {
	return &component.ConfigRegistration{
		Identifier: "downloader",
	}, nil
}

func (d *Downloader) DownloadFunc() interface{} {
	return d.Download
}

func (d *Downloader) Download() (err error) {
	client := retryablehttp.NewClient()
	client.RetryMax = d.config.RetryCount
	var req *retryablehttp.Request

	// Create request with request body if one is provided
	if d.config.RequestBody != nil {
		req, err = retryablehttp.NewRequest(
			d.config.Method.String(), d.config.Src, bytes.NewBuffer(d.config.RequestBody),
		)
		if err != nil {
			return err
		}
	} else {
		// If no request body is provided then create an empty request
		req, err = retryablehttp.NewRequest(
			d.config.Method.String(), d.config.Src, nil,
		)
	}

	// Add query params if provided
	if d.config.UrlQueryParams != nil {
		q := req.URL.Query()
		for k, v := range d.config.UrlQueryParams {
			q.Add(k, v)
		}
		req.URL.RawQuery = q.Encode()
	}

	// Set headers
	req.Header = d.config.Headers
	// Add headers to redirects
	client.HTTPClient.CheckRedirect = func(req *http.Request, via []*http.Request) error {
		for key, val := range via[0].Header {
			req.Header[key] = val
		}
		return err
	}

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
	_ component.Downloader = (*Downloader)(nil)
	_ component.Config     = (*Downloader)(nil)
)

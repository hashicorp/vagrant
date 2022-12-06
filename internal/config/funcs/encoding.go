package funcs

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"fmt"
	"log"
	"net/url"
	"unicode/utf8"

	"github.com/zclconf/go-cty/cty"
	"github.com/zclconf/go-cty/cty/function"
)

func Encoding() map[string]function.Function {
	return map[string]function.Function{
		"base64decode": Base64DecodeFunc,
		"base64encode": Base64EncodeFunc,
		"base64gzip":   Base64GzipFunc,
		"urlencode":    URLEncodeFunc,
	}
}

// Base64DecodeFunc constructs a function that decodes a string containing a base64 sequence.
var Base64DecodeFunc = function.New(&function.Spec{
	Params: []function.Parameter{
		{
			Name: "str",
			Type: cty.String,
		},
	},
	Type: function.StaticReturnType(cty.String),
	Impl: func(args []cty.Value, retType cty.Type) (cty.Value, error) {
		s := args[0].AsString()
		sDec, err := base64.StdEncoding.DecodeString(s)
		if err != nil {
			return cty.UnknownVal(cty.String), fmt.Errorf("failed to decode base64 data '%s'", s)
		}
		if !utf8.Valid([]byte(sDec)) {
			log.Printf("[DEBUG] the result of decoding the provided string is not valid UTF-8: %s", sDec)
			return cty.UnknownVal(cty.String), fmt.Errorf("the result of decoding the provided string is not valid UTF-8")
		}
		return cty.StringVal(string(sDec)), nil
	},
})

// Base64EncodeFunc constructs a function that encodes a string to a base64 sequence.
var Base64EncodeFunc = function.New(&function.Spec{
	Params: []function.Parameter{
		{
			Name: "str",
			Type: cty.String,
		},
	},
	Type: function.StaticReturnType(cty.String),
	Impl: func(args []cty.Value, retType cty.Type) (cty.Value, error) {
		return cty.StringVal(base64.StdEncoding.EncodeToString([]byte(args[0].AsString()))), nil
	},
})

// Base64GzipFunc constructs a function that compresses a string with gzip and then encodes the result in
// Base64 encoding.
var Base64GzipFunc = function.New(&function.Spec{
	Params: []function.Parameter{
		{
			Name: "str",
			Type: cty.String,
		},
	},
	Type: function.StaticReturnType(cty.String),
	Impl: func(args []cty.Value, retType cty.Type) (cty.Value, error) {
		s := args[0].AsString()

		var b bytes.Buffer
		gz := gzip.NewWriter(&b)
		if _, err := gz.Write([]byte(s)); err != nil {
			return cty.UnknownVal(cty.String), fmt.Errorf("failed to write gzip raw data: '%s'", s)
		}
		if err := gz.Flush(); err != nil {
			return cty.UnknownVal(cty.String), fmt.Errorf("failed to flush gzip writer: '%s'", s)
		}
		if err := gz.Close(); err != nil {
			return cty.UnknownVal(cty.String), fmt.Errorf("failed to close gzip writer: '%s'", s)
		}
		return cty.StringVal(base64.StdEncoding.EncodeToString(b.Bytes())), nil
	},
})

// URLEncodeFunc constructs a function that applies URL encoding to a given string.
var URLEncodeFunc = function.New(&function.Spec{
	Params: []function.Parameter{
		{
			Name: "str",
			Type: cty.String,
		},
	},
	Type: function.StaticReturnType(cty.String),
	Impl: func(args []cty.Value, retType cty.Type) (cty.Value, error) {
		return cty.StringVal(url.QueryEscape(args[0].AsString())), nil
	},
})

// Base64Decode decodes a string containing a base64 sequence.
//
// Vagrant uses the "standard" Base64 alphabet as defined in RFC 4648 section 4.
//
// Strings in the Vagrant language are sequences of unicode characters rather
// than bytes, so this function will also interpret the resulting bytes as
// UTF-8. If the bytes after Base64 decoding are _not_ valid UTF-8, this function
// produces an error.
func Base64Decode(str cty.Value) (cty.Value, error) {
	return Base64DecodeFunc.Call([]cty.Value{str})
}

// Base64Encode applies Base64 encoding to a string.
//
// Vagrant uses the "standard" Base64 alphabet as defined in RFC 4648 section 4.
//
// Strings in the Vagrant language are sequences of unicode characters rather
// than bytes, so this function will first encode the characters from the string
// as UTF-8, and then apply Base64 encoding to the result.
func Base64Encode(str cty.Value) (cty.Value, error) {
	return Base64EncodeFunc.Call([]cty.Value{str})
}

// Base64Gzip compresses a string with gzip and then encodes the result in
// Base64 encoding.
//
// Vagrant uses the "standard" Base64 alphabet as defined in RFC 4648 section 4.
//
// Strings in the Vagrant language are sequences of unicode characters rather
// than bytes, so this function will first encode the characters from the string
// as UTF-8, then apply gzip compression, and then finally apply Base64 encoding.
func Base64Gzip(str cty.Value) (cty.Value, error) {
	return Base64GzipFunc.Call([]cty.Value{str})
}

// URLEncode applies URL encoding to a given string.
//
// This function identifies characters in the given string that would have a
// special meaning when included as a query string argument in a URL and
// escapes them using RFC 3986 "percent encoding".
//
// If the given string contains non-ASCII characters, these are first encoded as
// UTF-8 and then percent encoding is applied separately to each UTF-8 byte.
func URLEncode(str cty.Value) (cty.Value, error) {
	return URLEncodeFunc.Call([]cty.Value{str})
}

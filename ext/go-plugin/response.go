package main

import (
	"C"
	"encoding/json"
	"errors"
	"fmt"
)

type Response struct {
	Error  error       `json:"error"`
	Result interface{} `json:"result"`
}

// Serialize the response into a JSON C string
func (r *Response) Dump() *C.char {
	tmp := map[string]interface{}{}
	if r.Error != nil {
		tmp["error"] = r.Error.Error()
	} else {
		tmp["error"] = nil
	}
	tmp["result"] = r.Result
	result, err := json.Marshal(tmp)
	if err != nil {
		return to_cs(fmt.Sprintf(`{"error": "failed to encode response - %s"}`, err))
	}
	return to_cs(string(result[:]))
}

// Load a new response from a JSON C string
func LoadResponse(s *C.char) (r *Response, err error) {
	tmp := map[string]interface{}{}
	st := []byte(to_gs(s))
	r = &Response{}
	err = json.Unmarshal(st, &tmp)
	if tmp["error"] != nil {
		e, ok := tmp["error"].(string)
		if !ok {
			err = errors.New(
				fmt.Sprintf("cannot load error content - %s", tmp["error"]))
			return
		}
		r.Error = errors.New(e)
	}
	r.Result = tmp["result"]
	return
}

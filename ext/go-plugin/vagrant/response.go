package vagrant

import (
	"encoding/json"
	"fmt"
)

type Response struct {
	Error  error       `json:"error"`
	Result interface{} `json:"result"`
}

// Serialize the response into a JSON string
func (r Response) Dump() string {
	result, err := json.Marshal(r)
	if err != nil {
		return fmt.Sprintf(`{"error": "failed to encode response - %s"}`, err)
	}
	return string(result[:])
}

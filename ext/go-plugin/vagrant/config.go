package vagrant

import (
	"context"
)

type Config interface {
	ConfigAttributes() (attrs []string, err error)
	ConfigLoad(ctx context.Context, data map[string]interface{}) (loaddata map[string]interface{}, err error)
	ConfigValidate(ctx context.Context, data map[string]interface{}, m *Machine) (errors []string, err error)
	ConfigFinalize(ctx context.Context, data map[string]interface{}) (finaldata map[string]interface{}, err error)
}

type NoConfig struct{}

func (c *NoConfig) ConfigAttributes() (a []string, e error) { return }
func (c *NoConfig) ConfigLoad(context.Context, map[string]interface{}) (d map[string]interface{}, e error) {
	return
}
func (c *NoConfig) ConfigValidate(context.Context, map[string]interface{}, *Machine) (es []string, e error) {
	return
}
func (c *NoConfig) ConfigFinalize(context.Context, map[string]interface{}) (f map[string]interface{}, e error) {
	return
}

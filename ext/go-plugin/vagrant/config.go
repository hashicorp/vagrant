package vagrant

type Config interface {
	ConfigAttributes() (attrs []string, err error)
	ConfigLoad(data map[string]interface{}) (loaddata map[string]interface{}, err error)
	ConfigValidate(data map[string]interface{}, m *Machine) (errors []string, err error)
	ConfigFinalize(data map[string]interface{}) (finaldata map[string]interface{}, err error)
}

type NoConfig struct{}

func (c *NoConfig) ConfigAttributes() (a []string, e error)                                   { return }
func (c *NoConfig) ConfigLoad(map[string]interface{}) (d map[string]interface{}, e error)     { return }
func (c *NoConfig) ConfigValidate(map[string]interface{}, *Machine) (es []string, e error)    { return }
func (c *NoConfig) ConfigFinalize(map[string]interface{}) (f map[string]interface{}, e error) { return }

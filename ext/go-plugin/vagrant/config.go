package vagrant

type Config interface {
	ConfigAttributes() (attrs []string, err error)
	ConfigLoad(data map[string]interface{}) (loaddata map[string]interface{}, err error)
	ConfigValidate(data map[string]interface{}, m *Machine) (errors []string, err error)
	ConfigFinalize(data map[string]interface{}) (finaldata map[string]interface{}, err error)
}

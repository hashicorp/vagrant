package state

import (
	"fmt"
	"reflect"
	"time"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/mitchellh/mapstructure"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// Custom decoder
type Decoder struct {
	config *mapstructure.DecoderConfig
	*mapstructure.Decoder
}

// Create a custom decoder that can handle model
// encoding/decoding to/from protobuf messages
func NewDecoder(config *mapstructure.DecoderConfig) (*Decoder, error) {
	intD, err := mapstructure.NewDecoder(config)
	if err != nil {
		return nil, err
	}

	return &Decoder{
		Decoder: intD,
		config:  config,
	}, nil
}

// Decodes a value with special handling on struct values. If
// the input value is unset it will not be applied to the
// destination.
func (d *Decoder) SoftDecode(input interface{}) error {
	v := reflect.Indirect(reflect.ValueOf(input))
	t := v.Type()
	if v.Kind() != reflect.Struct {
		return d.Decode(input)
	}

	newFields := []reflect.StructField{}

	for i := 0; i < t.NumField(); i++ {
		structField := t.Field(i)
		if !structField.IsExported() {
			continue
		}

		indirectVal := reflect.Indirect(v.FieldByName(structField.Name))
		if !indirectVal.IsValid() {
			continue
		}
		val := indirectVal.Interface()
		fieldType := structField.Type

		if fieldType.Kind() == reflect.Ptr {
			fieldType = fieldType.Elem()
		}
		defaultZero := reflect.Zero(fieldType).Interface()
		if reflect.DeepEqual(val, defaultZero) {
			continue
		}

		newField := reflect.StructField{
			Name:    structField.Name,
			PkgPath: structField.PkgPath,
			Tag:     structField.Tag,
			Type:    structField.Type,
		}

		newFields = append(newFields, newField)
	}

	newStruct := reflect.StructOf(newFields)
	newInput := reflect.New(newStruct).Elem()

	err := mapstructure.Decode(input, newInput.Addr().Interface())
	if err != nil {
		// This should not happen, but if it does, we need to bail
		panic("failed to generate decode copy: " + err.Error())
	}

	return d.Decode(newInput.Interface())

}

// Creates a decoder with all our custom hooks. This decoder can
// be used for converting models to protobuf messages and converting
// protobuf messages to models.
func (s *State) decoder(output interface{}) *Decoder {
	config := mapstructure.DecoderConfig{
		DecodeHook: mapstructure.ComposeDecodeHookFunc(
			projectToProtoRefHookFunc,
			projectToProtoHookFunc,
			s.projectFromProtoHookFunc,
			s.projectFromProtoRefHookFunc,
			basisToProtoHookFunc,
			basisToProtoRefHookFunc,
			s.basisFromProtoHookFunc,
			s.basisFromProtoRefHookFunc,
			targetToProtoHookFunc,
			targetToProtoRefHookFunc,
			s.targetFromProtoHookFunc,
			s.targetFromProtoRefHookFunc,
			vagrantfileToProtoHookFunc,
			s.vagrantfileFromProtoHookFunc,
			runnerToProtoHookFunc,
			s.runnerFromProtoHookFunc,
			protobufToProtoValueHookFunc,
			protobufToProtoRawHookFunc,
			boxToProtoHookFunc,
			boxToProtoRefHookFunc,
			s.boxFromProtoHookFunc,
			s.boxFromProtoRefHookFunc,
			timeToProtoHookFunc,
			timeFromProtoHookFunc,
			s.scopeFromProtoHookFunc,
			scopeToProtoHookFunc,
			protoValueToProtoHookFunc,
			protoRawToProtoHookFunc,
			s.componentFromProtoHookFunc,
			componentToProtoHookFunc,
			stringPtrToPathProtoHookFunc,
			pathProtoToStringPtrHookFunc,
		),
		Result: output,
	}

	d, err := NewDecoder(&config)
	if err != nil {
		panic("failed to create mapstructure decoder: " + err.Error())
	}

	return d
}

// Decodes input into output structure using custom decoder
func (s *State) decode(input, output interface{}) error {
	return s.decoder(output).Decode(input)
}

func (s *State) softDecode(input, output interface{}) error {
	return s.decoder(output).SoftDecode(input)
}

// Creates a decoder with some of our custom hooks. This can be used
// for converting models to protobuf messages but cannot be used for
// converting protobuf messages to models.
func decoder(output interface{}) *Decoder {
	config := mapstructure.DecoderConfig{
		DecodeHook: mapstructure.ComposeDecodeHookFunc(
			projectToProtoRefHookFunc,
			projectToProtoHookFunc,
			basisToProtoHookFunc,
			basisToProtoRefHookFunc,
			targetToProtoHookFunc,
			targetToProtoRefHookFunc,
			vagrantfileToProtoHookFunc,
			runnerToProtoHookFunc,
			protobufToProtoValueHookFunc,
			protobufToProtoRawHookFunc,
			boxToProtoHookFunc,
			boxToProtoRefHookFunc,
			timeToProtoHookFunc,
			timeFromProtoHookFunc,
			scopeToProtoHookFunc,
			protoValueToProtoHookFunc,
			protoRawToProtoHookFunc,
			componentToProtoHookFunc,
			stringPtrToPathProtoHookFunc,
			pathProtoToStringPtrHookFunc,
		),
		Result: output,
	}

	d, err := NewDecoder(&config)
	if err != nil {
		panic("failed to create mapstructure decoder: " + err.Error())
	}

	return d
}

// Decodes input into output structure using custom decoder
func decode(input, output interface{}) error {
	return decoder(output).Decode(input)
}

func softDecode(input, output interface{}) error {
	return decoder(output).SoftDecode(input)
}

// Everything below here are converters
func projectToProtoRefHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*Project)(nil)) ||
		to != reflect.TypeOf((*vagrant_plugin_sdk.Ref_Project)(nil)) {
		return data, nil
	}

	p, ok := data.(*Project)
	if !ok {
		return nil, fmt.Errorf("cannot serialize project ref, wrong type (%T)", data)
	}

	return p.ToProtoRef(), nil
}

func projectToProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*Project)(nil)) ||
		to != reflect.TypeOf((*vagrant_server.Project)(nil)) {
		return data, nil
	}

	p, ok := data.(*Project)
	if !ok {
		return nil, fmt.Errorf("cannot serialize project, wrong type (%T)", data)
	}

	return p.ToProto(), nil
}

func (s *State) projectFromProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_server.Project)(nil)) ||
		to != reflect.TypeOf((*Project)(nil)) {
		return data, nil
	}

	p, ok := data.(*vagrant_server.Project)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize project, wrong type (%T)", data)
	}

	return s.ProjectFromProto(p)
}

func (s *State) projectFromProtoRefHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_plugin_sdk.Ref_Project)(nil)) ||
		to != reflect.TypeOf((*Project)(nil)) {
		return data, nil
	}

	p, ok := data.(*vagrant_plugin_sdk.Ref_Project)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize project ref, wrong type (%T)", data)
	}

	return s.ProjectFromProtoRef(p)
}

func basisToProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*Basis)(nil)) ||
		to != reflect.TypeOf((*vagrant_server.Basis)(nil)) {
		return data, nil
	}

	b, ok := data.(*Basis)
	if !ok {
		return nil, fmt.Errorf("cannot serialize basis, wrong type (%T)", data)
	}

	return b.ToProto(), nil
}

func basisToProtoRefHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*Basis)(nil)) ||
		to != reflect.TypeOf((*vagrant_plugin_sdk.Ref_Basis)(nil)) {
		return data, nil
	}

	b, ok := data.(*Basis)
	if !ok {
		return nil, fmt.Errorf("cannot serialize basis ref, wrong type (%T)", data)
	}

	return b.ToProtoRef(), nil
}

func (s *State) basisFromProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_server.Basis)(nil)) ||
		to != reflect.TypeOf((*Basis)(nil)) {
		return data, nil
	}

	b, ok := data.(*vagrant_server.Basis)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize basis, wrong type (%T)", data)
	}

	return s.BasisFromProto(b)
}

func (s *State) basisFromProtoRefHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_plugin_sdk.Ref_Basis)(nil)) ||
		to != reflect.TypeOf((*Basis)(nil)) {
		return data, nil
	}

	b, ok := data.(*vagrant_plugin_sdk.Ref_Basis)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize basis ref, wrong type (%T)", data)
	}

	return s.BasisFromProtoRef(b)
}

func targetToProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*Target)(nil)) ||
		to != reflect.TypeOf((*vagrant_server.Target)(nil)) {
		return data, nil
	}

	t, ok := data.(*Target)
	if !ok {
		return nil, fmt.Errorf("cannot serialize target, wrong type (%T)", data)
	}

	return t.ToProto(), nil
}

func targetToProtoRefHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*Target)(nil)) ||
		to != reflect.TypeOf((*vagrant_plugin_sdk.Ref_Target)(nil)) {
		return data, nil
	}

	t, ok := data.(*Target)
	if !ok {
		return nil, fmt.Errorf("cannot serialize target ref, wrong type (%T)", data)
	}

	return t.ToProtoRef(), nil
}

func (s *State) targetFromProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_server.Target)(nil)) ||
		to != reflect.TypeOf((*Target)(nil)) {
		return data, nil
	}

	t, ok := data.(*vagrant_server.Target)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize target, wrong type (%T)", data)
	}

	return s.TargetFromProto(t)
}

func (s *State) targetFromProtoRefHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_plugin_sdk.Ref_Target)(nil)) ||
		to != reflect.TypeOf((*Target)(nil)) {
		return data, nil
	}

	t, ok := data.(*vagrant_plugin_sdk.Ref_Target)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize target ref, wrong type (%T)", data)
	}

	return s.TargetFromProtoRef(t)
}

func vagrantfileToProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*Vagrantfile)(nil)) ||
		to != reflect.TypeOf((*vagrant_server.Vagrantfile)(nil)) {
		return data, nil
	}

	v, ok := data.(*Vagrantfile)
	if !ok {
		return nil, fmt.Errorf("cannot serialize vagrantfile, wrong type (%T)", data)
	}

	return v.ToProto(), nil
}

func (s *State) vagrantfileFromProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_server.Vagrantfile)(nil)) ||
		to != reflect.TypeOf((*Vagrantfile)(nil)) {
		return data, nil
	}

	v, ok := data.(*vagrant_server.Vagrantfile)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize vagrantfile, wrong type (%T)", data)
	}

	return s.VagrantfileFromProto(v), nil
}

func runnerToProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*Runner)(nil)) ||
		to != reflect.TypeOf((*vagrant_server.Runner)(nil)) {
		return data, nil
	}

	r, ok := data.(*Runner)
	if !ok {
		return nil, fmt.Errorf("cannot serialize runner, wrong type (%T)", data)
	}

	return r.ToProto(), nil
}

func (s *State) runnerFromProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_server.Runner)(nil)) ||
		to != reflect.TypeOf((*Runner)(nil)) {
		return data, nil
	}

	r, ok := data.(*vagrant_server.Runner)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize runner, wrong type (%T)", data)
	}

	return s.RunnerFromProto(r)
}

func protobufToProtoValueHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if to != reflect.TypeOf((*ProtoValue)(nil)) {
		return data, nil
	}

	p, ok := data.(proto.Message)
	if ok {
		return &ProtoValue{Message: p}, nil
	}

	switch v := data.(type) {
	case *vagrant_server.Job_Init:
		return &ProtoValue{Message: v.Init}, nil
	case *vagrant_server.Job_Command:
		return &ProtoValue{Message: v.Command}, nil
	case *vagrant_server.Job_Noop_:
		return &ProtoValue{Message: v.Noop}, nil
	}

	return data, nil
}

func protobufToProtoRawHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if !from.Implements(reflect.TypeOf((*proto.Message)(nil)).Elem()) ||
		to != reflect.TypeOf((*ProtoRaw)(nil)) {
		return data, nil
	}

	p, ok := data.(proto.Message)
	if !ok {
		return nil, fmt.Errorf("cannot wrap into protovalue, wrong type (%T)", data)
	}

	return &ProtoRaw{Message: p}, nil
}

func boxToProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*Box)(nil)) ||
		to != reflect.TypeOf((*vagrant_server.Box)(nil)) {
		return data, nil
	}

	b, ok := data.(*Box)
	if !ok {
		return nil, fmt.Errorf("cannot serialize box, wrong type (%T)", data)
	}

	return b.ToProto(), nil
}

func boxToProtoRefHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*Box)(nil)) ||
		to != reflect.TypeOf((*vagrant_plugin_sdk.Ref_Box)(nil)) {
		return data, nil
	}

	b, ok := data.(*Box)
	if !ok {
		return nil, fmt.Errorf("cannot serialize box ref, wrong type (%T)", data)
	}

	return b.ToProtoRef(), nil
}

func (s *State) boxFromProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_server.Box)(nil)) ||
		to != reflect.TypeOf((*Box)(nil)) {
		return data, nil
	}

	b, ok := data.(*vagrant_server.Box)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize box, wrong type (%T)", data)
	}

	return s.BoxFromProto(b)
}

func (s *State) boxFromProtoRefHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_plugin_sdk.Ref_Box)(nil)) ||
		to != reflect.TypeOf((*Box)(nil)) {
		return data, nil
	}

	b, ok := data.(*vagrant_plugin_sdk.Ref_Box)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize box ref, wrong type (%T)", data)
	}

	return s.BoxFromProtoRef(b)
}

func timeToProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*time.Time)(nil)) ||
		to != reflect.TypeOf((*timestamppb.Timestamp)(nil)) {
		return data, nil
	}

	t, ok := data.(*time.Time)
	if !ok {
		return nil, fmt.Errorf("cannot serialize time, wrong type (%T)", data)
	}

	return timestamppb.New(*t), nil
}

func timeFromProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*timestamppb.Timestamp)(nil)) ||
		to != reflect.TypeOf((*time.Time)(nil)) {
		return data, nil
	}

	t, ok := data.(*timestamppb.Timestamp)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize time, wrong type (%T)", data)
	}

	at := t.AsTime()
	return &at, nil
}

func protoValueToProtoHookFunc(
	from, to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*ProtoValue)(nil)) {
		return data, nil
	}

	p, ok := data.(*ProtoValue)
	if !ok {
		return nil, fmt.Errorf("invalid proto value (%s -> %s)", from, to)
	}

	if p.Message == nil {
		return nil, fmt.Errorf("proto value contents is nil (destination: %s)", to)
	}

	if reflect.ValueOf(p.Message).Type().AssignableTo(to) {
		return p.Message, nil
	}

	switch v := p.Message.(type) {
	// Start with Job oneof types
	case *vagrant_server.Job_InitOp:
		if reflect.TypeOf((*vagrant_server.Job_Init)(nil)).AssignableTo(to) {
			return &vagrant_server.Job_Init{Init: v}, nil
		}
	case *vagrant_server.Job_CommandOp:
		if reflect.TypeOf((*vagrant_server.Job_Command)(nil)).AssignableTo(to) {
			return &vagrant_server.Job_Command{Command: v}, nil
		}
	case *vagrant_server.Job_Noop:
		if reflect.TypeOf((*vagrant_server.Job_Noop_)(nil)).AssignableTo(to) {
			return &vagrant_server.Job_Noop_{Noop: v}, nil
		}
	}

	return data, nil
}

func protoRawToProtoHookFunc(
	from, to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*ProtoRaw)(nil)) {
		return data, nil
	}

	p, ok := data.(*ProtoRaw)
	if !ok {
		return nil, fmt.Errorf("invalid proto value (%s -> %s)", from, to)
	}

	if !reflect.ValueOf(p.Message).Type().AssignableTo(to) {
		return data, nil
	}

	return p.Message, nil
}

func (s *State) scopeFromProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if (from != reflect.TypeOf((*vagrant_server.Job_Basis)(nil)) &&
		from != reflect.TypeOf((*vagrant_server.Job_Project)(nil)) &&
		from != reflect.TypeOf((*vagrant_server.Job_Target)(nil)) &&
		from != reflect.TypeOf((*vagrant_server.ConfigVar_Basis)(nil)) &&
		from != reflect.TypeOf((*vagrant_server.ConfigVar_Project)(nil)) &&
		from != reflect.TypeOf((*vagrant_server.ConfigVar_Target)(nil))) ||
		!to.Implements(reflect.TypeOf((*scope)(nil)).Elem()) {
		return data, nil
	}

	var result scope
	var err error

	switch v := data.(type) {
	case *vagrant_server.Job_Basis:
		result, err = s.BasisFromProtoRef(v.Basis)
	case *vagrant_server.ConfigVar_Basis:
		result, err = s.BasisFromProtoRef(v.Basis)
	case *vagrant_server.Job_Project:
		result, err = s.ProjectFromProtoRef(v.Project)
	case *vagrant_server.ConfigVar_Project:
		result, err = s.ProjectFromProtoRef(v.Project)
	case *vagrant_server.Job_Target:
		result, err = s.TargetFromProtoRef(v.Target)
	case *vagrant_server.ConfigVar_Target:
		result, err = s.TargetFromProtoRef(v.Target)
	default:
		err = fmt.Errorf("invalid job scope type (%T)", data)
	}

	if err != nil {
		return nil, err
	}

	return result, nil
}

func scopeToProtoHookFunc(
	from reflect.Type,
	to reflect.Type,
	data interface{},
) (interface{}, error) {
	if !from.Implements(reflect.TypeOf((*scope)(nil)).Elem()) {
		return data, nil
	}

	switch v := data.(type) {
	case *Basis:
		if reflect.TypeOf((*vagrant_server.Job_Basis)(nil)).AssignableTo(to) {
			return &vagrant_server.Job_Basis{Basis: v.ToProtoRef()}, nil
		}
		if reflect.TypeOf((*vagrant_server.ConfigVar_Basis)(nil)).AssignableTo(to) {
			return &vagrant_server.ConfigVar_Basis{Basis: v.ToProtoRef()}, nil
		}
	case *Project:
		if reflect.TypeOf((*vagrant_server.Job_Project)(nil)).AssignableTo(to) {
			return &vagrant_server.Job_Project{Project: v.ToProtoRef()}, nil
		}
		if reflect.TypeOf((*vagrant_server.ConfigVar_Project)(nil)).AssignableTo(to) {
			return &vagrant_server.ConfigVar_Project{Project: v.ToProtoRef()}, nil
		}
	case *Target:
		if reflect.TypeOf((*vagrant_server.Job_Target)(nil)).AssignableTo(to) {
			return &vagrant_server.Job_Target{Target: v.ToProtoRef()}, nil
		}
		if reflect.TypeOf((*vagrant_server.ConfigVar_Target)(nil)).AssignableTo(to) {
			return &vagrant_server.ConfigVar_Target{Target: v.ToProtoRef()}, nil
		}
	}

	return data, nil
}

func (s *State) componentFromProtoHookFunc(
	from, to reflect.Type,
	data interface{},

) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_server.Component)(nil)) ||
		to != reflect.TypeOf((*Component)(nil)) {
		return data, nil
	}

	c, ok := data.(*vagrant_server.Component)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize component, wrong type (%T)", data)
	}

	return s.ComponentFromProto(c)
}

func componentToProtoHookFunc(
	from, to reflect.Type,
	data interface{},

) (interface{}, error) {
	if from != reflect.TypeOf((*Component)(nil)) ||
		to != reflect.TypeOf((*vagrant_server.Component)(nil)) {
		return data, nil
	}

	c, ok := data.(*Component)
	if !ok {
		return nil, fmt.Errorf("cannot serialize component, wrong type (%T)", data)
	}

	return c.ToProto(), nil
}

func pathProtoToStringPtrHookFunc(
	from, to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*vagrant_plugin_sdk.Args_Path)(nil)) ||
		to != reflect.TypeOf((*string)(nil)) {
		return data, nil
	}

	p, ok := data.(*vagrant_plugin_sdk.Args_Path)
	if !ok {
		return nil, fmt.Errorf("cannot deserialize path, wrong type (%T)", data)
	}

	return &p.Path, nil
}

func stringPtrToPathProtoHookFunc(
	from, to reflect.Type,
	data interface{},
) (interface{}, error) {
	if from != reflect.TypeOf((*string)(nil)) ||
		to != reflect.TypeOf((*vagrant_plugin_sdk.Args_Path)(nil)) {
		return data, nil
	}

	s, ok := data.(*string)
	if !ok {
		return nil, fmt.Errorf("cannot serialize path, wrong type (%T)", data)
	}

	return &vagrant_plugin_sdk.Args_Path{Path: *s}, nil
}

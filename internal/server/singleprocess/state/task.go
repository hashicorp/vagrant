package state

import (
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

var taskOp = &genericOperation{
	Struct: (*vagrant_server.Task)(nil),
	Bucket: []byte("task"),
}

func init() {
	taskOp.register()
}

// TaskPut inserts or updates a task record.
func (s *State) TaskPut(update bool, t *vagrant_server.Task) error {
	return taskOp.Put(s, update, t)
}

// TaskGet gets a task by ref.
func (s *State) TaskGet(ref *vagrant_server.Ref_Operation) (*vagrant_server.Task, error) {
	result, err := taskOp.Get(s, ref)
	if err != nil {
		return nil, err
	}
	return result.(*vagrant_server.Task), nil
}

func (s *State) TaskList(
	ref interface{},
	opts ...ListOperationOption,
) (result []*vagrant_server.Task, err error) {
	raw, err := taskOp.List(s, buildListOperationsOptions(ref, opts...))
	if err != nil {
		return
	}

	result = make([]*vagrant_server.Task, len(raw))
	for i := 0; i < len(raw); i++ {
		result[i] = raw[i].(*vagrant_server.Task)
	}

	return
}

func (s *State) TaskLatest(
	ref interface{},
) (*vagrant_server.Task, error) {
	result, err := taskOp.Latest(s, ref)
	if result == nil || err != nil {
		return nil, err
	}

	return result.(*vagrant_server.Task), nil
}

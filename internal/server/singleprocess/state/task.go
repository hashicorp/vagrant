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
	// TODO(phinze): This Put operation will always fail because the Task
	// struct has neither a Basis, a Project, nor a Target set. This is ok for
	// now because nobody is using Task operations directly - Tasks seem to
	// enter state only from being nested in Jobs. At some point we'll need to
	// swing around and decide if we want to fix this wiring or if it's
	// unnecessary and okay to delete.
	//
	// If we do decide to fix it... the thing to sort out here will be how to
	// transform the basis, project, or target referenced by t.Scope into the
	// form expected by taskOp.Put().
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

package core

type closer interface {
	Closer(func() error)
}

package core

type closer interface {
	Closer(func() error)
}

type closes interface {
	Close() error
}

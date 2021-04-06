// +build windows

package execclient

import "os"

func registerSigwinch(chan os.Signal) {
	// NOTE(mitchellh): we should use Windows APIs to poll the window size
}

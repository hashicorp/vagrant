package none

import (
	"testing"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/communicator"
)

func TestCommIsCommunicator(t *testing.T) {
	// Force failure with explanation of why it's not valid
	var _ communicator.Communicator = new(Communicator)
}

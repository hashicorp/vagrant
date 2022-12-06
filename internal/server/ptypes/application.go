package ptypes

// import (
// 	"github.com/imdario/mergo"
// 	"github.com/mitchellh/go-testing-interface"
// 	"github.com/stretchr/testify/require"

// 	pb "github.com/hashicorp/vagrant/internal/server/gen"
// )

// // TestApplication returns a valid project for tests.
// func TestApplication(t testing.T, src *pb.Machine) *pb.Machine {
// 	t.Helper()

// 	if src == nil {
// 		src = &pb.Machine{}
// 	}

// 	require.NoError(t, mergo.Merge(src, &pb.Machine{
// 		Project: &pb.Ref_Project{
// 			Project: "test",
// 		},

// 		Name: "test",
// 	}))

// 	return src
// }

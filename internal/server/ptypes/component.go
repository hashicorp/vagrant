package ptypes

// import (
// 	"time"

// 	"google.golang.org/protobuf/ptypes"
// 	"github.com/imdario/mergo"
// 	"github.com/mitchellh/go-testing-interface"
// 	"github.com/stretchr/testify/require"

// 	pb "github.com/hashicorp/vagrant/internal/server/gen"
// )

// // Type wrapper around the proto type so that we can add some methods.
// type Component struct{ *pb.Component }

// // Match returns true if the component matches the given ref.
// func (c *Component) Match(ref *pb.Ref_Component) bool {
// 	if c == nil || ref == nil {
// 		return false
// 	}

// 	return c.Type == ref.Type && c.Name == ref.Name
// }

// func TestValidBuild(t testing.T, src *pb.Build) *pb.Build {
// 	t.Helper()

// 	if src == nil {
// 		src = &pb.Build{}
// 	}

// 	require.NoError(t, mergo.Merge(src, &pb.Build{
// 		Application: &pb.Ref_Application{
// 			Application: "a_test",
// 			Project:     "p_test",
// 		},
// 		Workspace: &pb.Ref_Workspace{
// 			Workspace: "default",
// 		},
// 		Status: testStatus(t),
// 	}))

// 	return src
// }

// func TestValidArtifact(t testing.T, src *pb.PushedArtifact) *pb.PushedArtifact {
// 	t.Helper()

// 	if src == nil {
// 		src = &pb.PushedArtifact{}
// 	}

// 	require.NoError(t, mergo.Merge(src, &pb.PushedArtifact{
// 		Application: &pb.Ref_Application{
// 			Application: "a_test",
// 			Project:     "p_test",
// 		},
// 		Workspace: &pb.Ref_Workspace{
// 			Workspace: "default",
// 		},
// 		Status: testStatus(t),
// 	}))

// 	return src
// }

// func TestValidDeployment(t testing.T, src *pb.Deployment) *pb.Deployment {
// 	t.Helper()

// 	if src == nil {
// 		src = &pb.Deployment{}
// 	}

// 	require.NoError(t, mergo.Merge(src, &pb.Deployment{
// 		Application: &pb.Ref_Application{
// 			Application: "a_test",
// 			Project:     "p_test",
// 		},
// 		Workspace: &pb.Ref_Workspace{
// 			Workspace: "default",
// 		},
// 		Status: testStatus(t),
// 	}))

// 	return src
// }

// func TestValidRelease(t testing.T, src *pb.Release) *pb.Release {
// 	t.Helper()

// 	if src == nil {
// 		src = &pb.Release{}
// 	}

// 	require.NoError(t, mergo.Merge(src, &pb.Release{
// 		Application: &pb.Ref_Application{
// 			Application: "a_test",
// 			Project:     "p_test",
// 		},
// 		Workspace: &pb.Ref_Workspace{
// 			Workspace: "default",
// 		},
// 		Status: testStatus(t),
// 	}))

// 	return src
// }

// func testStatus(t testing.T) *pb.Status {
// 	pt, err := ptypes.TimestampProto(time.Now())
// 	require.NoError(t, err)

// 	return &pb.Status{
// 		State:        pb.Status_SUCCESS,
// 		StartTime:    pt,
// 		CompleteTime: pt,
// 	}
// }

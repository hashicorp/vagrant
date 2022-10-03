package state

import (
	"testing"
	"time"

	"github.com/hashicorp/go-memdb"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
)

func TestConfig(t *testing.T) {
	t.Run("basic put and get", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projRef := testProjectProto(t, s)

		// Create a build
		require.NoError(s.ConfigSet(&vagrant_server.ConfigVar{
			Scope: &vagrant_server.ConfigVar_Project{
				Project: projRef,
			},

			Name:  "foo",
			Value: "bar",
		}))

		{
			// Get it exactly
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Project{
					Project: projRef,
				},

				Prefix: "foo",
			})
			require.NoError(err)
			require.Len(vs, 1)
		}

		{
			// Get it via a prefix match
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Project{
					Project: projRef,
				},

				Prefix: "",
			})
			require.NoError(err)
			require.Len(vs, 1)
		}

		{
			// non-matching prefix
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Project{
					Project: projRef,
				},

				Prefix: "bar",
			})
			require.NoError(err)
			require.Empty(vs)
		}
	})

	t.Run("merging", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProjectProto(t, s)

		// Create a build
		require.NoError(s.ConfigSet(
			&vagrant_server.ConfigVar{
				Scope: &vagrant_server.ConfigVar_Project{
					Project: projRef,
				},

				Name:  "global",
				Value: "value",
			},
			&vagrant_server.ConfigVar{
				Scope: &vagrant_server.ConfigVar_Project{
					Project: projRef,
				},

				Name:  "hello",
				Value: "project",
			},
		))

		{
			// Get our merged variables
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Project{
					Project: projRef,
				},
			})
			require.NoError(err)
			require.Len(vs, 2)

			// They are sorted, so check on them
			require.Equal("global", vs[0].Name)
			require.Equal("value", vs[0].Value)
			require.Equal("hello", vs[1].Name)
		}

		{
			// Get project scoped variables. This should return everything.
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Project{
					Project: projRef,
				},
			})
			require.NoError(err)
			require.Len(vs, 2)
		}
	})

	t.Run("delete", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProjectProto(t, s)

		// Create a var
		require.NoError(s.ConfigSet(&vagrant_server.ConfigVar{
			Scope: &vagrant_server.ConfigVar_Project{
				Project: projRef,
			},

			Name:  "foo",
			Value: "bar",
		}))

		{
			// Get it exactly
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Project{
					Project: projRef,
				},

				Prefix: "foo",
			})
			require.NoError(err)
			require.Len(vs, 1)
		}

		// Delete it
		require.NoError(s.ConfigSet(&vagrant_server.ConfigVar{
			Scope: &vagrant_server.ConfigVar_Project{
				Project: projRef,
			},

			Name: "foo",
		}))

		// Should not exist
		{
			// Get it exactly
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Project{
					Project: projRef,
				},

				Prefix: "foo",
			})
			require.NoError(err)
			require.Len(vs, 0)
		}
	})

	t.Run("runner configs any", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProjectProto(t, s)

		// Create the config
		require.NoError(s.ConfigSet(&vagrant_server.ConfigVar{
			Scope: &vagrant_server.ConfigVar_Runner{
				Runner: &vagrant_server.Ref_Runner{
					Target: &vagrant_server.Ref_Runner_Any{
						Any: &vagrant_server.Ref_RunnerAny{},
					},
				},
			},

			Name:  "foo",
			Value: "bar",
		}))

		// Create a var that shouldn't match
		require.NoError(s.ConfigSet(&vagrant_server.ConfigVar{
			Scope: &vagrant_server.ConfigVar_Project{
				Project: projRef,
			},

			Name:  "bar",
			Value: "baz",
		}))

		{
			// Get it exactly.
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Runner{
					Runner: &vagrant_server.Ref_RunnerId{Id: "R_A"},
				},

				Prefix: "foo",
			})
			require.NoError(err)
			require.Len(vs, 1)
		}

		{
			// Get it via a prefix match
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Runner{
					Runner: &vagrant_server.Ref_RunnerId{Id: "R_A"},
				},

				Prefix: "",
			})
			require.NoError(err)
			require.Len(vs, 1)
		}

		{
			// non-matching prefix
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Runner{
					Runner: &vagrant_server.Ref_RunnerId{Id: "R_A"},
				},

				Prefix: "bar",
			})
			require.NoError(err)
			require.Empty(vs)
		}
	})

	t.Run("runner configs targeting ID", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProjectProto(t, s)

		// Create the config
		require.NoError(s.ConfigSet(&vagrant_server.ConfigVar{
			Scope: &vagrant_server.ConfigVar_Runner{
				Runner: &vagrant_server.Ref_Runner{
					Target: &vagrant_server.Ref_Runner_Id{
						Id: &vagrant_server.Ref_RunnerId{
							Id: "R_A",
						},
					},
				},
			},

			Name:  "foo",
			Value: "bar",
		}))

		// Create a var that shouldn't match
		require.NoError(s.ConfigSet(&vagrant_server.ConfigVar{
			Scope: &vagrant_server.ConfigVar_Project{
				Project: projRef,
			},

			Name:  "bar",
			Value: "baz",
		}))

		{
			// Get it exactly.
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Runner{
					Runner: &vagrant_server.Ref_RunnerId{Id: "R_A"},
				},

				Prefix: "foo",
			})
			require.NoError(err)
			require.Len(vs, 1)
		}

		{
			// Doesn't match
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Runner{
					Runner: &vagrant_server.Ref_RunnerId{Id: "R_B"},
				},

				Prefix: "foo",
			})
			require.NoError(err)
			require.Len(vs, 0)
		}
	})

	t.Run("runner configs targeting any and ID", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		// Create the config
		require.NoError(s.ConfigSet(&vagrant_server.ConfigVar{
			Scope: &vagrant_server.ConfigVar_Runner{
				Runner: &vagrant_server.Ref_Runner{
					Target: &vagrant_server.Ref_Runner_Any{
						Any: &vagrant_server.Ref_RunnerAny{},
					},
				},
			},

			Name:  "foo",
			Value: "bar",
		}))

		require.NoError(s.ConfigSet(&vagrant_server.ConfigVar{
			Scope: &vagrant_server.ConfigVar_Runner{
				Runner: &vagrant_server.Ref_Runner{
					Target: &vagrant_server.Ref_Runner_Id{
						Id: &vagrant_server.Ref_RunnerId{
							Id: "R_A",
						},
					},
				},
			},

			Name:  "foo",
			Value: "baz",
		}))

		{
			// Get it exactly.
			vs, err := s.ConfigGet(&vagrant_server.ConfigGetRequest{
				Scope: &vagrant_server.ConfigGetRequest_Runner{
					Runner: &vagrant_server.Ref_RunnerId{Id: "R_A"},
				},

				Prefix: "foo",
			})
			require.NoError(err)
			require.Len(vs, 1)
			require.Equal("baz", vs[0].Value)
		}
	})
}

func TestConfigWatch(t *testing.T) {
	t.Run("basic put and get", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProjectProto(t, s)

		ws := memdb.NewWatchSet()

		// Get it with watch
		vs, err := s.ConfigGetWatch(&vagrant_server.ConfigGetRequest{
			Scope: &vagrant_server.ConfigGetRequest_Project{
				Project: projRef,
			},

			Prefix: "foo",
		}, ws)
		require.NoError(err)
		require.Len(vs, 0)

		// Watch should block
		require.True(ws.Watch(time.After(10 * time.Millisecond)))

		// Create a config
		require.NoError(s.ConfigSet(&vagrant_server.ConfigVar{
			Scope: &vagrant_server.ConfigVar_Project{
				Project: projRef,
			},

			Name:  "foo",
			Value: "bar",
		}))

		require.False(ws.Watch(time.After(100 * time.Millisecond)))
	})
}

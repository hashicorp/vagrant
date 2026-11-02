// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flags

import (
	"fmt"
	"strings"

	"github.com/hashicorp/go-multierror"
)

type ErrorHandling uint

const INTERNAL_GROUP_NAME = "__internal__"

const (
	ReturnOnError ErrorHandling = iota
	PanicOnError
)

type UnknownHandling uint

const (
	PassOnUnknown = iota
	ErrorOnUnknown
)

type Set struct {
	errorHandling   ErrorHandling
	flagMap         map[string]*Flag
	groups          []*Group
	name            string
	parsed          bool
	remaining       []string
	unknownFlags    []string
	unknownHandling UnknownHandling
}

type SetModifier func(s *Set)
type Visitor func(f *Flag)

// Set the error handling mode for the Set
func SetErrorMode(m ErrorHandling) SetModifier {
	return func(s *Set) {
		s.errorHandling = m
	}
}

// Set the mode for handling unknown flags
func SetUnknownMode(m UnknownHandling) SetModifier {
	return func(s *Set) {
		s.unknownHandling = m
	}
}

// Create a new set
func NewSet(name string, modifiers ...SetModifier) *Set {
	s := &Set{
		name:            name,
		groups:          []*Group{},
		errorHandling:   ReturnOnError,
		flagMap:         map[string]*Flag{},
		remaining:       []string{},
		unknownHandling: ErrorOnUnknown,
		unknownFlags:    []string{},
	}
	s.NewGroup(INTERNAL_GROUP_NAME, HideGroupName())

	for _, m := range modifiers {
		m(s)
	}
	return s
}

// Name of this flag set
func (s *Set) Name() string {
	return s.name
}

// All defined groups within the set
func (s *Set) Groups() []*Group {
	g := make([]*Group, len(s.groups))
	copy(g, s.groups)

	return g
}

// Visit flags that were updated either by CLI or
// environment variable
func (s *Set) Visit(fn Visitor) {
	for _, f := range s.Flags() {
		if f.Updated() {
			fn(f)
		}
	}
}

// Visit flags that were set by the CLI only
func (s *Set) VisitCalled(fn Visitor) {
	for _, f := range s.Flags() {
		if f.Called() {
			fn(f)
		}
	}
}

// Visit all flags
func (s *Set) VisitAll(fn Visitor) {
	for _, f := range s.Flags() {
		fn(f)
	}
}

// Add a group to the set. This is used to relocate
// a group from one set to another.
func (s *Set) AddGroup(g *Group) error {
	// Check that group hasn't already been added
	for _, cg := range s.groups {
		if g == cg {
			return fmt.Errorf("group already exists in set")
		}
	}
	// Remove the group from its current set
	idx := -1
	for i, cg := range g.set.groups {
		if cg == g {
			idx = i
			break
		}
	}
	if idx >= 0 {
		g.set.groups = append(g.set.groups[0:idx], g.set.groups[idx+1:]...)
	}

	// Update the groups Set and add the group to this Set's groups
	g.set = s
	s.groups = append(s.groups, g)

	return nil
}

// Add a new group
func (s *Set) NewGroup(name string, modifiers ...GroupModifier) (*Group, error) {
	for _, g := range s.groups {
		if g.name == name {
			return nil, fmt.Errorf("flag group already exists with name %s", name)
		}
	}
	grp := newGroup(s, name, modifiers...)
	return grp, nil
}

// Default group for flags. The default group does
// not include a title section when displayed
func (s *Set) DefaultGroup() *Group {
	if len(s.groups) < 1 {
		panic("default group does not exist")
	}
	return s.groups[0]
}

// All defined flags within the set
func (s *Set) Flags() []*Flag {
	f := []*Flag{}
	for _, g := range s.groups {
		f = append(f, g.flags...)
	}

	return f
}

// Get a flag by name. If the set has parsed, flags
// can be retrieved using short name and aliases.
func (s *Set) Flag(n string) (f *Flag, err error) {
	if s.parsed {
		f = s.flagMap[n]
	} else {
		for _, flg := range s.Flags() {
			if flg.longName == n {
				f = flg
			}
		}
	}

	if f == nil {
		err = fmt.Errorf("failed to locate flag named: %s", n)
	}

	return
}

// Generate flag usage output
func (s *Set) Display() (o string) {
	for _, g := range s.groups {
		o += g.Display(11)
	}

	return
}

// Parse the command line options. The remaining arguments will
// be non-flag arguments, or if the unkown handling allows for
// passing, it will include unused flag/values and arguments.
func (s *Set) Parse(args []string) (remaining []string, err error) {
	defer func() {
		if err != nil && s.errorHandling == PanicOnError {
			panic(err)
		}
	}()
	// We only allow a set to parse once
	if s.parsed {
		return nil, fmt.Errorf("Set has already parsed arguments")
	}
	s.parsed = true

	// Initialize all the flags. Errors returned from here
	// are either flag initialization issues or flag name
	// collisions
	if err = s.initFlags(); err != nil {
		return
	}
	// Now we start parsing
	for i := 0; i < len(args); i++ {
		w := args[i]

		// If the argument is the `--` separator, we stop parsing
		// and add the unprocessed arguments to the remaining list
		// to be returned
		if w == "--" {
			if i+1 < len(args) {
				// The remaining arguments may already be populated with
				// previously encountered unknown flags if the set is
				// configured for pass through. In that situation, we
				// want to retain the `--` separater
				if len(s.remaining) > 0 {
					s.remaining = append(s.remaining, args[i:]...)
				} else {
					s.remaining = append(s.remaining, args[i+1:]...)
				}
			}
			break
		}
		// Handle long name flag
		if strings.HasPrefix(w, "--") {
			var valueNext bool
			var name, value string
			flag := strings.Replace(w, "--", "", 1)
			if strings.Contains(flag, "=") {
				parts := strings.SplitN(flag, "=", 2)
				name, value = parts[0], parts[1]
			} else {
				name = flag
				valueNext = true
			}

			f, ok := s.flagMap[name]
			// If the flag is not found check if we should error
			if !ok {
				if err = s.flagNotFound(name); err != nil {
					return
				}
				// Since we haven't errored, add flag to remaining
				s.remaining = append(s.remaining, w)
				s.unknownFlags = append(s.unknownFlags, name)
				continue
			}
			switch f.kind {
			case BooleanType:
				// Since boolean types can be negated, check the flag
				// name to set the correct value
				if strings.HasPrefix(name, "no-") {
					value = "false"
				} else {
					value = "true"
				}
			case IncrementType:
				// Increment values don't matter, so just set as 1
				value = "1"
			default:
				// If the value was not included in the argument (argument form was not --flag=VAL)
				// then we need to get the value from the next argument
				if valueNext {
					if i+1 >= len(args) {
						return nil, fmt.Errorf("missing argument for flag `--%s`", f.longName)
					}
					i += 1
					value = args[i]
				}
			}
			// Mark the flag as being called on the CLI and the name used
			f.markCalled(name)
			// And finally, set the value
			if err = f.setValue(value); err != nil {
				return
			}
		} else if strings.HasPrefix(w, "-") {
			// For short flags, multiple patterns can be used. Valid examples:
			//
			// Boolean/Increment types can be chained: -vvvbx (-v -v -v -b -x)
			// Other types can include value in argument: -aVAL
			// Chaining can be used for both: -vvvbxaVAL
		wordLoop:
			for j := 1; j < len(w); j++ {
				c := string(w[j])
				f, ok := s.flagMap[c]
				// If the flag was not found check if we should error
				if !ok {
					if err = s.flagNotFound(c); err != nil {
						return
					}
					// Add the unprocessed to remaining
					s.remaining = append(s.remaining, "-"+w[j:])
					// Only add the flag we encountered that was unknown
					s.unknownFlags = append(s.unknownFlags, c)
					continue
				}

				// Mark the flag as being called on the CLI and the name used
				f.markCalled(c)

				switch f.kind {
				case BooleanType:
					err = f.setValue("true")
				case IncrementType:
					err = f.setValue("1")
				default:
					// Check if we have anything left in this argument. If we do, it is the value.
					// Otherwise, get the value from the next argument.
					if len(w)-1 == j {
						if i+1 >= len(args) {
							return nil, fmt.Errorf("missing argument for flag `-%s", string(f.shortName))
						}
						i += 1
						err = f.setValue(args[i])
					} else {
						err = f.setValue(w[j+1:])
					}
					if err != nil {
						return
					}
					break wordLoop
				}
				// If an error was encountered, bail out
				if err != nil {
					return
				}
			}
		} else {
			s.remaining = append(s.remaining, w)
		}
	}

	s.validateFlags()
	return s.remaining, nil
}

func (s *Set) validateFlags() (err error) {
	for _, f := range s.Flags() {
		if !f.required {
			continue
		}
		if !f.updated {
			err = multierror.Append(
				fmt.Errorf("missing required value for flag --%s", f.longName),
				err,
			)
		}
	}

	return
}

func (s *Set) flagNotFound(name string) error {
	if s.unknownHandling == ErrorOnUnknown {
		return fmt.Errorf("unknown flag encountered `%s`", name)
	}
	return nil
}

func (s *Set) initFlags() error {
	for _, f := range s.Flags() {
		if err := f.init(); err != nil {
			return err
		}
		names := make([]string, len(f.aliases))
		copy(names, f.aliases)
		names = append(names, f.longName)
		if f.shortName != 0 {
			names = append(names, string(f.shortName))
		}
		for _, n := range names {
			if cf, ok := s.flagMap[n]; ok {
				var colFlag string
				if len(n) == 1 {
					colFlag = "-" + n
				} else {
					colFlag = "--" + n
				}

				return fmt.Errorf("flags --%s and --%s share a common flag (collision on %s)",
					f.longName, cf.longName, colFlag)
			}
			s.flagMap[n] = f
		}
	}
	return nil
}

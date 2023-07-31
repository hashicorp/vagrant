// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flag

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"strings"

	"github.com/posener/complete"
)

// Sets is a group of flag sets.
type Sets struct {
	// unionSet is the set that is the union of all other sets. This
	// has ALL flags defined on it and is the set that is parsed. But
	// we maintain the other list of sets so that we can generate proper help.
	unionSet *flag.FlagSet

	// flagSets is the list of sets that we have. We don't parse these
	// directly but use them for help generation and autocompletion.
	flagSets []*Set

	// completions is our set of autocompletion handlers. This is also
	// the union of all available flags similar to unionSet.
	completions complete.Flags
}

// NewSets creates a new flag sets.
func NewSets() *Sets {
	unionSet := flag.NewFlagSet("", flag.ContinueOnError)

	// Errors and usage are expected to be controlled externally by
	// checking on the result of Parse.
	unionSet.Usage = func() {}
	unionSet.SetOutput(ioutil.Discard)

	return &Sets{
		unionSet:    unionSet,
		completions: complete.Flags{},
	}
}

// NewSet creates a new single flag set. A set should be created for
// any grouping of flags, for example "Common Options", "Auth Options", etc.
func (f *Sets) NewSet(name string) *Set {
	flagSet := NewSet(name)

	// The union and completions are pointers to our own values
	flagSet.unionSet = f.unionSet
	flagSet.completions = f.completions

	// Keep track of it for help generation
	f.flagSets = append(f.flagSets, flagSet)
	return flagSet
}

// AddSet adds a single flag set
func (f *Sets) AddSet(set *Set) {
	newSet := f.NewSet(set.Name())
	set.VisitVars(func(fl *VarFlag) {
		newSet.VarFlag(fl)
	})
}

// Completions returns the completions for this flag set.
func (f *Sets) Completions() complete.Flags {
	return f.completions
}

// Parse parses the given flags, returning any errors.
func (f *Sets) Parse(args []string) error {
	return f.unionSet.Parse(args)
}

// Parsed reports whether the command-line flags have been parsed.
func (f *Sets) Parsed() bool {
	return f.unionSet.Parsed()
}

// Args returns the remaining args after parsing.
func (f *Sets) Args() []string {
	return f.unionSet.Args()
}

// Visit visits the flags in lexicographical order, calling fn for each. It
// visits only those flags that have been set.
func (f *Sets) Visit(fn func(*flag.Flag)) {
	f.unionSet.Visit(fn)
}

// Help builds custom help for this command, grouping by flag set.
func (fs *Sets) Help() string {
	var out bytes.Buffer

	for _, set := range fs.flagSets {
		printFlagTitle(&out, set.name+":")
		set.VisitAll(func(f *flag.Flag) {
			// Skip any hidden flags
			if v, ok := f.Value.(FlagVisibility); ok && v.Hidden() {
				return
			}
			printFlagDetail(&out, f)
		})
	}

	return strings.TrimRight(out.String(), "\n")
}

// Help builds custom help for this command, grouping by flag set.
func (fs *Sets) VisitSets(fn func(name string, set *Set)) {
	for _, set := range fs.flagSets {
		fn(set.name, set)
	}
}

// Set is a grouped wrapper around a real flag set and a grouped flag set.
type Set struct {
	name        string
	flagSet     *flag.FlagSet
	unionSet    *flag.FlagSet
	completions complete.Flags

	vars []*VarFlag
}

// NewSet creates a new flag set.
func NewSet(name string) *Set {
	return &Set{
		name:    name,
		flagSet: flag.NewFlagSet(name, flag.ContinueOnError),
	}
}

// Name returns the name of this flag set.
func (f *Set) Name() string {
	return f.name
}

func (f *Set) Visit(fn func(*flag.Flag)) {
	f.flagSet.Visit(fn)
}

func (f *Set) VisitAll(fn func(*flag.Flag)) {
	f.flagSet.VisitAll(fn)
}

func (f *Set) VisitVars(fn func(*VarFlag)) {
	for _, v := range f.vars {
		fn(v)
	}
}

// printFlagTitle prints a consistently-formatted title to the given writer.
func printFlagTitle(w io.Writer, s string) {
	fmt.Fprintf(w, "%s\n\n", s)
}

// printFlagDetail prints a single flag to the given writer.
func printFlagDetail(w io.Writer, f *flag.Flag) {
	// Check if the flag is hidden - do not print any flag detail or help output
	// if it is hidden.
	if h, ok := f.Value.(FlagVisibility); ok && h.Hidden() {
		return
	}

	// Check for a detailed example
	example := ""
	if t, ok := f.Value.(FlagExample); ok {
		example = t.Example()
	}

	if example != "" {
		fmt.Fprintf(w, "  -%s=<%s>\n", f.Name, example)
	} else {
		fmt.Fprintf(w, "  -%s\n", f.Name)
	}

	usage := reRemoveWhitespace.ReplaceAllString(f.Usage, " ")
	indented := wrapAtLengthWithPadding(usage, 6)
	fmt.Fprintf(w, "%s\n\n", indented)
}

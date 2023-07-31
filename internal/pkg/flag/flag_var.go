// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flag

import (
	"flag"
	"fmt"
	"strings"

	"github.com/posener/complete"
)

// -- VarFlag
type VarFlag struct {
	Name       string
	Aliases    []string
	Usage      string
	Default    string
	EnvVar     string
	Value      flag.Value
	Completion complete.Predictor
}

func (f *Set) VarFlag(i *VarFlag) {
	f.vars = append(f.vars, i)

	// If the flag is marked as hidden, just add it to the set and return to
	// avoid unnecessary computations here. We do not want to add completions or
	// generate help output for hidden flags.
	if v, ok := i.Value.(FlagVisibility); ok && v.Hidden() {
		f.Var(i.Value, i.Name, "")
		return
	}

	// Calculate the full usage
	usage := i.Usage

	if len(i.Aliases) > 0 {
		sentence := make([]string, len(i.Aliases))
		for i, a := range i.Aliases {
			sentence[i] = fmt.Sprintf(`"-%s"`, a)
		}

		aliases := ""
		switch len(sentence) {
		case 0:
			// impossible...
		case 1:
			aliases = sentence[0]
		case 2:
			aliases = sentence[0] + " and " + sentence[1]
		default:
			sentence[len(sentence)-1] = "and " + sentence[len(sentence)-1]
			aliases = strings.Join(sentence, ", ")
		}

		usage += fmt.Sprintf(" This is aliased as %s.", aliases)
	}

	if i.Default != "" {
		usage += fmt.Sprintf(" The default is %s.", i.Default)
	}

	if i.EnvVar != "" {
		usage += fmt.Sprintf(" This can also be specified via the %s "+
			"environment variable.", i.EnvVar)
	}

	// Add aliases to the main set
	for _, a := range i.Aliases {
		f.unionSet.Var(i.Value, a, "")
	}

	f.Var(i.Value, i.Name, usage)
	f.completions["-"+i.Name] = i.Completion
}

// Var is a lower-level API for adding something to the flags. It should be used
// wtih caution, since it bypasses all validation. Consider VarFlag instead.
func (f *Set) Var(value flag.Value, name, usage string) {
	f.unionSet.Var(value, name, usage)
	f.flagSet.Var(value, name, usage)
}

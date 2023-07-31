// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flags

import "fmt"

type GroupModifier func(g *Group)

// Don't display the group name of the flags
func HideGroupName() GroupModifier {
	return func(g *Group) {
		g.showGroupName = false
	}
}

// Don't display this group of flags
func HideGroup() GroupModifier {
	return func(g *Group) {
		g.hidden = true
	}
}

type Group struct {
	flags         []*Flag // flags attached to group
	hidden        bool    // group should not be displayed
	name          string  // name of the group
	set           *Set    // Set group is attached to
	showGroupName bool    // group name should be included in display
}

func newGroup(s *Set, n string, modifiers ...GroupModifier) *Group {
	if s == nil {
		panic("group must be attached to set")
	}
	g := &Group{
		set:           s,
		name:          n,
		flags:         []*Flag{},
		showGroupName: true,
	}

	for _, fn := range modifiers {
		fn(g)
	}

	s.groups = append(s.groups, g)

	return g
}

// Add a flag to the group. This is used to relocate
// a flag from one group to another.
func (g *Group) Add(f *Flag) (err error) {
	if f.group == g {
		return nil
	}

	if f.group != nil {
		idx := -1
		for i, flg := range f.group.flags {
			if flg.longName == f.longName {
				idx = i
				break
			}
		}
		if idx >= 0 {
			f.group.flags = append(f.group.flags[0:idx], f.group.flags[idx+1:]...)
		}
	}

	f.group = g
	g.flags = append(g.flags, f)
	return err
}

// Name of the group
func (g *Group) Name() string {
	return g.name
}

// Flags contained by this group
func (g *Group) Flags() []*Flag {
	f := make([]*Flag, len(g.flags))
	copy(f, g.flags)
	return f
}

// Add a new BooleanType flag
func (g *Group) Bool(
	name string,
	modifiers ...FlagModifier,
) *Flag {
	return newFlag(name, BooleanType, g, modifiers...)
}

// Add a new BooleanType flag using variable
func (g *Group) BoolVar(
	name string,
	ptr *bool,
	modifiers ...FlagModifier,
) *Flag {
	f := g.Bool(name, modifiers...)
	f.ptr = true
	f.value = ptr

	return f
}

// Add a new StringType flag
func (g *Group) String(
	name string,
	modifiers ...FlagModifier,
) *Flag {
	return newFlag(name, StringType, g, modifiers...)
}

// Add a new StringType flag using variable
func (g *Group) StringVar(
	name string,
	ptr *string,
	modifiers ...FlagModifier,
) *Flag {
	f := g.String(name, modifiers...)
	f.ptr = true
	f.value = ptr

	return f
}

// Add a new ArrayType flag
func (g *Group) Array(
	name string,
	subtype Type,
	modifiers ...FlagModifier,
) *Flag {
	modifiers = append(modifiers, SetSubtype(subtype))
	return newFlag(name, ArrayType, g, modifiers...)
}

// Add a new ArrayType flag using variable
func (g *Group) ArrayVar(
	name string,
	subtype Type,
	ptr interface{},
	modifiers ...FlagModifier,
) *Flag {
	f := g.Array(name, subtype, modifiers...)
	f.ptr = true
	f.value = ptr

	return f
}

// Add a new FloatType flag
func (g *Group) Float(
	name string,
	modifiers ...FlagModifier,
) *Flag {
	return newFlag(name, FloatType, g, modifiers...)
}

// Add a new FloatType flag using variable
func (g *Group) FloatVar(
	name string,
	ptr *float64,
	modifiers ...FlagModifier,
) *Flag {
	f := g.Float(name, modifiers...)
	f.ptr = true
	f.value = ptr

	return f
}

// Add a new Integer flag
func (g *Group) Integer(
	name string,
	modifiers ...FlagModifier,
) *Flag {
	return newFlag(name, IntegerType, g, modifiers...)
}

// Add a new Integer flag using variable
func (g *Group) IntegerVar(
	name string,
	ptr *int64,
	modifiers ...FlagModifier,
) *Flag {
	f := g.Integer(name, modifiers...)
	f.ptr = true
	f.value = ptr

	return f
}

// Add a new IncrementType flag
func (g *Group) Increment(
	name string,
	modifiers ...FlagModifier,
) *Flag {
	modifiers = append(modifiers, SetSubtype(IntegerType))
	return newFlag(name, IncrementType, g, modifiers...)
}

// Add a new IncrementType flag using variable
func (g *Group) IncrementVar(
	name string,
	ptr *int64,
	modifiers ...FlagModifier,
) *Flag {
	f := g.Increment(name, modifiers...)
	f.ptr = true
	f.value = ptr

	return f
}

// Add a new MapType flag
func (g *Group) Map(
	name string,
	subtype Type,
	modifiers ...FlagModifier,
) *Flag {
	modifiers = append(modifiers, SetSubtype(subtype))
	return newFlag(name, MapType, g, modifiers...)
}

// Add a new MaptType flag using variable
func (g *Group) MapVar(
	name string,
	subtype Type,
	ptr interface{},
	modifiers ...FlagModifier,
) *Flag {
	f := g.Map(name, subtype, modifiers...)
	f.ptr = true
	f.value = ptr

	return f
}

// Generate printable output of flag group
func (g *Group) Display(
	indent int, // Number of spaces to indent
) string {
	if g.hidden {
		return ""
	}

	var pad int
	opts := []string{}
	desc := []string{}

	for i, f := range g.flags {
		if f.hidden {
			continue
		}
		if f.shortName != 0 {
			opts = append(opts, fmt.Sprintf("-%c,", f.shortName))
		} else {
			opts = append(opts, "   ")
		}
		switch f.kind {
		case BooleanType:
			opts[i] = fmt.Sprintf("%s --[no-]%s", opts[i], f.longName)
		case IncrementType:
			opts[i] = fmt.Sprintf("%s --%s", opts[i], f.longName)
		default:
			opts[i] = fmt.Sprintf("%s --%s VALUE", opts[i], f.longName)
		}
		desc = append(desc, f.description)
		if len(opts[i]) > pad {
			pad = len(opts[i])
		}
	}

	// If there were no flags to display (empty flag collection or all hidden)
	// then just return an empty string
	if len(opts) == 0 {
		return ""
	}

	pad += indent
	var d string

	if g.showGroupName {
		d = fmt.Sprintf("%s:\n", g.name)
	}

	for i := 0; i < len(opts); i++ {
		d = fmt.Sprintf("%s%4s%-*s%s\n", d, "", pad, opts[i], desc[i])
	}

	return d
}

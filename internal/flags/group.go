package flags

import "fmt"

type GroupModifier func(g *Group)

func HideGroupName() GroupModifier {
	return func(g *Group) {
		g.showGroupName = false
	}
}

func HideGroup() GroupModifier {
	return func(g *Group) {
		g.hidden = true
	}
}

type Group struct {
	flags         []*Flag
	hidden        bool
	name          string
	set           *Set
	showGroupName bool
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

func (g *Group) Name() string {
	return g.name
}

func (g *Group) Flags() []*Flag {
	f := make([]*Flag, len(g.flags))
	copy(f, g.flags)
	return f
}

func (g *Group) Bool(
	name string,
	modifiers ...FlagModifier,
) *Flag {
	return newFlag(name, BooleanType, g, modifiers...)
}

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

func (g *Group) String(
	name string,
	modifiers ...FlagModifier,
) *Flag {
	return newFlag(name, StringType, g, modifiers...)
}

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

func (g *Group) Array(
	name string,
	subtype Type,
	modifiers ...FlagModifier,
) *Flag {
	modifiers = append(modifiers, SetSubtype(subtype))
	return newFlag(name, ArrayType, g, modifiers...)
}

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

func (g *Group) Float(
	name string,
	modifiers ...FlagModifier,
) *Flag {
	return newFlag(name, StringType, g, modifiers...)
}

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

func (g *Group) Integer(
	name string,
	modifiers ...FlagModifier,
) *Flag {
	return newFlag(name, IntegerType, g, modifiers...)
}

func (g *Group) IntegerVar(
	name string,
	ptr *int,
	modifiers ...FlagModifier,
) *Flag {
	f := g.Integer(name, modifiers...)
	f.ptr = true
	f.value = ptr

	return f
}

func (g *Group) Increment(
	name string,
	modifiers ...FlagModifier,
) *Flag {
	modifiers = append(modifiers, SetSubtype(IntegerType))
	return newFlag(name, IncrementType, g, modifiers...)
}

func (g *Group) IncrementVar(
	name string,
	ptr *int,
	modifiers ...FlagModifier,
) *Flag {
	f := g.Increment(name, modifiers...)
	f.ptr = true
	f.value = ptr

	return f
}

func (g *Group) Map(
	name string,
	subtype Type,
	modifiers ...FlagModifier,
) *Flag {
	modifiers = append(modifiers, SetSubtype(subtype))
	return newFlag(name, MapType, g, modifiers...)
}

func (g *Group) MapVar(
	name string,
	subtype Type,
	ptr *map[string]interface{},
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
		if f.kind == BooleanType {
			opts[i] = fmt.Sprintf("%s --[no-]%s", opts[i], f.longName)
		} else {
			opts[i] = fmt.Sprintf("%s --%s VALUE", opts[i], f.longName)
		}
		desc = append(desc, f.description)
		if len(opts[i]) > pad {
			pad = len(opts[i])
		}
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

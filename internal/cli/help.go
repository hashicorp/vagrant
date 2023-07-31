// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package cli

import (
	"bytes"
	"regexp"
	"strings"

	"github.com/mitchellh/cli"
	"github.com/mitchellh/go-glint"
)

// formatHelp takes a raw help string and attempts to colorize it automatically.
func formatHelp(v string) string {
	// Trim the empty space
	v = strings.TrimSpace(v)

	var buf bytes.Buffer
	d := glint.New()
	d.SetRenderer(&glint.TerminalRenderer{
		Output: &buf,

		// We set rows/cols here manually. The important bit is the cols
		// needs to be wide enough so glint doesn't clamp any text and
		// lets the terminal just autowrap it. Rows doesn't make a big
		// difference.
		Rows: 10,
		Cols: 180,
	})

	for _, line := range strings.Split(v, "\n") {
		// Usage: prefix lines
		prefix := "Usage: "
		if strings.HasPrefix(line, prefix) {
			d.Append(glint.Layout(
				glint.Style(
					glint.Text(prefix),
					glint.Color("lightMagenta"),
				),
				glint.Text(line[len(prefix):]),
			).Row())

			continue
		}

		// Alias: prefix lines
		prefix = "Alias: "
		if strings.HasPrefix(line, prefix) {
			d.Append(glint.Layout(
				glint.Style(
					glint.Text(prefix),
					glint.Color("lightMagenta"),
				),
				glint.Text(line[len(prefix):]),
			).Row())

			continue
		}

		// A header line
		if reHelpHeader.MatchString(line) {
			d.Append(glint.Style(
				glint.Text(line),
				glint.Bold(),
			))

			continue
		}

		// If we have a command in the line, then highlight that.
		if matches := reCommand.FindAllStringIndex(line, -1); len(matches) > 0 {
			var cs []glint.Component
			idx := 0
			for _, match := range matches {
				start := match[0] + 1
				end := match[1] - 1

				cs = append(
					cs,
					glint.Text(line[idx:start]),
					glint.Style(
						glint.Text(line[start:end]),
						glint.Color("lightMagenta"),
					),
				)

				idx = end
			}

			// Add the rest of the text
			cs = append(cs, glint.Text(line[idx:]))

			d.Append(glint.Layout(cs...).Row())
			continue
		}

		// Normal line
		d.Append(glint.Text(line))
	}

	d.RenderFrame()
	return buf.String()
}

type helpCommand struct {
	SynopsisText string
	HelpText     string
}

func (c *helpCommand) Run(args []string) int {
	return cli.RunResultHelp
}

func (c *helpCommand) Synopsis() string {
	return strings.TrimSpace(c.SynopsisText)
}

func (c *helpCommand) Help() string {
	if c.HelpText == "" {
		return c.SynopsisText
	}

	return formatHelp(c.HelpText)
}

func (c *helpCommand) HelpTemplate() string {
	return formatHelp(helpTemplate)
}

var (
	reHelpHeader = regexp.MustCompile(`^[a-zA-Z0-9_-].*:$`)
	reCommand    = regexp.MustCompile(`"vagrant \w+"`)
)

const helpTemplate = `
Usage: {{.Name}} {{.SubcommandName}} SUBCOMMAND

{{indent 2 (trim .Help)}}{{if gt (len .Subcommands) 0}}

Subcommands:
{{- range $value := .Subcommands }}
    {{ $value.NameAligned }}    {{ $value.Synopsis }}{{ end }}

{{- end }}
`

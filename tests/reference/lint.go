// Development-only adapter for the pinned public Go linter API.
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	jsonnet "github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/linter"
	"os"
	"path"
	"strings"
)

type formatter struct{ Messages, Diagnostics []string }

func (f *formatter) Format(err error) string {
	raw := err.Error()
	f.Diagnostics = append(f.Diagnostics, raw)
	_, message, ok := strings.Cut(raw, " ")
	if !ok {
		message = raw
	}
	f.Messages = append(f.Messages, message)
	return raw
}
func (*formatter) SetMaxStackTraceSize(int)                 {}
func (*formatter) SetColorFormatter(jsonnet.ColorFormatter) {}

type importer struct {
	files map[string]string
	cache map[string]jsonnet.Contents
}

func (i importer) Import(from, p string) (jsonnet.Contents, string, error) {
	id := path.Join(path.Dir(from), p)
	if c, ok := i.cache[id]; ok {
		return c, id, nil
	}
	if s, ok := i.files[id]; ok {
		c := jsonnet.MakeContents(s)
		i.cache[id] = c
		return c, id, nil
	}
	return jsonnet.Contents{}, "", fmt.Errorf("missing import: %s", id)
}
func main() {
	var input struct {
		Snippets []struct{ ID, Text string }
		Files    map[string]string
	}
	if err := json.NewDecoder(os.Stdin).Decode(&input); err != nil {
		panic(err)
	}
	vm := jsonnet.MakeVM()
	f := &formatter{Messages: []string{}, Diagnostics: []string{}}
	vm.ErrorFormatter = f
	vm.Importer(importer{input.Files, map[string]jsonnet.Contents{}})
	snippets := []linter.Snippet{}
	for _, s := range input.Snippets {
		snippets = append(snippets, linter.Snippet{FileName: s.ID, Code: s.Text})
	}
	found := linter.LintSnippet(vm, &bytes.Buffer{}, snippets)
	if err := json.NewEncoder(os.Stdout).Encode(map[string]interface{}{"messages": f.Messages, "diagnostics": f.Diagnostics, "found": found}); err != nil {
		panic(err)
	}
}

// Development-only adapter for the pinned public ErrorFormatter and VM APIs.
package main

import (
	"encoding/json"
	"fmt"
	jsonnet "github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/ast"
	"io"
	"os"
)

type importer struct{ files map[string]string }

func (i importer) Import(_, path string) (jsonnet.Contents, string, error) {
	if source, ok := i.files[path]; ok {
		return jsonnet.MakeContents(source), path, nil
	}
	return jsonnet.Contents{}, "", fmt.Errorf("missing import: %s", path)
}

type capture struct {
	inner  jsonnet.ErrorFormatter
	frames []map[string]string
}

func (c *capture) Format(err error) string {
	if runtime, ok := err.(jsonnet.RuntimeError); ok {
		for _, frame := range runtime.StackTrace {
			c.frames = append(c.frames, map[string]string{"location": frame.Loc.String(), "name": frame.Name})
		}
	} else if err, ok := err.(interface{ Loc() ast.LocationRange }); ok {
		location := err.Loc()
		c.frames = append(c.frames, map[string]string{"location": location.String(), "name": ""})
	}
	return c.inner.Format(err)
}
func (c *capture) SetMaxStackTraceSize(size int)                  { c.inner.SetMaxStackTraceSize(size) }
func (c *capture) SetColorFormatter(color jsonnet.ColorFormatter) { c.inner.SetColorFormatter(color) }
func main() {
	var input struct {
		Source, Mode, Filename string
		TraceSize              *int `json:"trace_size"`
		Color                  bool
		StringOutput           bool `json:"string_output"`
		Files                  map[string]string
		ExtCode                map[string]string `json:"ext_code"`
		TlaCode                map[string]string `json:"tla_code"`
	}
	if err := json.NewDecoder(os.Stdin).Decode(&input); err != nil {
		panic(err)
	}
	if input.Filename == "" {
		input.Filename = "entry"
	}
	vm := jsonnet.MakeVM()
	cap := &capture{vm.ErrorFormatter, []map[string]string{}}
	vm.ErrorFormatter = cap
	vm.Importer(importer{input.Files})
	vm.StringOutput = input.StringOutput
	for name, source := range input.ExtCode {
		vm.ExtCode(name, source)
	}
	for name, source := range input.TlaCode {
		vm.TLACode(name, source)
	}
	colors := []string{}
	if input.TraceSize != nil {
		cap.SetMaxStackTraceSize(*input.TraceSize)
	}
	if input.Color {
		cap.SetColorFormatter(func(w io.Writer, f string, a ...interface{}) (int, error) {
			s := fmt.Sprintf(f, a...)
			colors = append(colors, s)
			return fmt.Fprint(w, "<color>"+s+"</color>")
		})
	}
	var output interface{}
	var err error
	switch input.Mode {
	case "stream":
		output, err = vm.EvaluateSnippetStream(input.Filename, input.Source)
	case "multi":
		output, err = vm.EvaluateSnippetMulti(input.Filename, input.Source)
	default:
		output, err = vm.EvaluateSnippet(input.Filename, input.Source)
	}
	bytes := []int{}
	if err != nil {
		for _, b := range []byte(err.Error()) {
			bytes = append(bytes, int(b))
		}
		output = nil
	}
	result := map[string]interface{}{"error": err != nil, "output": output, "bytes": bytes, "frames": cap.frames, "color_calls": colors}
	if err := json.NewEncoder(os.Stdout).Encode(result); err != nil {
		panic(err)
	}
}

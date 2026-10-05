// Development-only API adapter. Run through tools/parameter-integration.mbtx.
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"

	jsonnet "github.com/google/go-jsonnet"
)

type node struct{ Source, Filename string }
type fixture struct {
	Source, Mode string
	ExtValues    map[string]interface{} `json:"ext_vars"`
	TLAValues    map[string]interface{} `json:"tla_vars"`
	ExtCode      map[string]string      `json:"ext_code"`
	TLACode      map[string]string      `json:"tla_code"`
	ExtPrograms  map[string]node        `json:"ext_programs"`
	TLAPrograms  map[string]node        `json:"tla_programs"`
	Imports      map[string]string
}
type importer struct {
	files    map[string]string
	requests *[][2]string
}

func (i importer) Import(from, path string) (jsonnet.Contents, string, error) {
	*i.requests = append(*i.requests, [2]string{from, path})
	if text, ok := i.files[path]; ok {
		return jsonnet.MakeContents(text), "resolved/" + path, nil
	}
	return jsonnet.Contents{}, "", fmt.Errorf("missing import: %s", path)
}

type result struct {
	Result      interface{} `json:"result"`
	Error       string      `json:"error"`
	Requests    [][2]string `json:"requests"`
	Trace       string      `json:"trace"`
	NativeCalls int         `json:"native_calls"`
}

func evaluate(f fixture, r *result, trace *bytes.Buffer) (err error) {
	vm := jsonnet.MakeVM()
	defer func() {
		if err != nil {
			err = fmt.Errorf("%s", vm.ErrorFormatter.Format(err))
		}
	}()
	vm.Importer(importer{f.Imports, &r.Requests})
	vm.SetTraceOut(trace)
	vm.NativeFunction(&jsonnet.NativeFunction{Name: "tick", Func: func(_ []interface{}) (interface{}, error) { r.NativeCalls++; return 42, nil }})
	for name, value := range f.ExtValues {
		encoded, err := json.Marshal(value)
		if err != nil {
			return err
		}
		vm.ExtCode(name, string(encoded))
	}
	for name, value := range f.TLAValues {
		encoded, err := json.Marshal(value)
		if err != nil {
			return err
		}
		vm.TLACode(name, string(encoded))
	}
	for name, value := range f.ExtCode {
		vm.ExtCode(name, value)
	}
	for name, value := range f.TLACode {
		vm.TLACode(name, value)
	}
	for name, value := range f.ExtPrograms {
		filename := value.Filename
		if filename == "" {
			filename = "node"
		}
		n, err := jsonnet.SnippetToAST(filename, value.Source)
		if err != nil {
			return err
		}
		vm.ExtNode(name, n)
	}
	for name, value := range f.TLAPrograms {
		filename := value.Filename
		if filename == "" {
			filename = "node"
		}
		n, err := jsonnet.SnippetToAST(filename, value.Source)
		if err != nil {
			return err
		}
		vm.TLANode(name, n)
	}
	n, err := jsonnet.SnippetToAST("main", f.Source)
	if err != nil {
		return err
	}
	vm.StringOutput = f.Mode == "raw" || f.Mode == "multi-raw"
	switch f.Mode {
	case "stream":
		r.Result, err = vm.EvaluateStream(n)
	case "multi", "multi-raw":
		r.Result, err = vm.EvaluateMulti(n)
	default:
		var text string
		text, err = vm.Evaluate(n)
		if err == nil {
			if f.Mode == "raw" || f.Mode == "text" {
				r.Result = text
			} else {
				err = json.Unmarshal([]byte(text), &r.Result)
			}
		}
	}
	return err
}
func main() {
	var f fixture
	if err := json.NewDecoder(os.Stdin).Decode(&f); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	r := result{Requests: make([][2]string, 0)}
	var trace bytes.Buffer
	if err := evaluate(f, &r, &trace); err != nil {
		r.Error = err.Error()
		r.Result = nil
	}
	r.Trace = trace.String()
	if err := json.NewEncoder(os.Stdout).Encode(r); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
}

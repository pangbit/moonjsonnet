// Development-only adapter for stateful VM sequences.
package main

import (
	"encoding/json"
	"fmt"
	jsonnet "github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/ast"
	"os"
	"strings"
)

type step struct {
	Op, Name, Source, Mode, Label string
	From, Path                    string
	Paths                         []string
	Value                         json.RawMessage
	Increment                     bool
}
type fixture struct {
	Files map[string]string
	Steps []step
}
type importer struct {
	files *map[string]string
	cache map[string]jsonnet.Contents
	reads *int
}

func (i importer) Import(_, path string) (jsonnet.Contents, string, error) {
	if contents, ok := i.cache[path]; ok {
		return contents, path, nil
	}
	*i.reads++
	if source, ok := (*i.files)[path]; ok {
		c := jsonnet.MakeContents(source)
		i.cache[path] = c
		return c, path, nil
	}
	return jsonnet.Contents{}, "", fmt.Errorf("missing import: %s", path)
}

type traceSink struct {
	label  string
	traces *[]string
}

func (s traceSink) Write(p []byte) (int, error) {
	// Go std.trace writes one complete line, with source prefix and one trailing LF.
	line := strings.TrimSuffix(string(p), "\n")
	pieces := strings.SplitN(line, " ", 3)
	if len(pieces) != 3 {
		return 0, fmt.Errorf("unexpected trace: %q", line)
	}
	*s.traces = append(*s.traces, s.label+":"+pieces[2])
	return len(p), nil
}

type observation struct {
	Value interface{} `json:"value"`
	Error bool        `json:"error"`
	Calls int         `json:"calls"`
	Reads int         `json:"reads"`
	Trace []string    `json:"trace"`
}

func run(f fixture) (interface{}, error) {
	vm := jsonnet.MakeVM()
	calls, reads := 0, 0
	traces := []string{}
	results := []observation{}
	diagnostics := []string{}
	imported := map[string]ast.Node{}
	replaceImporter := func() { vm.Importer(importer{&f.Files, map[string]jsonnet.Contents{}, &reads}) }
	replaceImporter()
	vm.SetTraceOut(traceSink{"0", &traces})
	for _, s := range f.Steps {
		name := s.Name
		if name == "" {
			name = "x"
		}
		switch s.Op {
		case "ext_var":
			vm.ExtCode(name, string(s.Value))
		case "ext_code":
			vm.ExtCode(name, s.Source)
		case "ext_program":
			n, e := jsonnet.SnippetToAST("parameter", s.Source)
			if e != nil {
				return nil, e
			}
			vm.ExtNode(name, n)
		case "ext_reset":
			vm.ExtReset()
		case "tla_var":
			vm.TLACode(name, string(s.Value))
		case "tla_code":
			vm.TLACode(name, s.Source)
		case "tla_program":
			n, e := jsonnet.SnippetToAST("parameter", s.Source)
			if e != nil {
				return nil, e
			}
			vm.TLANode(name, n)
		case "tla_reset":
			vm.TLAReset()
		case "files":
			if e := json.Unmarshal(s.Value, &f.Files); e != nil {
				return nil, e
			}
		case "importer":
			replaceImporter()
		case "trace":
			vm.SetTraceOut(traceSink{s.Label, &traces})
		case "native":
			var value interface{}
			if len(s.Value) == 0 {
				value = float64(42)
			} else if e := json.Unmarshal(s.Value, &value); e != nil {
				return nil, e
			}
			increment := s.Increment
			vm.NativeFunction(&jsonnet.NativeFunction{Name: "tick", Func: func(_ []interface{}) (interface{}, error) {
				calls++
				if increment {
					return calls, nil
				}
				return value, nil
			}})
		case "string_output":
			if e := json.Unmarshal(s.Value, &vm.StringOutput); e != nil {
				return nil, e
			}
		case "resolve", "data", "program", "dependencies":
			from, path := s.From, s.Path
			if from == "" {
				from = "entry"
			}
			if path == "" {
				path = "main"
			}
			var value interface{}
			var err error
			switch s.Op {
			case "resolve":
				value, err = vm.ResolveImport(from, path)
			case "data":
				var data, id string
				data, id, err = vm.ImportData(from, path)
				if err == nil {
					bytes := make([]int, len(data))
					for i, b := range []byte(data) {
						bytes[i] = int(b)
					}
					value = map[string]interface{}{"id": id, "bytes": bytes}
				}
			case "program":
				var n ast.Node
				var id string
				n, id, err = vm.ImportAST(from, path)
				if err == nil {
					imported[name] = n
					value = map[string]interface{}{"id": id, "nil": n == nil}
				}
			case "dependencies":
				value, err = vm.FindDependencies(from, s.Paths)
			}
			diagnostic := ""
			if err != nil {
				// Query APIs return importer errors directly. ErrorFormatter is for
				// interpreter diagnostics and labels ordinary Go errors INTERNAL ERROR.
				diagnostic = err.Error()
				value = nil
			}
			diagnostics = append(diagnostics, diagnostic)
			results = append(results, observation{value, err != nil, calls, reads, append([]string{}, traces...)})
		case "evaluate", "evaluate_imported":
			var value interface{}
			var n ast.Node
			var err error
			if s.Op == "evaluate_imported" {
				n = imported[name]
				if n == nil {
					err = fmt.Errorf("nil imported AST")
				}
			} else {
				n, err = jsonnet.SnippetToAST("entry", s.Source)
			}
			if err == nil {
				switch s.Mode {
				case "stream":
					value, err = vm.EvaluateStream(n)
				case "multi":
					value, err = vm.EvaluateMulti(n)
				default:
					var output string
					output, err = vm.Evaluate(n)
					if err == nil {
						if s.Mode == "text" {
							value = output
						} else {
							err = json.Unmarshal([]byte(output), &value)
						}
					}
				}
			}
			diagnostic := ""
			if err != nil {
				diagnostic = vm.ErrorFormatter.Format(err)
				value = nil
			}
			diagnostics = append(diagnostics, diagnostic)
			results = append(results, observation{value, err != nil, calls, reads, append([]string{}, traces...)})
		default:
			return nil, fmt.Errorf("unknown action %s", s.Op)
		}
	}
	return map[string]interface{}{"result": results, "diagnostics": diagnostics, "error": "", "requests": []string{}, "trace": "", "native_calls": 0}, nil
}
func main() {
	var f fixture
	if e := json.NewDecoder(os.Stdin).Decode(&f); e != nil {
		panic(e)
	}
	r, e := run(f)
	if e != nil {
		panic(e)
	}
	if e = json.NewEncoder(os.Stdout).Encode(r); e != nil {
		panic(e)
	}
}

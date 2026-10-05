// Development-only adapter for public AST cloning, edits and VM execution.
package main

import (
	"encoding/json"
	"fmt"
	jsonnet "github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/ast"
	"os"
)

type fixture struct{ Source, Replacement, Op, Mode string }

func run(f fixture) (interface{}, error) {
	original, err := jsonnet.SnippetToAST("entry", f.Source)
	if err != nil {
		return nil, err
	}
	edited := ast.Clone(original)
	replacement := f.Replacement
	if replacement == "" {
		replacement = "42"
	}
	n, err := jsonnet.SnippetToAST("entry", replacement)
	if err != nil {
		return nil, err
	}
	switch f.Op {
	case "array-first":
		a, ok := edited.(*ast.Array)
		if !ok || len(a.Elements) == 0 {
			return nil, fmt.Errorf("expected array")
		}
		a.Elements[0].Expr = n
	case "add":
		edited = &ast.Binary{Left: edited, Right: n, Op: ast.BopPlus}
	}
	evaluate := func(node ast.Node) (interface{}, error) {
		vm := jsonnet.MakeVM()
		switch f.Mode {
		case "stream":
			return vm.EvaluateStream(node)
		case "multi":
			return vm.EvaluateMulti(node)
		}
		output, err := vm.Evaluate(node)
		if err != nil {
			return nil, err
		}
		if f.Mode == "text" {
			return output, nil
		}
		var value interface{}
		err = json.Unmarshal([]byte(output), &value)
		return value, err
	}
	if f.Op == "ext" || f.Op == "tla" {
		vm := jsonnet.MakeVM()
		source := "std.extVar('x')"
		if f.Op == "ext" {
			vm.ExtNode("x", edited)
		} else {
			vm.TLANode("x", edited)
			source = "function(x) x"
		}
		output, err := vm.EvaluateAnonymousSnippet("entry", source)
		if err != nil {
			return nil, err
		}
		var value interface{}
		err = json.Unmarshal([]byte(output), &value)
		return value, err
	}
	before, err := evaluate(original)
	if err != nil {
		return nil, err
	}
	after, err := evaluate(edited)
	if err != nil {
		return nil, err
	}
	return []interface{}{before, after}, nil
}
func main() {
	var f fixture
	if err := json.NewDecoder(os.Stdin).Decode(&f); err != nil {
		panic(err)
	}
	result, err := run(f)
	diagnostic := ""
	if err != nil {
		diagnostic = jsonnet.MakeVM().ErrorFormatter.Format(err)
	}
	if err := json.NewEncoder(os.Stdout).Encode(map[string]interface{}{"result": result, "error": diagnostic, "requests": []string{}, "trace": "", "native_calls": 0}); err != nil {
		panic(err)
	}
}

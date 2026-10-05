// Development-only adapter for public AST cloning, edits and VM execution.
package main

import (
	"encoding/json"
	"fmt"
	jsonnet "github.com/google/go-jsonnet"
	"github.com/google/go-jsonnet/ast"
	"os"
	"strconv"
	"strings"
)

type fixture struct {
	Source, Replacement, Op, Mode string
	Paths                         []string
}

func rangeNode(node ast.Node, path string) ast.Node {
	if path == "" {
		return node
	}
	for _, part := range strings.Split(path, ".") {
		key, index, _ := strings.Cut(part, ":")
		n, _ := strconv.Atoi(index)
		switch v := node.(type) {
		case *ast.Binary:
			if key == "left" {
				node = v.Left
			} else {
				node = v.Right
			}
		case *ast.Conditional:
			switch key {
			case "cond":
				node = v.Cond
			case "then", "body":
				node = v.BranchTrue
			case "else":
				node = v.BranchFalse
			}
		case *ast.Local:
			if key == "body" {
				node = v.Body
			} else {
				node = v.Binds[n].Body
			}
		case *ast.Function:
			if key == "body" {
				node = v.Body
			} else {
				node = v.Parameters[n].DefaultArg
			}
		case *ast.Array:
			node = v.Elements[n].Expr
		case *ast.DesugaredObject:
			if key == "key" {
				node = v.Fields[n].Name
			} else {
				node = v.Fields[n].Body
			}
		case *ast.Apply:
			if key == "target" {
				node = v.Target
			} else {
				node = v.Arguments.Positional[n].Expr
			}
		case *ast.Index:
			if key == "target" {
				node = v.Target
			} else {
				node = v.Index
			}
		case *ast.Unary:
			node = v.Expr
		case *ast.Error:
			node = v.Expr
		default:
			panic("unsupported range path: " + path)
		}
	}
	return node
}

func run(f fixture) (interface{}, error) {
	original, err := jsonnet.SnippetToAST("entry", f.Source)
	if err != nil {
		return nil, err
	}
	edited := ast.Clone(original)
	if f.Op == "parameters" {
		result := []interface{}{}
		for _, path := range f.Paths {
			function, ok := rangeNode(edited, path).(*ast.Function)
			if !ok {
				return nil, fmt.Errorf("expected function")
			}
			rows := []interface{}{}
			for _, p := range function.Parameters {
				r := p.LocRange
				var loc interface{}
				if r.IsSet() {
					loc = []interface{}{r.Begin.Line, r.Begin.Column, r.End.Line, r.End.Column, r.String()}
				}
				rows = append(rows, []interface{}{string(p.Name), p.DefaultArg != nil, loc})
			}
			result = append(result, rows)
		}
		return result, nil
	}
	if f.Op == "bindings" {
		result := []interface{}{}
		for _, path := range f.Paths {
			var binds ast.LocalBinds
			switch n := rangeNode(edited, path).(type) {
			case *ast.Local:
				binds = n.Binds
			case *ast.DesugaredObject:
				binds = n.Locals
			default:
				return nil, fmt.Errorf("expected local bindings")
			}
			rows := []interface{}{}
			for _, b := range binds {
				if b.Variable == "$" {
					continue
				}
				r := b.LocRange
				var loc interface{}
				if r.IsSet() {
					loc = []interface{}{r.Begin.Line, r.Begin.Column, r.End.Line, r.End.Column, r.String()}
				}
				rows = append(rows, []interface{}{string(b.Variable), loc})
			}
			result = append(result, rows)
		}
		return result, nil
	}
	if f.Op == "numbers" {
		result := []string{}
		for _, path := range f.Paths {
			result = append(result, rangeNode(edited, path).(*ast.LiteralNumber).OriginalString)
		}
		return result, nil
	}
	if f.Op == "ranges" {
		result := []interface{}{}
		for _, path := range f.Paths {
			r := rangeNode(edited, path).Loc()
			if !r.IsSet() {
				result = append(result, nil)
			} else {
				result = append(result, []interface{}{r.Begin.Line, r.Begin.Column, r.End.Line, r.End.Column, r.String()})
			}
		}
		return result, nil
	}
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

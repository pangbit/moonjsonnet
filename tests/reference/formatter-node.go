// Development-only raw AST mutation adapter for pinned go-jsonnet v0.21.0.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/google/go-jsonnet/ast"
	"github.com/google/go-jsonnet/formatter"
)

func main() {
	var input struct {
		Source, Mode string
		Style        int
	}
	if err := json.NewDecoder(os.Stdin).Decode(&input); err != nil {
		panic(err)
	}
	node, final, err := formatter.SnippetToRawAST("entry", input.Source)
	if err != nil {
		panic(err)
	}
	switch input.Mode {
	case "number":
		switch n := node.(type) {
		case *ast.LiteralNumber:
			n.OriginalString = "42"
		case *ast.Array:
			n.Elements[0].Expr.(*ast.LiteralNumber).OriginalString = "42"
		default:
			panic("number node")
		}
	case "string":
		node.(*ast.LiteralString).Value = "中\\n"
	case "append":
		n := node.(*ast.Array)
		n.Elements = append(n.Elements, ast.CommaSeparatedExpr{Expr: &ast.LiteralNumber{OriginalString: "3"}})
	case "remove":
		n := node.(*ast.Array)
		n.Elements = n.Elements[1:]
	case "rename":
		n := node.(*ast.Local)
		n.Binds[0].Variable = "b"
		n.Body.(*ast.Local).Body.(*ast.Array).Elements[0].Expr.(*ast.Var).Id = "b"
	case "comments":
		for i := range *node.OpenFodder() {
			for j, text := range (*node.OpenFodder())[i].Comment {
				(*node.OpenFodder())[i].Comment[j] = strings.ReplaceAll(text, "head", "added")
			}
		}
		for i := range final {
			for j, text := range final[i].Comment {
				final[i].Comment[j] = strings.ReplaceAll(text, "tail", "changed")
			}
		}
	default:
		panic("mutation")
	}
	options := formatter.DefaultOptions()
	switch input.Style {
	case 1:
		options.StringStyle = formatter.StringStyleDouble
	case 2:
		options.Indent = 4
	case 3:
		options.PrettyFieldNames = false
	case 4:
		options.PadArrays = true
	case 5:
		options.StripComments = true
	case 6:
		options.StripEverything = true
	case 7:
		options.SortImports = false
	}
	result, err := formatter.FormatNode(node, final, options)
	message := ""
	valid, idempotent := false, false
	if err != nil {
		message = err.Error()
	} else {
		again, nextErr := formatter.Format("entry", result, options)
		valid = nextErr == nil
		idempotent = valid && again == result
	}
	output, err := json.Marshal(map[string]any{"result": result, "error": message, "valid": valid, "idempotent": idempotent})
	if err != nil {
		panic(err)
	}
	fmt.Println(string(output))
}

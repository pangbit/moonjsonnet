// Development-only adapter for the pinned go-jsonnet formatter.
package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/google/go-jsonnet/formatter"
)

func main() {
	var input struct {
		Source  string
		Options json.RawMessage
	}
	if err := json.NewDecoder(os.Stdin).Decode(&input); err != nil {
		panic(err)
	}
	options := formatter.DefaultOptions()
	if len(input.Options) > 0 {
		if err := json.Unmarshal(input.Options, &options); err != nil {
			panic(err)
		}
	}
	result, err := formatter.Format("entry", input.Source, options)
	message := ""
	if err != nil {
		message = err.Error()
	}
	valid, idempotent := false, false
	if err == nil {
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

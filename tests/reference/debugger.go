// Development-only adapter for the pinned public Go debugger API.
package main

import (
	"encoding/json"
	"fmt"
	jsonnet "github.com/google/go-jsonnet"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

func main() {
	var input struct {
		Source            string
		Line, Column      int
		Lookups, Commands []string
		Locations         bool
	}
	if err := json.NewDecoder(os.Stdin).Decode(&input); err != nil {
		panic(err)
	}
	if input.Line == 0 {
		input.Line = 1
	}
	if input.Column == 0 {
		input.Column = 1
	}
	work, err := os.MkdirTemp("", "moonjsonnet-go-debugger-")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(work)
	file := filepath.Join(work, "entry")
	if err = os.WriteFile(file, []byte(input.Source), 0600); err != nil {
		panic(err)
	}
	debugger := jsonnet.MakeDebugger()
	_, err = debugger.SetBreakpoint(file, input.Line, input.Column)
	set := err == nil
	stops := []any{}
	diagnostics := []string{}
	commandIndex := 0
	debugger.Launch(file, input.Source, nil)
	output := ""
	failed := false
events:
	for event := range debugger.Events() {
		switch event := event.(type) {
		case *jsonnet.DebugEventStop:
			if len(stops) >= 100 {
				panic("too many debugger stops")
			}
			loc := event.Current.Loc()
			values := map[string]any{}
			for _, name := range input.Lookups {
				text, err := debugger.LookupValue(name)
				if err != nil {
					values[name] = map[string]any{"error": true}
					continue
				}
				var value any
				if err = json.Unmarshal([]byte(text), &value); err == nil {
					values[name] = value
				} else if n, err := strconv.ParseFloat(text, 64); err == nil {
					values[name] = n
				} else if strings.HasPrefix(text, "*jsonnet.valueNull") {
					values[name] = nil
				} else {
					values[name] = text
				}
			}
			vars := []string{}
			for _, name := range debugger.ListVars() {
				vars = append(vars, string(name))
			}
			sort.Strings(vars)
			reason := []string{"step", "breakpoint", "exception"}[int(event.Reason)]
			if event.Error != nil {
				diagnostics = append(diagnostics, strings.ReplaceAll(event.ErrorFmt(), file, "entry"))
			}
			stops = append(stops, map[string]any{"reason": reason, "range": []int{loc.Begin.Line, loc.Begin.Column, loc.End.Line, loc.End.Column}, "variables": vars, "values": values})
			command := "continue"
			if commandIndex < len(input.Commands) {
				command = input.Commands[commandIndex]
			}
			commandIndex++
			switch command {
			case "step":
				debugger.Step()
			case "finish":
				debugger.ContinueUntilAfter(event.Current)
			case "terminate":
				debugger.Terminate()
			default:
				debugger.Continue()
			}
		case *jsonnet.DebugEventExit:
			output = event.Output
			failed = event.Error != nil
			if event.Error != nil {
				diagnostics = append(diagnostics, strings.ReplaceAll(event.Error.Error(), file, "entry"))
			}
			break events
		}
	}
	active := len(debugger.ActiveBreakpoints())
	debugger.ClearBreakpoints(file)
	result := map[string]any{"output": output, "error": failed, "stops": stops, "set": set, "active": active, "cleared": len(debugger.ActiveBreakpoints())}
	if input.Locations {
		ranges, err := debugger.BreakpointLocations(file)
		if err != nil {
			panic(err)
		}
		locations := [][]int{}
		for _, loc := range ranges {
			locations = append(locations, []int{loc.Begin.Line, loc.Begin.Column, loc.End.Line, loc.End.Column})
		}
		result["locations"] = locations
	}
	bytes, err := json.Marshal(map[string]any{"result": result, "diagnostics": diagnostics})
	if err != nil {
		panic(err)
	}
	fmt.Println(string(bytes))
}

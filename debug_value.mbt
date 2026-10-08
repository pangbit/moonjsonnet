///|
/// Preview cached content without forcing child thunks, fields or assertions.
/// Unevaluated/busy/failed thunks are explicit placeholders. Recursive/cyclic
/// values and large previews obey execution step/depth and output-byte limits.
pub fn DebugValue::display(self : DebugValue) -> String raise JsonnetError {
  self.check()
  let writer : FormatOutput = {
    out: StringBuilder(),
    bytes: 0,
    steps: 0,
    line_start: true,
    column: 0,
    limits: self.vm.limits,
    loc: self.location,
  }
  self.vm.debug_display(self.value, writer, 0) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, self.location, e.to_string())
  }
  writer.out.to_string()
}

///|
fn Vm::debug_thunk(
  self : Vm,
  id : Int,
  writer : FormatOutput,
  depth : Int,
) -> Unit raise {
  self.tick(writer.loc)
  match self.thunks[id] {
    Ready(value) => self.debug_display(value, writer, depth)
    Busy | Running(_) | RunningParameter(_, _) => writer.write("<evaluating>")
    Failed(_) => writer.write("<failed>")
    _ => writer.write("<unevaluated>")
  }
}

///|
fn Vm::debug_display(
  self : Vm,
  value : Value,
  writer : FormatOutput,
  depth : Int,
) -> Unit raise {
  self.tick(writer.loc)
  if depth >= self.limits.depth {
    raise problem(Limit, writer.loc, "debug preview depth limit exceeded")
  }
  match value {
    Nil => writer.write("null")
    Bool(value) => writer.write(if value { "true" } else { "false" })
    Num(value) => writer.write(manifest_number(value))
    Str(value) => writer.write(Json::string(value).stringify())
    ArrayValue(items) => {
      writer.write("[")
      for i, id in items {
        if i > 0 {
          writer.write(", ")
        }
        self.debug_thunk(id, writer, depth + 1)
      }
      writer.write("]")
    }
    ObjectValue(id, top) => {
      let object = self.objects[id]
      writer.write("{")
      let mut first = true
      for name in self.keys(id, top, false) {
        self.tick(writer.loc)
        let mut layer = top - 1
        while layer >= 0 && !object.layers[layer].fields.contains(name) {
          layer -= 1
        }
        if object.cache.get((layer, name)) is Some(thunk) {
          if !first {
            writer.write(", ")
          }
          first = false
          writer.write(Json::string(name).stringify() + ": ")
          self.debug_thunk(thunk, writer, depth + 1)
        }
      }
      writer.write("}")
    }
    Closure(params, _, _) =>
      writer.write("function(" + params.map(p => p.name).join(", ") + ")")
    Builtin(name) =>
      writer.write("function(" + builtin_params(name).join(", ") + ")")
    Native(native) => writer.write("function(" + native.params.join(", ") + ")")
  }
}

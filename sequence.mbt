///|
// Source std.map and std.slice defer the indexing expression itself. Capturing
// the current thunk would miss a subsequent removeAt mutation of the array.
fn Vm::defer_index(
  self : Vm,
  value : Value,
  index : Double,
  loc : Location,
) -> Int {
  let env : Env = {
    parent: None,
    names: Map([("a", self.store(Ready(value)))]),
    import_from: "",
    debug_visible: None,
    diagnostic_context: ("$", "anonymous"),
  }
  self.store(
    Pending(
      {
        kind: Index({ kind: Var("a"), loc, end: None, }, {
          kind: Literal(Json::number(index)),
          loc,
          end: None,
        }),
        loc,
        end: None,
      },
      env,
    ),
  )
}

///|
fn Vm::sequence(self : Vm, value : Value, loc : Location) -> Array[Int] raise {
  match value {
    ArrayValue(a) => a
    Str(s) =>
      s
      .to_array()
      .map(c => {
        self.tick(loc)
        self.store(Ready(Str(c.to_string())))
      })
    _ => raise problem(Type, loc, "expected array or string")
  }
}

///|
fn Vm::flat_map(
  self : Vm,
  func : Value,
  input : Value,
  loc : Location,
) -> Value raise {
  if value_type(func) != "function" {
    raise problem(Type, loc, "expected function")
  }
  match input {
    ArrayValue(items) => {
      let out = []
      for t in items {
        self.tick(loc)
        let returned = array_value(self.call(func, [(None, t)], loc), loc)
        for element in returned {
          self.tick(loc)
          out.push(element)
        }
      }
      ArrayValue(out)
    }
    Str(s) => {
      let out = StringBuilder()
      let mut bytes = 0
      for c in s.iter() {
        self.tick(loc)
        let t = self.store(Ready(Str(c.to_string())))
        let returned = text_value(self.call(func, [(None, t)], loc), loc)
        let size = @utf8.encode(returned).length()
        if size > self.limits.output_bytes - bytes {
          raise problem(Limit, loc, "flatMap string exceeds output limit")
        }
        bytes += size
        out.write_string(returned)
      }
      Str(out.to_string())
    }
    _ => raise problem(Type, loc, "expected array or string")
  }
}

///|
// Array generators defer both the call and its arguments until an element is used.
fn Vm::defer_call(
  self : Vm,
  func : Value,
  args : Array[Int],
  loc : Location,
) -> Int {
  self.store(GeneratedCall(func, args, loc))
}

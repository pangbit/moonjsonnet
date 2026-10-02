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
  let names = Map([("f", self.store(Ready(func)))])
  let params = []
  for i, t in args {
    let name = i.to_string()
    names[name] = t
    params.push((None, { kind: Var(name), loc, }))
  }
  self.store(
    Pending({ kind: Call({ kind: Var("f"), loc, }, params, false), loc, }, {
      parent: None,
      names,
    }),
  )
}

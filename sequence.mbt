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

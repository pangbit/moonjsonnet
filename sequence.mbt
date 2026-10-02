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

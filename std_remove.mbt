///|
fn Vm::remove_at(
  self : Vm,
  items : Array[Int32],
  index : Int32,
  loc : Location,
) -> Value raise {
  if index < 0 || index >= items.length() {
    raise problem(Runtime, loc, "removeAt index out of bounds")
  }
  // Copy thunk references without forcing payloads or changing the input.
  let out = []
  for i, item in items {
    self.tick(loc)
    if i != index {
      out.push(item)
    }
  }
  ArrayValue(out)
}

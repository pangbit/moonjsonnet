///|
fn Vm::remove_at(
  self : Vm,
  items : Array[Int],
  index : Int,
  loc : Location,
) -> Value raise {
  if index < 0 || index >= items.length() {
    raise problem(Runtime, loc, "removeAt index out of bounds")
  }
  // Go append shifts the original slice, then makeValueArray copies the
  // shorter result to exact capacity. Keep the old length and trailing slot.
  for i in index..<(items.length() - 1) {
    self.tick(loc)
    items[i] = items[i + 1]
  }
  ArrayValue(items[:items.length() - 1].to_owned())
}

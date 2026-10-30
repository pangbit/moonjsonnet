///|
fn Vm::membership(
  self : Vm,
  input : Value,
  target_thunk : Int32,
  short_circuit : Bool,
  loc : Location,
) -> Value raise {
  if !short_circuit && input is Str(text) {
    let pattern = text_value(self.force(target_thunk, loc), loc)
    // Fixed member uses findSubstr, whose empty-pattern result is empty.
    return Bool(!pattern.is_empty() && text.contains(pattern))
  }
  let items = array_value(input, loc)
  // Neither count nor any needs an equality target for an empty Array.
  if items.is_empty() {
    return Bool(false)
  }
  let target = self.force(target_thunk, loc)
  let mut found = false
  for item in items {
    self.tick(loc)
    if self.equal(self.force(item, loc), target, loc) {
      found = true
      // contains uses any; member uses count and must visit later entries.
      if short_circuit {
        break
      }
    }
  }
  Bool(found)
}

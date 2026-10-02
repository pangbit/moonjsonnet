///|
fn Vm::extreme_value(
  self : Vm,
  input : Value,
  key : Value?,
  on_empty : Value?,
  maximum : Bool,
  loc : Location,
) -> Value raise {
  let items = array_value(input, loc)
  if key is Some(f) && value_type(f) != "function" {
    raise problem(Type, loc, "keyF must be a function")
  }
  if items.is_empty() {
    return match on_empty {
      Some(v) => v
      None => raise problem(Runtime, loc, "expected at least one array element")
    }
  }
  // Go forces each element and computes its key once, even when keyF ignores it.
  let mut selected = self.force(items[0], loc)
  let mut selected_key = match key {
    None => selected
    Some(f) => self.call(f, [(None, items[0])], loc)
  }
  for i in 1..<items.length() {
    self.tick(loc)
    let current = self.force(items[i], loc)
    let current_key = match key {
      None => current
      Some(f) => self.call(f, [(None, items[i])], loc)
    }
    if boolean(
        self.binary(
          if maximum {
            "<"
          } else {
            ">"
          },
          selected_key,
          current_key,
          loc,
        ),
        loc,
      ) {
      selected = current
      selected_key = current_key
    }
  }
  selected
}

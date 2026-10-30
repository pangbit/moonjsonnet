///|
fn Vm::extreme_value(
  self : Vm,
  input : Value,
  key_thunk : Int32?,
  on_empty : Int32?,
  maximum : Bool,
  loc : Location,
) -> Value raise {
  let items = array_value(input, loc)
  if items.is_empty() {
    return match on_empty {
      Some(t) => self.force(t, loc)
      None =>
        raise problem(
          Runtime,
          loc,
          "Expected at least one element in array. Got none",
        )
    }
  }
  let key = key_thunk.map(t => self.force(t, loc))
  if key is Some(f) && value_type(f) != "function" {
    raise problem(
      Type,
      loc,
      "Unexpected type " + value_type(f) + ", expected function",
    )
  }
  let mut selected_key = match key {
    None => self.force(items[0], loc)
    Some(f) => self.call(f, [(None, items[0])], loc)
  }
  // The source fold starts at zero, so even a singleton key is compared.
  // Its condition must succeed before demanding the selected item.
  ignore(self.compare_values(selected_key, selected_key, loc))
  let mut selected = self.force(items[0], loc)
  for i in 1..<items.length() {
    self.tick(loc)
    // An explicit key can leave an unselected element's payload unevaluated.
    let current_key = match key {
      None => self.force(items[i], loc)
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
      selected = self.force(items[i], loc)
      selected_key = current_key
    }
  }
  selected
}

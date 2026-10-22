///|
fn Vm::slice(
  self : Vm,
  value : Value,
  start : Value,
  end : Value,
  step : Value,
  loc : Location,
) -> Value raise {
  let items = self.sequence(value, loc)
  let length = items.length().to_double()
  let mut index = match start {
    Nil => 0.0
    _ => number_value(start, loc)
  }
  if index < 0 {
    index = Double::max(0, number_value(finite(length + index, loc), loc))
  }
  let mut stop = match end {
    Nil => length
    _ => number_value(end, loc)
  }
  if stop < 0 {
    stop = number_value(finite(stop + length, loc), loc)
  }
  let stride = match step {
    Nil => 1.0
    _ => number_value(step, loc)
  }
  if stride <= 0 {
    raise problem(Assertion, loc, "slice step must be positive")
  }
  let out = []
  while index < stop && index < length {
    self.tick(loc)
    out.push(
      if value is ArrayValue(_) {
        // Array elements, including index validation, remain deferred.
        self.defer_index(value, index, loc)
      } else {
        items[array_index(Num(index), items.length(), loc)]
      },
    )
    index = number_value(finite(index + stride, loc), loc)
  }
  if value is Str(_) {
    let b = StringBuilder()
    for t in out {
      b.write_string(text_value(self.force(t, loc), loc))
    }
    Str(b.to_string())
  } else {
    ArrayValue(out)
  }
}

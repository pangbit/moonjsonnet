///|
fn Vm::sort_values(
  self : Vm,
  input : Value,
  key : Int?,
  loc : Location,
) -> Value raise {
  // The fixed source returns these Arrays before using any key or element.
  if input is ArrayValue(items) && items.length() <= 1 {
    return input
  }
  let items = match input {
    ArrayValue(items) => items
    _ => {
      // The source definition first asks for length, without an Array guard.
      let size = integer(
        self.builtin("length", [(None, self.store(Ready(input)))], loc),
        loc,
      )
      if size <= 1 {
        return input
      }
      // Its long branch slices the input before sorting either half.
      if size > 30 && !(input is Str(_)) {
        raise problem(
          Assertion,
          loc,
          "std.slice accepts a string or an array, but got: " +
          value_type(input),
        )
      }
      if input is Str(_) {
        // Strings are strict; materialize codepoints once instead of rescanning
        // the complete String for each deferred index.
        self.sequence(input, loc)
      } else {
        let items = []
        for i in 0..<size {
          self.tick(loc)
          items.push(self.defer_index(input, i.to_double(), loc))
        }
        items
      }
    }
  }
  let key_value = key.map(t => self.force(t, loc))
  if key_value is Some(f) && value_type(f) != "function" {
    raise problem(
      Type,
      loc,
      "Unexpected type " + value_type(f) + ", expected function",
    )
  }
  // Cache keys once; retain original thunks so unused payloads remain lazy.
  let mut source = items.map(t => {
    self.tick(loc)
    let value = match key_value {
      None => self.force(t, loc)
      Some(f) => self.call(f, [(None, t)], loc)
    }
    (t, value)
  })
  let n = source.length()
  let mut target = source.copy()
  let mut width = 1
  while width < n {
    let mut start = 0
    while start < n {
      let middle = start + Int::min(width, n - start)
      let end = middle + Int::min(width, n - middle)
      let mut left = start
      let mut right = middle
      for out in start..<end {
        self.tick(loc)
        // Take the left item on equal keys, preserving input order.
        if left < middle &&
          (
            right == end ||
            !boolean(
              self.binary("<", source[right].1, source[left].1, loc),
              loc,
            )
          ) {
          target[out] = source[left]
          left += 1
        } else {
          target[out] = source[right]
          right += 1
        }
      }
      start = end
    }
    let previous = source
    source = target
    target = previous
    if width >= n - width {
      break
    }
    width *= 2
  }
  ArrayValue(source.map(item => item.0))
}

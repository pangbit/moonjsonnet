///|
fn Vm::sort_values(
  self : Vm,
  input : Value,
  key : Value?,
  loc : Location,
) -> Value raise {
  let items = array_value(input, loc)
  if key is Some(f) && value_type(f) != "function" {
    raise problem(
      Type,
      loc,
      "Unexpected type " + value_type(f) + ", expected function",
    )
  }
  // Cache keys once; retain original thunks so unused payloads remain lazy.
  let mut source = items.map(t => {
    self.tick(loc)
    let value = match key {
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

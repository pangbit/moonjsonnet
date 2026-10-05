///|
priv struct LintArrayType {
  elements : Array[Array[Int]]
  further : Array[Int]
}

///|
priv struct LintObjectType {
  fields : Map[String, Array[Int]]
  unknown : Array[Int]
  mut known : Bool
}

///|
priv struct LintFunctionType {
  results : Array[Int]
  mut params : Array[(String, Bool)]?
  mut min : Int
  mut max : Int
}

///|
priv struct LintType {
  // bool=1, number=2, string=4, null=8
  mut mask : Int
  mut array : LintArrayType?
  mut object : LintObjectType?
  mut func : LintFunctionType?
}

///|
fn LintType::empty() -> LintType {
  { mask: 0, array: None, object: None, func: None, }
}

///|
fn lint_refs(refs : Array[Int]) -> Array[Int] {
  if refs.contains(1) {
    return [1]
  }
  let result = refs.copy()
  result.sort()
  let out = []
  for id in result {
    if out.last() != Some(id) {
      out.push(id)
    }
  }
  out
}

///|
fn LintType::widen(self : LintType, other : LintType) -> Unit {
  self.mask = self.mask | other.mask
  if other.array is Some(b) {
    match self.array {
      None =>
        self.array = Some({
          elements: b.elements.map(e => e.copy()),
          further: b.further.copy(),
        })
      Some(a) => {
        for i, e in b.elements {
          if a.elements.length() <= i {
            a.elements.push(a.further.copy())
          }
          a.elements[i].append(e)
        }
        for i = b.elements.length(); i < a.elements.length(); i = i + 1 {
          a.elements[i].append(b.further)
        }
        a.further.append(b.further)
      }
    }
  }
  if other.object is Some(b) {
    match self.object {
      None =>
        self.object = Some({
          fields: b.fields.map((_, v) => v.copy()),
          unknown: b.unknown.copy(),
          known: b.known,
        })
      Some(a) => {
        a.unknown.append(b.unknown)
        for k, v in b.fields {
          a.fields.get_or_init(k, () => []).append(v)
        }
        if !b.known {
          for k, v in a.fields {
            if !b.fields.contains(k) {
              v.append(b.unknown)
            }
          }
          a.known = false
        }
      }
    }
  }
  if other.func is Some(b) {
    match self.func {
      None =>
        self.func = Some({
          results: b.results.copy(),
          params: b.params.map(ps => ps.copy()),
          min: b.min,
          max: b.max,
        })
      Some(a) => {
        if b.min < a.min {
          a.min = b.min
        }
        if b.max > a.max {
          a.max = b.max
        }
        if a.params is None || b.params is None || a.params != b.params {
          a.params = None
        }
        a.results.append(b.results)
      }
    }
  }
}

///|
fn LintType::normalize(self : LintType) -> Unit {
  if self.array is Some(a) {
    for i, e in a.elements {
      a.elements[i] = lint_refs(e)
    }
    let refs = lint_refs(a.further)
    a.further.clear()
    a.further.append(refs)
  }
  if self.object is Some(o) {
    for k, v in o.fields {
      o.fields[k] = lint_refs(v)
    }
    let refs = lint_refs(o.unknown)
    o.unknown.clear()
    o.unknown.append(refs)
  }
  if self.func is Some(f) {
    let refs = lint_refs(f.results)
    f.results.clear()
    f.results.append(refs)
  }
}

///|
fn LintType::describe(self : LintType) -> String {
  let parts = []
  for
    (bit, name) in [
      (1, "a bool"),
      (2, "a number"),
      (4, "a string"),
      (8, "a null"),
    ] {
    if (self.mask & bit) != 0 {
      parts.push(name)
    }
  }
  if self.func is Some(_) {
    parts.push("a function")
  }
  if self.object is Some(_) {
    parts.push("an object")
  }
  if self.array is Some(_) {
    parts.push("an array")
  }
  if parts.is_empty() {
    "void"
  } else {
    parts.join(" or ")
  }
}

///|
fn lint_plus(a : LintType, b : LintType) -> LintType {
  let t = LintType::empty()
  t.mask = (a.mask & b.mask & 3) | ((a.mask | b.mask) & 4)
  if a.array is Some(a) && b.array is Some(b) {
    let further = a.further.copy()
    for e in b.elements {
      further.append(e)
    }
    further.append(b.further)
    t.array = Some({ elements: a.elements.map(e => e.copy()), further, })
  }
  if a.object is Some(a) && b.object is Some(b) {
    let fields : Map[String, Array[Int]] = Map([])
    for k, v in a.fields {
      fields[k] = v.copy()
      if !b.known && !b.fields.contains(k) {
        fields[k].append(b.unknown)
      }
    }
    for k, v in b.fields {
      fields[k] = v.copy()
      if !a.known && !a.fields.contains(k) {
        fields[k].append(a.unknown)
      }
    }
    let unknown = a.unknown.copy()
    unknown.append(b.unknown)
    t.object = Some({ fields, unknown, known: a.known && b.known, })
  }
  t
}

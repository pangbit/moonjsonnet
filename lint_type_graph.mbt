// Portions adapted from google/go-jsonnet v0.21.0 (Apache-2.0).
// https://github.com/google/go-jsonnet/tree/67968688d9952f50662e979fab1bef889d0d3e57
// Source: linter/internal/types/graph.go
// Source: linter/internal/types/placeholder.go
// Source: linter/internal/types/process_graph.go
// Upstream attribution: Google Inc. (see NOTICE).
// Modifications: Ported type-graph propagation to bounded MoonBit data structures.
// License and retained attribution: LICENSE and NOTICE at the module root.

///|
priv enum LintIndex {
  AnyIndex
  IntIndex(Int)
  StringIndex(String)
  ResultIndex
} derive(Eq, Hash)

///|
priv struct LintSlot {
  mut concrete : LintType
  mut refs : Array[Int]
  mut index : (Int, LintIndex)?
  mut plus : (Int, Int)?
}

///|
priv struct LintTyped {
  expression : Expr
  id : Int
  children : Array[LintTyped]
}

///|
priv struct LintGraph {
  scan : LintScan
  slots : Array[LintSlot]
  elements : Map[(Int, LintIndex), Int]
  bounds : Array[LintType]
  roots : Map[String, Int]
  imports : Map[(String, String), String]
}

///|
fn LintGraph::add(self : LintGraph, t? : LintType = LintType::empty()) -> Int {
  let id = self.slots.length()
  self.slots.push({ concrete: t, refs: [], index: None, plus: None, })
  id
}

///|
fn LintGraph::function(
  self : LintGraph,
  result : Int,
  params : Array[(String, Bool)],
  simple : Bool,
) -> Int {
  let t = LintType::empty()
  // Fixed Go countRequiredParameters counts defaults; retain its actual rule.
  t.func = Some({
    results: [result],
    params: Some(params),
    min: if simple {
      params.length()
    } else {
      params.filter(p => p.1).length()
    },
    max: params.length(),
  })
  self.add(t~)
}

///|
fn LintGraph::new(
  scan : LintScan,
  imports : Map[(String, String), String],
) -> LintGraph {
  let g : LintGraph = {
    scan,
    slots: [],
    elements: Map([]),
    bounds: [],
    roots: Map([]),
    imports,
  }
  for _ in 0..<12 {
    ignore(g.add())
  }
  let any_array : LintArrayType = { elements: [], further: [1], }
  let any_object : LintObjectType = {
    fields: Map([]),
    unknown: [1],
    known: false,
  }
  let any_func : LintFunctionType = {
    results: [1],
    params: None,
    min: 0,
    max: 2147483647,
  }
  g.slots[1].concrete = {
    mask: 15,
    array: Some(any_array),
    object: Some(any_object),
    func: Some(any_func),
  }
  for (id, mask) in [(2, 1), (3, 2), (4, 4), (5, 8)] {
    g.slots[id].concrete.mask = mask
  }
  g.slots[6].concrete.array = Some(any_array)
  g.slots[7].concrete.array = Some({ elements: [], further: [3], })
  g.slots[8].concrete.array = Some({ elements: [], further: [2], })
  g.slots[9].concrete.object = Some(any_object)
  g.slots[10].concrete.func = Some(any_func)
  g.stdlib()
  g
}

///|
fn LintGraph::work(self : LintGraph, amount : Int) -> Unit raise JsonnetError {
  if amount > self.scan.limits.steps - self.scan.steps {
    raise problem(
      Limit,
      { file: "<lint>", line: 1, column: 1, },
      "lint type graph limit exceeded",
    )
  }
  self.scan.steps += amount
}

///|
fn LintGraph::element(
  self : LintGraph,
  container : Int,
  index : LintIndex,
  depth : Int,
) -> Int raise JsonnetError {
  if self.elements.get((container, index)) is Some(id) {
    return id
  }
  let loc : Location = { file: "<lint>", line: 1, column: 1, }
  if depth >= self.scan.limits.depth {
    raise problem(Limit, loc, "lint type index depth exceeded")
  }
  self.work(1)
  let id = self.add()
  self.elements[(container, index)] = id
  let slot = self.slots[container]
  let t = slot.concrete
  let refs = []
  match index {
    StringIndex(key) =>
      if t.object is Some(o) {
        if o.fields.get(key) is Some(v) {
          refs.append(v)
        } else if !o.known {
          refs.append(o.unknown)
        }
      }
    IntIndex(i) => {
      if t.array is Some(a) {
        refs.append(a.elements.get(i).unwrap_or(a.further))
      }
      if (t.mask & 4) != 0 {
        refs.push(4)
      }
    }
    ResultIndex => if t.func is Some(f) { refs.append(f.results) }
    AnyIndex => {
      if t.object is Some(o) {
        refs.append(o.unknown)
        for _, v in o.fields {
          refs.append(v)
        }
      }
      if t.array is Some(a) {
        for v in a.elements {
          refs.append(v)
        }
        refs.append(a.further)
      }
      if (t.mask & 4) != 0 {
        refs.push(4)
      }
    }
  }
  if slot.index is Some((target, key)) {
    let inner = self.element(target, key, depth + 1)
    refs.push(self.element(inner, index, depth + 1))
  }
  for child in slot.refs {
    refs.push(self.element(child, index, depth + 1))
  }
  if slot.plus is Some((a, b)) {
    refs.push(self.element(a, index, depth + 1))
    refs.push(self.element(b, index, depth + 1))
  }
  let refs = lint_refs(refs)
  self.slots[id].refs = refs
  if refs.length() == 1 {
    self.elements[(container, index)] = refs[0]
    refs[0]
  } else {
    id
  }
}

///|
fn LintGraph::solve(self : LintGraph) -> Unit raise JsonnetError {
  self.work(self.slots.length())
  // Match reference alias compression before separating container element types.
  let mapping = self.slots.mapi((i, s) => {
    if s.concrete.mask == 0 &&
      s.concrete.array is None &&
      s.concrete.object is None &&
      s.concrete.func is None &&
      s.index is None &&
      s.plus is None &&
      s.refs.length() == 1 {
      s.refs[0]
    } else {
      i
    }
  })
  for i in 0..<mapping.length() {
    if mapping[mapping[i]] != mapping[i] {
      mapping[i] = mapping[mapping[i]]
    }
  }
  for s in self.slots {
    self.work(1 + s.refs.length())
    s.refs = s.refs.map(id => mapping[id])
    if s.index is Some((id, key)) {
      s.index = Some((mapping[id], key))
    }
  }
  let count = self.slots.length()
  for i in 0..<count {
    self.work(1)
    if self.slots[i].index is Some((target, key)) {
      let id = self.element(target, key, 0)
      self.slots[i].index = None
      self.slots[i].refs.push(id)
    }
  }
  let edges = self.slots.map(s => {
    let refs = s.refs.copy()
    if s.plus is Some((a, b)) {
      refs.push(a)
      refs.push(b)
    }
    refs
  })
  let n = edges.length()
  let seen = Array::make(n, false)
  let order = []
  for start in 0..<n {
    if seen[start] {
      continue
    }
    let stack = [(start, false)]
    while stack.pop() is Some((id, exit)) {
      if exit {
        order.push(id)
        continue
      }
      if seen[id] {
        continue
      }
      seen[id] = true
      self.work(1 + edges[id].length())
      stack.push((id, true))
      for child in edges[id] {
        if !seen[child] {
          stack.push((child, false))
        }
      }
    }
  }
  let reverse : Array[Array[Int]] = Array::makei(n, _ => [])
  for id, children in edges {
    self.work(1 + children.length())
    for child in children {
      reverse[child].push(id)
    }
  }
  let group = Array::make(n, -1)
  let groups : Array[Array[Int]] = []
  for i = order.length() - 1; i >= 0; i = i - 1 {
    let start = order[i]
    if group[start] >= 0 {
      continue
    }
    let component = groups.length()
    let members = []
    let stack = [start]
    while stack.pop() is Some(id) {
      if group[id] >= 0 {
        continue
      }
      group[id] = component
      self.work(1 + reverse[id].length())
      members.push(id)
      for parent in reverse[id] {
        if group[parent] < 0 {
          stack.push(parent)
        }
      }
    }
    groups.push(members)
  }
  for _ in 0..<n {
    self.bounds.push(LintType::empty())
  }
  for i = groups.length() - 1; i >= 0; i = i - 1 {
    let t = LintType::empty()
    for id in groups[i] {
      let slot = self.slots[id]
      self.work(1 + slot.refs.length())
      for child in slot.refs {
        if group[child] != i {
          t.widen(self.bounds[child])
        }
      }
      if slot.plus is Some((a, b)) {
        if group[a] != i && group[b] != i {
          t.widen(lint_plus(self.bounds[a], self.bounds[b]))
        }
        if group[a] != i {
          t.widen(self.bounds[a])
        }
        if group[b] != i {
          t.widen(self.bounds[b])
        }
      }
    }
    for id in groups[i] {
      t.widen(self.slots[id].concrete)
    }
    t.normalize()
    for id in groups[i] {
      self.bounds[id] = t
    }
  }
}

///|
priv struct LintBinding {
  name : String
  loc : Location
  warn : Bool
  mut used : Bool
}

///|
priv struct LintScan {
  limits : Limits
  mut steps : Int
  bindings : Array[LintBinding]
  diagnostics : Array[Diagnostic]
}

///|
fn LintScan::tick(self : LintScan, e : Expr) -> Unit raise JsonnetError {
  self.steps += 1
  if self.steps > self.limits.steps {
    raise problem(Limit, e.loc, "lint step limit exceeded")
  }
}

///|
fn LintScan::report(self : LintScan, loc : Location, message : String) -> Unit {
  self.diagnostics.push({ kind: Static, location: loc, message, context: [], })
}

///|
fn LintScan::bind(
  self : LintScan,
  scope : Map[String, Int],
  name : String,
  loc : Location,
  warn : Bool,
) -> Unit {
  scope[name] = self.bindings.length()
  self.bindings.push({ name, loc, warn, used: false, })
}

///|
fn LintScan::locals(
  self : LintScan,
  bs : Array[(String, Expr)],
  scope : Map[String, Int],
) -> Map[String, Int] raise JsonnetError {
  let inner = scope.copy()
  for (n, e) in bs {
    self.bind(inner, n, e.loc, true)
  }
  for (_, e) in bs {
    self.variables(e, inner)
  }
  inner
}

///|
fn LintScan::clauses(
  self : LintScan,
  cs : Array[Clause],
  scope : Map[String, Int],
) -> Map[String, Int] raise JsonnetError {
  let inner = scope.copy()
  for c in cs {
    match c {
      For(n, e) => {
        self.variables(e, inner)
        self.bind(inner, n, e.loc, false)
      }
      When(e) => self.variables(e, inner)
    }
  }
  inner
}

///|
fn LintScan::variables(
  self : LintScan,
  e : Expr,
  scope : Map[String, Int],
) -> Unit raise JsonnetError {
  self.tick(e)
  match e.kind {
    Var(n) => if scope.get(n) is Some(id) { self.bindings[id].used = true }
    Local(bs, body) => self.variables(body, self.locals(bs, scope))
    Func(ps, body) => {
      let inner = scope.copy()
      for (n, _) in ps {
        self.bind(inner, n, e.loc, false)
      }
      for (_, x) in ps {
        if x is Some(x) {
          self.variables(x, inner)
        }
      }
      self.variables(body, inner)
    }
    Obj(fs, bs, checks) => {
      let inner = self.locals(bs, scope)
      for (a, b) in checks {
        self.variables(a, inner)
        if b is Some(b) {
          self.variables(b, inner)
        }
      }
      for f in fs {
        self.variables(f.value, inner)
        self.variables(f.key, scope)
      }
    }
    ArrayComp(body, cs) => self.variables(body, self.clauses(cs, scope))
    ObjectComp(key, body, cs, bs) => {
      let outer = self.clauses(cs, scope)
      self.variables(key, outer)
      self.variables(body, self.locals(bs, outer))
    }
    _ =>
      for child in lint_children(e) {
        self.variables(child, scope)
      }
  }
}

///|
fn LintScan::looping(
  self : LintScan,
  e : Expr,
  vars : Map[String, Expr],
  runs : Map[String, Int],
  run : Int,
) -> Bool raise JsonnetError {
  let pending = [e]
  while pending.pop() is Some(e) {
    self.tick(e)
    if e.kind is Var(n) && vars.get(n) is Some(body) {
      match runs.get(n) {
        Some(first) =>
          if first == run {
            self.report(e.loc, "Endless loop in local definition")
            return true
          }
        None => {
          runs[n] = run
          pending.push(body)
          continue
        }
      }
    }
    let children = lint_children(e, direct=true)
    for i = children.length() - 1; i >= 0; i = i - 1 {
      pending.push(children[i])
    }
  }
  false
}

///|
fn LintScan::loops(self : LintScan, e : Expr) -> Unit raise JsonnetError {
  self.tick(e)
  if e.kind is Local(bs, _) {
    let vars = Map::from_array(bs)
    let runs = Map([])
    for i, (_, body) in bs {
      if self.looping(body, vars, runs, i) {
        break
      }
    }
  }
  for child in lint_children(e) {
    self.loops(child)
  }
}

///|
/// Check snippets without execution. Returns parse/static/import findings,
/// unused bindings, eager cycles, and conservative inferred-type findings for
/// calls, arguments, indexing and unary operators. No Jsonnet code is executed.
/// Imports are checked recursively, but only entry snippets receive lint checks.
/// Limits abort analysis with JsonnetError instead of returning a partial result.
///
/// ```mbt check
/// test {
///   let issues = @moonjsonnet.lint([{ id: "entry", text: "local unused=1;42", }])
///   assert_eq(issues[0].message, "Unused variable: unused")
/// }
/// ```
pub fn lint(
  snippets : Array[Source],
  resolver? : (String, String) -> BinarySource raise,
  limits? : Limits = Limits::default(),
) -> Array[Diagnostic] raise JsonnetError {
  let loc : Location = { file: "<lint>", line: 1, column: 1, }
  check_limits(limits, loc)
  let scan : LintScan = { limits, steps: 0, bindings: [], diagnostics: [], }
  let entries : Array[(String, Expr)] = []
  let roots : Map[String, Expr] = Map([])
  let imported : Map[(String, String), String] = Map([])
  for source in snippets {
    try {
      let program = Program::parse(source.text, filename=source.id, limits~)
      entries.push((source.id, program.expression))
      roots[source.id] = program.expression
    } catch {
      Error(d) =>
        if d.kind == Limit {
          raise Error(d)
        } else {
          scan.diagnostics.push(d)
        }
    }
  }
  let evaluator = Evaluator::new()
  evaluator.set_limits(limits)
  evaluator.set_importer(binary_resolver?=resolver)
  let requests : Map[(String, String), Bool] = Map([])
  let mut bytes = 0
  // Iterative import traversal terminates cycles by resolved identity, including
  // paths already supplied as roots. Raw imports never undergo UTF-8 decoding.
  let pending = []
  for i = entries.length() - 1; i >= 0; i = i - 1 {
    pending.push(entries[i])
  }
  while pending.pop() is Some((from, e)) {
    scan.tick(e)
    let request : (String, Bool)? = match e.kind {
      ImportFile(path, string) => Some((path, !string))
      ImportBinary(path) => Some((path, false))
      _ => None
    }
    if request is Some((path, code)) {
      try {
        let source = evaluator.import_data(from, path)
        if !requests.contains((from, path)) {
          requests[(from, path)] = true
          bytes += source.bytes.length()
          if requests.length() > limits.imports || bytes > limits.import_bytes {
            raise problem(Limit, e.loc, "lint import limit exceeded")
          }
        }
        if code {
          let (program, id) = evaluator.import_program(from, path)
          imported[(from, path)] = id
          if !roots.contains(id) {
            roots[id] = program.expression
            pending.push((id, program.expression))
          }
        }
      } catch {
        Error(d) =>
          if d.kind == Limit {
            raise Error(d)
          } else {
            scan.report(e.loc, d.message)
          }
      }
    } else {
      let children = lint_children(e)
      for i = children.length() - 1; i >= 0; i = i - 1 {
        pending.push((from, children[i]))
      }
    }
  }
  let graph = LintGraph::new(scan, imported)
  for name, _ in roots {
    graph.roots[name] = graph.add()
  }
  let typed : Map[String, LintTyped] = Map([])
  for name, e in roots {
    typed[name] = graph.build(e, Map([("std", 11)]), name, id=graph.roots[name])
  }
  graph.solve()
  for (name, e) in entries {
    scan.bindings.clear()
    scan.variables(e, Map([]))
    for b in scan.bindings {
      if b.warn && !b.used && b.name != "$" {
        scan.report(b.loc, "Unused variable: " + b.name)
      }
    }
    graph.check(typed[name])
    scan.loops(e)
  }
  scan.diagnostics
}

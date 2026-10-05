// Analysis-only lowering follows pinned go-jsonnet internal/program/desugarer.go.
// Copyright Google Inc.; Apache-2.0; see NOTICE.

///|
fn lint_std_call(name : String, args : Array[Expr], loc : Location) -> Expr {
  let std : Expr = { kind: Var("$std"), loc, }
  let key : Expr = { kind: Literal(Json::string(name)), loc, }
  let target : Expr = { kind: Index(std, key), loc, }
  { kind: Call(target, args.map(e => (None, e)), false), loc, }
}

///|
fn lint_comp(body : Expr, clauses : Array[Clause], loc : Location) -> Expr {
  let mut inside : Expr = { kind: Arr([body]), loc, }
  let conditions = []
  for i = clauses.length() - 1; i >= 0; i = i - 1 {
    match clauses[i] {
      When(e) => conditions.push(e)
      For(name, source) => {
        if conditions.pop() is Some(first) {
          let mut condition = first
          while conditions.pop() is Some(next) {
            condition = { kind: Binary("&&", condition, next), loc, }
          }
          inside = {
            kind: If(condition, inside, { kind: Arr([]), loc, }),
            loc,
          }
        }
        let function : Expr = { kind: Func([(name, None)], inside), loc, }
        inside = lint_std_call("$flatMapArray", [function, source], loc)
      }
    }
  }
  inside
}

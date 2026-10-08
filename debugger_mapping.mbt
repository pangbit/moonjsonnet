///|
// Go's public debugger traverses the lowered tree: direct children, thunks,
// then children evaluated in a separate scope. Preserve duplicates from sugar.
fn debugger_children(node : Expr) -> Array[Expr] {
  match node.kind {
    Local(bindings, body) => [body] + bindings.map(b => b.value)
    Func(parameters, body) =>
      [body] + parameters.filter_map(p => p.default_value)
    Assert(condition, message, body) =>
      [
        condition,
        body,
        {
          kind: Fail(
            message.unwrap_or({
              kind: Literal(Json::string("Assertion failed")),
              loc: node.loc,
              end: None,
            }),
          ),
          loc: node.loc,
          end: Some(diagnostic_expr_end(node)),
        },
      ]
    Obj(fields, locals, assertions, sites) => {
      let result = fields.map(f => f.key)
      for index, (condition, message) in assertions {
        let range = sites.get(index).bind(site => site)
        let loc = range.map(r => r.begin).unwrap_or(condition.loc)
        let end = range.map(r => r.end)
        let failure : Expr = {
          kind: Fail(
            message.unwrap_or({
              kind: Literal(Json::string("Object assertion failed.")),
              loc,
              end: None,
            }),
          ),
          loc,
          end,
        }
        result.push({
          kind: If(
            condition,
            { kind: Literal(Json::boolean(true)), loc: node.loc, end: None, },
            failure,
          ),
          loc,
          end,
        })
      }
      result.append(fields.map(f => f.value))
      result.append(locals.map(b => b.value))
      result
    }
    ArrayComp(_, _) | ObjectComp(_, _, _, _) =>
      debugger_children(debugger_lower_comprehension(node))
    _ => ast_export_children(node)
  }
}

///|
fn debugger_std_call(node : Expr, name : String, args : Array[Expr]) -> Expr {
  let target : Expr = {
    kind: Index({ kind: Var("$std"), loc: node.loc, end: None, }, {
      kind: Literal(Json::string(name)),
      loc: node.loc,
      end: None,
    }),
    loc: node.loc,
    end: None,
  }
  {
    kind: Call(target, args.map(arg => (None, arg)), false),
    loc: node.loc,
    end: node.end,
  }
}

///|
// A hook observes the same lowering as the public Go debugger. Ordinary
// execution retains the direct comprehension path and its existing budgets.
fn debugger_lower_comprehension(node : Expr) -> Expr {
  let (body, clauses, object) = match node.kind {
    ArrayComp(body, clauses) => (body, clauses, false)
    ObjectComp(key, body, clauses, locals) =>
      (
        {
          kind: Obj(
            [
              {
                key,
                value: if locals.is_empty() {
                  body
                } else {
                  { kind: Local(locals, body), loc: node.loc, end: None, }
                },
                visibility: 1,
                additive: false,
              },
            ],
            [],
            [],
            [],
          ),
          loc: node.loc,
          end: node.end,
        },
        clauses,
        true,
      )
    _ => return node
  }
  let mut inside : Expr = { kind: Arr([body]), loc: node.loc, end: None, }
  for i = clauses.length() - 1; i >= 0; i = i - 1 {
    match clauses[i] {
      When(condition) =>
        inside = {
          kind: If(condition, inside, {
            kind: Arr([]),
            loc: node.loc,
            end: None,
          }),
          loc: node.loc,
          end: None,
        }
      For(name, source) =>
        inside = debugger_std_call(node, "$flatMapArray", [
          {
            kind: Func([{ name, default_value: None, range: None, }], inside),
            loc: node.loc,
            end: None,
          },
          source,
        ])
    }
  }
  if object {
    debugger_std_call(node, "$objectFlatMerge", [inside])
  } else {
    inside
  }
}

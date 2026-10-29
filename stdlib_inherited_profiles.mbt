// Local adapters for the fixed std.jsonnet methods whose public input policy
// differs from the unguarded source. StandardFunction calls are private native
// operations: they neither look up receiver fields nor expose new std names.

///|
fn inherited_profile_expr(kind : ExprKind, loc : Location) -> Expr {
  { kind, loc, end: None, }
}

///|
fn inherited_profile_native(
  name : String,
  args : Array[Expr],
  loc : Location,
) -> Expr {
  inherited_profile_expr(
    Call(
      inherited_profile_expr(StandardFunction(name), loc),
      args.map(arg => (None, arg)),
      false,
    ),
    loc,
  )
}

///|
fn inherited_profile_kind(value : Expr, kind : String) -> Expr {
  let loc = value.loc
  inherited_profile_expr(
    Binary(
      "==",
      inherited_profile_native("type", [value], loc),
      inherited_profile_expr(Literal(Json::string(kind)), loc),
    ),
    loc,
  )
}

///|
fn inherited_profile_guard(
  value : Expr,
  policy : String,
  fallback : Expr,
) -> Expr {
  let loc = value.loc
  let number = fn(n : Int) {
    inherited_profile_expr(Literal(Json::number(n.to_double())), loc)
  }
  let binary = fn(op : String, a : Expr, b : Expr) {
    inherited_profile_expr(Binary(op, a, b), loc)
  }
  if policy == "base64-text" {
    // Normalize only when str is consumed. Canonical input is unchanged;
    // retained CRLF/pad-bit extensions reach the source as canonical text.
    return inherited_profile_native(
      "base64",
      [inherited_profile_native("base64DecodeBytes", [value], loc)],
      loc,
    )
  }
  if policy == "base64-input" {
    let byte = inherited_profile_expr(Var("$inherited_byte"), loc)
    let admitted = binary(
      "&&",
      inherited_profile_kind(byte, "number"),
      binary(
        "&&",
        binary(">=", byte, number(0)),
        binary("<=", byte, number(255)),
      ),
    )
    let checked = inherited_profile_expr(
      If(
        admitted,
        byte,
        inherited_profile_native(
          "base64",
          [inherited_profile_expr(Arr([byte]), loc)],
          loc,
        ),
      ),
      loc,
    )
    let check_byte = inherited_profile_expr(
      Func(
        [{ name: "$inherited_byte", default_value: None, range: None, }],
        checked,
      ),
      loc,
    )
    // Native map stores deferred calls, so checking the Array head does not
    // validate or coerce its elements. Accepted fractional Numbers stay intact.
    return inherited_profile_expr(
      If(
        inherited_profile_kind(value, "string"),
        value,
        inherited_profile_expr(
          If(
            inherited_profile_kind(value, "array"),
            inherited_profile_native("map", [check_byte, value], loc),
            fallback,
          ),
          loc,
        ),
      ),
      loc,
    )
  }
  let admitted = match policy {
    "count" =>
      binary(
        "&&",
        inherited_profile_kind(value, "number"),
        binary(
          "||",
          binary("==", value, number(-1)),
          binary(
            "&&",
            binary(">=", value, number(0)),
            binary("==", value, inherited_profile_native("floor", [value], loc)),
          ),
        ),
      )
    "delimiter" =>
      binary(
        "&&",
        inherited_profile_kind(value, "string"),
        binary(">", inherited_profile_native("length", [value], loc), number(0)),
      )
    _ => inherited_profile_kind(value, policy)
  }
  inherited_profile_expr(If(admitted, value, fallback), loc)
}

///|
fn inherited_profile_body(name : String, body : Expr) -> Expr {
  let loc = body.loc
  match (name, body.kind) {
    ("splitLimitR", Assert(condition, message, next)) =>
      {
        ..body,
        kind: Assert(condition, message, inherited_profile_body(name, next)),
      }
    ("splitLimitR", If(_, _, reverse)) =>
      // The public right-to-left promise also applies to unlimited splitting.
      // Keep the original reverse pipeline and pass maxsplits=-1 unchanged.
      reverse
    ("manifestTomlEx", Local(bindings, next)) => {
      let bindings = bindings.map(fn(binding) {
        if binding.name == "escapeKeyToml" &&
          binding.value.kind is Func(params, original) {
          let key = inherited_profile_expr(Var("key"), loc)
          let empty = inherited_profile_expr(Literal(Json::string("")), loc)
          let quoted = inherited_profile_expr(Literal(Json::string("''")), loc)
          {
            ..binding,
            value: {
              ..binding.value,
              kind: Func(
                params,
                inherited_profile_expr(
                  If(
                    inherited_profile_expr(Binary("==", key, empty), loc),
                    quoted,
                    original,
                  ),
                  loc,
                ),
              ),
            },
          }
        } else {
          binding
        }
      })
      { ..body, kind: Local(bindings, next), }
    }
    ("base64", Local(bindings, next)) => {
      let bindings = bindings.map(fn(binding) {
        if binding.name == "sanity" {
          let a = inherited_profile_expr(Var("a"), loc)
          let bounds = inherited_profile_expr(
            Binary(
              "&&",
              inherited_profile_expr(
                Binary(">=", a, inherited_profile_expr(Literal(0), loc)),
                loc,
              ),
              inherited_profile_expr(
                Binary("<=", a, inherited_profile_expr(Literal(255), loc)),
                loc,
              ),
            ),
            loc,
          )
          let checks = inherited_profile_expr(
            ArrayComp(bounds, [
              For("a", inherited_profile_expr(Var("bytes"), loc)),
            ]),
            loc,
          )
          let all = inherited_profile_expr(
            Index(
              inherited_profile_expr(Var("std"), loc),
              inherited_profile_expr(Literal("all"), loc),
            ),
            loc,
          )
          {
            ..binding,
            value: inherited_profile_expr(
              Call(all, [(None, checks)], false),
              loc,
            ),
          }
        } else {
          binding
        }
      })
      { ..body, kind: Local(bindings, inherited_profile_body(name, next)), }
    }
    _ => body
  }
}

///|
fn inherited_profile_expression(name : String, expression : Expr) -> Expr {
  let checks : Array[(String, String)] = match name {
    "startsWith" | "endsWith" => [("a", "string"), ("b", "string")]
    "lstripChars" | "rstripChars" => [("str", "string")]
    "minArray" | "maxArray" => [("arr", "array")]
    "splitLimit" | "splitLimitR" =>
      [("str", "string"), ("c", "delimiter"), ("maxsplits", "count")]
    "base64" => [("input", "base64-input")]
    "base64DecodeBytes" => [("str", "base64-text")]
    "manifestTomlEx" => [("value", "object"), ("indent", "string")]
    _ => return expression
  }
  guard expression.kind is Func(params, original) else { return expression }
  let loc = expression.loc
  let raw_name = fn(name : String) { "$inherited_arg_" + name }
  let raw_args = params.map(p => {
    inherited_profile_expr(Var(raw_name(p.name)), loc)
  })
  let fallback = inherited_profile_native(name, raw_args, loc)
  let raw : Array[ExprBinding] = params.map(p => {
    name: raw_name(p.name),
    value: inherited_profile_expr(Var(p.name), loc),
    range: None,
  })
  let checked : Array[ExprBinding] = checks.map(pair => {
    let value = inherited_profile_expr(Var(raw_name(pair.0)), loc)
    // A receiver override can consume indent where the original value would
    // not. Its rejected String head must still fail, without rerendering value.
    let reject = if name == "manifestTomlEx" && pair.0 == "indent" {
      inherited_profile_native(
        "startsWith",
        [value, inherited_profile_expr(Literal(""), loc)],
        loc,
      )
    } else {
      fallback
    }
    {
      name: pair.0,
      value: inherited_profile_guard(value, pair.1, reject),
      range: None,
    }
  })
  // Two nested locals capture the original parameters before shadowing them.
  // Both aliases and guards remain thunks; an ignored argument stays unforced.
  let body = inherited_profile_expr(
    Local(
      raw,
      inherited_profile_expr(
        Local(checked, inherited_profile_body(name, original)),
        loc,
      ),
    ),
    loc,
  )
  { ..expression, kind: Func(params, body), }
}

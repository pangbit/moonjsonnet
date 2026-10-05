///|
fn range_node(root : @moonjsonnet.Ast, path : String) -> @moonjsonnet.Ast raise {
  let mut node = root
  if path.is_empty() {
    return node
  }
  for part in path.split(".") {
    let key = part.to_owned()
    let number = fn(prefix : String) raise {
      @string.parse_int(key[prefix.length():])
    }
    node = match (key, node.kind) {
      ("left", Binary(_, a, _)) | ("right", Binary(_, _, a)) => a
      ("cond", If(a, _, _)) | ("then", If(_, a, _)) | ("else", If(_, _, a)) => a
      ("body", Local(_, a))
      | ("body", Func(_, a))
      | ("body", Assert(_, _, a)) => a
      ("target", Index(a, _))
      | ("target", Slice(a, _, _, _))
      | ("target", Call(a, _, _)) => a
      ("index", Index(_, a))
      | ("operand", Unary(_, a))
      | ("operand", Fail(a)) => a
      (_, Arr(xs)) if key.has_prefix("item:") => xs[number("item:")]
      (_, Local(bs, _)) if key.has_prefix("bind:") => bs[number("bind:")].1
      (_, Func(ps, _)) if key.has_prefix("default:") =>
        ps[number("default:")].1.unwrap()
      (_, Call(_, args, _)) if key.has_prefix("arg:") => args[number("arg:")].1
      (_, Obj(fs, _, _)) if key.has_prefix("field:") =>
        fs[number("field:")].value
      (_, Obj(fs, _, _)) if key.has_prefix("key:") => fs[number("key:")].key
      _ => fail("unsupported range path: " + path)
    }
  }
  node
}

///|
fn range_result(root : @moonjsonnet.Ast, input : Json) -> Json raise {
  guard input is Object(fields) && fields.get("paths") is Some(Array(paths)) else {
    fail("range paths")
  }
  Json::array(
    paths.map(path => {
      guard path is String(path) else { fail("range path") }
      match range_node(root, path).source_range() {
        None => Json::null()
        Some(r) =>
          Json::array([
            Json::number(r.begin.line.to_double()),
            Json::number(r.begin.column.to_double()),
            Json::number(r.end.line.to_double()),
            Json::number(r.end.column.to_double()),
            Json::string(r.format()),
          ])
      }
    }),
  )
}

///|
// Follow Go's dependency walker order: direct, thunk, then special children.
// Its desugared object walk omits assertions; preserve that observed contract.
fn dependency_children(expr : Expr) -> Array[Expr] {
  let children = []
  let optional = fn(value : Expr?) {
    if value is Some(value) {
      children.push(value)
    }
  }
  let clauses = fn(items : Array[Clause]) {
    for item in items {
      match item {
        For(_, e) | When(e) => children.push(e)
      }
    }
  }
  match expr.kind {
    Literal(_)
    | NumberLiteral(_)
    | Var(_)
    | ImportFile(_, _)
    | ImportBinary(_)
    | StandardFunction(_)
    | StandardValue(_) => ()
    Local(bindings, body) => {
      children.push(body)
      for (_, e) in bindings {
        children.push(e)
      }
    }
    Func(params, body) => {
      children.push(body)
      for (_, e) in params {
        optional(e)
      }
    }
    If(a, b, c) => {
      children.push(a)
      children.push(b)
      children.push(c)
    }
    Call(target, args, _) => {
      children.push(target)
      for (_, e) in args {
        children.push(e)
      }
    }
    Arr(items) => children.append(items)
    Obj(fields, locals, _) => {
      for field in fields {
        children.push(field.key)
      }
      for field in fields {
        children.push(field.value)
      }
      for (_, e) in locals {
        children.push(e)
      }
    }
    ArrayComp(body, items) => {
      clauses(items)
      children.push(body)
    }
    ObjectComp(key, body, items, locals) => {
      clauses(items)
      children.push(key)
      children.push(body)
      for (_, e) in locals {
        children.push(e)
      }
    }
    Index(a, b) | Binary(_, a, b) => {
      children.push(a)
      children.push(b)
    }
    Slice(a, b, c, d) => {
      children.push(a)
      optional(b)
      optional(c)
      optional(d)
    }
    Unary(_, a) | Fail(a) => children.push(a)
    Assert(a, msg, body) => {
      children.push(a)
      optional(msg)
      children.push(body)
    }
  }
  children
}

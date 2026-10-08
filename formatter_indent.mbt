// Expression indentation follows the pinned Go formatter's base/lineUp model.
// Copyright Google Inc.; Apache-2.0; see NOTICE.

///|
priv struct FormatIndentValue {
  anchor : Int
  levels : Int
}

///|
priv struct FormatIndentContext {
  base : FormatIndentValue
  line_up : FormatIndentValue
}

///|
priv struct FormatIndentPlan {
  base : Array[FormatIndentValue]
  line_up : Array[FormatIndentValue]
}

///|
fn FormatIndentValue::resolve(
  self : FormatIndentValue,
  columns : Array[Int],
  indent : Int,
  maximum : Int,
) -> Int {
  // Slice closing fodder is intentionally left untouched by fixed Go.
  if self.anchor == -2 {
    return self.levels
  }
  let anchor = if self.anchor >= 0 { columns[self.anchor] } else { 0 }
  if anchor > maximum || self.levels > (maximum - anchor) / indent {
    maximum
  } else {
    anchor + self.levels * indent
  }
}

///|
fn format_grouping_paren(
  tokens : Array[Token],
  layout : FormatLayout,
  open : Int,
) -> Bool {
  if tokens[open].text != "(" || layout.parameter[open] {
    return false
  }
  if open == 0 {
    return true
  }
  let previous = tokens[open - 1]
  !(previous.value is Some(_) ||
  is_name(previous.text) ||
  previous.text == "]" ||
  previous.text == "}" ||
  previous.text == "self" ||
  previous.text == "super" ||
  previous.text == "$" ||
  (previous.text == ")" && !layout.parameter[layout.close[open - 1]]))
}

///|
fn format_indent_plan(
  tokens : Array[Token],
  root : Expr,
  layout : FormatLayout,
  writer : FormatOutput,
) -> FormatIndentPlan raise JsonnetError {
  let zero : FormatIndentValue = { anchor: -1, levels: 0, }
  let plan : FormatIndentPlan = {
    base: Array::make(tokens.length(), zero),
    line_up: Array::make(tokens.length(), zero),
  }
  let positions : Map[(Int, Int), Int] = Map([])
  let ends : Map[(Int, Int), Int] = Map([])
  for i, token in tokens {
    writer.tick()
    positions[(token.loc.line, token.loc.column)] = i
    ends[(token.end.line, token.end.column)] = i + 1
  }
  let start = fn(e : Expr) {
    let mut first = positions.get((e.loc.line, e.loc.column)).unwrap_or(0)
    let mut end = match e.end {
      Some(end) => ends.get((end.line, end.column)).unwrap_or(first + 1)
      None => first + 1
    }
    while first > 0 && format_grouping_paren(tokens, layout, first - 1) {
      let close = layout.close[first - 1]
      if close != end && close != end - 1 {
        break
      }
      first -= 1
      end = close + 1
    }
    first
  }
  let finish = fn(e : Expr) {
    let mut current = e
    while current.end is None {
      match current.kind {
        Func(_, body) | Assert(_, _, body) => current = body
        _ => break
      }
    }
    match current.end {
      Some(end) =>
        ends.get((end.line, end.column)).unwrap_or(start(current) + 1)
      None => start(current) + 1
    }
  }
  let on_new_line = fn(i : Int) {
    if layout.newline[i] {
      true
    } else {
      let mut result = false
      for trivia in tokens[i].leading {
        match trivia.kind {
          Whitespace =>
            if trivia.raw.contains("\n") {
              result = true
              break
            }
          LineComment => {
            result = true
            break
          }
          BlockComment => {
            result = trivia.raw.contains("\n")
            break
          }
          TokenText => ()
        }
      }
      result
    }
  }
  let child_at = fn(
    i : Int,
    old : FormatIndentContext,
    strong : Bool,
  ) -> FormatIndentContext {
    if on_new_line(i) {
      let next = { ..old.base, levels: old.base.levels + 1, }
      { base: next, line_up: next, }
    } else {
      let line_up : FormatIndentValue = { anchor: i, levels: 0, }
      { base: if strong { line_up } else { old.base }, line_up, }
    }
  }
  let stack : Array[(Expr, FormatIndentContext)] = [
    (root, { base: zero, line_up: zero, }),
  ]
  while stack.pop() is Some((e, context)) {
    writer.tick()
    let first = positions.get((e.loc.line, e.loc.column)).unwrap_or(0)
    let end = finish(e)
    for i in start(e)..<end {
      writer.tick()
      plan.base[i] = context.base
      plan.line_up[i] = context.line_up
    }
    let push = fn(child : Expr, next : FormatIndentContext) {
      stack.push((child, next))
    }
    let visit = fn(child : Expr) { push(child, context) }
    let new_child = fn(child : Expr) { child_at(start(child), context, false) }
    let clauses = fn(cs : Array[Clause], next : FormatIndentContext) {
      for clause in cs {
        match clause {
          For(_, value) | When(value) =>
            push(value, child_at(start(value), next, false))
        }
      }
    }
    match e.kind {
      Local(bindings, body) => {
        let name = if bindings[0].range is Some(range) {
          positions
          .get((range.begin.line, range.begin.column))
          .unwrap_or(first + 1)
        } else {
          first + 1
        }
        let names = bindings.map(binding => {
          match binding.range {
            Some(range) =>
              positions
              .get((range.begin.line, range.begin.column))
              .unwrap_or(name)
            None => start(binding.value)
          }
        })
        if names.any(i => tokens[i].has_newline()) {
          for i in names[1:] {
            layout.newline[i] = true
          }
        }
        let next = child_at(name, context, false)
        for i in name..<start(body) {
          plan.base[i] = next.base
          plan.line_up[i] = next.line_up
        }
        for binding in bindings {
          let value_start = start(binding.value)
          let lowered_function = binding.value.kind is Func(_, _) &&
            tokens[value_start].text != "function"
          push(
            binding.value,
            if lowered_function {
              next
            } else {
              child_at(value_start, next, false)
            },
          )
        }
        visit(body)
      }
      Func(parameters, body) => {
        let mut parameter_context = context
        for open in first..<start(body) {
          if layout.parameter[open] {
            let close = layout.close[open]
            parameter_context = child_at(open + 1, context, false)
            for i in (open + 1)..<close {
              plan.base[i] = parameter_context.base
              plan.line_up[i] = parameter_context.line_up
            }
            plan.line_up[close] = context.line_up
            break
          }
        }
        for parameter in parameters {
          if parameter.default_value is Some(value) {
            push(value, parameter_context)
          }
        }
        push(body, new_child(body))
      }
      If(condition, yes, no) => {
        push(condition, new_child(condition))
        push(yes, new_child(yes))
        if no.end is Some(_) {
          push(no, new_child(no))
        }
        // Branch markers reset to the parent base, including an inline else-if.
        for i in finish(condition)..<start(yes) {
          if tokens[i].text == "then" {
            plan.line_up[i] = context.base
          }
        }
        if no.end is Some(_) {
          for i in finish(yes)..<start(no) {
            if tokens[i].text == "else" {
              plan.line_up[i] = context.base
            }
          }
        }
      }
      Binary(op, left, right) => {
        let mut strong = false
        for i in finish(left)..<start(right) {
          if tokens[i].text == op {
            strong = tokens[i].has_newline() || tokens[i + 1].has_newline()
            break
          }
        }
        let next = if on_new_line(first) {
          context
        } else {
          let line_up : FormatIndentValue = { anchor: first, levels: 0, }
          { base: if strong { line_up } else { context.base }, line_up, }
        }
        for i in first..<end {
          plan.base[i] = next.base
          plan.line_up[i] = next.line_up
        }
        push(left, next)
        push(right, next)
      }
      Arr(items) => {
        let next = child_at(first + 1, context, false)
        for i in (first + 1)..<end {
          plan.base[i] = next.base
          plan.line_up[i] = next.line_up
        }
        for value in items {
          push(value, next)
        }
        if layout.close[first] >= 0 {
          plan.line_up[layout.close[first]] = context.base
        }
      }
      Obj(fields, bindings, assertions) => {
        let next = child_at(first + 1, context, false)
        for i in (first + 1)..<end {
          plan.base[i] = next.base
          plan.line_up[i] = next.line_up
        }
        for field in fields {
          push(field.key, next)
          if field.value.kind is Func(_, _) && field.value.end is None {
            push(field.value, next)
          } else {
            push(field.value, child_at(start(field.value), next, false))
          }
        }
        for binding in bindings {
          push(
            binding.value,
            if binding.value.kind is Func(_, _) &&
              tokens[start(binding.value)].text != "function" {
              next
            } else {
              child_at(start(binding.value), next, false)
            },
          )
        }
        for (condition, message) in assertions {
          push(condition, next)
          if message is Some(value) {
            push(value, child_at(start(condition), next, false))
          }
        }
        if layout.close[first] >= 0 {
          let close = layout.close[first]
          plan.base[close] = context.base
          plan.line_up[close] = context.base
        }
      }
      ArrayComp(body, cs) => {
        let next = child_at(first + 1, context, false)
        for i in (first + 1)..<end {
          plan.base[i] = next.base
          plan.line_up[i] = next.line_up
        }
        push(body, next)
        clauses(cs, next)
        if layout.close[first] >= 0 {
          plan.line_up[layout.close[first]] = context.base
        }
      }
      ObjectComp(key, body, cs, bindings) => {
        let next = child_at(first + 1, context, false)
        for i in (first + 1)..<end {
          plan.base[i] = next.base
          plan.line_up[i] = next.line_up
        }
        push(key, next)
        push(body, child_at(start(body), next, false))
        for binding in bindings {
          push(binding.value, child_at(start(binding.value), next, false))
        }
        clauses(cs, next)
        if layout.close[first] >= 0 {
          plan.line_up[layout.close[first]] = context.base
        }
      }
      Call(target, arguments, _) => {
        visit(target)
        let open = finish(target)
        if tokens.get(open) is Some({ text: "(", .. }) {
          let strong = arguments.length() > 1 &&
            arguments[1:].any(arg => tokens[start(arg.1)].has_newline())
          let next = child_at(open + 1, context, strong)
          let close = layout.close[open]
          for i in (open + 1)..<close {
            plan.base[i] = next.base
            plan.line_up[i] = next.line_up
          }
          for (_, value) in arguments {
            push(value, next)
          }
          if close >= 0 {
            plan.line_up[close] = context.base
          }
        } else {
          for (_, value) in arguments {
            push(value, new_child(value))
          }
        }
      }
      Index(target, index) => {
        visit(target)
        if index.end is None && tokens[start(index)].text == "." {
          let name = start(index) + 1
          let next = child_at(name, context, false)
          plan.base[name] = next.base
          plan.line_up[name] = next.line_up
        } else {
          for open in finish(target)..<start(index) {
            if tokens[open].text == "[" {
              let close = layout.close[open]
              let next = child_at(open + 1, context, false)
              for i in (open + 1)..<close {
                plan.base[i] = next.base
                plan.line_up[i] = next.line_up
              }
              plan.line_up[close] = context.base
              push(index, next)
              break
            }
          }
        }
      }
      Slice(target, begin, stop, step) => {
        visit(target)
        for open in finish(target)..<end {
          if tokens[open].text != "[" {
            continue
          }
          let close = layout.close[open]
          let mut next = child_at(open + 1, context, false)
          if begin is Some(value) {
            push(value, next)
          }
          for i in (open + 1)..<close {
            if tokens[i].text == ":" || tokens[i].text == "::" {
              next = child_at(i, context, false)
              for j in i..<close {
                plan.base[j] = next.base
                plan.line_up[j] = next.line_up
              }
              break
            }
          }
          for value in [stop, step] {
            if value is Some(value) {
              push(value, next)
            }
          }
          plan.line_up[close] = {
            anchor: -2,
            levels: tokens[close].loc.column - 1,
          }
          break
        }
      }
      Assert(condition, message, body) => {
        let next = new_child(condition)
        push(condition, next)
        if message is Some(value) {
          push(value, next)
        }
        visit(body)
      }
      Unary(_, value) | Fail(value) => push(value, new_child(value))
      ImportFile(_, _) | ImportBinary(_) =>
        if first + 1 < end {
          let next = child_at(first + 1, context, false)
          plan.base[first + 1] = next.base
          plan.line_up[first + 1] = next.line_up
        }
      Literal(_)
      | NumberLiteral(_)
      | Var(_)
      | StandardFunction(_)
      | StandardValue(_) => ()
    }
  }
  // The semantic tree intentionally removes grouping parentheses. Restore
  // their strong base before resolving output-column references.
  for open, token in tokens {
    writer.tick()
    if token.text != "(" || !format_grouping_paren(tokens, layout, open) {
      continue
    }
    let close = layout.close[open]
    let old = plan.base[open]
    let next = if on_new_line(open + 1) {
      { ..old, levels: old.levels + 1, }
    } else {
      { anchor: open + 1, levels: 0, }
    }
    let translate = fn(value : FormatIndentValue) {
      if value.anchor == -2 {
        value
      } else if value.anchor <= open || value.anchor > close {
        {
          anchor: next.anchor,
          levels: next.levels +
          value.levels -
          (if value.anchor == old.anchor { old.levels } else { 0 }),
        }
      } else {
        value
      }
    }
    for i in (open + 1)..<close {
      writer.tick()
      plan.base[i] = translate(plan.base[i])
      plan.line_up[i] = translate(plan.line_up[i])
    }
    plan.line_up[close] = old
  }
  plan
}

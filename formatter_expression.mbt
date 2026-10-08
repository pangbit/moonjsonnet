///|
priv struct FormatContinuation {
  align : Array[Int]
  strong : Array[Bool]
}

///|
// Binary continuations align with the whole left expression, rather than
// adding one level for every physical newline inside a delimiter.
fn format_binary_continuations(
  tokens : Array[Token],
  root : Expr,
) -> FormatContinuation {
  let positions : Map[(Int, Int), Int] = Map([])
  let ends : Map[(Int, Int), Int] = Map([])
  for i, token in tokens {
    positions[(token.loc.line, token.loc.column)] = i
    ends[(token.end.line, token.end.column)] = i + 1
  }
  let align = Array::make(tokens.length(), -1)
  let strong = Array::make(tokens.length(), false)
  let stack = [root]
  while stack.pop() is Some(e) {
    if e.kind is Binary(op, left, right) &&
      positions.get((e.loc.line, e.loc.column)) is Some(start) &&
      positions.get((right.loc.line, right.loc.column)) is Some(rhs) &&
      left.end is Some(end) &&
      ends.get((end.line, end.column)) is Some(after_left) {
      for i in after_left..<rhs {
        if tokens[i].text == op {
          align[i] = start
          // The semantic tree omits wrapping parentheses around the right
          // operand, but the first printed token still belongs to it.
          if i + 1 < tokens.length() {
            align[i + 1] = start
            let reset = tokens[i].has_newline() || tokens[i + 1].has_newline()
            strong[i] = reset
            strong[i + 1] = reset
          }
          break
        }
      }
    }
    stack.append(lint_children(e))
    if e.kind is Obj(_, _, assertions) {
      for (condition, message) in assertions {
        stack.push(condition)
        if message is Some(message) {
          stack.push(message)
        }
      }
    }
  }
  { align, strong, }
}

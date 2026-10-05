///|
// Structural edits use parsed expression ranges rather than guessing operator
// precedence from adjacent tokens. The token stream retains parentheses that
// the semantic expression tree intentionally discards.
fn format_plus_edits(
  root : Expr,
  tokens : Array[Token],
  skip : Array[Bool],
  insert_plus : Array[Bool],
  implicit : Bool,
) -> Unit {
  let positions : Map[(Int, Int), Int] = Map([])
  for i, token in tokens {
    positions[(token.loc.line, token.loc.column)] = i
  }
  let stack = [root]
  while stack.pop() is Some(e) {
    if e.kind is Binary("+", left, right) &&
      (right.kind is Obj(_, _, _) || right.kind is ObjectComp(_, _, _, _)) &&
      positions.get((right.loc.line, right.loc.column)) is Some(i) &&
      i > 0 &&
      tokens[i].text == "{" {
      if tokens[i - 1].text == "+" {
        if implicit &&
          right.kind is Obj(_, _, _) &&
          (left.kind is Var(_) || left.kind is Index(_, _)) &&
          i > 1 &&
          left.end == Some(tokens[i - 2].end) {
          skip[i - 1] = true
        }
      } else if !implicit && tokens[i - 1].text != "(" {
        insert_plus[i] = true
      }
    }
    stack.append(lint_children(e))
    // Lint traversal omits object assertions; formatting must retain them.
    if e.kind is Obj(_, _, assertions) {
      for (condition, message) in assertions {
        stack.push(condition)
        if message is Some(message) {
          stack.push(message)
        }
      }
    }
  }
}

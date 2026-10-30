///|
/// Structural syntax categories before semantic lowering. Spelling, operators,
/// names and comments are authoritative in RawNode.parts, not this tag.
pub(all) enum RawNodeKind {
  Literal
  Number
  StringLiteral
  TextBlock
  Variable
  Parens
  Local
  Binding
  Parameter
  Argument
  If
  Function
  Array
  Object
  Field
  ObjectLocal
  ObjectAssert
  ArrayComp
  ObjectComp
  ForClause
  IfClause
  Call
  ApplyBrace
  Index
  DotIndex
  Slice
  Unary(String)
  Binary(String)
  Assert
  ErrorExpr
  Import
  ImportStr
  ImportBin
} derive(Eq, Debug)

///|
pub extend RawNodeKind with Eq::{equal, not_equal}

///|
pub extend RawNodeKind with @debug.Debug::{to_repr}

///|
/// Ordered lossless syntax. Every token and trivia fragment occurs exactly once.
pub(all) enum RawPart {
  Text(SourcePart)
  Child(RawNode)
}

///|
/// Editable concrete syntax node. Ranges and tags describe the parsed source;
/// edits to parts change text, and reparsing refreshes metadata. Containers are
/// caller-owned; formatting reparses the edited text without evaluating it.
pub(all) struct RawNode {
  kind : RawNodeKind
  range : SourceRange?
  parts : Array[RawPart]
}

///|
/// Root syntax and the final EOF trivia, kept separately like Go's final fodder.
pub(all) struct RawAst {
  root : RawNode
  final_fodder : Array[SourcePart]
}

///|
priv struct RawSpan {
  kind : RawNodeKind
  begin : Int32
  end : Int32
} derive(Eq)

///|
fn Parser::record_raw(self : Parser, kind : RawNodeKind, begin : Int32) -> Unit {
  if self.raw_spans is Some(spans) {
    let span : RawSpan = { kind, begin, end: self.pos, }
    // Objects are recorded at their own entry and at the primary expression.
    if spans.last() != Some(span) {
      spans.push(span)
    }
  }
}

///|
fn raw_primary_kind(expression : Expr, token : Token) -> RawNodeKind {
  if token.text == "(" {
    return Parens
  }
  if token.text == "<block>" {
    return TextBlock
  }
  if token.text == "<string>" {
    return StringLiteral
  }
  match expression.kind {
    Literal(_) => Literal
    NumberLiteral(_) => Number
    Var(_) | StandardFunction(_) | StandardValue(_) => Variable
    Local(_, _) => Local
    If(_, _, _) => If
    Func(_, _) => Function
    Arr(_) => Array
    Obj(_, _, _, _) => Object
    ArrayComp(_, _) => ArrayComp
    ObjectComp(_, _, _, _) => ObjectComp
    Unary(op, _) => Unary(op)
    Assert(_, _, _) => Assert
    Fail(_) => ErrorExpr
    ImportFile(_, false) => Import
    ImportFile(_, true) => ImportStr
    ImportBinary(_) => ImportBin
    Binary(op, _, _) => Binary(op)
    Call(_, _, _) => Call
    Index(_, _) => Index
    Slice(_, _, _, _) => Slice
  }
}

///|
fn raw_token_parts(
  token : Token,
  work : FormatOutput,
) -> Array[RawPart] raise JsonnetError {
  let parts = token.leading.map(t => {
    work.tick()
    Text({ kind: t.kind, text: t.raw, range: t.range, })
  })
  if !token.raw.is_empty() {
    parts.push(
      Text({
        kind: TokenText,
        text: token.raw,
        range: { begin: token.loc, end: token.end, },
      }),
    )
  }
  parts
}

///|
priv struct RawBuilt {
  begin : Int32
  end : Int32
  node : RawNode
  depth : Int32
}

///|
fn build_raw_ast(
  tokens : Array[Token],
  spans : Array[RawSpan],
  limits : SyntaxLimits,
) -> RawAst raise JsonnetError {
  let loc = tokens[0].loc
  if spans.length() > limits.nodes {
    raise problem(Limit, loc, "raw syntax node limit exceeded")
  }
  let completed : Array[RawBuilt] = []
  let work : FormatOutput = {
    out: StringBuilder(),
    bytes: 0,
    steps: 0,
    line_start: true,
    column: 0,
    limits: limits.output_limits(),
    loc,
  }
  for span in spans {
    work.tick()
    let children : Array[RawBuilt] = []
    while completed.last() is Some(child) &&
          child.begin >= span.begin &&
          child.end <= span.end {
      work.tick()
      children.push(completed.pop().unwrap())
    }
    let parts : Array[RawPart] = []
    let mut position = span.begin
    let mut depth = 0
    for child_index = children.length() - 1
        child_index >= 0
        child_index = child_index - 1 {
      let child = children[child_index]
      depth = Int32::max(depth, child.depth + 1)
      if child.begin < position {
        raise problem(Runtime, loc, "overlapping raw syntax children")
      }
      for i in position..<child.begin {
        work.tick()
        parts.append(raw_token_parts(tokens[i], work))
      }
      parts.push(Child(child.node))
      position = child.end
    }
    for i in position..<span.end {
      work.tick()
      parts.append(raw_token_parts(tokens[i], work))
    }
    if depth >= limits.tree_depth {
      raise problem(
        Limit,
        tokens[span.begin].loc,
        "raw syntax tree depth limit exceeded",
      )
    }
    completed.push({
      begin: span.begin,
      end: span.end,
      depth,
      node: {
        kind: span.kind,
        range: Some({
          begin: tokens[span.begin].loc,
          end: tokens[span.end - 1].end,
        }),
        parts,
      },
    })
  }
  guard completed is [root] &&
    root.begin == 0 &&
    root.end == tokens.length() - 1 else {
    raise problem(Runtime, loc, "incomplete raw syntax tree")
  }
  {
    root: root.node,
    final_fodder: tokens.last().unwrap().leading.map(t => {
      work.tick()
      { kind: t.kind, text: t.raw, range: t.range, }
    }),
  }
}

///|
/// Export a fresh concrete tree, including parentheses, fields, declarations,
/// parameters, arguments and clauses. No returned mutable container is shared.
pub fn SyntaxDocument::raw_ast(
  self : SyntaxDocument,
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> RawAst raise JsonnetError {
  let document = self.document
  let loc = document.expression.loc
  check_syntax_limits(limits, loc)
  if @utf8.encode(document.text()).length() > limits.source_bytes {
    raise problem(Limit, loc, "source byte limit exceeded")
  }
  let spans : Array[RawSpan] = []
  ignore(
    parse_tokens(
      document.tokens,
      limits.parser_depth,
      tree_depth=limits.tree_depth,
      node_limit=limits.nodes,
      raw_spans=spans,
    ),
  ) catch {
    Error(d) => raise Error(d)
    e => raise problem(Runtime, loc, e.to_string())
  }
  build_raw_ast(document.tokens, spans, limits)
}

///|
pub fn RawAst::parse(
  source : String,
  filename~ : String = "<input>",
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> RawAst raise JsonnetError {
  SyntaxDocument::parse(source, filename~, limits~).raw_ast(limits~)
}

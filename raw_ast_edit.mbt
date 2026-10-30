///|
fn raw_text(
  root : RawNode,
  final_fodder : Array[SourcePart],
  limits : SyntaxLimits,
) -> String raise JsonnetError {
  let loc = root.range
    .map(r => r.begin)
    .unwrap_or({ file: "<node>", line: 1, column: 1, })
  check_syntax_limits(limits, loc)
  let writer : FormatOutput = {
    out: StringBuilder(),
    bytes: 0,
    steps: 0,
    line_start: true,
    column: 0,
    limits: { ..limits.output_limits(), output_bytes: limits.source_bytes, },
    loc,
  }
  let stack : Array[(RawPart, Int32)] = [(Child(root), 0)]
  let mut nodes = 0
  while stack.pop() is Some((part, depth)) {
    writer.tick()
    match part {
      Text(part) => writer.write(part.text)
      Child(node) => {
        if depth >= limits.tree_depth || nodes >= limits.nodes {
          raise problem(Limit, loc, "raw syntax tree limit exceeded")
        }
        nodes += 1
        for i = node.parts.length() - 1; i >= 0; i = i - 1 {
          writer.tick()
          stack.push((node.parts[i], depth + 1))
        }
      }
    }
  }
  for part in final_fodder {
    writer.tick()
    writer.write(part.text)
  }
  writer.out.to_string()
}

///|
/// Serialize edited syntax exactly. Cycles/depth, nodes, steps and source bytes
/// are bounded; this does not itself validate the resulting Jsonnet grammar.
pub fn RawAst::text(
  self : RawAst,
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> String raise JsonnetError {
  raw_text(self.root, self.final_fodder, limits)
}

///|
pub fn RawNode::text(
  self : RawNode,
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> String raise JsonnetError {
  raw_text(self, [], limits)
}

///|
/// Reparse and format editable expression-node syntax with separate final trivia. Tags and
/// retained ranges are metadata; parts determine the admitted source. The input
/// node is not mutated and no expression/import is executed.
pub fn format_node(
  node : RawNode,
  final_fodder~ : Array[SourcePart] = [],
  options~ : FormatOptions = FormatOptions::default(),
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> String raise JsonnetError {
  let filename = node.range.map(r => r.begin.file).unwrap_or("<node>")
  format_syntax_source(
    raw_text(node, final_fodder, limits),
    filename~,
    options~,
    limits~,
  )
}

///|
pub fn RawAst::format(
  self : RawAst,
  options~ : FormatOptions = FormatOptions::default(),
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> String raise JsonnetError {
  format_node(self.root, final_fodder=self.final_fodder, options~, limits~)
}

///|
priv enum RawCloneFrame {
  Enter(RawNode, Int32)
  Leave(RawNode, Int32)
}

///|
/// Clone every child occurrence iteratively, preserving metadata and isolating
/// mutable arrays. Complete tree/node/work budgets also bound cyclic edits.
fn clone_raw_node(
  root : RawNode,
  limits : SyntaxLimits,
  work : FormatOutput,
) -> RawNode raise JsonnetError {
  let loc = root.range
    .map(r => r.begin)
    .unwrap_or({ file: "<node>", line: 1, column: 1, })
  check_syntax_limits(limits, loc)
  let stack : Array[RawCloneFrame] = [Enter(root, 0)]
  let completed : Array[RawNode] = []
  let mut nodes = 0
  while stack.pop() is Some(frame) {
    work.tick()
    match frame {
      Enter(node, depth) => {
        if depth >= limits.tree_depth || nodes >= limits.nodes {
          raise problem(Limit, loc, "raw syntax tree limit exceeded")
        }
        nodes += 1
        let children : Array[RawNode] = []
        for part in node.parts {
          work.tick()
          match part {
            Child(child) => children.push(child)
            Text(_) => ()
          }
        }
        stack.push(Leave(node, children.length()))
        for i = children.length() - 1; i >= 0; i = i - 1 {
          stack.push(Enter(children[i], depth + 1))
        }
      }
      Leave(node, count) => {
        let children = completed[completed.length() - count:].to_owned()
        let mut position = 0
        let parts = node.parts.map(part => {
          match part {
            Text(part) => Text(part)
            Child(_) => {
              let child = children[position]
              position += 1
              Child(child)
            }
          }
        })
        for _ in 0..<count {
          ignore(completed.pop())
        }
        completed.push({ ..node, parts, })
      }
    }
  }
  completed[0]
}

///|
/// Clone every child occurrence, preserving metadata and isolating mutable arrays.
pub fn RawNode::clone(
  self : RawNode,
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> RawNode raise JsonnetError {
  let loc = self.range
    .map(r => r.begin)
    .unwrap_or({ file: "<node>", line: 1, column: 1, })
  let work : FormatOutput = {
    out: StringBuilder(),
    bytes: 0,
    steps: 0,
    line_start: true,
    column: 0,
    limits: limits.output_limits(),
    loc,
  }
  clone_raw_node(self, limits, work)
}

///|
pub fn RawAst::clone(
  self : RawAst,
  limits~ : SyntaxLimits = SyntaxLimits::default(),
) -> RawAst raise JsonnetError {
  let loc = self.root.range
    .map(r => r.begin)
    .unwrap_or({ file: "<node>", line: 1, column: 1, })
  let work : FormatOutput = {
    out: StringBuilder(),
    bytes: 0,
    steps: 0,
    line_start: true,
    column: 0,
    limits: limits.output_limits(),
    loc,
  }
  let root = clone_raw_node(self.root, limits, work)
  let final_fodder = self.final_fodder.map(part => {
    work.tick()
    part
  })
  { root, final_fodder, }
}

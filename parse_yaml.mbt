///|
priv enum ParsedYamlNode {
  Scalar(String, @yaml.TScalarStyle, @yaml.Tag?)
  Sequence(Array[Int])
  Mapping(Array[Int])
  Alias(Int)
}

///|
fn Vm::parse_yaml(self : Vm, source : String, loc : Location) -> Value raise {
  if @utf8.encode(source).length() > self.limits.output_bytes {
    raise problem(Limit, loc, "YAML input exceeds output byte limit")
  }
  for c in source.iter() {
    if !(c == '\t' ||
      c == '\n' ||
      c == '\r' ||
      c == '\u0085' ||
      (c >= ' ' && c <= '~') ||
      (c >= '\u00a0' && c <= '\ud7ff') ||
      (c >= '\ue000' && c <= '\ufffd') ||
      c >= '\u{10000}') {
      raise problem(
        Runtime,
        loc,
        "failed to parse YAML: error converting YAML to JSON: yaml: control characters are not allowed",
      )
    }
  }
  // Go splits only on an unindented --- followed by whitespace, then decodes
  // the first YAML document in each chunk.
  let chunks : Array[String] = []
  let mut buffer = StringBuilder()
  let mut stream = false
  let lines = source.split("\n").collect()
  for i, line in lines {
    self.tick(loc)
    if i == lines.length() - 1 && line.is_empty() {
      break
    }
    let line = line.strip_suffix("\r").unwrap_or(line).to_owned()
    if line.has_prefix("---") && line[3:].trim().is_empty() {
      stream = true
      if !buffer.to_string().is_empty() {
        chunks.push(buffer.to_string())
        buffer = StringBuilder()
        continue
      }
    }
    buffer.write_string(line)
    buffer.write_char('\n')
  }
  if !buffer.to_string().is_empty() {
    chunks.push(buffer.to_string())
  }
  if chunks.is_empty() {
    // Pinned Go indexes an empty slice here; preserve a bounded diagnostic.
    raise problem(Runtime, loc, "cannot parse an empty YAML input")
  }
  let saved_output = self.output_bytes
  self.output_bytes = 0
  defer {
    self.output_bytes = saved_output
  }
  let values = chunks.map(chunk => self.yaml_document(chunk, loc))
  self.native_result(
    if stream {
      Json::array(values)
    } else {
      values[0]
    },
    loc,
    0,
  )
}

///|
fn Vm::yaml_document(self : Vm, source : String, loc : Location) -> Json raise {
  let source = source.strip_prefix("\ufeff").unwrap_or(source[:])
  let parser = @yaml.Parser::new(source, max_depth=self.limits.depth)
  let nodes : Array[ParsedYamlNode] = []
  let parents : Array[Int] = []
  let anchors : Map[Int, Int] = Map([])
  let mut root = -1
  while true {
    self.tick(loc)
    let (event, _) = parser.next_token() catch {
      @yaml.YamlError(info="recursion limit exceeded", ..) =>
        raise problem(Limit, loc, "YAML nesting depth limit exceeded")
      @yaml.ParserError(mark~, info~) =>
        raise problem(
          Runtime,
          loc,
          "failed to parse YAML: error converting YAML to JSON: " +
          yaml_parser_error(mark.line, info),
        )
      @yaml.YamlError(mark~, info~) =>
        raise problem(
          Runtime,
          loc,
          "failed to parse YAML: error converting YAML to JSON: " +
          yaml_scanner_error(mark.line, info),
        )
    }
    let (node, anchor) = match event {
      StreamStart | DocumentStart => continue
      StreamEnd | DocumentEnd => break
      MappingEnd | SequenceEnd => {
        ignore(parents.pop())
        continue
      }
      Scalar(value~, style~, id~, tag~) =>
        (ParsedYamlNode::Scalar(value, style, tag), id)
      SequenceStart(id~, ..) => (ParsedYamlNode::Sequence([]), id)
      MappingStart(id~, ..) => (ParsedYamlNode::Mapping([]), id)
      Alias(id~) => {
        guard anchors.get(id) is Some(target) else {
          raise problem(Runtime, loc, "unknown YAML alias")
        }
        (ParsedYamlNode::Alias(target), 0)
      }
    }
    if parents.length() >= self.limits.depth {
      raise problem(Limit, loc, "YAML nesting depth limit exceeded")
    }
    let index = nodes.length()
    nodes.push(node)
    if anchor != 0 {
      anchors[anchor] = index
    }
    if parents.last() is Some(parent) {
      match nodes[parent] {
        Sequence(items) | Mapping(items) => items.push(index)
        _ => abort("YAML parent is a collection")
      }
    } else {
      root = index
    }
    if node is Sequence(_) || node is Mapping(_) {
      parents.push(index)
    }
  }
  if root < 0 {
    return Json::null()
  }
  self.yaml_to_json(nodes, root, Map([]), 0, loc)
}

///|
// The fixed goyaml.v2 decoder reports parser problem lines without the scanner's
// extra increment. Internal Marker lines are one-based; first-line errors omit
// a line prefix in that decoder. Preserve the parser/scanner distinction.
fn yaml_parser_error(line : Int, info : String) -> String {
  let problem = if info.has_prefix("while parsing ") {
    match info.find(", ") {
      Some(index) => info[index + 2:].to_owned()
      None => info
    }
  } else {
    info
  }
  let problem = match problem {
    "duplicate version directive" => "found duplicate %YAML directive"
    "did not find expected <document-start>" =>
      "did not find expected <document start>"
    "the handle wasn't declared" => "found undefined tag handle"
    "the TAG directive must only be given at most once per handle in the same document" =>
      "found duplicate %TAG directive"
    _ if problem.has_prefix("expected ") => "did not find " + problem
    _ => problem
  }
  "yaml: " + (if line > 1 { "line \{line-1}: " } else { "" }) + problem
}

///|
fn yaml_scanner_error(line : Int, info : String) -> String {
  let problem = if info.has_prefix("while ") {
    match info.find(", ") {
      Some(index) => info[index + 2:].to_owned()
      None => info
    }
  } else {
    info
  }
  let problem = match problem {
    "tabs disallowed within this context (block indentation)" =>
      "found character that cannot start any token"
    _ => problem
  }
  "yaml: " + (if line > 1 { "line \{line}: " } else { "" }) + problem
}

///|
fn Vm::yaml_to_json(
  self : Vm,
  nodes : Array[ParsedYamlNode],
  index : Int,
  active : Map[Int, Bool],
  depth : Int,
  loc : Location,
) -> Json raise {
  self.tick(loc)
  if depth >= self.limits.depth {
    raise problem(Limit, loc, "YAML expansion depth limit exceeded")
  }
  if active.get(index).unwrap_or(false) {
    raise problem(Runtime, loc, "YAML alias contains itself")
  }
  active[index] = true
  defer {
    active[index] = false
  }
  match nodes[index] {
    Alias(target) => self.yaml_to_json(nodes, target, active, depth + 1, loc)
    Scalar(s, style, tag) => {
      let (value, _, _) = self.yaml_scalar(s, style, tag, loc)
      if value is Number(n, ..) && (n.is_inf() || n.is_nan()) {
        raise problem(
          Runtime,
          loc,
          "YAML non-finite value cannot be converted to JSON",
        )
      }
      self.account_output(@utf8.encode(value.stringify()).length(), loc)
      value
    }
    Sequence(items) => {
      self.account_output(2 + items.length(), loc)
      Json::array(
        items.map(i => self.yaml_to_json(nodes, i, active, depth + 1, loc)),
      )
    }
    Mapping(items) => {
      let fields : Map[String, Json] = Map([])
      self.account_output(2, loc)
      for i = 0; i < items.length(); i = i + 2 {
        let key = items[i]
        let value = items[i + 1]
        if nodes[key] is Scalar("<<", style, tag) &&
          ((style is @yaml.Plain && tag is None) || yaml_tag(tag) == "merge") {
          let merged = self.yaml_to_json(nodes, value, active, depth + 1, loc)
          if nodes[value] is Alias(_) && !(merged is Object(_)) {
            raise problem(
              Runtime,
              loc,
              "YAML merge alias must reference a mapping",
            )
          }
          match merged {
            Object(o) =>
              for k, v in o {
                fields[k] = v
              }
            Array(a) =>
              for j = a.length() - 1; j >= 0; j = j - 1 {
                guard a[j] is Object(o) else {
                  raise problem(Runtime, loc, "YAML merge requires mappings")
                }
                for k, v in o {
                  fields[k] = v
                }
              }
            _ => raise problem(Runtime, loc, "YAML merge requires mappings")
          }
        } else {
          let name = self.yaml_key(nodes, key, 0, loc)
          self.account_output(
            @utf8.encode(Json::string(name).stringify()).length() + 2,
            loc,
          )
          fields[name] = self.yaml_to_json(nodes, value, active, depth + 1, loc)
        }
      }
      Json::object(fields)
    }
  }
}

///|
fn Vm::yaml_key(
  self : Vm,
  nodes : Array[ParsedYamlNode],
  index : Int,
  depth : Int,
  loc : Location,
) -> String raise {
  self.tick(loc)
  if depth >= self.limits.depth {
    raise problem(Limit, loc, "YAML key depth limit exceeded")
  }
  match nodes[index] {
    Alias(target) => self.yaml_key(nodes, target, depth + 1, loc)
    Scalar(s, style, tag) => {
      let (v, kind, key) = self.yaml_scalar(s, style, tag, loc)
      if kind == "uint" || v is Null {
        raise problem(Runtime, loc, "unsupported YAML map key")
      }
      key
    }
    _ => raise problem(Runtime, loc, "YAML map keys must be scalars")
  }
}

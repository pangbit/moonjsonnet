///|
/// Source location. Lines and UTF-8 byte columns are one-based, matching Go.
pub(all) struct Location {
  file : String
  line : Int
  column : Int
} derive(Debug, Eq)

///|
pub(all) enum ErrorKind {
  Syntax
  Static
  Type
  Runtime
  Assertion
  Import
  Limit
  Unsupported
} derive(Debug, Eq)

///|
pub(all) struct Diagnostic {
  kind : ErrorKind
  message : String
  location : Location
  context : Array[Location]
} derive(Debug)

///|
pub(all) suberror JsonnetError {
  Error(Diagnostic)
} derive(Debug)

///|
pub impl Show for Diagnostic with fn output(self, logger) {
  logger.write_string(self.format())
}

///|
/// Render the error header and context. A positive limit keeps half the context
/// at each end (the outer end gets the odd frame); zero or negative is unlimited.
/// The primary location stays in the header and the stored context is unchanged.
///
/// ```mbt check
/// test {
///   let loc : @moonjsonnet.Location = { file: "example", line: 1, column: 1, }
///   let diagnostic : @moonjsonnet.Diagnostic = {
///     kind: @moonjsonnet.Runtime,
///     message: "failed",
///     location: loc,
///     context: [loc, loc, loc],
///   }
///   assert_eq(
///     diagnostic.format(max_trace=1),
///     "example:1:1: Runtime: failed\n  ...\n  at example:1:1",
///   )
/// }
/// ```
pub fn Diagnostic::format(self : Diagnostic, max_trace? : Int = 0) -> String {
  let logger = StringBuilder()
  logger.write_string(
    "\{self.location.file}:\{self.location.line}:\{self.location.column}: \{Repr(self.kind)}: \{self.message}",
  )
  let write = fn(loc : Location) {
    logger.write_string("\n  at \{loc.file}:\{loc.line}:\{loc.column}")
  }
  let size = self.context.length()
  if max_trace > 0 && size > max_trace {
    let above = max_trace / 2
    let below = max_trace - above
    for loc in self.context[:above] {
      write(loc)
    }
    logger.write_string("\n  ...")
    for loc in self.context[size - below:] {
      write(loc)
    }
  } else {
    for loc in self.context {
      write(loc)
    }
  }
  logger.to_string()
}

///|
/// A host import response. `id` must be a stable canonical identity.
pub(all) struct Source {
  id : String
  text : String
} derive(Debug)

///|
/// Raw import response. Binary data is never decoded as UTF-8.
pub(all) struct BinarySource {
  id : String
  bytes : Bytes
} derive(Debug)

///|
pub extend BinarySource with @debug.Debug::{to_repr}

///|
/// Limits are per evaluation. Byte limits count UTF-8; all must be positive.
/// `stack` counts runtime frames independently of the syntax/evaluation `depth`.
///
/// ```mbt check
/// test {
///   let limits = { ..@moonjsonnet.Limits::default(), stack: 2, }
///   assert_eq(@moonjsonnet.evaluate("local x=42; x", limits~), 42)
/// }
/// ```
pub(all) struct Limits {
  steps : Int
  depth : Int
  stack : Int
  source_bytes : Int
  import_bytes : Int
  imports : Int
  output_bytes : Int
} derive(Debug)

///|
pub fn Limits::default() -> Limits {
  {
    steps: 1000000,
    depth: 200,
    stack: 500,
    source_bytes: 1048576,
    import_bytes: 4194304,
    imports: 128,
    output_bytes: 4194304,
  }
}

///|
fn problem(kind : ErrorKind, loc : Location, message : String) -> JsonnetError {
  Error({ kind, message, location: loc, context: [], })
}

///|
pub extend Location with @debug.Debug::{to_repr}

///|
pub extend Location with Eq::{equal, not_equal}

///|
pub extend ErrorKind with @debug.Debug::{to_repr}

///|
pub extend ErrorKind with Eq::{equal, not_equal}

///|
pub extend Diagnostic with @debug.Debug::{to_repr}

///|
pub extend Diagnostic with Show::{output, to_string}

///|
pub extend JsonnetError with @debug.Debug::{to_repr}

///|
pub extend Source with @debug.Debug::{to_repr}

///|
pub extend Limits with @debug.Debug::{to_repr}

///|
priv struct Expr {
  kind : ExprKind
  loc : Location
  end : Location?
}

///|
priv struct ExprBinding {
  name : String
  value : Expr
  range : SourceRange?
}

///|
priv struct ExprParameter {
  name : String
  default_value : Expr?
  range : SourceRange?
}

///|
priv enum ExprKind {
  NumberLiteral(String)
  Literal(Json)
  Var(String)
  Local(Array[ExprBinding], Expr)
  If(Expr, Expr, Expr)
  Func(Array[ExprParameter], Expr)
  Call(Expr, Array[(String?, Expr)], Bool)
  Arr(Array[Expr])
  Obj(Array[Field], Array[ExprBinding], Array[(Expr, Expr?)])
  ArrayComp(Expr, Array[Clause])
  ObjectComp(Expr, Expr, Array[Clause], Array[ExprBinding])
  Index(Expr, Expr)
  Slice(Expr, Expr?, Expr?, Expr?)
  Unary(String, Expr)
  Binary(String, Expr, Expr)
  Assert(Expr, Expr?, Expr)
  Fail(Expr)
  ImportFile(String, Bool)
  ImportBinary(String)
  StandardFunction(String)
  StandardValue(Json)
}

///|
priv struct Field {
  key : Expr
  value : Expr
  visibility : Int
  additive : Bool
}

///|
priv enum Clause {
  For(String, Expr)
  When(Expr)
}

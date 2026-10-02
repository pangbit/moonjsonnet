///|
/// Source location. Lines and Unicode code-point columns are one-based.
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
  logger.write_string(
    "\{self.location.file}:\{self.location.line}:\{self.location.column}: \{Repr(self.kind)}: \{self.message}",
  )
  for loc in self.context {
    logger.write_string("\n  at \{loc.file}:\{loc.line}:\{loc.column}")
  }
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
pub(all) struct Limits {
  steps : Int
  depth : Int
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
    source_bytes: 1048576,
    import_bytes: 4194304,
    imports: 128,
    output_bytes: 4194304,
  }
}

///|
fn problem(kind : ErrorKind, loc : Location, message : String) -> Error {
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
}

///|
priv enum ExprKind {
  Literal(Json)
  Var(String)
  Local(Array[(String, Expr)], Expr)
  If(Expr, Expr, Expr)
  Func(Array[(String, Expr?)], Expr)
  Call(Expr, Array[(String?, Expr)], Bool)
  Arr(Array[Expr])
  Obj(Array[Field], Array[(String, Expr)], Array[(Expr, Expr?)])
  ArrayComp(Expr, Array[Clause])
  ObjectComp(Expr, Expr, Array[Clause], Array[(String, Expr)])
  Index(Expr, Expr)
  Slice(Expr, Expr?, Expr?, Expr?)
  Unary(String, Expr)
  Binary(String, Expr, Expr)
  Assert(Expr, Expr?, Expr)
  Fail(Expr)
  ImportFile(String, Bool)
  ImportBinary(String)
  StandardFunction(String)
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

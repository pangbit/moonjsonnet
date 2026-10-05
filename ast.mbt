///|
/// Editable semantic syntax tree. Containers may be edited by the caller.
/// Program conversion copies them; comments and formatting are not represented.
pub(all) struct Ast {
  kind : AstKind
  loc : Location
  /// Exclusive end position, or None for a node without a source range.
  end : Location?
}

///|
/// Scalar Literal values only; use Arr/Obj for containers. Field visibility is
/// 1 (inherit), 2 (hidden), or 3 (visible). Call's Bool denotes tailstrict.
pub(all) enum AstKind {
  /// Unsigned decimal token spelling, converted only when evaluated.
  NumberLiteral(String)
  Literal(Json)
  Var(String)
  Local(Array[AstBinding], Ast)
  If(Ast, Ast, Ast)
  Func(Array[AstParameter], Ast)
  Call(Ast, Array[(String?, Ast)], Bool)
  Arr(Array[Ast])
  Obj(Array[AstField], Array[AstBinding], Array[(Ast, Ast?)])
  ArrayComp(Ast, Array[AstClause])
  ObjectComp(Ast, Ast, Array[AstClause], Array[AstBinding])
  Index(Ast, Ast)
  Slice(Ast, Ast?, Ast?, Ast?)
  Unary(String, Ast)
  Binary(String, Ast, Ast)
  Assert(Ast, Ast?, Ast)
  Fail(Ast)
  ImportFile(String, Bool)
  ImportBinary(String)
}

///|
/// Local declaration metadata is independent of the initializer's location.
pub(all) struct AstBinding {
  name : String
  value : Ast
  /// Declaration name through initializer; None for synthetic or lowered local functions.
  range : SourceRange?
}

///|
/// A formal parameter; repeated names are allowed, as in go-jsonnet.
pub(all) struct AstParameter {
  name : String
  default_value : Ast?
  range : SourceRange?
}

///|
pub(all) struct AstField {
  key : Ast
  value : Ast
  visibility : Int
  additive : Bool
}

///|
pub(all) enum AstClause {
  For(String, Ast)
  When(Ast)
}

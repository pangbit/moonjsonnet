///|
/// Editable semantic syntax tree. Containers may be edited by the caller.
/// Program conversion copies them; comments and formatting are not represented.
pub(all) struct Ast {
  kind : AstKind
  loc : Location
}

///|
/// Scalar Literal values only; use Arr/Obj for containers. Field visibility is
/// 1 (inherit), 2 (hidden), or 3 (visible). Call's Bool denotes tailstrict.
pub(all) enum AstKind {
  Literal(Json)
  Var(String)
  Local(Array[(String, Ast)], Ast)
  If(Ast, Ast, Ast)
  Func(Array[(String, Ast?)], Ast)
  Call(Ast, Array[(String?, Ast)], Bool)
  Arr(Array[Ast])
  Obj(Array[AstField], Array[(String, Ast)], Array[(Ast, Ast?)])
  ArrayComp(Ast, Array[AstClause])
  ObjectComp(Ast, Ast, Array[AstClause], Array[(String, Ast)])
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

///|
fn Vm::account_output(self : Vm, size : Int, loc : Location) -> Unit raise {
  if size > self.limits.output_bytes - self.output_bytes {
    raise problem(Limit, loc, "output byte limit exceeded")
  }
  self.output_bytes += size
}

///|
fn Vm::manifest(
  self : Vm,
  value : Value,
  loc : Location,
  depth : Int,
) -> Json raise {
  self.tick(loc)
  if depth >= self.limits.depth {
    raise problem(
      Limit,
      loc,
      "manifest depth limit exceeded (possibly cyclic object)",
    )
  }
  match value {
    ArrayValue(a) => {
      self.account_output(2 + Int::max(0, a.length() - 1), loc)
      Json::array(a.map(t => self.manifest(self.force(t, loc), loc, depth + 1)))
    }
    ObjectValue(id, top) => {
      self.check_assertions(id, loc)
      let keys = self.keys(id, top, false)
      self.account_output(2 + Int::max(0, keys.length() - 1), loc)
      let fields : Map[String, Json] = Map([])
      for k in keys {
        self.account_output(
          @utf8.encode(Json::string(k).stringify()).length() + 1,
          loc,
        )
        fields[k] = self.manifest(self.field(id, top, k, loc), loc, depth + 1)
      }
      Json::object(fields)
    }
    Closure(_, _, _) | Builtin(_) =>
      raise problem(Type, loc, "cannot manifest a function or std")
    _ => {
      let j = match value {
        Nil => Json::null()
        Bool(b) => Json::boolean(b)
        Num(n) => Json::number(n)
        Str(s) => Json::string(s)
        _ => abort("unreachable non-scalar")
      }
      self.account_output(@utf8.encode(j.stringify()).length(), loc)
      j
    }
  }
}

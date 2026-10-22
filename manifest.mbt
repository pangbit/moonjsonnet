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
  self.push_frame(loc, false)
  defer self.pop_frame()
  if depth >= self.limits.depth {
    raise problem(
      Limit,
      loc,
      "manifest depth limit exceeded (possibly cyclic object)",
    )
  }
  try {
    match value {
      ArrayValue(a) => {
        self.account_output(2 + Int::max(0, a.length() - 1), loc)
        let values : Array[Json] = []
        for index, t in a {
          values.push(
            self.with_trace(Synthetic("Array element \{index}"), () => {
              self.manifest(self.force(t, loc), loc, depth + 1)
            }),
          )
        }
        Json::array(values)
      }
      ObjectValue(id, top) => {
        self.with_trace(Synthetic("Checking object assertions"), () => {
          self.check_assertions(id, loc)
        })
        let keys = self.keys(id, top, false)
        self.account_output(2 + Int::max(0, keys.length() - 1), loc)
        let fields : Map[String, Json] = Map([])
        for k in keys {
          self.account_output(
            @utf8.encode(Json::string(k).stringify()).length() + 1,
            loc,
          )
          fields[k] = self.with_trace(Synthetic("Field " + lint_quote(k)), () => {
            self.manifest(self.field(id, top, k, loc), loc, depth + 1)
          })
        }
        Json::object(fields)
      }
      Closure(_, _, _) | Builtin(_) | Native(_) =>
        raise problem(Type, loc, "couldn't manifest function as JSON")
      _ => {
        let j = match value {
          Nil => Json::null()
          Bool(b) => Json::boolean(b)
          Num(n) => {
            ignore(finite(n, loc))
            Json::number(n)
          }
          Str(s) => Json::string(s)
          _ => abort("unreachable non-scalar")
        }
        self.account_output(@utf8.encode(j.stringify()).length(), loc)
        j
      }
    }
  } catch {
    Error(d) => raise Error(self.traced(d))
    e => raise e
  }
}

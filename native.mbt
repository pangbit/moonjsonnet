///|
/// A host callback registered by name in `evaluate(native_functions=...)`.
/// Arguments are fully manifested JSON in parameter order. The callback may
/// raise an error, which becomes a runtime diagnostic at its call site.
pub(all) struct NativeFunction {
  params : Array[String]
  callback : (Array[Json]) -> Json raise
}

///|
fn default_trace(loc : Location, message : String) -> Unit {
  @posix.stderr("TRACE: \{loc.file}:\{loc.line} \{message}")
}

///|
fn Vm::call_native(
  self : Vm,
  function : NativeFunction,
  args : Array[(String?, Int)],
  loc : Location,
) -> Value raise {
  let env = self.call_env(
    function.params.map(n => { name: n, default_value: None, range: None, }),
    args,
    {
      parent: None,
      names: Map([]),
      import_from: "",
      debug_visible: None,
      diagnostic_context: ("$", "anonymous"),
      diagnostic_suppressed: false,
    },
    loc,
  )
  // Native arguments have their own bounded manifestation. Restore the outer
  // counter even when a callback is reached during final output traversal.
  let saved_output = self.output_bytes
  self.output_bytes = 0
  defer {
    self.output_bytes = saved_output
  }
  let values = function.params.map(n => {
    self.manifest(self.force(env.names[n], loc), loc, 0)
  })
  let result = (function.callback)(values) catch {
    e => raise problem(Runtime, loc, e.to_string())
  }
  // Go converts every returned object member eagerly, including members the
  // Jsonnet caller will never read. Copy containers so later host mutations
  // cannot change the value already returned to Jsonnet.
  self.native_result(result, loc, 0)
}

///|
fn Vm::native_result(
  self : Vm,
  value : Json,
  loc : Location,
  depth : Int,
) -> Value raise {
  self.tick(loc)
  if depth >= self.limits.depth {
    raise problem(Limit, loc, "native result depth limit exceeded")
  }
  match value {
    Number(n, ..) => finite(n, loc)
    Array(items) =>
      ArrayValue(
        items.map(item => {
          self.store(Ready(self.native_result(item, loc, depth + 1)))
        }),
      )
    Object(fields) => {
      let env : Env = {
        parent: None,
        names: Map([]),
        import_from: "",
        debug_visible: None,
        diagnostic_context: ("$", "anonymous"),
        diagnostic_suppressed: false,
      }
      let result : Map[String, LayerField] = Map([])
      for name, item in fields {
        env.names[name] = self.store(
          Ready(self.native_result(item, loc, depth + 1)),
        )
        result[name] = {
          field: {
            key: { kind: Literal(Json::string(name)), loc, end: None, },
            value: { kind: Var(name), loc, end: None, },
            visibility: 1,
            additive: false,
          },
          env,
        }
      }
      self.object_value([
        {
          fields: result,
          locals: [],
          assertions: [],
          assertion_sites: [],
          env,
        },
      ])
    }
    Null => Nil
    True => Bool(true)
    False => Bool(false)
    String(s) => Str(s)
  }
}

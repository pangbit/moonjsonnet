///|
fn Vm::object_flat_merge(
  self : Vm,
  items : Array[Int],
  loc : Location,
) -> Value raise {
  let fields : Map[String, LayerField] = Map([])
  let env : Env = { parent: None, names: Map([]), import_from: "", }
  for t in items {
    self.tick(loc)
    guard self.force(t, loc) is ObjectValue(id, top) else {
      raise problem(Type, loc, "$objectFlatMerge requires objects")
    }
    let layers = self.objects[id].layers
    if top != 1 || !layers[0].locals.is_empty() {
      // The reference panics when this compiler helper is called with an
      // extended object or object-local bindings. Keep the host process alive.
      raise problem(
        Runtime,
        loc,
        "$objectFlatMerge requires simple objects without locals",
      )
    }
    for name, field in layers[0].fields {
      self.tick(loc)
      if fields.contains(name) {
        raise problem(Runtime, loc, "duplicate field name: " + name)
      }
      fields[name] = field
    }
  }
  self.object_value([{ fields, locals: [], assertions: [], env, }])
}

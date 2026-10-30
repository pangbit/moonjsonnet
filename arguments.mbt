///|
// Validate the entire call before forcing arguments or inserting defaults.
// Positional overflow precedes named checks; missing names follow declaration
// order, including repeated formal names accepted by the parser.
fn bind_arguments(
  parameters : Array[(String, Bool)],
  arguments : Array[(String?, Int32)],
  location : Location,
) -> Map[String, Int32] raise {
  let positional = arguments.iter().filter(pair => pair.0 is None).count()
  if positional > parameters.length() {
    raise problem(
      Runtime,
      location,
      "function expected \{parameters.length()} positional argument(s), but got \{positional}",
    )
  }
  let accepted : Map[String, Bool] = Map([])
  for (name, _) in parameters {
    accepted[name] = true
  }
  let bound : Map[String, Int32] = Map([])
  let mut position = 0
  for (name, thunk) in arguments {
    match name {
      None => {
        bound[parameters[position].0] = thunk
        position += 1
      }
      Some(name) => {
        if bound.contains(name) {
          raise problem(
            Runtime,
            location,
            "Argument " + name + " already provided",
          )
        }
        if !accepted.contains(name) {
          raise problem(Runtime, location, "function has no parameter " + name)
        }
        bound[name] = thunk
      }
    }
  }
  for (name, required) in parameters {
    if required && !bound.contains(name) {
      raise problem(Runtime, location, "Missing argument: " + name)
    }
  }
  bound
}

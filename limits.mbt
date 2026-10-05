///|
fn check_limits(limits : Limits, loc : Location) -> Unit raise Error {
  if limits.steps <= 0 ||
    limits.depth <= 0 ||
    limits.depth > 512 ||
    limits.stack <= 0 ||
    limits.source_bytes <= 0 ||
    limits.import_bytes <= 0 ||
    limits.imports <= 0 ||
    limits.output_bytes <= 0 {
    raise problem(
      Limit,
      loc,
      "limits must be positive; depth must be at most 512",
    )
  }
}

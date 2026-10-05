///|
/// Scan entries through this host's library search and byte cache. Returned
/// identities are canonical absolute paths confined to the configured root.
pub fn FileHost::find_dependencies(
  self : FileHost,
  paths : Array[String],
  imported_from? : String = "",
  limits? : @moonjsonnet.Limits = @moonjsonnet.Limits::default(),
) -> Array[String] raise @moonjsonnet.JsonnetError {
  @moonjsonnet.find_dependencies(
    imported_from,
    paths,
    resolver=(from, path) => self.resolve_binary(from, path),
    limits~,
  )
}

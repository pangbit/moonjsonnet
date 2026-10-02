local defaults = import 'defaults.libsonnet';
local replicas = std.extVar('replicas');
assert std.isNumber(replicas): 'replicas must be numeric';
defaults + {
  assert self.replicas >= 1 && self.replicas <= 10: 'replicas out of range',
  replicas: replicas,
}

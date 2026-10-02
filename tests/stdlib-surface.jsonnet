[
  {
    name: n,
    type: std.type(std[n]),
    required: if std.type(std[n]) == 'function' then std.length(std[n]) else null,
  }
  for n in std.objectFieldsAll(std)
]

local services = std.parseJson(importstr 'services.json');
local panel(service, index) = {
  id: index + 1,
  title: service.name + ' requests',
  target: service.name + ':' + std.toString(service.port),
  tags: std.split('http,local', ','),
};
{
  title: 'Services',
  panels: [panel(services[i], i) for i in std.range(0, std.length(services)-1)],
  byName: { [service.name]: service.port for service in services },
}

local template = import 'template.libsonnet';
{
  development: template('dev') + { debug: true },
  production: template('prod', replicas=3) + { debug: false },
}

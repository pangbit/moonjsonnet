function(env, replicas=1)
{
  app: 'checkout',
  region: 'local',
  environment: env,
  replicas: replicas,
  endpoint: 'https://' + self.environment + '.example.test',
}

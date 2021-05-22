# StaticDeploy jsonnet library

Jsonnet library for https://staticdeploy.io/

I have written this for exploratory purposes but should run just fine for production.

## Example

```jsonnet
local staticdeploy = import 'staticdeploy/main.libsonnet';
{
  staticdeploy:
    staticdeploy.new('localhost', name='my-staticdeploy')
    + staticdeploy.config.withStoragesSecret(
      postgres_url='postgresql://localhost:5432',
      s3_bucket='my-staticdeploy',
      s3_endpoint='https://storage.googleapis.com',
      s3_access_key_id='someAccessKey',
      s3_secret_access_key='someSecretAccessKey',
    ),
}
```

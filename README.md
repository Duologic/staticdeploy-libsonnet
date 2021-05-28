# StaticDeploy jsonnet library

Jsonnet library for https://staticdeploy.io/

## Usage

Install it with jsonnet-bundler:

```console
jb install https://github.com/Duologic/staticdeploy-libsonnet
```

Import into your jsonnet:

```jsonnet
local staticdeploy = import 'github.com/Duologic/staticdeploy-libsonnet/main.libsonnet';

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

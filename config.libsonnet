local k = import 'ksonnet-util/kausal.libsonnet';

{
  local this = self,

  withStoragesSecret(
    postgres_url,
    s3_bucket,
    s3_endpoint,
    s3_access_key_id,
    s3_secret_access_key
  ):: {
    local secret = k.core.v1.secret,
    storage_secret:
      secret.new(
        super.name + '-pg-s3-storages',
        {
          POSTGRES_URL: std.base64(postgres_url),
          S3_BUCKET: std.base64(s3_bucket),
          S3_ENDPOINT: std.base64(s3_endpoint),
          S3_ACCESS_KEY_ID: std.base64(s3_access_key_id),
          S3_SECRET_ACCESS_KEY: std.base64(s3_secret_access_key),
        },
        'Opaque',
      ),
    container+: this.withStoragesSecretRef(self.storage_secret.metadata.name).container,
  },

  withStoragesSecretRef(secretRefName):: {
    local container = k.core.v1.container,
    local envVar = k.core.v1.envVar,
    container+::
      container.withEnvMixin([
        envVar.fromSecretRef('POSTGRES_URL', secretRefName, 'POSTGRES_URL'),
        envVar.fromSecretRef('S3_BUCKET', secretRefName, 'S3_BUCKET'),
        envVar.fromSecretRef('S3_ENDPOINT', secretRefName, 'S3_ENDPOINT'),
        envVar.fromSecretRef('S3_ACCESS_KEY_ID', secretRefName, 'S3_ACCESS_KEY_ID'),
        envVar.fromSecretRef('S3_SECRET_ACCESS_KEY', secretRefName, 'S3_SECRET_ACCESS_KEY'),
      ]),
  },

  withJWTKey(key):: {
    local secret = k.core.v1.secret,
    jwt_secret:
      secret.new(
        super.name + '-jwt-key',
        {
          JWT_SECRET_OR_PUBLIC_KEY: std.base64(key),
        },
        'Opaque',
      ),
    container+: this.withJWTKeySecretRef(self.jwt_secret.metadata.name).container,
  },

  withJWTKeySecretRef(secretRefName):: {
    local container = k.core.v1.container,
    local envVar = k.core.v1.envVar,
    container+::
      container.withEnvMixin([
        envVar.fromSecretRef('JWT_SECRET_OR_PUBLIC_KEY', secretRefName, 'JWT_SECRET_OR_PUBLIC_KEY'),
      ]),
  },

  withOIDC(url, client_id, name='StaticDeploy'):: {
    local container = k.core.v1.container,
    container+::
      container.withEnvMap({
        OIDC_CONFIGURATION_URL: url,
        OIDC_CLIENT_ID: client_id,
        OIDC_PROVIDER_NAME: name,
      }),
  },

  withHostnameHeader(header_name):: {
    local container = k.core.v1.container,
    container+::
      container.withEnvMap({
        HOSTNAME_HEADER: header_name,
      }),
  },
}

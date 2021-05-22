local k = import 'ksonnet-util/kausal.libsonnet';

function(
  mgmt_hostname,
  name='staticdeploy',
  port=8080,
  auth=true,
) {
  local this = self,

  image:: 'staticdeploy/staticdeploy:v0.15.4',

  container_env:: {
    MANAGEMENT_HOSTNAME: mgmt_hostname,
    PORT: std.toString(port),
    ENABLE_MANAGEMENT_ENDPOINTS: 'true',
    MAX_REQUEST_BODY_SIZE: '100mb',
    ENFORCE_AUTH: std.toString(auth),
    CREATE_ROOT_USER: 'true',
  },

  withStoragesSecret(
    postgres_url,
    s3_bucket,
    s3_endpoint,
    s3_access_key_id,
    s3_secret_access_key
  ):: {
    local secret = k.core.v1.secret,
    secret:
      secret.new(
        'pg-s3-storages',
        {
          POSTGRES_URL: std.base64(postgres_url),
          S3_BUCKET: std.base64(s3_bucket),
          S3_ENDPOINT: std.base64(s3_endpoint),
          S3_ACCESS_KEY_ID: std.base64(s3_access_key_id),
          S3_SECRET_ACCESS_KEY: std.base64(s3_secret_access_key),
        },
        'Opaque',
      ),
    container+: this.withStoragesSecretRef(self.secret.metadata.name).container,
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

  local container = k.core.v1.container,
  container::
    container.new('staticdeploy', this.image)
    + container.withPorts([
      k.core.v1.containerPort.newNamed(name='http', containerPort=port),
    ])
    + container.withEnvMap(this.container_env)
    + container.withImagePullPolicy('IfNotPresent')
    + container.readinessProbe.httpGet.withHttpHeaders([
      k.core.v1.httpHeader.withName('Host')
      + k.core.v1.httpHeader.withValue(mgmt_hostname),
    ])
    + container.readinessProbe.httpGet.withPath('/api/health')
    + container.readinessProbe.httpGet.withPort(port)
    + container.readinessProbe.httpGet.withScheme('HTTP')
    + container.readinessProbe.withFailureThreshold(3)
    + container.readinessProbe.withTimeoutSeconds(1)
    + k.util.resourcesRequests('20m', '20Mi')
  ,

  local deployment = k.apps.v1.deployment,
  deployment:
    deployment.new(name, replicas=1, containers=[this.container])
  ,

  service:
    k.util.serviceFor(this.deployment),
}

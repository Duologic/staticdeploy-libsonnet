local k = import 'ksonnet-util/kausal.libsonnet';

function(
  mgmt_hostname,
  name='staticdeploy',
  port=8080,
  auth=true,
  image='staticdeploy/staticdeploy:v0.15.4',
) {
  local this = self,

  name:: name,

  config:: (import 'config.libsonnet'),

  container_env:: {
    MANAGEMENT_HOSTNAME: mgmt_hostname,
    PORT: std.toString(port),
    ENABLE_MANAGEMENT_ENDPOINTS: 'true',
    MAX_REQUEST_BODY_SIZE: '100mb',
    ENFORCE_AUTH: std.toString(auth),
    CREATE_ROOT_USER: 'true',
  },

  local container = k.core.v1.container,
  container::
    container.new('staticdeploy', image)
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

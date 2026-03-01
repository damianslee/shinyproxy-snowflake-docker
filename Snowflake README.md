# ShinyProxy Docker files

This repository contains the Dockerfiles of the Docker images of the
ShinyProxy with support for Snowflake SnowPark Container Services backend.
This allows you to inspect how our images are build and to
build your own image.

## ShinyProxy for SPCS

The Dockerfile for ShinyProxy on SPCS can be found in the
[ShinyProxy directory](ShinyProxy/Dockerfile). The same Dockerfile is used for building
development, snapshot and production images.

Note: SPCS is only amd64.  Use docker build --platform linux/amd64

## SnowPark Container Services Setup
SPCS requires a paid Snowflake account; it is not currently available in trial accounts.

ShinyProxy runs containerised on SPCS as a Service with a public endpoint, and creates private
services per user via the REST API.

ShinyProxy implements the SPCS support by specifying "container-backend: spcs" and "authentication: spcs".

```
  authentication: spcs
  container-backend: spcs
  stop-proxies-on-shutdown: false
  recover-running-proxies: true
  spcs:
    compute-pool: my_compute_pool
    compute-warehouse: my_warehouse   # optional; required for RBAC (admin-groups, access-groups) when using authentication: spcs
    use-role: MY_PROXY_SERVICES_ROLE  # optional
```

### SPCS Authentication

SPCS Authentication obtains the users identity from the injected HTTP header "Sf-Context-Current-User".
When the ShinyProxy SPCS service has been configured with executeAsCaller=True, then ContainerProxy is 
able to obtain via impersonation of the users current available Snowflake roles.  Which is then used for RBAC of 
ShinyProxy admin-groups and access-groups application.yml config.
The "compute-warehouse" is currently required for getting users current roles as there is no REST API for this.


### SPCS Service

Once the ShinyProxy image is loaded into a Snowflake Image Repository a Service can be created.
Obtain the public DNS URL from *SHOW ENDPOINTS*.
When Azure or AWS private link is configured with Snowflake, 
(Business Critical sku) the private URL can be used to access ShinyProxy.

```
-- https://docs.snowflake.com/en/sql-reference/sql/create-service
USE ROLE <service_owner_role>;

CREATE SERVICE IF NOT EXISTS MY_DB.MY_SHINYPROXY.SHINYPROXY
  IN COMPUTE POOL MY_COMPUTE_POOL
     fromSpecification
     <todo>
  AUTO_RESUME = TRUE
  MIN_INSTANCES = 1
  MIN_READY_INSTANCES = 1
  MAX_INSTANCES = 1
  LOG_LEVEL = 'DEBUG'
  COMMENT = 'ShinyProxy on SPCS';


SHOW ENDPOINTS IN SERVICE MY_DB.MY_SHINYPROXY.SHINYPROXY;

GRANT USAGE ON SERVICE ROLE <x> TO ROLE MY_SHINYPROXY_USERS;

```

### Applications

ShinyProxy with SPCS backend will create Services on demand for each users' application instance.
This will be a private SPCS service owned by the same Snowflake role which the ShinyProxy Service is 
running as.
The service will have the naming convention "SP_SERVICE__<proxy guid>", and the service comment will have
shinyproxy metadata describing the proxy.


#### Application Database and Schema

The database and schema for proxy service creation are resolved as follows:

- **Database:** Uses `proxy.spcs.database` from application YAML if set. Otherwise uses `SNOWFLAKE_DATABASE` environment variable (injected by Snowflake based on where the ShinyProxy service is defined).
- **Schema:** Uses `proxy.spcs.schema` from application YAML if set. Otherwise uses `SNOWFLAKE_SCHEMA` environment variable (injected by Snowflake).

Application YAML config overrides the environment variables.


#### Application Service Onwer Role

When `use-role` is set, all SPCS REST API calls (create, list, suspend, resume, delete services) use the specified role for authorization. Proxy services created will be owned by that role. The ShinyProxy service owner role must have `GRANT USAGE ON ROLE <role> TO ROLE <shinyproxy_owner>`.

```
  spcs:
    use-role: MY_PROXY_SERVICES_ROLE  # optional
```


#### Application External Access Integrations

Snowflake by default does not provide internet access to containers.  External access is provided via
External Access Integration(s).  ShinyProxy application spec config supports a list of Snowflake external access 
integrations.
Note: not available on Trial Snowflake accounts.

**Permissions:** The ShinyProxy owner Snowflake role must be granted `USAGE` on each external access integration used by your specs (e.g. `GRANT USAGE ON INTEGRATION <eai_name> TO ROLE <shinyproxy_owner_role>`).

```
  specs:
    - id: 01_hello_sf
      ...
      spcs-external-access-integrations:
        - <My EAI Name>
```


#### Application Secrets
Secrets can be mounted as files (directory-path) or as environment variables (env-var-name; requires secret-key-ref: "username", "password", or "secret_string"). Specify the secret with either object-name or object-reference. See the [SPCS specification reference](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/specification-reference).

**Permissions:** The ShinyProxy owner Snowflake role must be granted `USAGE` on each secret used by your specs (e.g. `GRANT USAGE ON SECRET <secret_name> TO ROLE <shinyproxy_owner_role>`).

```yaml
  specs:
    - id: 01_hello_sf
      ...
      spcs-secrets:               # optional
        - object-name: MY_DB.MY_SCHEMA.MY_SECRET
          directory-path: /secrets
        # Or as environment variable:
        - object-name: MY_DB.MY_SCHEMA.MY_SECRET
          env-var-name: MY_ENV_VAR
          secret-key-ref: secret_string
```

#### Application Volumes
Volumes are defined with `spcs-volumes` and mounted via `container-volumes` (format: `volume-name:mount-path`). Supported sources: `local`, `stage`, `memory`, `block`. For block and memory, `size` is required (e.g. `20` or `20Gi`).

**Permissions (stage volumes):** When using `source: stage`, the ShinyProxy owner Snowflake role must be granted `USAGE` on each stage used (e.g. `GRANT USAGE ON STAGE <stage_name> TO ROLE <shinyproxy_owner_role>`).

See the [SPCS specification reference](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/specification-reference).

To avoid potential errors related to file user permissions, it’s important to set the UID (User ID) and GID (Group ID) of the container as part of the specification. Set `uid` and `gid` when using a non-root user. See [file permissions on mounted volumes](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/specification-reference#about-file-permissions-on-mounted-volumes).

```yaml
  specs:
    - id: 01_hello_sf
      ...
      container-volumes: ["my-volume:/mnt/my-volume"]
      spcs-volumes:
        - name: my-volume
          source: block
          size: 20
          uid: 1000              # optional
          gid: 1000              # optional
          # Optional for block: block-config (iops, throughput, encryption, snapshot-on-delete, initial-contents.from-snapshot)
        # Stage volume: source: stage with stage-config (name, metadata-cache, resources)
```

#### Readiness probe (optional)
To control when the container is considered ready for traffic, set `spcs-readiness-probe` with `port` and `path` (HTTP path to probe):

```yaml
      spcs-readiness-probe:
        port: 3838
        path: /
```

#### Per-spec overrides (optional)
You can override `compute-pool`, `database`, and `schema` per spec with `spcs-compute-pool`, `spcs-database`, and `spcs-schema`.



## SPCS FAQ
1. How to restart the ShinyProxy service once the image has been updated?
A: SPCS stores the SHA256 of the image, not the tag when the Service was created.  To reload a newer image with
the same tag, ALTER the service using the same specification

```
todo
```

2. How to restart the ShinyProxy service when the image has not been updated.  Eg some dependency on config in a stage.
A: Suspending a SPCS service will terminate the compute usage.  Resuming will launch a new container instance.  A small
outage will occur.  The public DNS will be the same.

```
ALTER SERVICE SHINYPROXY SUSPEND;
ALTER SERVICE SHINYPROXY RESUME;
```



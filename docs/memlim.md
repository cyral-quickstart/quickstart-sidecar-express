# Memory Limiting

Each of the individual services within the sidecar have a default
memory limit. The memory limit is a maximum number of bytes that a service is 
allowed to consume. This is useful to prevent a single service from consuming
all available memory on the container and causing other services to fail as a
result. Currently, each "wire" service has a default memory limit of `512MB`
while other services are limited to `128MB`.

Users can override the default memory limits if desired by setting various 
environment variables as detailed below.

## Environment Variables

The following environment variables can be set to override the default memory
limits.

Wires (default `512MB` since `v4.15.1` and `128MB` on all previous versions):

* `CYRAL_DREMIO_WIRE_MAX_MEM`
* `CYRAL_DYNAMODB_WIRE_MAX_MEM`
* `CYRAL_MONGODB_WIRE_MAX_MEM`
* `CYRAL_MYSQL_WIRE_MAX_MEM`
* `CYRAL_ORACLE_WIRE_MAX_MEM`
* `CYRAL_PG_WIRE_MAX_MEM`
* `CYRAL_S3_WIRE_MAX_MEM`
* `CYRAL_SNOWFLAKE_WIRE_MAX_MEM`
* `CYRAL_SQLSERVER_WIRE_MAX_MEM`

Misc. services (default `128MB`):

* `ALERTER_MAX_SYS_SIZE_MB`
* `CYRAL_AUTHENTICATOR_MAX_SYS_SIZE_MB`
* `FORWARD_PROXY_MAX_SYS_SIZE_MB`
* `NGINX_PROXY_HELPER_MAX_SYS_SIZE_MB`
* `SERVICE_MONITOR_MAX_SYS_SIZE_MB`

Values should be set in megabytes (`MB`). For example, to set the memory limit
for the PostgreSQL wire service to `1GB`, set `CYRAL_PG_WIRE_MAX_MEM=1024`.

The environment variables passed to the sidecar container are set in the file
`/home/ec2-user/.env`. Any changes to the memory limits as environment variables
should be made in this file (see next section).

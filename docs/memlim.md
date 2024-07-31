# Memory Limiting

Each of the individual services within the sidecar has a default
memory limit. The memory limit is a maximum number of bytes that a service is 
allowed to consume. This is useful to prevent a single service from consuming
all available memory on the container and causing other services to fail as a
result.

Refer to the [Memory Limits](https://cyral.com/docs/sidecars/deployment/memory-limits)
page of our public docs for more details.

In order to change the memory limits for your sidecar container, override the
default settings using the [environment variables](https://cyral.com/docs/sidecars/deployment/memory-limits#environment-variables)
detailed in our public docs.

## Setting memory limits via environment file

An environment file can be used to configure the memory limits for the services.
The following is an example file to set the memory limit for the PostgreSQL and SQLServer
wires services to `1GB`:

```bash
CYRAL_PG_WIRE_MAX_MEM=1024
CYRAL_SQLSERVER_WIRE_MAX_MEM=1024
```

The initialization parameter `ENV_FILE_PATH` can be used to provide the path to
the environment file to the express installer. Assuming the file is stored in
`/Users/root/env_sidecar`, the new configuration can be provided to the 
express installer by prepending this variable declaration to the command
retrieved from the Cyral control plane as follows:

```bash
ENV_FILE_PATH=/Users/root/env_sidecar CLIENT_ID=<client-id> CLIENT_SECRET=-<client-secret> SIDECAR_ID=<sidecar-id> CONTROL_PLANE=<control-plane> bash -c "$(curl -fsSL https://raw.githubusercontent.com/cyral-quickstart/quickstart-sidecar-express/main/install-sidecar.sh)"
```

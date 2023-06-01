# Advanced configuration

## Certificates

_Added in sidecar version v4.7_

To provide a custom certificate to the sidecar, include the following
environment variables in an env file:

```shell
CYRAL_SIDECAR_TLS_CERT=        # x509 TLS certificate
CYRAL_SIDECAR_TLS_PRIVATE_KEY= # private key corresponding to TLS cert
CYRAL_SIDECAR_CA_CERT=         # x509 CA certificate
CYRAL_SIDECAR_CA_PRIVATE_KEY=  # private key corresponding to CA cert
```

Provide the env file to the script with the variable `envFilePath`.

Note that the contents of the environment variables **must be encoded in
base64**. For instance, if your TLS certificate is:

```
-----BEGIN CERTIFICATE-----
aGVsbG8gd29ybGQK
-----END CERTIFICATE-----
```

You would provide the following input to `CYRAL_SIDECAR_TLS_CERT`:

```
CYRAL_SIDECAR_TLS_CERT=LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCmFHVnNiRzhnZDI5eWJHUUsKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
```

To learn more about sidecar certificates, visit the official Cyral docs:
[Sidecar Certificates](https://cyral.com/docs/sidecars/sidecar-certificates).

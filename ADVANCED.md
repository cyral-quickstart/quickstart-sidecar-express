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

> **Note:** the contents of these environment variables **must be encoded in base64**.

If, for example, your TLS certificate has the following contents in the
`tls-cert.pem` file:

```
-----BEGIN CERTIFICATE-----
aGVsbG8gd29ybGQK
-----END CERTIFICATE-----
```

And something similar for the private key, stored in `tls-key.pem`:

```
-----BEGIN RSA PRIVATE KEY-----
aGVsbG8gd29ybGQK
-----END RSA PRIVATE KEY-----
```

You could use the following command to create an env file with your custom TLS
certificate:

```
cat > .env <<EOF
CYRAL_SIDECAR_TLS_CERT=$(cat 'tls-cert.pem' | base64 -w 0)
CYRAL_SIDECAR_TLS_PRIVATE_KEY=$(cat 'tls-key.pem' | base64 -w 0)
EOF
```

To learn more about sidecar certificates, visit the official Cyral docs:
[Sidecar Certificates](https://cyral.com/docs/sidecars/sidecar-certificates).

# Configuring certificates for Cyral sidecars

You can use Cyral's default [sidecar-created
certificate](https://cyral.com/docs/sidecars/deployment/certificates#sidecar-created-certificate) or use a
[custom certificate](https://cyral.com/docs/sidecars/deployment/certificates#custom-certificate) to secure
the communications performed by the sidecar. In this page, we provide
instructions on how to use a custom certificate.

> [!NOTE]
> Custom certificates are supported since sidecar version `v4.7`.

To provide a custom certificate to the sidecar, include the following
environment variables in an env file:

```dotenv
CYRAL_SIDECAR_TLS_CERT=        # x509 TLS certificate
CYRAL_SIDECAR_TLS_PRIVATE_KEY= # private key corresponding to TLS cert
CYRAL_SIDECAR_CA_CERT=         # x509 CA certificate
CYRAL_SIDECAR_CA_PRIVATE_KEY=  # private key corresponding to CA cert
```

Provide the env file to the script with the variable `envFilePath`.

> [!IMPORTANT]
> The contents of these environment variables **must be encoded in base64**.

If, for example, your TLS certificate has the following contents in the
`tls-cert.pem` file:

```text
-----BEGIN CERTIFICATE-----
aGVsbG8gd29ybGQK
-----END CERTIFICATE-----
```

And something similar for the private key, stored in `tls-key.pem`:

```text
-----BEGIN RSA PRIVATE KEY-----
aGVsbG8gd29ybGQK
-----END RSA PRIVATE KEY-----
```

You could use the following command to create an env file with your custom TLS
certificate:

```shell
cat > .env <<EOF
CYRAL_SIDECAR_TLS_CERT=$(cat 'tls-cert.pem' | base64 -w 0)
CYRAL_SIDECAR_TLS_PRIVATE_KEY=$(cat 'tls-key.pem' | base64 -w 0)
EOF
```

To learn more about sidecar certificates, visit the official Cyral docs:
[Sidecar Certificates](https://cyral.com/docs/sidecars/sidecar-certificates).
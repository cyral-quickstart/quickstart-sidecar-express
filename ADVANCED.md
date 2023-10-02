# Advanced configuration

Most of these configuration options will leverage the env file set by `ENV_FILE_PATH` to
provide these variables to the sidecar.

## Database Accounts

If you are using local credentails for testing, as part of the install script you will have the option to use an enviroment file to provide those credentials to the sidecar.

The value of the secret should be in the following format

```json
{"username":"someuser","password":"somepassword","databaseName":"db1"}
```

An example of what the env file should look like:

```shell
REPO_DATA={"username":"someuser","password":"somepassword","databaseName":"db1"}
```

To learn more about sidecar certificates, visit the official Cyral docs:
[Register database accounts](https://cyral.com/docs/manage-user-access/database-accounts).

## Certificates

_Added in sidecar version v4.7_

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

### Snowflake Configuration

To enable snowflake support, provide these variables and values in the env file.

```dotenv
CYRAL_SSO_LOGIN_URL=             # This setting holds the Identity provider single sign-on URL of the SAML app.
CYRAL_IDP_CERTIFICATE=           # Certificiate provided by SAML app
CYRAL_SIDECAR_IDP_PUBLIC_CERT=   # The X.509 certificate of the SAML app, formatted as a single line
CYRAL_SIDECAR_IDP_PRIVATE_KEY=   # Private key for cert provided by SAML app
```

To learn more about sidecar certificates, visit the official Cyral docs:
[SSO for Snowflake](https://cyral.com/docs/manage-repositories/sso-for-snowflake/#configure-your-cyral-sidecar-as-the-idp-in-snowflake).

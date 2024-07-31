# Snowflake Configuration

To enable snowflake support, provide these variables and values in the env file.

```dotenv
CYRAL_SSO_LOGIN_URL=             # This setting holds the Identity provider single sign-on URL of the SAML app.
CYRAL_IDP_CERTIFICATE=           # Certificiate provided by SAML app
CYRAL_SIDECAR_IDP_PUBLIC_CERT=   # The X.509 certificate of the SAML app, formatted as a single line
CYRAL_SIDECAR_IDP_PRIVATE_KEY=   # Private key for cert provided by SAML app
```

To learn more, visit the official Cyral docs:
[SSO for Snowflake](https://cyral.com/docs/how-to/sso/snowflake).

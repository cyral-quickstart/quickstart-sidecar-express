# Database Accounts

If you are using local credentials for testing, as part of the install script you will have the option to use an environment file to provide those credentials to the sidecar.

The value of the secret must be in the following format

```json
{"username":"someuser","password":"somepassword","databaseName":"db1"}
```

An example of what the env file should look like:

```shell
REPO_DATA={"username":"someuser","password":"somepassword","databaseName":"db1"}
```

For more details, check the [Database accounts](https://cyral.com/docs/data-repos/access-rules/database-accounts) documentation.
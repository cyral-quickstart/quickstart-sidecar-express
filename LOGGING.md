# Logging Configuration for POC

The install script will allow for a fluent-bit based logging option that can be configured with a standard output 

# Enable Fluent based logging

If you want to use a fluent based config there are two env variables related to this.

`outputConfig` should be supplied to enabled Fluent Bit Logging. The examples below provide some options. 

If you'd like to run a custom image, or an internal image you can use the `fluentBitImage` variable to override the default value of `fluent/fluent-bit:latest`

# Output Configuration Examples

All options and configuration information can be found at https://docs.fluentbit.io/manual/pipeline/outputs

- [Stdout te](#Stdout)
- [Amazon Cloudwatch](#Amazon-Cloudwatch)
- [Amazon S3](#Amazon-S3)
- [Datadog](#Datadog)
- [Elasticsearch](#Elasticsearch)
- [Opensearch](#Opensearch)
- [Splunk](#Splunk)

## Stdout

[Documentation](https://docs.fluentbit.io/manual/pipeline/outputs/standard-output)

Dump to stdout, simple way to see how it works

```
[OUTPUT]
    Name    stdout
    Match   *
```

## Amazon Cloudwatch

[Documentation](https://docs.fluentbit.io/manual/pipeline/outputs/cloudwatch)

```
[OUTPUT]
    Name cloudwatch_logs
    Match   *
    region us-east-1
    log_group_name fluent-bit-cloudwatch
    log_stream_prefix from-fluent-bit-
    auto_create_group On
```

## Amazon S3

[Documentation](https://docs.fluentbit.io/manual/pipeline/outputs/s3)

```
[OUTPUT]
    Name                         s3
    Match                        *
    bucket                       my-bucket
    region                       us-west-2
    total_file_size              250M
    s3_key_format                /$TAG[2]/$TAG[0]/%Y/%m/%d/%H/%M/%S/$UUID.gz
    s3_key_format_tag_delimiters .-
```

## Datadog

[Documentation](https://docs.fluentbit.io/manual/pipeline/outputs/datadog)

```
[OUTPUT]
    Name        datadog
    Match       *
    Host        http-intake.logs.datadoghq.com
    TLS         on
    compress    gzip
    apikey      <my-datadog-api-key>
    dd_service  <my-app-service>
    dd_source   <my-app-source>
    dd_tags     team:logs,foo:bar
```

## Elasticsearch

[Documentation](https://docs.fluentbit.io/manual/pipeline/outputs/elasticsearch)

```
[OUTPUT]
    Name  es
    Match *
    Host  192.168.2.3
    Port  9200
    Index my_index
    Type  my_type
```

## Opensearch

[Documentation](https://docs.fluentbit.io/manual/pipeline/outputs/opensearch)

```
[OUTPUT]
    Name  opensearch
    Match *
    Host  192.168.2.3
    Port  9200
    Index my_index
    Type  my_type
```

## Splunk

[Documentation](https://docs.fluentbit.io/manual/pipeline/outputs/splunk)

```
[OUTPUT]
    Name        splunk
    Match       *
    Host        127.0.0.1
    Splunk_Token xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx
    Splunk_Send_Raw On
```

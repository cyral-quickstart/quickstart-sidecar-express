# Sidecar - Express Install

A quick start for a Express to get a simple sidecar online quickly!

An install command can be generated on the sidecar deployment page.

Learn more in the [Sidecar Deployment](https://cyral.com/docs/sidecars/deployment/) page.

## Cloud Deployment Instructions

The above command will work on just about any system, but you can follow the below directions to create a new instance for the sidecar.

<details>
    <summary>AWS EC2</summary>

1. Go to [EC2 Service](https://console.aws.amazon.com/ec2)
1. Select [Launch Instance](https://console.aws.amazon.com/ec2/v2/home#LaunchInstances) and provide the following info
    1. Name: Provide something meaningful like CyralSidecar
    1. Amazon Machine Image (AMI): The default Amazon Linux image and options are fine, but most linux based images should work
    1. Instance Type: Our recommended flavor is M5.large, but a T3 or T2 large will work well for a express install as well
    1. Key Pair: Select or create one
    1. Network Settings: Utilize the Edit button on the section header to create a new Security Group for this express install
        1. Make sure Create Security Group is selected
        1. Security Group Name: Provide a useful name like cyral-sidecar-express
        1. Description: This is required so provide a description
        1. Inbound Security Rules:
            1. ssh - This rule should already exist, but review the Source Type and Source to make sure its appropriate for your environment
            1. Add Security Group Rule: One per DB type you'd like to test
                1. Type: Custom TCP
                1. Port Range: This is the port or range of ports where database clients will connect to this database through the Cyral sidecar
                1. Source Type / Source: Provide approrpriate values that will allow your database clients to connect to this port
    1. Launch Instance!
1. SSH to the new instance and install the sidecar with the above command

</details>

<details>
    <summary>Azure VM</summary>

1. Go to [Virtaual Machines](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Compute%2FVirtualMachines)
1. Select Create -> [Azure virtual Machine](https://portal.azure.com/#create/Microsoft.VirtualMachine)
1. Required fields outlined below
    1. Image: Ubuntu Server 20.04 is the optimal option, however other linux based images should work well too
    1. Size: A typical express install should work well with a Standard_D2s_v3 (2 cpu/8gb)
    1. Inbound Ports: you'll want to provide ssh access as well as the approrpiate DB ports you'll want the clients to connect to
    1. Configure network as needed so both the client has access to the instance, and the instance has access to the DB
    1. Create Instance!
1. SSH to the new instance and install the sidecar with the above command

</details>

## Custom Setup Options

The following command can be used to invoke the script and is what is provided by the Express Install Command

```sh
CLIENT_ID=<client id> \
CLIENT_SECRET=<client secret> \
SIDECAR_ID=<sidecar id> \
CONTROL_PLANE=<control plane host> \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/cyral-quickstart/quickstart-sidecar-express/main/install-sidecar.sh)"
```

### Parameters provided by the control plane

|Name|Description|
|---|---|
|`CLIENT_ID`|Sidecar credentials|
|`CLIENT_SECRET`|Sidecar credentials|
|`CONTROL_PLANE`|URL of the control plane|
|`SIDECAR_ID`|Sidecar ID to use|

### Optional parameters

|Name|Description|
|---|---|
|`SIDECAR_VERSION`|Version to use for the sidecar **(required below version v4.10)**|
|`CONTAINER_REGISTRY`|Where to pull images from|
|`REGISTRY_KEY`| Base64 encoded docker login credentials|
|`ENV_FILE_PATH`|Environment variable file to use|
|`ENDPOINT`|Address to advertise to the CP for configuration|
|`IMAGE_PATH`|Will override the image used (path/image/tag). Typicaly used for local development|
|`LOG_DRIVER`|This controls the docker logging driver. default: `local`|
|`LOG_OPT`|Additional logging driver options provided as space delimited options. default: `max-size=500m`|

## Advanced

Instructions for advanced deployment configurations are available for the following topics:

* [Database accounts](./docs/database-accounts.md)
* [Sidecar certificates](./docs/certificates.md)
* [Snowflake configuration](./docs/snowflake.md)

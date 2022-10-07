# Quickstart Sidecar POC

A quick start for a POC to get a simple sidecar online quickly!

Install with a single command

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/cyral-quickstart/quickstart-sidecar-poc/main/install-poc.sh)"
```

# Cloud Deployment Instructions

The above command will work on just about any system, but you can follow the below directions to create a new instance for the sidecar.

<details>
    <summary>AWS EC2</summary>

1. Go to [EC2 Service](https://console.aws.amazon.com/ec2)
1. Select [Launch Instance](https://console.aws.amazon.com/ec2/v2/home#LaunchInstances) and provide the following info
    1. Name: Provide something meaningful like CyralSidecar
    1. Amazon Machine Image (AMI): The default Amazon Linux image and options are fine, but most linux based images should work
    1. Instance Type: Our recommended flavor is M5.large, but a T3 or T2 large will work well for a POC as well
    1. Key Pair: Select or create one
    1. Network Settings: Utilize the Edit button on the section header to create a new Security Group for this POC
        1. Make sure Create Security Group is selected
        1. Security Group Name: Provide a useful name like cyral-sidecar-poc
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
    1. Size: A typical POC should work well with a Standard_D2s_v3 (2 cpu/8gb)
    1. Inbound Ports: you'll want to provide ssh access as well as the approrpiate DB ports you'll want the clients to connect to
    1. Configure network as needed so both the client has access to the instance, and the instance has access to the DB
    1. Create Instance!
1. SSH to the new instance and install the sidecar with the above command

</details>

# Advanced Setup Options

The script will bypass all prompts if the values are provided by environment variables. Addtional variables are available for the Logging Setup.

|Name|Description|
|---|---|
|containerRegistry|Where to pull images from|
|controlPlaneUrl|URL of the control plane|
|sidecarId|Sidecar ID to use|
|sidecarVersion|Version to use for the sidecar|
|envFilePath|Environment variable file to use|
|endpoint|Address to advertise to the CP for configuration|
|---|---|
|secretBlob| Json Blob from Sidecar creation|
|---|---|
|clientId|From json blob|
|clientSecret|From json blob|
|registryKey| From json blob, Base64 encoded docker login credentials|

# Logging Option

By default standard docker logging will apply.
Logging can be setup as a step in the install script where you will paste the Fluent-Bit output config. 

More info can be found in [LOGGING.md](../main/LOGGING.md)

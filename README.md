# Quickstart Sidecar POC

A quick start for a POC to get a simple sidecar online quickly!

Install with a single command

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/cyral-quickstart/quickstart-sidecar-poc/main/install-poc.sh)"
```

# Deploy an Instance

## AWS EC2

1. Go to [EC2 Service](https://console.aws.amazon.com/ec2)
1. Select [Launch Instance](https://console.aws.amazon.com/ec2/v2/home#LaunchInstances) and provide the following info
    1. Name: Provide something meaningful like CyralSidecar
    1. Amazon Machine Image (AMI): The default Amazon Linux image and options are fine, but most images should work fine
    1. Instance Type: Our recommended flavor is M5.large, but a T3 or T2 large will work well for a POC as well
    1. Key Pair: Select or create one
    1. Security Group: You can use a precreated one or create a new one. You'll want to make sure it has SSH access. *Make note of the name*, we'll have to modify it for the DB Ports
    1. Launch Instance!
1. Update the [Security Group](https://console.aws.amazon.com/ec2/v2/home#SecurityGroups) ports for the desired database
    1. Find the Secrity Group created above
    1. Edit Inbound Rules
    1. Provide the Port and CIDR 
1. SSH to the new instance and Install the sidecar with the above command.
# Advanced Setup

The script will bypass all prompts if the values are provided by environment vairables. Addtional variables are available for the Logging Setup.

|Name|Description|
|---|---|
|containerRegistry|Where to pull images from|
|controlPlaneUrl|URL of the control plane|
|sidecarId|Sidecar ID to use|
|sidecarVersion|Version to use for the sidecar|
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

More info can be found in [LOGGING.md](../blob/main/LOGGING.md)

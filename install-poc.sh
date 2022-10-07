#!/usr/bin/env bash
defaultSidecarVersion="v2.34.0"

# Optional Parameters
###
if [ -z "$containerRegistry" ]; then
    containerRegistry="gcr.io/cyralinc"
else
    echo "containerRegistry enviroment variable found, using '$containerRegistry'"
fi

if [ -z "$fluentBitImage" ]; then
    fluentBitImage="fluent/fluent-bit:latest"
else
    echo "fluentBitImage enviroment variable found, using '$fluentBitImage"
fi

if [ -z "$fluentConfigFile" ]; then
    fluentConfigFile="fluent.conf"
else
    echo "fluentConfigFile enviroment variable found, using '$fluentConfigFile'"
fi
###

fluentConfig="
[INPUT]
    Name              forward
    Listen            0.0.0.0
    Port              24224
    Buffer_Chunk_Size 1M
    Buffer_Max_Size   6M

"

# validate/install commands
installs=""
dependencies=("docker" "jq")

for cmd in "${dependencies[@]}" ; do command -v "$cmd" &> /dev/null || installs+="$cmd "; done

if [ -n "$installs" ]; then
    printf "Prepairing the system, please wait"
    [ -n "$(command -v yum)" ] && pcmd=yum
    [ -n "$(command -v apt-get)" ] && pcmd=apt-get
    if [ -z "$pcmd" ]; then
        printf "\nPlease install the following first: %s" "$installs"
        exit 1
    fi
    if [ "$pcmd" = "apt-get" ]; then
        if ! outUpdate=$(sudo $pcmd update 2>&1); then
            printf "\nProblem updating!"
            printf "\n Install Failure Message:\n"
            echo "${outUpdate}"
            exit 1
        fi
    fi
    printf "."

    # Some OS's will have docker under the name docker.io, having both will successfully install docker without error
    [[ "$installs" =~ "docker" && "$pcmd" = "apt-get" ]] && installs+="docker.io"
    
    if ! outInstall=$(sudo $pcmd install -y $installs 2>&1); then
        printf "\nProblem installing tools!"
        printf "\nPlease make sure the following tools are installed and run the script again: %s" "$installs"
        printf "\n Install Failure Message:\n"
        echo "${outInstall}"
        exit 1
    fi
    printf "."
    if [[ $(docker ps 2>&1) =~ "daemon running" ]]; then
        if ! outEnable=$(sudo systemctl enable docker 2>&1); then
            printf "\nProblem enabling docker!\n"
            echo "$outEnable"
            exit 1
        fi
        printf "."

        if ! outStart=$(sudo systemctl start docker 2>&1); then
            printf "\nProblem starting docker!\n"
            echo "$outStart"
            exit 1
        fi
    fi
    printf ".\n\n"
fi

containerCheck() {
    NEXT_WAIT_TIME=0
    until [ $NEXT_WAIT_TIME -eq 5 ] || [ "$(sudo docker inspect "$1" | jq -r -e '.[].RestartCount')" -ne 0 ]; do
        printf "."
        (( NEXT_WAIT_TIME++ ))
        sleep 1
    done
    echo ""
    [ "$NEXT_WAIT_TIME" -eq 5 ]
}

containerStopAndRemove() {
    sudo docker stop "$1" >/dev/null 2>&1
    sudo docker rm "$1" >/dev/null 2>&1
}

echo "Sidecar Setup"
echo "============="
echo "From the controlplane, click Sidecars and click the + for a new sidecar."
echo "Select Custom as the sidecar type, give it a name and click Generate"
echo "Provide a name and click Generate again, you will be prompted to provide the values."
echo "============="

# gather input
if [ -z "$controlPlaneUrl" ]; then
    read -r -p "Control Plane URL (copy/paste current control plane url): " controlPlaneUrl
else
    echo "controlPlaneUrl enviroment variable found, using '$controlPlaneUrl'"
fi

if [ -z "$sidecarId" ]; then
    read -r -p "Sidecar ID: " sidecarId
else
    echo "sidecarId enviroment variable found, using '$sidecarId'"
fi

if [ -z "$sidecarVersion" ]; then
    read -r -p "Sidecar Version (default: $defaultSidecarVersion): " sidecarVersion
    if [ -z "$sidecarVersion" ]; then
        sidecarVersion="$defaultSidecarVersion"
    fi
else
    envFilePrompt="false" # use this to block prompting for env file related to using this script in an automated way
    echo "sidecarVersion enviroment variable found, using '$sidecarVersion'"
fi

if [[ -n "$secretBlob" ]]; then
    echo "secretBlob enviroment variable found, using that"
elif [[ -n "$clientId" && -n "$clientSecret" ]]; then
    echo "clientId and clientSecret enviroment variables found, client ID being used '$clientId'"
else
    printf "Secret Blob: "
    secretBlob=$(sed '/}/q') # specific to expected inputs
fi

## Attach an env file if required for secret injection for testing
if [[ -z "$envFilePath" ]]; then
    if [[ -z "$envFilePrompt" ]]; then # if sidecarVersion is set we wont prompt assuming automation
        read -r -p "Env File Path (blank if not required): " envFilePath
    else
        echo "sidecarVersion set, skipping prompt for envFilePath"
    fi
else
    echo "envFilePath enviroment variable found, using '$envFilePath'"
fi

if [ -n "$outputConfig" ]; then
    echo "outputConfig found, generating configuration file"
    logDriver="fluentd"
    fluentConfig="${fluentConfig}${outputConfig}"
    echo "$fluentConfig" > "$fluentConfigFile"
fi

echo "Parsing input"
controlPlaneUrl=$(echo "$controlPlaneUrl" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

if [ -z "$clientId" ]; then
    clientId=$(echo "$secretBlob" | jq -r  -e .clientId)
fi

if [ -z "$clientSecret" ]; then
    clientSecret=$(echo "$secretBlob" | jq -r -e .clientSecret)
fi

if [ -n "$secretBlob" ]; then
    registryKey=$(echo "$secretBlob" | jq -r -e .registryKey)
fi

if [ -n "$envFilePath" ]; then
    envFilePath=$(realpath "$envFilePath")
    if [[ -r "$envFilePath" ]]; then
        envFileParam=("--env-file" "$envFilePath")
        echo "Injectig env file '${envFileParam[1]}'"
    else
        echo "Unable to read/mount the env file, '${envFilePath}', skipping!!"
    fi
fi

if [ -z "$endpoint" ]; then
    if ! endpoint=$(curl --fail --silent --connect-timeout .5 http://169.254.169.254/latest/meta-data/public-ipv4); then
        endpoint=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
    fi
else
    echo "endpoint enviroment variable found, using '$endpoint'"
fi

if [ "$logDriver" = "fluentd" ]; then
    echo "Starting Logger"  
    containerStopAndRemove "fluent"
    if ! outFluent=$(sudo docker run -d --name fluent --restart=unless-stopped \
                    -p 24224:24224 \
                    -v "${PWD}/$fluentConfigFile:/etc/$fluentConfigFile" \
                    "$fluentBitImage" \
                    -c /etc/$fluentConfigFile 2>&1 \
                    ); then
        echo "Problem with Logging configuration!"
        echo "${outFluent}"
        exit 1
    else
        if ! containerCheck "fluent"; then
            echo "Problem with Fluent Configuration!"
            exit 1
        else
            echo "Logging successfully setup"
        fi
    fi
fi

if [ -n "$registryKey" ]; then
    echo "Accessing resources"
    if ! dLogin=$(echo "$registryKey" | base64 --decode | sudo docker login -u _json_key --password-stdin "$containerRegistry" 2>&1); then
        echo "Problem logging in to registry!"
        echo "$dLogin"
        exit 1
    fi
fi

echo "Downloading sidecar version ${sidecarVersion}"
if ! outPull=$(sudo docker pull "${containerRegistry}/cyral-sidecar:${sidecarVersion}"); then
    echo "Problem pulling images!"
    echo "$outPull"
    exit 1
fi

containerStopAndRemove "sidecar"

echo "Starting Sidecar"
if ! containerId=$(sudo docker run -d --name sidecar --network=host --log-driver=${logDriver:=json-file} --restart=unless-stopped \
    -e CYRAL_SIDECAR_ID="$sidecarId" \
    -e CYRAL_SIDECAR_CLIENT_ID="$clientId" \
    -e CYRAL_SIDECAR_CLIENT_SECRET="$clientSecret" \
    -e CYRAL_CONTROL_PLANE="$controlPlaneUrl" \
    -e CYRAL_SIDECAR_ENDPOINT="$endpoint" \
    "${envFileParam[@]}" \
    "${containerRegistry}/cyral-sidecar:${sidecarVersion}" 2>&1) ; then

    echo "Problem starting sidecar!"
    echo "$containerId"
    exit 1
fi

echo "Sidecar Started, checking for Controleplane connectivity..."
if ! containerCheck "sidecar"; then
    echo "--> Problem with sidecar! Inspect the logs to diagnose the issue. <--"
else
    echo 'Sidecar successfully online!'
    echo "To check if its has successfully connected to the controlplane go to Sidecar -> your sidecar -> Sidecar Instances"
fi

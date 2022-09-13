#!/usr/bin/env bash
defaultSidecarVersion="v2.34.0"

# Optional Parameters
###
if [ -z "$containerRegistry" ]; then
    containerRegistry="gcr.io/cyralinc"
fi

if [ -z "$fluentBitImage" ]; then
    fluentBitImage="fluent/fluent-bit:latest"
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

containerCheck() {
    NEXT_WAIT_TIME=0
    until [ $NEXT_WAIT_TIME -eq 5 ] || [ "$(dockercmd inspect "$1" | jq -r -e '.[].RestartCount')" -ne 0 ]; do
        printf "."
        (( NEXT_WAIT_TIME++ ))
        sleep 1
    done
    echo ""
    [ "$NEXT_WAIT_TIME" -eq 5 ]
}

containerStopAndRemove() {
    dockercmd stop "$1" >/dev/null 2>&1
    dockercmd rm "$1" >/dev/null 2>&1
}


# validate/install commands
installs=""
dependencies=("docker" "jq")

for cmd in "${dependencies[@]}" ; do command -v "$cmd" &> /dev/null || installs+="$cmd "; done

if [ -n "$installs" ]; then
    printf "Prepairing the system, please wait"
    [ -n "$(command -v yum)" ] && pcmd=yum
    [ -n "$(command -v apt-get)" ] && pcmd=apt-get
    if [ -z "$pcmd" ]; then
        printf "\nPlease install the following first: $installs"
        exit 1
    fi
    if ! outInstall=$(sudo $pcmd install -y $installs 2>&1); then
        printf "\nProblem installing tools!\n"
        echo "${outInstall}"
        exit 1
    fi
    printf "."
    if [[ "$installs" =~ docker ]]; then
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

shopt -s expand_aliases
alias dockercmd="docker"
if ! dockercmd ps &> /dev/null; then alias dockercmd="sudo docker";fi

echo "Sidecar Setup"
echo "============="
echo "From the controlplane, click Sidecars and click the + for a new sidecar."
echo "Select Custom as the sidecar type, give it a name and click Generate"
echo "Provide a name and click Generate again, you will be prompted to provide the values."
echo "============="

# gather input
if [ -z "$controlplaneUrl" ]; then
    read -r -p "Control Plane URL (copy/paste current control plane url): " controlplaneUrl
fi
if [ -z "$sidecarId" ]; then
    read -r -p "Sidecar ID: " sidecarId
fi
if [ -z "$sidecarVersion" ]; then
    read -r -p "Sidecar Version (default: $defaultSidecarVersion): " sidecarVersion
    if [ -z "$sidecarVersion" ]; then
        sidecarVersion="$defaultSidecarVersion"
    fi
fi
if [[ -z $clientId || -z $clientSecret ]] && [[ -z $secretBlob ]]; then
    printf "Secret Blob: "
    secretBlob=$(sed '/}/q') # specific to expected inputs
fi

logDriver="json-file"
if [ -n "$outputConfig" ]; then
    fluentConfig="${fluentConfig}${outputConfig}"
    logDriver="fluentd"
fi

echo "Parsing input"
controlplaneUrl=$(echo "$controlplaneUrl" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

if [ -z "$clientId" ]; then
    clientId=$(echo "$secretBlob" | jq -r  -e .clientId)
fi

if [ -z "$clientSecret" ]; then
    clientSecret=$(echo "$secretBlob" | jq -r -e .clientSecret)
fi
if [ -n "$secretBlob" ]; then
    registryKey=$(echo "$secretBlob" | jq -r -e .registryKey)
fi


endpoint=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

if [ "$logDriver" = "fluentd" ]; then
    echo "Starting Logger"
    fluentConfigFile="fluent.conf"
    if [[ -e "$fluentConfigFile" ]]; then
        rm $fluentConfigFile
    fi
    echo "$fluentConfig" > "$fluentConfigFile"
    containerStopAndRemove "fluent"
    if ! outFluent=$(dockercmd run -d --name fluent --restart=unless-stopped \
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
    if ! dLogin=$(echo "$registryKey" | base64 --decode | dockercmd login -u _json_key --password-stdin "$containerRegistry" 2>&1); then
        echo "Problem logging in to registry!"
        echo "$dLogin"
        exit 1
    fi
fi

echo "Downloading sidecar version ${sidecarVersion}"
if ! outPull=$(dockercmd pull "${containerRegistry}/cyral-sidecar:${sidecarVersion}"); then
    echo "Problem pulling images!"
    echo "$outPull"
    exit 1
fi

containerStopAndRemove "sidecar"

echo "Starting Sidecar"
if ! containerId=$(dockercmd run -d --name sidecar --network=host --log-driver=$logDriver --restart=unless-stopped \
    -e CYRAL_SIDECAR_ID="$sidecarId" \
    -e CYRAL_SIDECAR_CLIENT_ID="$clientId" \
    -e CYRAL_SIDECAR_CLIENT_SECRET="$clientSecret" \
    -e CYRAL_CONTROL_PLANE="$controlplaneUrl" \
    -e CYRAL_SIDECAR_ENDPOINT="$endpoint" \
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

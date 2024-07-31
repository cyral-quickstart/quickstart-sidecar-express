#!/usr/bin/env bash
defaultSidecarVersion="v4.10.0"

# Optional Parameters
###
if [ -z "${CONTAINER_REGISTRY:=$containerRegistry}" ] && [ -n "${REGISTRY_KEY:=$registryKey}" ]; then
    CONTAINER_REGISTRY="gcr.io/cyralinc"
elif [ -z "$CONTAINER_REGISTRY" ]; then
    CONTAINER_REGISTRY="public.ecr.aws/cyral"
else
    echo "CONTAINER_REGISTRY enviroment variable found, using '$CONTAINER_REGISTRY'"
fi

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

if ! out=$(docker ps 2>&1); then
    if ! sout=$(sudo -n docker ps 2>&1); then
        echo "Unable to run docker! Docker needs to be able to run on its own without sudo, or non-interactively via sudo"
        echo "Output:"
        echo "Standard: $out"
        echo "Sudo: $sout"
        exit 1
    else
        dockercmd="sudo -n docker"
    fi
else
    dockercmd="docker"
fi

containerCheck() {
    NEXT_WAIT_TIME=0
    until [ $NEXT_WAIT_TIME -eq 5 ] || [ "$(eval $dockercmd inspect "$1" | jq -r -e '.[].RestartCount')" -ne 0 ]; do
        printf "."
        (( NEXT_WAIT_TIME++ ))
        sleep 1
    done
    echo ""
    [ "$NEXT_WAIT_TIME" -eq 5 ]
}

containerStopAndRemove() {
    eval $dockercmd stop "$1" >/dev/null 2>&1
    eval $dockercmd rm "$1" >/dev/null 2>&1
}

function get_token () {
    local url_token="https://${CONTROL_PLANE}/v1/users/oidc/token"
    local response status_code body
    response=$(curl --silent -w "%{http_code}" --request POST "$url_token" -d grant_type=client_credentials -d client_id="$CLIENT_ID" -d client_secret="$CLIENT_SECRET" 2>&1)
    
    status_code="${response: -3}"  # Extract the last three characters (HTTP status code)
    body=$(echo "$response" | sed '$s/...$//')  # Remove the last three characters (HTTP status code)

    if [ "$status_code" -eq 200 ]; then  
        access_token=$(echo "$body" | jq -r .access_token)
    else
        echo "Unable to retrieve token check client id and secret: $status_code - $body"
        exit "$status_code"
    fi
}

function get_sidecar_version () {
    local response status_code body
    echo "Getting sidecar version from Control Plane..."
    get_token

    response=$(curl --silent -w "%{http_code}" --request GET "https://${CONTROL_PLANE}/v2/sidecars/${SIDECAR_ID}" -H "Authorization: Bearer $access_token")

    status_code="${response: -3}"  # Extract the last three characters (HTTP status code)
    body=$(echo "$response" | sed '$s/...$//')  # Remove the last three characters (HTTP status code)

    if [[ "$status_code" -ne 200 ]]; then
        echo "Error retrieving sidecar version from Control Plane. Please provide a version"
        return 1
    fi
    SIDECAR_VERSION=$(echo "$body" | jq -r '.sidecar.version // empty')
}

# pull info from currently running instance
if inspect=$(eval $dockercmd inspect sidecar 2>/dev/null); then
    # update default version to currently used version
    printf "Pulling config from current sidecar deployment...\n\n"
    defaultSidecarVersion=$(echo "$inspect" | jq -r '.[].Config.Image' | cut -d: -f2)
    currentEnv=$(echo "$inspect" | jq -r '.[].Config.Env[] | select(startswith("CYRAL_"))')
    
fi

echo "Sidecar Setup"
echo "============="

# gather input
if [ -z "${CONTROL_PLANE:=$controlPlaneUrl}" ]; then
    CONTROL_PLANE=$(echo "$currentEnv"| grep 'CYRAL_CONTROL_PLANE=' | cut -d= -f2)
    if [ -z "$CONTROL_PLANE" ]; then
        read -r -p "Control Plane URL (copy/paste current control plane url): " CONTROL_PLANE
    else
        echo "CONTROL_PLANE found from existing sidecar, using '$CONTROL_PLANE'"
    fi
else
    echo "CONTROL_PLANE enviroment variable found, using '$CONTROL_PLANE'"
fi

if [ -z "${SIDECAR_ID:=$sidecarId}" ]; then
    SIDECAR_ID=$(echo "$currentEnv"| grep 'CYRAL_SIDECAR_ID=' | cut -d= -f2)
    if [ -z "$SIDECAR_ID" ]; then
        read -r -p "Sidecar ID: " SIDECAR_ID
    else
        echo "SIDECAR_ID found from existing sidecar, using '$SIDECAR_ID'"
    fi
else
    echo "SIDECAR_ID enviroment variable found, using '$SIDECAR_ID'"
fi

if [[ -n "${CLIENT_ID:=$clientId}" && -n "${CLIENT_SECRET:=$clientSecret}" ]]; then
    echo "CLIENT_ID and CLIENT_SECRET enviroment variables found, client ID being used '$CLIENT_ID'"
else
    CLIENT_ID=$(echo "$currentEnv"| grep 'CYRAL_SIDECAR_CLIENT_ID=' | cut -d= -f2)
    CLIENT_SECRET=$(echo "$currentEnv"| grep 'CYRAL_SIDECAR_CLIENT_SECRET=' | cut -d= -f2)
    if [ -z "$CLIENT_ID" ]; then
        read -r -p "Client ID:" CLIENT_ID
    fi
    if [ -z "$CLIENT_SECRET" ]; then
        read -r -p "Client Secret:" CLIENT_SECRET
    fi     
fi

if [ -z "${SIDECAR_VERSION:=$sidecarVersion}" ]; then
    get_sidecar_version
    if [ -z "${SIDECAR_VERSION}" ]; then
        read -r -p "Sidecar Version [${defaultSidecarVersion}]: " sidecarVersion
        if [ -z "$SIDECAR_VERSION" ]; then
            SIDECAR_VERSION="$defaultSidecarVersion"
        fi
    fi
fi
## Attach an env file if required for secret injection for testing

CONTROL_PLANE=$(echo "$CONTROL_PLANE" | sed -e 's|^[^/]*//||' -e 's|/.*$||')

if [ -n "${ENV_FILE_PATH:=$envFilePath}" ]; then
    ENV_FILE_PATH=$(realpath "$ENV_FILE_PATH")
    if [[ -r "$ENV_FILE_PATH" ]]; then
        envFileParam=("--env-file" "$ENV_FILE_PATH")
        echo "Injectig env file '${envFileParam[1]}'"
    else
        echo "Unable to read/mount the env file, '${envFilePath}', skipping!!"
    fi
else
    echo "ENV_FILE_PATH not set, skipping"
fi

if [ -z "${ENDPOINT:=$endpoint}" ]; then
    ENDPOINT=$(curl --fail --silent --max-time 1 \
        -H "X-aws-ec2-metadata-token: $(curl --max-time 1 --fail --silent \
        -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")" \
        http://169.254.169.254/latest/meta-data/public-ipv4 || (hostname -I 2>/dev/null || echo "manually-set-endpoint") | awk '{print $1}')
else
    echo "endpoint enviroment variable found, using '$ENDPOINT'"
fi

if [ -n "${REGISTRY_KEY}" ]; then
    echo "Logging in to image registry"
    if ! dLogin=$(echo "$REGISTRY_KEY" | base64 --decode | eval $dockercmd login -u _json_key --password-stdin "$CONTAINER_REGISTRY" 2>&1); then
        echo "Problem logging in to registry!"
        echo "$dLogin"
        exit 1
    fi
fi

imagePath="${IMAGE_PATH:-${CONTAINER_REGISTRY}/cyral-sidecar:${SIDECAR_VERSION}}"
echo "Downloading sidecar version ${SIDECAR_VERSION}"
if ! outPull=$(eval $dockercmd pull $imagePath); then
    echo "Problem pulling $imagePath!"
    echo "$outPull"
    exit 1
fi

if [ -n "${LOG_OPT}" ]; then
    IFS=' ' read -ra log_opt_array <<< "${LOG_OPT}"
    for opt in "${log_opt_array[@]}"; do
        log_opt_params+="--log-opt $opt "
    done
elif [ -z "${LOG_OPT+x}" ]; then
    log_opt_params="--log-opt max-size=500m"
fi

containerStopAndRemove "sidecar"

echo "Starting Sidecar"
# shellcheck disable=SC2294
if ! containerId=$(eval $dockercmd run -d --name sidecar --network=host --log-driver="${LOG_DRIVER:-json-file}" $log_opt_params --restart=unless-stopped \
    -e CYRAL_SIDECAR_ID="$SIDECAR_ID" \
    -e CYRAL_SIDECAR_CLIENT_ID="$CLIENT_ID" \
    -e CYRAL_SIDECAR_CLIENT_SECRET="$CLIENT_SECRET" \
    -e CYRAL_CONTROL_PLANE="$CONTROL_PLANE" \
    -e CYRAL_SIDECAR_ENDPOINT="$ENDPOINT" \
    -e CYRAL_CONTROL_PLANE_HTTPS_PORT="${CONTROL_PLANE_HTTPS_PORT:-443}"\
    -e CYRAL_CONTROL_PLANE_GRPC_PORT="${CONTROL_PLANE_GRPC_PORT:-443}"\
    -e IS_DYNAMIC_VERSION="true" \
    -e CYRAL_SSO_LOGIN_URL \
    -e CYRAL_IDP_CERTIFICATE \
    -e CYRAL_SIDECAR_IDP_PUBLIC_CERT \
    -e CYRAL_SIDECAR_IDP_PRIVATE_KEY \
    -e LOG_LEVEL="${LOG_LEVEL:-"info"}" \
    "${envFileParam[@]}" \
    "${imagePath}" 2>&1) ; then

    echo "Problem starting sidecar!"
    echo "$containerId"
    exit 1
fi

echo "Sidecar Started, checking for Control Plane connectivity..."
if ! containerCheck "sidecar"; then
    echo "--> Problem with sidecar! Inspect the logs to diagnose the issue. <--"
else
    echo 'Sidecar successfully started!'
    echo "To check if its has successfully connected to the controlplane go to Sidecar -> your sidecar -> Sidecar Instances"
fi

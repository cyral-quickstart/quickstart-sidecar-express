#!/bin/sh

PATHS_GLOB="${PATHS_GLOB:-*.sh}"

# This crazy syntax is so that we capture the error codes of commands run inside
# of find. This image does have /bin/sh installed, but not all images do so we
# decided to go with this more generic approach where we call sh from outside
# the docker container.
#
# shellcheck disable=SC2156
errorout=$(find . -type f -name "$PATHS_GLOB" \( -exec sh -c '
{
docker run \
  -v "$PWD":/data \
  --workdir /data \
  "$SHELLCHECK_IMAGE_URL" \
  -S warning {}
} || echo "error" 1>&2
' \; -o -quit \) )
test -z "$errorout" || {
    echo "Error: $errorout" && exit 1
}

#!/bin/bash

# Check dependencies.
set -e
type curl grep sed tr >&2

# Validate settings.
[ -f ~/.secrets ] && source ~/.secrets
[ "$GITHUB_TOKEN" ] || {
  echo "Error: Please define GITHUB_TOKEN variable." >&2
  exit 1
}
[ $# -ne 4 ] && {
  echo "Usage: $0 [owner] [repo] [tag] [name]"
  exit 1
}
[ "$TRACE" ] && set -x
read owner repo tag name <<<$@

# Define variables.
GH_API="https://api.github.com"
GH_REPO="$GH_API/repos/$owner/$repo"
GH_TAGS="$GH_REPO/releases/tags/$tag"
AUTH="Authorization: token $GITHUB_TOKEN"
CURL_ARGS="-LJO#"

# Validate token.
curl -o /dev/null -sH "$AUTH" $GH_REPO || {
  echo "Error: Invalid repo, token or network issue!"
  exit 1
}

# Read asset tags.
response=$(curl -sH "$AUTH" $GH_TAGS)

# Get ID of the asset based on given name.
id=$(echo "$response" | jq --arg name "$name" '.assets[] | select(.name == $name).id') # If jq is installed, this can be used instead.
[ "$id" ] || {
  echo "Error: Failed to get asset id, response: $response" | awk 'length($0)<100' >&2
  exit 1
}
GH_ASSET="$GH_REPO/releases/assets/$id"

# Download asset file.
echo "Downloading asset..." >&2
curl $CURL_ARGS -H "Authorization: token $GITHUB_TOKEN" -H 'Accept: application/octet-stream' "$GH_ASSET"
echo "$0 done." >&2

# Unzip and cleanup
unzip "$name"
rm -rf "$name"

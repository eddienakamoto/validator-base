#!/bin/bash

# Check if DOCKER_USERNAME and DOCKER_IMAGE_NAME_VALI are set
if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_VALIDATOR_BASE" ]; then
    echo "DOCKER_USERNAME and DOCKER_IMAGE_NAME_VALI must be set."
    exit 1
fi

# Function to print usage
print_usage() {
    echo "Usage: $0 -u [major|minor|patch] -p platforms -t [cpu|gpu]"
}

# Default values
update_type=""
platforms=""
base_type=""

# Parse command line options
while getopts ":u:p:t:" opt; do
    case ${opt} in
        u )
            update_type="$OPTARG"
            ;;
        p )
            platforms="$OPTARG"
            ;;
        t )
            base_type="$OPTARG"
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            print_usage
            exit 1
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            print_usage
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Check if update_type, platforms, and base_type are provided
if [ -z "$update_type" ] || [ -z "$platforms" ] || [ -z "$base_type" ]; then
    echo "Missing required arguments"
    print_usage
    exit 1
fi

# Check if base_type is either cpu or gpu
if [ "$base_type" != "cpu" ] && [ "$base_type" != "gpu" ]; then
    echo "Invalid base type: $base_type. Must be either cpu or gpu."
    print_usage
    exit 1
fi

# Check if platforms is valid
if [ "$platforms" != "linux/amd64" ] && [ "$platforms" != "linux/arm64" ] && [ "$platforms" != "linux/amd64,linux/arm64" ]; then
    echo "Invalid platforms: $platforms. Must be either linux/amd64, linux/arm64, or linux/amd64,linux/arm64."
    print_usage
    exit 1
fi

# Get the current version on docker hub.
current_version=$(curl -s "https://hub.docker.com/v2/repositories/$DOCKER_USERNAME/$DOCKER_VALIDATOR_BASE/tags/" | \
    jq -r '.results[].name | sub("-cpu|-gpu"; "")' | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | \
    sort -V | \
    tail -n 1)

# Split version into major, minor, and patch components
IFS='.' read -r major minor patch <<< "$current_version"

# Determine version increment based on update type
case $update_type in
    "major")
        ((major++))
        minor=0
        patch=0
        ;;
    "minor")
        ((minor++))
        patch=0
        ;;
    "patch")
        ((patch++))
        ;;
    * )
        echo "Invalid update type: $update_type. Usage: $0 [major|minor|patch]"
        print_usage
        exit 1
        ;;
esac

# Construct new version string
new_version="$major.$minor.$patch"

docker buildx build \
    --platform="$platforms" \
    --build-arg BASE_TYPE="$base_type" \
    -t "$DOCKER_USERNAME/$DOCKER_VALIDATOR_BASE:$new_version-$base_type" \
    --push .


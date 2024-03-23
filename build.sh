#!/bin/bash

# Check if DOCKER_USERNAME and DOCKER_IMAGE_NAME_VALI are set
if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_VALIDATOR_BASE" ]; then
    echo "DOCKER_USERNAME and DOCKER_IMAGE_NAME_VALI must be set."
    exit 1
fi

# Function to print usage
print_usage() {
    echo "Usage: $0 [OPTIONS]
Options:
  -p <platforms>        Specify platforms; multiple can be comma-separated (options: linux/arm64, linux/amd64, or both)
  -t <type>             Set base type (options: cpu, gpu)
  -u <update_type>      Define update type (options: major, minor, patch); If not specified, the current version is used without increment
  -v <ubuntu_version>   Set Ubuntu version (default: 22.04)
  -c <cuda_version>     Specify CUDA version (default: 11.8.0); Only required if -t gpu is used
  --local               Perform a local build without pushing to a registry

Examples:
  $0 -p linux/amd64 -t cpu -u minor -v 20.04             # Increment minor version
  $0 -p linux/amd64,linux/arm64 -t gpu -c 11.2.0 --local # Build with the current version for GPU, without incrementing

Note: Ensure DOCKER_USERNAME and DOCKER_VALIDATOR_BASE environment variables are set before running. 
      Not specifying '-u' builds with the current version without incrementing."
}

# Default values
update_type=""
platforms=""
base_type=""
ubuntu_version="22.04"
cuda_version="11.8.0"
local_build=false

# Parse command line options
while getopts ":u:p:t:v:c:-:" opt; do
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
        v )
            ubuntu_version="$OPTARG"
            ;;
        c )
            cuda_version="$OPTARG"
            ;;
        - )
            case "${OPTARG}" in
                local )
                    local_build=true
                    ;;
                * )
                    echo "Invalid option: --$OPTARG" 1>&2
                    print_usage
                    exit 1
                    ;;
            esac
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

# Check if platforms and base_type are provided
if [ -z "$platforms" ] || [ -z "$base_type" ]; then
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
if [ "$platforms" != "linux/amd64" ] && \
   [ "$platforms" != "linux/arm64" ] && \
   [ "$platforms" != "linux/amd64,linux/arm64" ] && \
   [ "$platforms" != "linux/arm64,linux/amd64" ]; then
    echo "Invalid platforms: $platforms. Must be either linux/amd64, linux/arm64, or linux/amd64,linux/arm64."
    print_usage
    exit 1
fi

# Get the current version on docker hub for the specified base type
current_version=$(curl -s "https://hub.docker.com/v2/repositories/$DOCKER_USERNAME/$DOCKER_VALIDATOR_BASE/tags/?name=$base_type" | \
    jq -r '.results[].name | select(test("'$base_type'")) | sub("-cpu|-gpu"; "") | sub("-ub.*"; "")' | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | \
    sort -V | \
    tail -n 1)

# If no version exists for the specified base type, default to 0.0.0
if [ -z "$current_version" ]; then
    current_version="0.0.0"
fi

# Split version into major, minor, and patch components
IFS='.' read -r major minor patch <<< "$current_version"

# If update_type is not specified, use the current version
if [ -z "$update_type" ]; then
    new_version="$current_version"
else
    # Determine version increment based on update type
    case $update_type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        * )
            echo "Invalid update type: $update_type. Usage: $0 [major|minor|patch]"
            print_usage
            exit 1
            ;;
    esac

    # Construct new version string
    new_version="$major.$minor.$patch"
fi

# Build the Docker image
docker_tag="$DOCKER_USERNAME/$DOCKER_VALIDATOR_BASE:$new_version-$base_type-ub$ubuntu_version"

# If base_type is gpu, append CUDA version
if [ "$base_type" = "gpu" ]; then
    docker_tag="${docker_tag}-cuda$cuda_version"
fi

docker buildx build \
    --platform="$platforms" \
    --build-arg BASE_TYPE="$base_type" \
    --build-arg UBUNTU_VERSION="$ubuntu_version" \
    $(if [ "$base_type" = "gpu" ]; then echo "--build-arg CUDA_VERSION=$cuda_version"; fi) \
    -t "$docker_tag" \
    $([[ "$local_build" == true ]] && echo "--load" || echo "--push") .

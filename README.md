# Validator Base 
The validator base template is the base template for containerizing Bittensor subtensor validators. The `Dockerfile` can be built for both `cpu` and `gpu` based validators, and supports `amd64` and `arm64` architectures. The `cpu` image is built from `ubuntu`. The `gpu` image is built from `nvidia/cuda`.

## Packages
The image comes with common packages used with Bittensor validators preinstalled:
- Python 3.10
- Git
- NPM
- Curl
- Unzip
- Jq
- Tini
- Nano
- Pm2

The image includes an `ENTRYPOINT` that prepends `tini --` to the start command, setting `tini` to `PID 1`. This enables any command that is executed when starting the container to be backed by a fully featured, light weight, init system. `tini` will manage all the signal handling, process management, and reaping of zombie processes.

The Bittensor package was intentionally excluded since each subnet validator includes it in their `requirements.txt` file. Preinstalling Bittensor can lead to dependency conflicts.

## Environment Variables
For building and pushing to work correctly, the environment variables `DOCKER_USERNAME` and `DOCKER_VALIDATOR_BASE` should be set on the host machine i.e. the machine that is building the images. 

| Name                   | Description                            | Required on Host |
|------------------------|----------------------------------------|------------------|
| DOCKER_USERNAME        | Docker username that hosts the image   | ✅               |
| DOCKER_VALIDATOR_BASE  | The Docker repository name             | ✅               |

If running the images locally, it is recommended to have `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_WALLET_URL` set on the host machine. This will align the commands in this documentation to work in your environment. Alternatively, these values can be specified directly when running the docker container.

| Name                  | Description                        | Required on Host |
|-----------------------|------------------------------------|------------------|
| AWS_ACCESS_KEY_ID     | AWS access key ID                  | ❌               |
| AWS_SECRET_ACCESS_KEY | AWS secret access key              | ❌               |
| AWS_WALLET_URL        | AWS S3 URL to download your wallet | ❌               |

## Building Locally
Base images can be built for either `cpu` or `gpu` by specifying the type with build arguments. They can also be built for multiple platforms utilizing the `buildx` docker extension. Unfortunately, you cannot build for multiple platforms inline (at least on Mac). Each platform build needs to be executed as its own command.

The version of `Ubuntu` the images are built from defaults to `ubuntu:22.04`. This can be overridden by using `--build-arg UBUNTU_VERSION="<version-number>"`.

### CPU Image
Building the `Validator Base` CPU image locally requires the `cpu` value to be specified for the `BASE_TYPE`.

#### ARM64
```bash
docker buildx build \
    --platform=linux/arm64 \
    --build-arg BASE_TYPE="cpu" \
    -t "$DOCKER_USERNAME/$DOCKER_VALIDATOR_BASE":latest-cpu \
    -o type=docker .
```

#### AMD64
```bash
docker buildx build \
    --platform=linux/amd64 \
    --build-arg BASE_TYPE="cpu" \
    -t "$DOCKER_USERNAME/$DOCKER_VALIDATOR_BASE":latest-cpu \
    -o type=docker .
```

### GPU Image
Building the `Validator Base` GPU image locally requires the `gpu` value to be specified for the `BASE_TYPE`.

#### ARM64
```bash
docker buildx build \
    --platform=linux/arm64 \
    --build-arg BASE_TYPE="gpu" \
    -t "$DOCKER_USERNAME/$DOCKER_VALIDATOR_BASE":latest-gpu \
    -o type=docker .
```

#### AMD64
```bash
docker buildx build \
    --platform=linux/amd64 \
    --build-arg BASE_TYPE="gpu" \
    -t "$DOCKER_USERNAME/$DOCKER_VALIDATOR_BASE":latest-gpu \
    -o type=docker .
```

## Pushing a Image
Images can be built and pushed using the `push.sh` script. The script requires 3 arguments for the base type (`cpu` or `gpu`), the type of update (`major`, `minor`, or `patch`), and the platform (`linux/arm64`, `linux/amd64`, or both). The current version of the image is retrieved from docker hub. Depending on the type of update (`major`, `minor`, or `patch`), it will increment the correct digit by 1. This enables a streamlined versioning system.

To push a update the following command is executed.

```bash
./push.sh -u [major|minor|patch] -p [linux/arm64,linux/amd64] -t [cpu|gpu]
```

## Wallet Support
The base image includes a custom script `wallet` that will fetch your wallet from `aws`. `wallet` needs the following environment variables set in order to properly set up your wallet:

| Name                  | Description                                               | Required |
|-----------------------|-----------------------------------------------------------|----------|
| AWS_ACCESS_KEY_ID     | AWS access key ID                                         | ✅       |
| AWS_SECRET_ACCESS_KEY | AWS secret access key                                     | ✅       |
| AWS_WALLET_URL        | AWS S3 URL to download your wallet                        | ✅       |
| AWS_DEFAULT_REGION    | Default AWS region of your S3 bucket (default: us-east-1) | ❌       |
| AWS_DEFAULT_OUTPUT    | Default AWS S3 response format (default: json)            | ❌       |

The `wallet` command will setup your wallet in the `~/.bittensor` directory. 

## Running a Container
To streamline the process, when running the container, specify the required environment variables. Optionally, you can specify 
`AWS_DEFAULT_REGION` and `AWS_DEFAULT_OUTPUT`. 

```bash
docker run -it \
    --env=AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    --env=AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    --env=AWS_WALLET_URL=$AWS_WALLET_URL \
    "$DOCKER_USERNAME/$DOCKER_VALIDATOR_BASE":latest-cpu
```

There is no `CMD` specified in the `Dockerfile` because this image is designed to be a base. But to set up the wallet manually you can enter the container with bash.

```bash
docker run -it \
    --env=AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    --env=AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    --env=AWS_WALLET_URL=$AWS_WALLET_URL \
    "$DOCKER_USERNAME/$DOCKER_VALIDATOR_BASE":latest-cpu /bin/bash
```

Then run the wallet command:

```bash
wallet
```

Your wallet should now be set up in the `~/.bittensor` directory.
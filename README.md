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

## Building a Image
Base images can be built for either `cpu` or `gpu` by specifying the type with build arguements. They can also be built for multiple platforms utilizing the `buildx` docker extension.

### CPU Image

```bash
docker buildx build \
    --platform=linux/amd64,linux/arm64 \
    --build-arg BASE_TYPE="cpu" \
    -t $DOCKER_USERNAME/$DOCKER_IMAGE_NAME_VALI:<tag>-cpu \
    -o type=docker .
```

### GPU Image

```bash
docker buildx build \
    --platform=linux/amd64,linux/arm64 \
    --build-arg BASE_TYPE="gpu" \
    -t $DOCKER_USERNAME/$DOCKER_IMAGE_NAME_VALI:<tag>-gpu \
    -o type=docker .
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
To streamline the process, when running the container, specify the required environment variables.

```bash
docker run -it \
    --env=AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID> \
    --env=AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY> \
    --env=AWS_WALLET_URL=<AWS_WALLET_URL> \
    <image-name>
```

There is no `CMD` specified in the `Dockerfile` because this image is designed to be a base. But to set up the wallet manually you can enter the container with bash (substitute your values for placeholders):

```bash
docker run -it \
    --env=AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID> \
    --env=AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY> \
    --env=AWS_WALLET_URL=<AWS_WALLET_URL> \
    eddienakamoto/base:v1.0.0-cpu /bin/bash
```

Then run the wallet command:

```bash
wallet
```

Your wallet should now be set up in the `~/.bittensor` directory.
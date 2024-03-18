# Validator Base 
The validator base template is the base template for Bittensor subnet validators. The `Dockerfile` can be built for both `cpu` and `gpu` based validators, and supports `amd64` and `arm64` architectures. 

## Building a Image
Base images can be built for either `cpu` or `gpu` by specifying the type with build arguements. They can also be built for multiple platforms utilizing the `buildx` docker extension.

```bash
docker buildx build \
    --platform=<platforms> \
    --build-arg BASE_TYPE="<cpu or gpu>" \
    -t <username>/<name>:<tag> \
    -o type=docker .
```

For example, to build a `cpu` based image that supports both `amd64` and `arm64`, you'd run the following:

```bash
docker buildx build \
    --platform=linux/amd64,linux/arm64 \
    --build-arg BASE_TYPE="cpu" \
    -t eddienakamoto/base:v1.0.0-cpu \
    -o type=docker .
```

## Wallet Support
The base image includes a custom script `wallet` that will fetch your wallet from `aws`. `wallet` needs the following environment set in order to properly set up your wallet:

| Name                  | Description                                               | Required |
|-----------------------|-----------------------------------------------------------|----------|
| AWS_ACCESS_KEY_ID     | AWS access key ID                                         | ✅       |
| AWS_SECRET_ACCESS_KEY | AWS secret access key                                     | ✅       |
| AWS_WALLET_URL        | AWS S3 URL to download your wallet                        | ✅       |
| AWS_DEFAULT_REGION    | Default AWS region of your S3 bucket (default: us-east-1) | ❌       |
| AWS_DEFAULT_OUTPUT    | Default AWS S3 response format (default: json)            | ❌       |

The `wallet` command will set up your wallet in the `~/.bittensor` directory. 

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
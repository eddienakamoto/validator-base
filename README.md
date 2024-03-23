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

## Building
The image can be built using the `build.sh` script. As stated above, the `DOCKER_USERNAME` and `DOCKER_VALIDATOR_BASE` environment variables must be set to function properly. The script accepts a range of arguments. _Note: building locally with `--load` does not support multiplatform builds. The build script must be executed once per platform._

| Argument       | Flag     | Description                                                                                         | Required |
|----------------|----------|-----------------------------------------------------------------------------------------------------|----------|
| Update type    | `-v`     | The type of update (major, minor, or patch), ommitting this flag will build for the current version | ❌       |
| Platform       | `-a`     | The image platform (linux/arm64, linux/amd64, or both)                                              | ✅       |
| Base type      | `-t`     | The base image type (cpu or gpu)                                                                    | ✅       |
| Ubuntu version | `-u`     | The version of Ubuntu (default: 22.04)                                                              | ❌       |
| CUDA version   | `-c`     | The version of CUDA, only required if the -t is gpu (default: 11.8.0)                               | ❌       |
| Python version | `-p`     | The version of Python (default: 3.10)                                                               | ❌       |
| Build locally  | `--load` | Builds the image to the local docker registry, omitting this flag will build and push to docker hub | ❌       |

### Usage
```bash
./build.sh \
    -a [linux/arm64|linux/amd64|linux/arm64,linux/amd64]
    -t [cpu|gpu]
    [-v [major|minor|path]]
    [-u [ubuntu_version]]
    [-c [cuda_version]]
    [-p [python_version]]
    [--load]
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
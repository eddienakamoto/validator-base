# The base type to build the image for (cpu or gpu).
ARG BASE_TYPE=cpu 

# The ubuntu version to build the image from (default 22.04).
ARG UBUNTU_VERSION=22.04

# The cuda version to build the gpu image from (default 11.8.0)
ARG CUDA_VERSION=11.8.0

# Use Ubuntu as the base cpu image.
FROM ubuntu:${UBUNTU_VERSION} AS base-cpu 
ARG BASE_TYPE 
ARG UBUNTU_VERSION

# Use Nvidia CUDA as the base gpu image.
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS base-gpu 
ARG BASE_TYPE
ARG UBUNTU_VERSION
ARG CUDA_VERSION
RUN echo "Cuda Version: $CUDA_VERSION"

# Use the appropriate base image (base-cpu or base-gpu).
FROM base-${BASE_TYPE} AS base
RUN echo "Building base: $BASE_TYPE-ubuntu$UBUNTU_VERSION" && sleep 2

# The target architecture the image is being built as (amd64 or arm64).
ARG TARGETARCH

# Tell the package manager to operate in a non-interactive mode, 
# which means it won't prompt the user for input during package 
# installation.
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and installs Python3.10, git, npm, curl,
# unzip, jq, tini, nano, and pm2, then clean to reduce size.
RUN apt-get update && \
    apt-get install -y python3.10 python3-pip git npm curl unzip jq tini nano && \
    npm install -g pm2 && \
    apt-get clean

# Download the appropriate aws cli installation files based on 
# this images build architecture.
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        echo "Downloading AWS for AMD64..." && \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        echo "Downloading AWS for ARM64..." && \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    else \
        echo "Unkown architecture: exiting..." && \
        exit 1; \
    fi;

# Install the aws client.
RUN unzip awscliv2.zip -d opt && ./opt/aws/install && rm awscliv2.zip

# Copy the wallet.sh script to the /usr/local/bin directory
# and make executable. This creates the wallet command.
#
# The wallet command will setup the users wallet when ran. To run 
# this command, the AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
# and AWS_WALLET_URL environment variables must be set. Optionally,
# the AWS_DEFAULT_REGION and AWS_DEFAULT_OUTPUT can be set. These 
# default to "us-east-1" and "json". 
COPY wallet.sh /usr/local/bin/wallet 
RUN chmod +x /usr/local/bin/wallet

# Set tini as the entry point. This starts tini with PID 1
# and allows it to act as the init system.
ENTRYPOINT ["tini", "--"]
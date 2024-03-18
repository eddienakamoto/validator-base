#!/bin/bash

# Script: wallet.sh
# Description: This script is responsible for configuring the bittensor 
# wallet within the Docker container. An encrypted wallet is downloaded
# from an AWS endpoint and stored in the users ~/.bittensor directory.
#
# AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are required environment
# variables that must be set before running this script. 
#
# AWS_DEFAULT_REGION and AWS_DEFAULT_OUTPUT are optional environment
# variables that can be set. If not set they will use a default value.

# If the AWS_ACCESS_KEY_ID environment variable is not set, print error
# and exit.
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "Error: Environment variable AWS_ACCESS_KEY_ID is not set." >&2
    exit 1
fi 

# If the AWS_SECRET_ACCESS_KEY environment variable is not set, print error
# and exit.
if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: Environment variable AWS_SECRET_ACCESS_KEY is not set." >&2
    exit 1
fi 

# If the AWS_WALLET_URL environment variable is not set, print error and exit.
if [ -z "$AWS_WALLET_URL" ]; then
    echo "Error: Environment variable AWS_WALLET_URL is not set." >&2
    exit 1
fi 

# Set the remaining environment variables to default values if they are not
# explicitly set.
: ${AWS_DEFAULT_REGION:="us-east-1"}
: ${AWS_DEFAULT_OUTPUT:="json"}

BITTENSOR_DIR_PATH="$HOME/.bittensor"

# Create the ~/.bittensor directory if it does not exist.
echo "Creating $BITTENSOR_DIR_PATH if does not exist..."
mkdir -p $BITTENSOR_DIR_PATH

echo "Downloading wallet from aws..."
aws s3 cp $AWS_WALLET_URL wallet.zip

echo "Unzipping wallet.zip..."
unzip wallet.zip

echo "Moving wallets to $BITTENSOR_DIR_PATH..."
mv wallets $BITTENSOR_DIR_PATH

echo "Removing wallet.zip..."
rm wallet.zip
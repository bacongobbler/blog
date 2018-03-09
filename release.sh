#!/usr/bin/env bash
set -eo pipefail

# Print a usage message and exit.
usage() {
	cat >&2 <<-'EOF'
	Usage: ./release.sh
	
	To run, I need:
	- to be provided with the name of the resource group these assets live in, in environment variable AZURE_RG_NAME
	- to be provided with the name of an Azure Blob Storage Container, in environment variable AZURE_CONTAINER
	- to be provided with Azure credentials for the container, in environment variables AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY
	- to be provided with the name of the Azure CDN, in environment variable AZURE_CDN_NAME
	- to be provided with the name of the endpoint in the Azure CDN, in environment variable AZURE_CDN_ENDPOINT_NAME
	EOF
	exit 1
}


echo "Building site with hugo"
hugo

if [ ! -d public ]; then
	echo "Something went wrong. public/ should exist."
fi

[ "$AZURE_RG_NAME" ] || usage
[ "$AZURE_CONTAINER" ] || usage
[ "$AZURE_STORAGE_ACCOUNT" ] || usage
[ "$AZURE_STORAGE_KEY" ] || usage
[ "$AZURE_CDN_NAME" ] || usage
[ "$AZURE_CDN_ENDPOINT_NAME" ] || usage

# upload the files to azure
az storage blob upload-batch --source public/ --destination "${AZURE_CONTAINER}"

# purge the CDN
echo "Purging CDN. Please wait..."
az cdn endpoint purge -g "${AZURE_RG_NAME}" --profile-name "${AZURE_CDN_NAME}" -n "${AZURE_CDN_ENDPOINT_NAME}" --content-paths '/*'

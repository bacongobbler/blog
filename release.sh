#!/usr/bin/env sh
set -eo pipefail

# Print a usage message and exit.
usage() {
	cat >&2 <<-'EOF'
	Usage: ./release.sh
	
	To run, I need:
	- to be provided with the name of an Azure Blob Storage Container, in environment variable AZURE_CONTAINER
	- to be provided with Azure credentials for the container, in environment variables AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY
	EOF
	exit 1
}


echo "Building site with hugo"
hugo

if [ ! -d public ]; then
	echo "Something went wrong. public/ should exist."
fi

[ "$AZURE_CONTAINER" ] || usage
[ "$AZURE_STORAGE_ACCOUNT" ] || usage
[ "$AZURE_STORAGE_KEY" ] || usage

# upload the files to azure
az storage blob upload-batch --source public/ --destination "${AZURE_CONTAINER}"

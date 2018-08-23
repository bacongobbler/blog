#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
ROOT="${BASH_SOURCE[0]%/*}/.."

cd "$ROOT"

# Skip on pull request builds
if [[ -n "${CIRCLE_PR_NUMBER:-}" ]]; then
	echo "Skipping deploy step; this is a pull request"
	exit
fi

VERSION=
if [[ -n "${CIRCLE_TAG:-}" ]]; then
	VERSION="$CIRCLE_TAG"
elif [[ "${CIRCLE_BRANCH:-}" == "master" ]]; then
	VERSION="canary"
else
	echo "Skipping deploy step; this is neither master or a tag"
	exit
fi

# Print a usage message and exit.
usage() {
	cat >&2 <<-'EOF'
	Usage: ./release.sh

	To run, I need:
	- to be provided with the name of the resource group these assets live in, in environment variable AZURE_RG_NAME
	- to be provided with Azure credentials for the container, in environment variables AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY
	EOF
	exit 1
}

[ "$AZURE_RG_NAME" ] || usage
[ "$AZURE_STORAGE_ACCOUNT" ] || usage
[ "$AZURE_STORAGE_KEY" ] || usage

echo "Installing Azure components"
# NOTE(bacongobbler): azure-cli needs a newer version of libffi/libssl. See https://github.com/Azure/azure-cli/issues/3720#issuecomment-350335381
apt-get update && apt-get install -yq python-pip libffi-dev libssl-dev
pip install pyopenssl
pip install --disable-pip-version-check --no-cache-dir azure-cli~=2.0
echo

echo "Pushing assets to Azure Blob Storage"
pushd public/
	for i in $(ls -p); do
		# if this is a directory, upload to a blob container with the same name as the subdirectory
		if [[ $i = *"/" ]]; then
			az storage blob upload-batch --source "$i" --destination "$i"
		else
			# otherwise upload it to the root container
			az storage blob upload-batch --source $i --destination '$root'
		fi
	done
popd

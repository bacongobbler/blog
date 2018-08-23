#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
ROOT="${BASH_SOURCE[0]%/*}/.."

cd "$ROOT"

echo "Building site with hugo"
hugo

if [ ! -d public ]; then
	echo "Something went wrong. public/ should exist."
fi

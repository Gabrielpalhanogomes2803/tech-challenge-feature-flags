#!/usr/bin/env bash

set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ensure_aws_auth

echo
echo "Autenticação AWS válida."

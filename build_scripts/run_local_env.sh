#!/usr/bin/env bash
set -euo pipefail

if ! command -v mprocs >/dev/null 2>&1; then
  echo "Please install mprocs: https://github.com/pvolok/mprocs" >&2
  exit 1
fi

mprocs --config mprocs.yaml

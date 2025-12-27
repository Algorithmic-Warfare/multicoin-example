#!/usr/bin/env bash
set -euo pipefail

# Example transaction block usage placeholders

if [ ! -f .env.local ]; then
  echo ".env.local missing" >&2
  exit 1
fi
source .env.local

cat <<'EOF'
# Example: Transfer a coin
# 1. Get a coin object id for your address
# sui client gas
# 2. Transfer:
# sui client transfer --to <RECIPIENT> --object-id <COIN_ID> --gas-budget 2000000

# Example: Custom transaction block (JSON / programmable tx) could be added here.
EOF

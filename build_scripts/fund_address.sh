#!/usr/bin/env bash
set -euo pipefail

# Optional: delay execution to allow local node / faucet to finish booting.
# Set FUND_DELAY_SECONDS env var (e.g. 5) in mprocs or shell before starting.
FUND_DELAY_SECONDS=${FUND_DELAY_SECONDS:-0}
if [[ ${FUND_DELAY_SECONDS} -gt 0 ]]; then
  echo "[fund] Delaying start for ${FUND_DELAY_SECONDS}s..."
  sleep "${FUND_DELAY_SECONDS}"
fi

# Set up local client config using
# sui client new-env --alias local --rpc http://127.0.0.1:9000

if sui client active-env 2>/dev/null | grep -qi local; then
  echo "Local environment already set as active."
else
  sui client switch --env local
fi

# Switch to the local environment using
# sui client switch --env local

if sui client active-env 2>/dev/null | grep -qi local; then
  echo "Switched to local environment."
else
  echo "Failed to switch to local environment. Please check your SUI client configuration."
  exit 1
fi


# Import private key and set account using create_and_import_account.sh
# Make sure you have your PRIVATE_KEY set in .env file
sh ./build_scripts/create_and_import_account.sh

ADDRESS=$(sui client active-address)
echo "Funding address: $ADDRESS"

# Faucet retry loop with incremental backoff.
MAX_FAUCET_ATTEMPTS=${MAX_FAUCET_ATTEMPTS:-10}
for attempt in $(seq 1 ${MAX_FAUCET_ATTEMPTS}); do
  echo "[fund] Faucet attempt ${attempt}/${MAX_FAUCET_ATTEMPTS}..."
  if sui client faucet --address "$ADDRESS"; then
    echo "[fund] Faucet request succeeded."
    break
  fi
  if [[ $attempt -eq ${MAX_FAUCET_ATTEMPTS} ]]; then
    echo "[fund] Faucet failed after ${MAX_FAUCET_ATTEMPTS} attempts." >&2
    exit 1
  fi
  # Exponential-ish backoff capped at 10s
  SLEEP=$(( attempt * 2 ))
  if [[ $SLEEP -gt 10 ]]; then SLEEP=10; fi
  echo "[fund] Faucet attempt failed; sleeping ${SLEEP}s before retry..."
  sleep $SLEEP
done

# Wait for non-zero balance (poll every 1s up to 60s)
MAX_BALANCE_WAIT=${MAX_BALANCE_WAIT:-60}
BALANCE=0
for i in $(seq 1 ${MAX_BALANCE_WAIT}); do
  # Extract numeric balance (allow smaller numbers too, not only >=10 digits)
  RAW=$(sui client balance "$ADDRESS" 2>/dev/null || true)
  BALANCE=$(echo "$RAW" | grep 'Sui' | grep -oE '[0-9]+' | head -n1 || true)
  BALANCE=${BALANCE:-0}
  echo "[fund] Poll ${i}/${MAX_BALANCE_WAIT} - balance=${BALANCE}"
  if [[ ${BALANCE} -gt 0 ]]; then
    echo "Account funded with balance: ${BALANCE}"
    break
  fi
  sleep 1
done

if [[ ${BALANCE} -eq 0 ]]; then
  echo "[fund] Failed to observe funded balance after ${MAX_BALANCE_WAIT}s." >&2
  exit 1
fi
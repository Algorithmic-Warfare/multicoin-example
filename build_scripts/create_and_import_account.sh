# First, export your private key from .env file
ALIAS=test_key
export PRIVATE_KEY_FILE=$(grep PRIVATE_KEY_FILE .env | cut -d '=' -f2)
echo "Using private key file: $PRIVATE_KEY_FILE"
PRIVATE_KEY=$(sui keytool convert "$PRIVATE_KEY_FILE" | grep "bech32WithFlag" | cut -d'│' -f3 | tr -d ' ')
echo "Converted private key: $PRIVATE_KEY"
# Import the account (note: SUI expects the key in a specific format)
# check if alias exists - update it if so
if sui keytool list | grep -q $ALIAS; then
  echo "Alias $ALIAS already exists. Updating it instead of adding."
  OLD_ALIAS=${ALIAS}_old
  echo "Backing up old alias to $OLD_ALIAS"
  sui keytool update-alias $ALIAS $OLD_ALIAS
fi
echo "Importing private key with alias $ALIAS"
sui keytool import --alias $ALIAS $PRIVATE_KEY ed25519
PUBLIC_ADDRESS=$(sui client addresses | grep "$ALIAS" | cut -d'│' -f3 | tr -d ' ')
echo "Imported account with address: $PUBLIC_ADDRESS"

# Set the imported account as active
sui client switch --address $PUBLIC_ADDRESS
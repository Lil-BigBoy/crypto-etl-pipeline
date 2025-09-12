#!/usr/bin/env bash

# This script will generate a new unique client with each run (client1, client2, ...)
# Do not run this script before generating a Root CA cert - See make_ca_and_server_certs.sh

set -euo pipefail
trap 'echo "Error on line $LINENO. Exiting."; exit 1' ERR

# ---------------------------
# CONFIG
# ---------------------------
TF_DIR="../terraform"
CERTS_DIR="$TF_DIR/certs"
CLIENTS_DIR="$CERTS_DIR/clients"
CA_KEY="$CERTS_DIR/ca.key"
CA_CRT="$CERTS_DIR/ca.crt"      

# ---------------------------
# Check Root CA cert exists or exit script
# ---------------------------
if [ ! -f "$CA_KEY" ] || [ ! -f "$CA_CRT" ]; then
    echo "[ERROR] Root CA key/cert files not found! Run make_ca_and_server_certs.sh first."
    exit 1
fi

# Ensure certs/ and clients/ directories exist
mkdir -p "$CLIENTS_DIR"

# ---------------------------
# Determine next client folder
# ---------------------------
NEXT_NUM=1
# Get the highest existing client number
for d in "$CLIENTS_DIR"/client*/; do
    if [ -d "$d" ]; then
        # Extract numeric part of folder name
        DIR_NAME=$(basename "$d")
        NUM=${DIR_NAME//client/}
        if [[ $NUM =~ ^[0-9]+$ ]] && [ "$NUM" -ge "$NEXT_NUM" ]; then
            NEXT_NUM=$((NUM + 1))
        fi
    fi
done

NEW_CLIENT_DIR="$CLIENTS_DIR/client$NEXT_NUM"
mkdir -p "$NEW_CLIENT_DIR"

echo "[INFO] Created new client directory: $NEW_CLIENT_DIR"

# ---------------------------
# Generate client key, CSR, and cert
# ---------------------------
CLIENT_KEY="$NEW_CLIENT_DIR/client.key"
CLIENT_CSR="$NEW_CLIENT_DIR/client.csr"
CLIENT_CRT="$NEW_CLIENT_DIR/client.crt"

echo "[INFO] Generating client private key..."
openssl genrsa -out "$CLIENT_KEY" 2048
chmod 600 "$CLIENT_KEY"

echo "[INFO] Generating client CSR..."
openssl req -new -key "$CLIENT_KEY" -out "$CLIENT_CSR" -subj "/CN=client$NEXT_NUM"

echo "[INFO] Signing client certificate with Root CA..."
openssl x509 -req -in "$CLIENT_CSR" -CA "$CA_CRT" -CAkey "$CA_KEY" \
    -CAcreateserial -out "$CLIENT_CRT" -days 365 -sha256

# Remove CSR as optional cleanup
rm "$CLIENT_CSR"

echo "[INFO] Client certificate created for client$NEXT_NUM:"
echo "  Key: $CLIENT_KEY"
echo "  Cert: $CLIENT_CRT"

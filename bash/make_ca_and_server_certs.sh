#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Error on line $LINENO. Exiting."; exit 1' ERR

# ---------------------------
# CONFIG
# ---------------------------
TF_DIR="../terraform"
CERTS_DIR="$TF_DIR/certs"
CA_KEY="$CERTS_DIR/ca.key"
CA_CERT="$CERTS_DIR/ca.crt"
SERVER_KEY="$CERTS_DIR/server.key"
SERVER_CSR="$CERTS_DIR/server.csr"
SERVER_CERT="$CERTS_DIR/server.crt"

# ---------------------------
# 1. Create certs/ dir
# ---------------------------
mkdir -p "$CERTS_DIR"

# ---------------------------
# 2. Generate Root CA (if not exists)
# ---------------------------
if [ ! -f "$CA_KEY" ] || [ ! -f "$CA_CERT" ]; then
    echo "[INFO] Generating Root CA..."
    openssl genrsa -out "$CA_KEY" 4096
    chmod 600 "$CA_KEY"
    openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days 3650 \
        -out "$CA_CERT" -subj "/CN=crypto-etl-RootCA"
else
    echo "[INFO] Root CA already exists. Skipping CA generation."
fi

# ---------------------------
# 3. Generate Server Certificate (always allow regeneration)
# ---------------------------
if [ -f "$SERVER_KEY" ] && [ -f "$SERVER_CERT" ]; then
    echo "[INFO] Server certificate already exists. Skipping generation."
    echo "[INFO] Delete $SERVER_KEY and $SERVER_CERT, then re-run script to regenerate a new server cert."
else
    echo "[INFO] Generating Server Certificate signed by Root CA..."
    openssl genrsa -out "$SERVER_KEY" 2048
    chmod 600 "$SERVER_KEY"
    openssl req -new -key "$SERVER_KEY" -out "$SERVER_CSR" -subj "/CN=vpn-server"
    openssl x509 -req -in "$SERVER_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
        -out "$SERVER_CERT" -days 365 -sha256

    # Clean up
    rm -f "$SERVER_CSR"
fi

echo "[INFO] Root CA: $CA_CERT"
echo "[INFO] Server Cert: $SERVER_CERT"
echo "[INFO] Certs created. Run complete."

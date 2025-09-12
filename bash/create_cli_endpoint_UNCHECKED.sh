#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Error on line $LINENO. Exiting."; exit 1' ERR

# ---------------------------
# CONFIG
# ---------------------------
TF_DIR="../terraform"
CERTS_DIR="$TF_DIR/certs"

SERVER_CERT="$CERTS_DIR/server.crt"
SERVER_KEY="$CERTS_DIR/server.key"
CA_CERT="$CERTS_DIR/ca.crt"

CLIENT_CIDR="10.10.0.0/22"
VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text)
SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=client-vpn-sg --query "SecurityGroups[0].GroupId" --output text)
REGION=$(aws configure get region)

# ---------------------------
# 1. Create Client VPN Endpoint
# ---------------------------
ENDPOINT_ID=$(aws ec2 create-client-vpn-endpoint \
    --client-cidr-block "$CLIENT_CIDR" \
    --server-certificate "$SERVER_CERT" \
    --authentication-options Type=certificate-authentication,RootCertificateChainArn="$CA_CERT" \
    --connection-log-options Enabled=false \
    --split-tunnel \
    --vpc-id "$VPC_ID" \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=client-vpn-endpoint,Tags=[{Key=Name,Value=crypto-etl-client-vpn}]" \
    --region "$REGION" \
    --query "ClientVpnEndpointId" --output text)

echo "[INFO] Client VPN Endpoint created: $ENDPOINT_ID"

# ---------------------------
# 2. Associate with a subnet (required)
# ---------------------------
SUBNET_ID=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" --query "Subnets[0].SubnetId" --output text)

aws ec2 associate-client-vpn-target-network \
    --client-vpn-endpoint-id "$ENDPOINT_ID" \
    --subnet-id "$SUBNET_ID" \
    --region "$REGION"

echo "[INFO] Client VPN Endpoint associated with subnet: $SUBNET_ID"

# ---------------------------
# Done
# ---------------------------
echo "[INFO] VPN setup complete. Endpoint ID: $ENDPOINT_ID"
echo "You can now reference this endpoint in Terraform using a data block if needed."

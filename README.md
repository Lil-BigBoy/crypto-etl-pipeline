# Crypto ETL Pipeline

This project provisions and runs an AWS hosted, event driven cryptocurrency ETL pipeline with the following components:

- **AWS infrastructure**: RDS database, S3 bucket, Client VPN, and related networking
- **Certificates**: Root CA, Server, and per-client certificates managed via ACM - for querying the DB via AWS ClientVPN endpoint
- **Terraform**: Used to define and provision all infrastructure
- **Python ETL logic**: Extracts data from CoinGeko API, performs formatting and Loads crypto pricing into the database
- **Tests**: A `test_load/` directory provides isolated tests for `load.py` with a dedicated test database and test data
- **Scripts**: bash scripts for managing AWS keys and ClientVPN certs

Here are the steps to prepare your environment, bootstrap the AWS setup, deploy infrastructure, and generate certificates:

---

## Prerequisites

- **AWS Account** – with Administrator-level permissions (or equivalent).

- **CLI Tools** – Ensure the following are installed and available in your `$PATH`:
  - [AWS CLI](https://aws.amazon.com/cli/) – manage AWS resources from the command line
  - [Terraform](https://developer.hashicorp.com/terraform/downloads) – infrastructure as code
  - [jq](https://stedolan.github.io/jq/) – lightweight JSON processor
  - [OpenSSL](https://www.openssl.org/) – for certificate/key generation
  - [OpenVPN](https://openvpn.net/) *(optional)* – required if you want to connect to the RDS instance via the Client VPN
  - [psql](https://www.postgresql.org/download/) *(optional)* – PostgreSQL CLI client, required if you want to query the RDS instance via the Client VPN

---

## Python Environment Setup For Local Testing (Optional)

- Only needed if you want to run the Python tests before deploying.
- See the README.md file in test_load/

---

## AWS Bootstrap

Follow these steps in order to set up the environment, manage AWS ClientVPN certificates, provision IaC with Terraform, and ready the permanent IAM User:


# 1. Create Temporary AWS User

- [ ] In the AWS Console, create a **temporary IAM user** with the `AdministratorAccess` policy
- [ ] Enable **Programmatic access** (access keys) so the user can run CLI/Terraform commands
- [ ] Generate and securely store **Access key ID** and **Secret access key**.


# 2. Configure AWS CLI for Temporary User

- [ ] Use **Access key ID** and **Secret access key**:
  - Run:
    ```bash
    aws configure
    ```
  - Use the temporary access keys, and set region


# 3. Generate Root CA & Server Certificates

- [ ] From project root - Run:
    ```bash
    ./bash/make_ca_and_server_certs.sh
    ```

  This will:
  - Create Root CA and Server certificates
  - Import them into ACM
  - Update ``.tfvars`` with the certificate ARNs


# 4. Deploy Terraform Infrastructure

- [ ] Provide a complete .tfvars file in terraform
  - See .tfvars.example file in the project root for details

- [ ] From the ``terraform/`` dir:
  - run
    ```bash
    terraform apply
    ```
  - Confirm the apply when prompted (type 'yes')


# 5. Switch to Permanent IAM User - terraform-crypto-etl

- [ ] From project root - Run:
    ```bash
    ./bash/update_aws_keys.sh
    ```

  This will:
  - Create **new access keys** for the ``terraform-crypto-etl`` user
  - Export them into the environment (no ``aws configure`` needed)


# 6. Remove Temporary AWS User

- [ ] In the AWS Console, delete:
  - The temporary IAM user
  - The temporary access keys

---

## Query the Database

# 1. Generate Fresh Client Certs (Optional, Anytime)

- [ ] From the project root - Run:
    ```bash
    ./bash/make_client_certs.sh
    ```

  This will:
  - Ensure ``certs/clients/`` exists
  - Create a new client directory (e.g. ``client1/``)
  - Generate the ``client.key``, ``client.crt``, and sign it with the Root CA

# 2. Connect to DB via VPN endpoint (Optional, Anytime)

- [ ]

## Common Pitfalls


## Project work-arounds

- **-**

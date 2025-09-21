# Crypto ETL Pipeline

Terraform-provisioned AWS infrastructure to ingest, transform, and store cryptocurrency price data.
The pipeline fetches prices for key coins, stores raw and processed JSON files in S3, and loads records into a PostgreSQL (RDS) database.

## Prerequisites

* Terraform ≥ 1.5.x
* AWS account with billing enabled
* AWS CLI ≥ 2.x
* Python 3.x (for local ETL testing, if needed)
* pgAdmin4 or psql (for database inspection)

## Verify local environment (optional)

```bash
terraform -v                 # Terraform version
aws --version                # AWS CLI version
aws sts get-caller-identity  # Confirm valid AWS credentials
python3 --version            # Optional: for local ETL
psql --version               # PostgreSQL client for DB queries
```

## AWS IAM Setup

Sign in as root only to create a dedicated IAM user (e.g. terraform-bootstrap-temp).

Attach AdministratorAccess policy (Privileges will de-escalate when you switch to the user terraform-crypto-etl, after deployment).

### Generate access keys:

- In the AWS console, go to IAM >>> Users >>> <Your-temp-user>

- In the 'Security credentials' tab, scroll to 'Access keys' and select 'Create access key', choosing 'CLI' when prompted for  the type of access key

- Store the access key and secret access key safely.
Never store these credentials in plain text.

### Configure temp user locally in the CLI:

```bash
aws configure
```
Provide the access key, secret key, and default region (e.g. us-east-1).

## terraform.tfvars

1. Create a file inside the /terraform directory called terraform.tfvars

2. Populate it with the information from terraform.tfvars.example

3. Replace any placeholders appropriately (and optionally remove the comments)

The name terraform.tfvars is recognised automatically by both Terraform and your .gitignore file.

Never commit real credentials to Git.

## Deployment

- From the /terraform dir, run:

```bash
terraform init             # Initialize backend and providers
terraform validate         # Optional: syntax check
terraform plan -out=tfplan # Save the plan
terraform apply tfplan     # Deploy infrastructure
```

### Successful apply outputs:

- `db_host` – RDS PostgreSQL endpoint

- `s3_bucket` – S3 bucket name for raw/processed data

## Switch to the user terraform-crypto-etl

1. Follow the rule of least privilege and switch AWS access keys to the permanent user, terraform-crypto-etl, by running:
```bash
source ./update_aws_keys
```
This user is privileged to do three things:
- Invoke: permission for manual CLI invocation of the lambda
```bash
aws lambda invoke \
--function-name crypto-etl-lambda \
--payload '{}' \
lambda_output.json
```
- Config: Permission to alter the EventBridge schedule frequency of crypto-etl-schedule
- Read:   readonly permissions to allow for TF plan/apply, and for CLI monitoring of resources & logs

2. When terraform-crypto-etl is configured...
```bash
aws sts get-caller-identity 
```
...and functioning, for security reasons, destroy the now unused temp user

## Running the ETL Pipeline

Deployment creates a Lambda that runs automatically via EventBridge (See EventBridge.tf), but may be invoked manually.

### The pipeline:

- Fetches crypto prices (bitcoin, ethereum, tether, binancecoin, solana) from the CoinGecko API

- Stores raw JSON in s3://<s3_bucket>/raw/

- Transforms records and stores processed JSON in s3://<s3_bucket>/processed/

- Inserts records into the crypto_prices table in RDS

### Manual invocation via AWS console

- Navigate to Lambda >>> Lambda functions >>> crypto_etl

- Select the 'Test' tab, optionally give your test a name (e.g. TestEvent) and run 'Test'

- Check progress in CloudWatch Logs and confirm files in S3/raw & S3/processed

### Manual invocation via CLI

- Invoke:
```bash
aws lambda invoke \
    --function-name crypto_etl \
    --payload '{}'
```

- Check CloudWatch logs:
```bash
aws logs tail /aws/lambda/crypto_etl --follow
```

- Check S3 (replace <s3_bucket>):
```bash
aws s3 ls s3://<s3_bucket>/raw/
aws s3 ls s3://<s3_bucket>/processed/
```

## Verify the Database

### query psql CLI:

``` bash
psql -h <db_host> -U <db_user> -d <db_name>
```
- Query example:
``` sql
SELECT * FROM crypto_prices ORDER BY timestamp DESC LIMIT 10;
```

### pgAdmin4:

- Create a new server with the RDS endpoint (use the db_host output), port 5432, and DB credentials

- Browse and query the crypto_prices table
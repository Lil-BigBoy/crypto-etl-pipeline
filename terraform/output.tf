output "db_host" {
  value = aws_db_instance.crypto_etl_db.address
}

output "s3_bucket" {
  value = aws_s3_bucket.crypto_data_bucket.bucket
}
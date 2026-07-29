resource_policy "aws_s3_bucket" "require_encryption" {
  locals {
    encryption_config = core::getresources("aws_s3_bucket_server_side_encryption_configuration", {
      bucket = attrs.bucket
    })
    is_encrypted = core::length(local.encryption_config) > 0
  }
  enforce {
    condition     = local.is_encrypted
    error_message = "S3 bucket '${attrs.bucket}' must have an aws_s3_bucket_server_side_encryption_configuration attached"
  }
}

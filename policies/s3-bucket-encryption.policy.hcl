resource_policy "aws_s3_bucket" "require_encryption" {
  locals {
    encryption_config = core::getresources("aws_s3_bucket_server_side_encryption_configuration", {
      bucket = attrs.bucket
    })
    is_encrypted = core::try(core::length(local.encryption_config) > 0, false)
  }
  enforce {
    condition     = local.is_encrypted
    error_message = "S3 bucket ${attrs.bucket} must be encrypted using 'aws_s3_bucket_server_side_encryption_configuration'."
  }
}

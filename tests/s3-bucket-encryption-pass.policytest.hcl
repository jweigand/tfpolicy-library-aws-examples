policytest {
  targets = ["../policies/s3-bucket-encryption.policy.hcl"]
}

# PASS: bucket has a server-side encryption configuration attached.
resource "aws_s3_bucket" "encrypted_bucket" {
  attrs = {
    bucket = "my-encrypted-bucket"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypted_bucket" {
  skip = true
  attrs = {
    bucket = "my-encrypted-bucket"
    rule = [
      {
        apply_server_side_encryption_by_default = [
          {
            sse_algorithm = "aws:kms"
          }
        ]
      }
    ]
  }
}

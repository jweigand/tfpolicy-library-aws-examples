policytest {
  targets = ["../policies/s3-bucket-encryption.policy.hcl"]
}

# FAIL: bucket has no server-side encryption configuration — policy blocks it.
resource "aws_s3_bucket" "unencrypted_bucket" {
  expect_failure = true
  attrs = {
    bucket = "my-unencrypted-bucket"
  }
}

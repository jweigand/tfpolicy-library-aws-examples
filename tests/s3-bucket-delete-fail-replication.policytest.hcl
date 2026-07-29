policytest {
  targets = ["../policies/s3-bucket-delete.policy.hcl"]
}

# FAIL: bucket has a replication configuration data source — deletion blocked.
resource "aws_s3_bucket" "replicated_bucket" {
  expect_failure = true
  prior_attrs = {
    bucket = "my-replicated-bucket"
  }
}

data "aws_s3_bucket_replication_configuration" "replicated_bucket" {
  attrs = {
    bucket = "my-replicated-bucket"
    role   = "arn:aws:iam::123456789012:role/replication-role"
  }
}

data "aws_s3_objects" "replicated_bucket" {
  attrs = {
    bucket = "my-replicated-bucket"
    keys   = []
  }
}

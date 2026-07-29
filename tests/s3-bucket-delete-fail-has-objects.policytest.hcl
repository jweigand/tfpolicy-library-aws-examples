policytest {
  targets = ["../policies/s3-bucket-delete.policy.hcl"]
}

# FAIL: bucket still contains objects — deletion blocked.
resource "aws_s3_bucket" "non_empty_bucket" {
  expect_failure = true
  prior_attrs = {
    bucket = "my-non-empty-bucket"
  }
}

data "aws_s3_objects" "non_empty_bucket" {
  attrs = {
    bucket   = "my-non-empty-bucket"
    max_keys = 1
    keys     = ["some-object-key"]
  }
}

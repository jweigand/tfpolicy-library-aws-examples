policytest {
  targets = ["../policies/s3-bucket-delete.policy.hcl"]
}

# FAIL: bucket is referenced by a multi-region access point data source — deletion blocked.
resource "aws_s3_bucket" "mrap_bucket" {
  expect_failure = true
  prior_attrs = {
    bucket = "my-mrap-bucket"
  }
}

data "aws_s3control_multi_region_access_points" "mrap_bucket" {
  attrs = {
    bucket = "my-mrap-bucket"
  }
}

data "aws_s3_objects" "mrap_bucket" {
  attrs = {
    bucket = "my-mrap-bucket"
    keys   = []
  }
}

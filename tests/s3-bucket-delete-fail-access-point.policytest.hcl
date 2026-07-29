policytest {
  targets = ["../policies/s3-bucket-delete.policy.hcl"]
}

# FAIL: bucket is referenced by an access points data source — deletion blocked.
resource "aws_s3_bucket" "access_point_bucket" {
  expect_failure = true
  prior_attrs = {
    bucket = "my-access-point-bucket"
  }
}

data "aws_s3control_access_points" "access_point_bucket" {
  attrs = {
    bucket = "my-access-point-bucket"
  }
}

data "aws_s3_objects" "access_point_bucket" {
  attrs = {
    bucket = "my-access-point-bucket"
    keys   = []
  }
}

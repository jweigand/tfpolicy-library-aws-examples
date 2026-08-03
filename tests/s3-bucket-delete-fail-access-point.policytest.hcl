policytest {
  targets = ["../policies/s3-bucket-delete.policy.hcl"]
}

# FAIL: bucket is referenced by an access point — deletion blocked.
resource "aws_s3_bucket" "access_point_bucket" {
  expect_failure = true
  prior_attrs = {
    bucket = "my-access-point-bucket"
  }
}

# delete_checks_base — no lock, no objects
data "aws_s3_objects" "access_point_bucket" {
  attrs = {
    bucket = "my-access-point-bucket"
    keys   = []
  }
}

# delete_checks_access_points — access point present (triggers failure), no MRAPs
data "aws_s3control_access_points" "access_point_bucket" {
  attrs = {
    bucket = "my-access-point-bucket"
    access_points = [
      {
        name             = "my-access-point"
        access_point_arn = "arn:aws:s3:us-east-1:123456789012:accesspoint/my-access-point"
        alias            = "my-access-point-abc123-s3alias"
      }
    ]
  }
}

data "aws_s3control_multi_region_access_points" "access_point_bucket" {
  attrs = {
    region        = "us-west-2"
    access_points = []
  }
}

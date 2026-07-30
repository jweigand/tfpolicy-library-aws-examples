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

# delete_checks_base — no lock, no replication, no objects
data "aws_s3_bucket_object_lock_configuration" "access_point_bucket" {
  attrs = {
    bucket = "my-access-point-bucket"
  }
}

data "aws_s3_bucket_replication_configuration" "access_point_bucket" {
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

# delete_checks_access_points — access point present (triggers failure), no MRAPs
data "aws_s3control_access_points" "access_point_bucket" {
  attrs = {
    bucket        = "my-access-point-bucket"
    access_points = [{ name = "my-access-point" }]
  }
}

data "aws_s3control_multi_region_access_points" "access_point_bucket" {
  attrs = {
    access_points = []
  }
}

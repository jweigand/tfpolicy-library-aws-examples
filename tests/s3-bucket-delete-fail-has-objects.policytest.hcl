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

# delete_checks_base — objects present (triggers failure), no lock/replication
data "aws_s3_bucket_object_lock_configuration" "non_empty_bucket" {
  attrs = {
    bucket = "my-non-empty-bucket"
  }
}

data "aws_s3_bucket_replication_configuration" "non_empty_bucket" {
  attrs = {
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

# delete_checks_access_points — no access points, no MRAPs
data "aws_s3control_access_points" "non_empty_bucket" {
  attrs = {
    bucket        = "my-non-empty-bucket"
    access_points = null
  }
}

data "aws_s3control_multi_region_access_points" "non_empty_bucket" {
  attrs = {
    access_points = []
  }
}

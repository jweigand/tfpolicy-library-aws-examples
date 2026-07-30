policytest {
  targets = ["../policies/s3-bucket-delete.policy.hcl"]
}

# FAIL: bucket has an object lock configuration data source — deletion blocked.
resource "aws_s3_bucket" "locked_bucket" {
  expect_failure = true
  prior_attrs = {
    bucket = "my-locked-bucket"
  }
}

# delete_checks_base — object lock present (triggers failure), no objects
data "aws_s3_bucket_object_lock_configuration" "locked_bucket" {
  attrs = {
    bucket              = "my-locked-bucket"
    object_lock_enabled = "Enabled"
  }
}

data "aws_s3_bucket_replication_configuration" "locked_bucket" {
  attrs = {
    bucket = "my-locked-bucket"
  }
}

data "aws_s3_objects" "locked_bucket" {
  attrs = {
    bucket = "my-locked-bucket"
    keys   = []
  }
}

# delete_checks_access_points — no access points, no MRAPs
data "aws_s3control_access_points" "locked_bucket" {
  attrs = {
    bucket        = "my-locked-bucket"
    access_points = null
  }
}

data "aws_s3control_multi_region_access_points" "locked_bucket" {
  attrs = {
    access_points = []
  }
}

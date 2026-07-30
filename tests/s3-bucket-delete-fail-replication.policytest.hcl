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

# delete_checks_base — replication present (triggers failure), no objects
data "aws_s3_bucket_object_lock_configuration" "replicated_bucket" {
  attrs = {
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

# delete_checks_access_points — no access points, no MRAPs
data "aws_s3control_access_points" "replicated_bucket" {
  attrs = {
    bucket        = "my-replicated-bucket"
    access_points = null
  }
}

data "aws_s3control_multi_region_access_points" "replicated_bucket" {
  attrs = {
    access_points = []
  }
}

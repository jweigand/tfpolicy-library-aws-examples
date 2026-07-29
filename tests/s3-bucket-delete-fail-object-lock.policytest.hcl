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

data "aws_s3_bucket_object_lock_configuration" "locked_bucket" {
  attrs = {
    bucket               = "my-locked-bucket"
    object_lock_enabled  = "Enabled"
  }
}

data "aws_s3_objects" "locked_bucket" {
  attrs = {
    bucket = "my-locked-bucket"
    keys   = []
  }
}

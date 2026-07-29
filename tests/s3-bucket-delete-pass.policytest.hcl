policytest {
  targets = ["../policies/s3-bucket-delete.policy.hcl"]
}

# PASS: bucket has no object lock config, replication config, access points,
# multi-region access points, and contains no objects — safe to delete.
resource "aws_s3_bucket" "clean_bucket" {
  prior_attrs = {
    bucket = "my-clean-bucket"
  }
}

data "aws_s3control_access_points" "clean_bucket" {
  attrs = {
    bucket        = "my-clean-bucket"
    access_points = null
  }
}

data "aws_s3_objects" "clean_bucket" {
  attrs = {
    bucket = "my-clean-bucket"
    keys   = []
  }
}

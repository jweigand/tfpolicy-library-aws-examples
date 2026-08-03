policytest {
  targets = ["../policies/s3-bucket-delete.policy.hcl"]
}

# FAIL: bucket is referenced by a multi-region access point — deletion blocked.
resource "aws_s3_bucket" "mrap_bucket" {
  expect_failure = true
  prior_attrs = {
    bucket = "my-mrap-bucket"
  }
}

# delete_checks_base — no lock, no objects
data "aws_s3_objects" "mrap_bucket" {
  attrs = {
    bucket = "my-mrap-bucket"
    keys   = []
  }
}

# delete_checks_access_points — no access points, MRAP present referencing this bucket
data "aws_s3control_access_points" "mrap_bucket" {
  attrs = {
    bucket        = "my-mrap-bucket"
    access_points = null
  }
}

data "aws_s3control_multi_region_access_points" "mrap_bucket" {
  attrs = {
    region = "us-west-2"
    access_points = [
      {
        name       = "my-mrap"
        alias      = "abc123.mrap"
        created_at = "2024-01-01T00:00:00Z"
        status     = "READY"
        regions = [
          {
            bucket = "my-mrap-bucket"
          }
        ]
      }
    ]
  }
}

policytest {
  targets = ["../policies/s3-replication-iam-permissions.policy.hcl"]
}

# FAIL: replication role is denied s3:GetObjectVersionAcl and
# s3:GetObjectVersionTagging on source objects — source object permission
# check must fail.

resource "aws_s3_bucket_replication_configuration" "missing_source_permissions" {
  expect_failure = true
  attrs = {
    bucket = "source-bucket-no-obj-perms"
    role   = "arn:aws:iam::123456789012:role/s3-replication-role-restricted"
    rule = [
      {
        id     = "replicate-all"
        status = "Enabled"
        destination = [
          {
            bucket        = "arn:aws:s3:::destination-bucket"
            storage_class = "STANDARD"
          }
        ]
      }
    ]
  }
}

# Source bucket-level simulation — all allowed (not the failing check)
data "aws_iam_principal_policy_simulation" "source_bucket_sim_missing_source" {
  attrs = {
    policy_source_arn = "arn:aws:iam::123456789012:role/s3-replication-role-restricted"
    action_names      = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resource_arns     = ["arn:aws:s3:::source-bucket-no-obj-perms"]
    results = [
      {
        action_name  = "s3:GetReplicationConfiguration"
        resource_arn = "arn:aws:s3:::source-bucket-no-obj-perms"
        decision     = "allowed"
      },
      {
        action_name  = "s3:ListBucket"
        resource_arn = "arn:aws:s3:::source-bucket-no-obj-perms"
        decision     = "allowed"
      }
    ]
  }
}

# Source object-level simulation — two actions denied
data "aws_iam_principal_policy_simulation" "source_object_sim_missing_source" {
  attrs = {
    policy_source_arn = "arn:aws:iam::123456789012:role/s3-replication-role-restricted"
    action_names      = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
    resource_arns     = ["arn:aws:s3:::source-bucket-no-obj-perms/*"]
    results = [
      {
        action_name  = "s3:GetObjectVersionForReplication"
        resource_arn = "arn:aws:s3:::source-bucket-no-obj-perms/*"
        decision     = "allowed"
      },
      {
        action_name  = "s3:GetObjectVersionAcl"
        resource_arn = "arn:aws:s3:::source-bucket-no-obj-perms/*"
        decision     = "implicitDeny"
      },
      {
        action_name  = "s3:GetObjectVersionTagging"
        resource_arn = "arn:aws:s3:::source-bucket-no-obj-perms/*"
        decision     = "implicitDeny"
      }
    ]
  }
}

# Destination simulation — all allowed (not the failing check)
data "aws_iam_principal_policy_simulation" "destination_sim_missing_source" {
  attrs = {
    policy_source_arn = "arn:aws:iam::123456789012:role/s3-replication-role-restricted"
    action_names      = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
    resource_arns     = ["arn:aws:s3:::destination-bucket/*"]
    results = [
      {
        action_name  = "s3:ReplicateObject"
        resource_arn = "arn:aws:s3:::destination-bucket/*"
        decision     = "allowed"
      },
      {
        action_name  = "s3:ReplicateDelete"
        resource_arn = "arn:aws:s3:::destination-bucket/*"
        decision     = "allowed"
      },
      {
        action_name  = "s3:ReplicateTags"
        resource_arn = "arn:aws:s3:::destination-bucket/*"
        decision     = "allowed"
      }
    ]
  }
}

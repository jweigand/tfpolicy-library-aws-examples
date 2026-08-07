policytest {
  targets = ["../policies/s3-replication-iam-permissions.policy.hcl"]
}

# FAIL: replication role is denied s3:ReplicateDelete and s3:ReplicateTags on
# the destination bucket — destination permission check must fail.

resource "aws_s3_bucket_replication_configuration" "missing_destination_permissions" {
  expect_failure = true
  attrs = {
    bucket = "source-bucket-no-dest-perms"
    role   = "arn:aws:iam::123456789012:role/s3-replication-role-no-dest"
    rule = [
      {
        id     = "replicate-all"
        status = "Enabled"
        destination = [
          {
            bucket        = "arn:aws:s3:::destination-bucket-restricted"
            storage_class = "STANDARD"
          }
        ]
      }
    ]
  }
}

# Source bucket-level simulation — all allowed
data "aws_iam_principal_policy_simulation" "source_bucket_sim_missing_dest" {
  attrs = {
    policy_source_arn = "arn:aws:iam::123456789012:role/s3-replication-role-no-dest"
    action_names      = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resource_arns     = ["arn:aws:s3:::source-bucket-no-dest-perms"]
    results = [
      {
        action_name  = "s3:GetReplicationConfiguration"
        resource_arn = "arn:aws:s3:::source-bucket-no-dest-perms"
        decision     = "allowed"
      },
      {
        action_name  = "s3:ListBucket"
        resource_arn = "arn:aws:s3:::source-bucket-no-dest-perms"
        decision     = "allowed"
      }
    ]
  }
}

# Source object-level simulation — all allowed
data "aws_iam_principal_policy_simulation" "source_object_sim_missing_dest" {
  attrs = {
    policy_source_arn = "arn:aws:iam::123456789012:role/s3-replication-role-no-dest"
    action_names      = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
    resource_arns     = ["arn:aws:s3:::source-bucket-no-dest-perms/*"]
    results = [
      {
        action_name  = "s3:GetObjectVersionForReplication"
        resource_arn = "arn:aws:s3:::source-bucket-no-dest-perms/*"
        decision     = "allowed"
      },
      {
        action_name  = "s3:GetObjectVersionAcl"
        resource_arn = "arn:aws:s3:::source-bucket-no-dest-perms/*"
        decision     = "allowed"
      },
      {
        action_name  = "s3:GetObjectVersionTagging"
        resource_arn = "arn:aws:s3:::source-bucket-no-dest-perms/*"
        decision     = "allowed"
      }
    ]
  }
}

# Destination simulation — s3:ReplicateDelete and s3:ReplicateTags denied
data "aws_iam_principal_policy_simulation" "destination_sim_missing_dest" {
  attrs = {
    policy_source_arn = "arn:aws:iam::123456789012:role/s3-replication-role-no-dest"
    action_names      = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
    resource_arns     = ["arn:aws:s3:::destination-bucket-restricted/*"]
    results = [
      {
        action_name  = "s3:ReplicateObject"
        resource_arn = "arn:aws:s3:::destination-bucket-restricted/*"
        decision     = "allowed"
      },
      {
        action_name  = "s3:ReplicateDelete"
        resource_arn = "arn:aws:s3:::destination-bucket-restricted/*"
        decision     = "explicitDeny"
      },
      {
        action_name  = "s3:ReplicateTags"
        resource_arn = "arn:aws:s3:::destination-bucket-restricted/*"
        decision     = "implicitDeny"
      }
    ]
  }
}

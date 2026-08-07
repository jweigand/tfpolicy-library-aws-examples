policytest {
  targets = ["../policies/s3-replication-iam-permissions.policy.hcl"]
}

# PASS: replication role is granted all required source and destination
# permissions — policy simulator returns "allowed" for every action.

resource "aws_s3_bucket_replication_configuration" "fully_permitted" {
  attrs = {
    bucket = "source-bucket"
    role   = "arn:aws:iam::123456789012:role/s3-replication-role"
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

# Source bucket-level simulation — all actions allowed
data "aws_iam_principal_policy_simulation" "source_bucket_sim_fully_permitted" {
  attrs = {
    policy_source_arn = "arn:aws:iam::123456789012:role/s3-replication-role"
    action_names      = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resource_arns     = ["arn:aws:s3:::source-bucket"]
    results = [
      {
        action_name  = "s3:GetReplicationConfiguration"
        resource_arn = "arn:aws:s3:::source-bucket"
        decision     = "allowed"
      },
      {
        action_name  = "s3:ListBucket"
        resource_arn = "arn:aws:s3:::source-bucket"
        decision     = "allowed"
      }
    ]
  }
}

# Source object-level simulation — all actions allowed
data "aws_iam_principal_policy_simulation" "source_object_sim_fully_permitted" {
  attrs = {
    policy_source_arn = "arn:aws:iam::123456789012:role/s3-replication-role"
    action_names      = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
    resource_arns     = ["arn:aws:s3:::source-bucket/*"]
    results = [
      {
        action_name  = "s3:GetObjectVersionForReplication"
        resource_arn = "arn:aws:s3:::source-bucket/*"
        decision     = "allowed"
      },
      {
        action_name  = "s3:GetObjectVersionAcl"
        resource_arn = "arn:aws:s3:::source-bucket/*"
        decision     = "allowed"
      },
      {
        action_name  = "s3:GetObjectVersionTagging"
        resource_arn = "arn:aws:s3:::source-bucket/*"
        decision     = "allowed"
      }
    ]
  }
}

# Destination object-level simulation — all actions allowed
data "aws_iam_principal_policy_simulation" "destination_sim_fully_permitted" {
  attrs = {
    policy_source_arn = "arn:aws:iam::123456789012:role/s3-replication-role"
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

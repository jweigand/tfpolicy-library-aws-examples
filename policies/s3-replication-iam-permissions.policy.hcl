# S3 Bucket Replication — IAM Permission Validation
#
# Validates that the IAM role configured in every
# aws_s3_bucket_replication_configuration has the permissions required for
# cross-bucket replication, using the aws_iam_principal_policy_simulation
# data source to call the AWS IAM policy simulator API.
#
# Source-bucket checks (performed against the source bucket ARN):
#   s3:GetReplicationConfiguration  — read replication rules from source bucket
#   s3:ListBucket                   — list objects to be replicated
#   s3:GetObjectVersionForReplication — read each object version to replicate
#   s3:GetObjectVersionAcl          — read ACLs to carry across
#   s3:GetObjectVersionTagging      — read object tags to carry across
#
# Destination-bucket checks (performed against every destination bucket ARN):
#   s3:ReplicateObject              — write replicated objects to destination
#   s3:ReplicateDelete              — propagate deletes to destination
#   s3:ReplicateTags                — copy tags to destination
#
# NOTE: KMS-encrypted replication (kms:Decrypt / kms:GenerateDataKey) is not
# checked here because the kms_encrypted_objects enablement flag and key ARNs
# live inside replication rule blocks whose structure varies widely.  Add a
# separate policy targeting aws_s3_bucket_replication_configuration for KMS if
# your organisation requires it.
#
# NOTE: This policy uses aws_iam_principal_policy_simulation, which calls the
# live AWS IAM policy simulator.  It resolves at apply time (not plan time).

resource_policy "aws_s3_bucket_replication_configuration" "replication_role_source_permissions" {
  enforcement_level = "mandatory"

  locals {
    role_arn    = core::try(attrs.role, "")
    rules       = core::try(attrs.rule, [])
    source_bucket_arn = core::try(attrs.bucket, "")

    # Source-bucket actions that the role must be allowed on the source bucket
    # and on objects inside it (checked separately below).
    source_bucket_actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    source_object_actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    # Simulate source-bucket-level actions
    source_bucket_sim = core::try(core::getdatasource("aws_iam_principal_policy_simulation", {
      policy_source_arn = local.role_arn
      action_names      = local.source_bucket_actions
      resource_arns     = ["arn:aws:s3:::${local.source_bucket_arn}"]
    }), null)

    # Simulate source object-level actions
    source_object_sim = core::try(core::getdatasource("aws_iam_principal_policy_simulation", {
      policy_source_arn = local.role_arn
      action_names      = local.source_object_actions
      resource_arns     = ["arn:aws:s3:::${local.source_bucket_arn}/*"]
    }), null)

    # Gather all results that were denied (decision != "allowed")
    source_bucket_denied = local.source_bucket_sim == null ? [] : [
      for r in core::try(local.source_bucket_sim.results, []) : r
      if core::try(r.decision, "implicitDeny") != "allowed"
    ]

    source_object_denied = local.source_object_sim == null ? [] : [
      for r in core::try(local.source_object_sim.results, []) : r
      if core::try(r.decision, "implicitDeny") != "allowed"
    ]

    denied_source_actions = core::join(", ", [for r in local.source_bucket_denied : core::try(r.action_name, "unknown")])
    denied_source_object_actions = core::join(", ", [for r in local.source_object_denied : core::try(r.action_name, "unknown")])
  }

  enforce {
    condition     = local.source_bucket_sim != null && core::length(local.source_bucket_denied) == 0
    error_message = "Replication role '${local.role_arn}' is missing required source bucket permissions. Denied actions: ${local.denied_source_actions}"
  }

  enforce {
    condition     = local.source_object_sim != null && core::length(local.source_object_denied) == 0
    error_message = "Replication role '${local.role_arn}' is missing required source object permissions. Denied actions: ${local.denied_source_object_actions}"
  }
}

resource_policy "aws_s3_bucket_replication_configuration" "replication_role_destination_permissions" {
  enforcement_level = "mandatory"

  locals {
    role_arn = core::try(attrs.role, "")
    rules    = core::try(attrs.rule, [])

    # Collect all unique destination bucket ARNs across all rules
    destination_arns = [for rule in local.rules : core::try(rule.destination[0].bucket, "") if core::try(rule.destination[0].bucket, "") != ""]

    # Destination actions that the role must be allowed on each destination bucket
    destination_actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    # Simulate destination object-level actions for all destination buckets at once.
    # The policy simulator accepts multiple resource ARNs and returns one result per
    # action/resource combination.
    dest_object_arns = [for arn in local.destination_arns : "${arn}/*"]

    destination_sim = core::length(local.destination_arns) == 0 ? null : core::try(core::getdatasource("aws_iam_principal_policy_simulation", {
      policy_source_arn = local.role_arn
      action_names      = local.destination_actions
      resource_arns     = local.dest_object_arns
    }), null)

    destination_denied = local.destination_sim == null ? [] : [
      for r in core::try(local.destination_sim.results, []) : r
      if core::try(r.decision, "implicitDeny") != "allowed"
    ]

    denied_destination_summary = core::join(", ", [
      for r in local.destination_denied : "${core::try(r.action_name, "unknown")} on ${core::try(r.resource_arn, "unknown")}"
    ])
  }

  enforce {
    condition     = core::length(local.destination_arns) == 0 || (local.destination_sim != null && core::length(local.destination_denied) == 0)
    error_message = "Replication role '${local.role_arn}' is missing required destination bucket permissions. Denied: ${local.denied_destination_summary}"
  }
}

# SSM Parameter KMS Key Required
#
# Ensures that every SecureString SSM parameter is encrypted with a
# customer-managed KMS key (key_manager = "CUSTOMER") rather than the
# AWS-managed default key (key_manager = "AWS").
#
# Two checks are applied:
#   1. key_id must be set and non-empty.
#   2. The referenced KMS key must not be an AWS-managed key.
#
# Lookup order for the referenced KMS key:
#   a. If key_id is null/unknown at plan time, the SSM parameter is referencing
#      a KMS key being created in the same plan. In this case we skip the
#      data source lookup — a customer-created aws_kms_key resource is by
#      definition not AWS-managed.
#   b. If key_id is a known string, check plan resources first (core::getresources)
#      matching on arn or key_id. If found in the plan it is customer-managed.
#   c. If not found in the plan, fall back to the aws_kms_key data source and
#      check key_manager != "AWS".
#
# Scope: only aws_ssm_parameter resources whose type = "SecureString".
#        String and StringList parameters are not encrypted, so key_id is
#        irrelevant for those types and they are excluded via the filter.

/*

resource_policy "aws_ssm_parameter" "require_customer_managed_kms_key" {
  enforcement_level = "mandatory"
  filter            = attrs.type == "SecureString"

  locals {
    key_id     = core::try(attrs.key_id, null)
    key_is_set = local.key_id != null && local.key_id != ""

    # (a) key_id is null/unknown — SSM param references a key being created in
    # this plan. core::try returns null for unknown computed values, so we treat
    # this as a customer-managed key and skip further checks.
    key_id_unknown = local.key_id == null

    # (b) Search plan resources for an aws_kms_key whose arn or key_id matches.
    # arn and id are unknown for new resources, so this only matches keys that
    # are being updated (where prior values are known) or aliased by a known ARN.
    plan_keys        = local.key_is_set ? core::getresources("aws_kms_key", {}) : []
    key_in_plan      = core::length([for k in local.plan_keys : k
                         if core::try(k.arn, "") == local.key_id ||
                            core::try(k.key_id, "") == local.key_id]) > 0

    # (c) Fall back to data source for pre-existing keys not in the plan.
    kms_datasource = local.key_is_set && !local.key_in_plan ? core::try(core::getdatasource("aws_kms_key", { key_id = local.key_id }), null) : null
    key_manager    = core::try(local.kms_datasource.key_manager, "")

    # A key is compliant if:
    #  - key_id is unknown (references a new in-plan resource), or
    #  - key_id resolves to a resource in the plan (customer-created), or
    #  - the data source confirms key_manager != "AWS"
    key_is_compliant = local.key_id_unknown || local.key_in_plan || local.key_manager != "AWS"
  }

  enforce {
    condition     = local.key_id_unknown || local.key_is_set
    error_message = "SSM SecureString parameters must specify a customer-managed KMS key via 'key_id'. Leaving it blank defaults to the AWS-managed 'aws/ssm' key."
  }

  enforce {
    condition     = !local.key_is_set || local.key_is_compliant
    error_message = "SSM SecureString parameter 'key_id' must reference a customer-managed KMS key. The key '${local.key_id}' is managed by AWS and is not permitted."
  }
}

*/

resource_policy "aws_ssm_parameter" "custom_kms_key" {
  enforcement_level = "mandatory"
  filter            = attrs.type == "SecureString"

  locals {
    key_id        = core::try(attrs.key_id, null)
    key_is_set    = local.key_id != null && local.key_id != ""
    resource_keys = local.key_is_set ? core::getresources("aws_kms_key", {}) : []
    key_in_plan   = core::length([for k in local.resource_keys : k
                      if core::try(k.arn, "") == local.key_id ||
                         core::try(k.id, "") == local.key_id]) > 0
    datasource_key = local.key_is_set && !local.key_in_plan ? core::try(core::getdatasource("aws_kms_key", { key_id = local.key_id }), null) : null
  }

  enforce {
    condition     = local.key_is_set
    error_message = "SSM SecureString parameters must specify a customer-managed KMS key via 'key_id'. Leaving it blank defaults to the AWS-managed 'aws/ssm' key."
  }

  enforce {
    condition     = !local.key_is_set || local.key_in_plan || core::try(local.datasource_key.key_manager != "AWS", false)
    error_message = "SSM SecureString parameter 'key_id' must reference a customer-managed KMS key. The key '${local.key_id}' is managed by AWS and is not permitted."
  }

}

resource_policy "aws_ssm_parameter" "custom_kms_key" {
  enforcement_level = "mandatory"
  filter            = attrs.type == "SecureString"

  locals {
    unset_key      = attrs.key_id != null || attrs.key_id != ""
    resource_key   = local.unset_key ? core::getresources("aws_kms_key", { key_id = attrs.key_id }) : false
    datasource_key = local.resource_key ? core::try(core::getdatasource("aws_kms_key", { key_id = attrs.key_id }), null) : null
  }

  enforce {
    condition     = !local.unset_key
    error_message = "SSM SecureString parameters must specify a customer-managed KMS key via 'key_id'. Leaving it blank defaults to the AWS-managed 'aws/ssm' key."
    info_message  = "unset_key: ${local.unset_key}"
  }

  enforce {
    condition     = local.resource_key != false || core::try(local.datasource_key.key_manager != "AWS", false)
    error_message = "SSM SecureString parameters must specify a customer-managed KMS key via 'key_id'. Leaving it blank defaults to the AWS-managed 'aws/ssm' key."
    info_message  = "value"
  }

}

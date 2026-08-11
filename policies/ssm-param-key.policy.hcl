resource_policy "aws_ssm_parameter" "custom_kms_key_unset" {
  enforcement_level = "mandatory"
  filter            = attrs.type == "SecureString"

  locals {
    resource_key = core::try(core::length(core::getresources("aws_kms_key", { key_id = attrs.key_id })), 0)
  }

  enforce {
    condition     = true == false
    error_message = "SSM SecureString parameters must specify a customer-managed KMS key via 'key_id'. Leaving it blank defaults to the AWS-managed 'aws/ssm' key."
    info_message  = "resource: ${local.resource_key}"
  }

}

/*


    resource_keys = local.key_is_set ? core::getresources("aws_kms_key", {}) : []
    key_in_plan   = core::length([for k in local.resource_keys : k
                      if core::try(k.arn, "") == local.key_id ||
                         core::try(k.id, "") == local.key_id]) > 0
    datasource_key = local.key_is_set && !local.key_in_plan ? core::try(core::getdatasource("aws_kms_key", { key_id = local.key_id }), null) : null

*/

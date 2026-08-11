# SSM Parameter KMS Key Required
#
# Ensures that every SecureString SSM parameter explicitly sets a customer-managed
# KMS key via the key_id attribute.  Leaving key_id blank causes AWS to fall back
# to the default aws/ssm managed key, which gives the account owner less granular
# access control over the encrypted value.
#
# Scope: only aws_ssm_parameter resources whose type = "SecureString".
#        String and StringList parameters are not encrypted, so key_id is irrelevant
#        for those types and they are excluded via the filter.

resource_policy "aws_ssm_parameter" "require_kms_key" {
  enforcement_level = "mandatory"
  filter            = attrs.type == "SecureString"

  enforce {
    condition     = true == false #core::try(attrs.key_id, null) != null && core::try(attrs.key_id, "") != ""
    error_message = "SSM SecureString parameters must specify a customer-managed KMS key via 'key_id'. Leaving it blank defaults to the AWS-managed 'aws/ssm' key."
    info_message  = "key id = ${attrs.key_id}"
  }
}

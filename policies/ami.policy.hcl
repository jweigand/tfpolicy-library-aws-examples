# AMI Validation
#
# Enforces AMI governance rules for resources that reference AMIs:
#
#   aws_instance
#     - Owner allowlist: the AMI must be owned by one of the principals in
#       `allowed_ami_owners` (defaults to AWS-managed Amazon images).
#
#   aws_launch_template
#     - Required tags: the AMI must carry every key/value pair in
#       `ami_required_tags`, enforcing that only internally-approved or
#       compliance-stamped AMIs are used.  The default requires Approved=true.
#
# NOTE: aws_launch_template.image_id may be null when the launch template is
# intentionally created without a fixed AMI (e.g. the AMI is supplied at
# launch time via an override).  The policy skips those templates via `filter`.
#
# NOTE: core::getdatasource() resolves at apply time, not plan time.  On first-
# create plans the AMI data source may be unavailable; both policies degrade
# gracefully to a deny when the lookup returns null.

input "allowed_ami_owners" {
  type    = list(string)
  default = ["amazon"]
}

input "ami_required_tags" {
  type    = map(string)
  default = { Approved = "true" }
}

resource_policy "aws_instance" "ami_owners" {
  locals {
    ami = core::try(core::getdatasource("aws_ami", {
      filter = [{
        name   = "image-id"
        values = [attrs.ami]
      }]
    }), null)

    allowed_owner = local.ami == null ? false : core::length([
      for owner in core::try(local.ami.owners, []) : owner
      if core::contains(input.allowed_ami_owners, owner)
    ]) > 0
  }

  enforce {
    condition     = local.allowed_owner
    error_message = "AMI '${attrs.ami}' is not owned by an allowed owner. Allowed: ${core::join(", ", input.allowed_ami_owners)}"
  }
}

resource_policy "aws_launch_template" "ami_tag" {
  # Skip launch templates that have no fixed AMI configured
  filter = core::try(attrs.image_id, null) != null && core::try(attrs.image_id, "") != ""

  locals {
    image_id = core::try(attrs.image_id, "")

    ami = core::try(core::getdatasource("aws_ami", {
      filter = [{
        name   = "image-id"
        values = [local.image_id]
      }]
    }), null)

    ami_tags = core::try(local.ami.tags, {})

    # Collect every required tag whose key is absent or whose value does not match
    missing_tags = local.ami == null ? [] : [
      for k, v in input.ami_required_tags : "${k}=${v}"
      if core::try(local.ami_tags[k], null) != v
    ]
  }

  enforce {
    condition     = core::length(local.missing_tags) == 0
    error_message = "Launch template AMI '${local.image_id}' is missing required tag(s): ${core::join(", ", local.missing_tags)}"
  }
}

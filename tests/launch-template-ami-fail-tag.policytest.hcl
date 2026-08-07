policytest {
  targets = ["../policies/ami.policy.hcl"]
}

inputs {
  ami_required_tags = { Approved = "true" }
}

# FAIL: AMI has no tags at all — every required tag is missing.

resource "aws_launch_template" "missing_tag" {
  expect_failure = true
  attrs = {
    image_id = "ami-0missingtag00000000"
  }
}

data "aws_ami" "missing_tag" {
  attrs = {
    id     = "ami-0missingtag00000000"
    tags   = {}
    filter = [{ name = "image-id", values = ["ami-0missingtag00000000"] }]
  }
}

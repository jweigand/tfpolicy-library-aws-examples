policytest {
  targets = ["../policies/ami.policy.hcl"]
}

inputs {
  ami_required_tags = { Approved = "true" }
}

# FAIL: AMI has the required tag key but the wrong value (Approved=false) —
# tag enforce block must fail.

resource "aws_launch_template" "wrong_tag_value" {
  expect_failure = true
  attrs = {
    image_id = "ami-0wrongtagvalue00000"
  }
}

data "aws_ami" "wrong_tag_value" {
  attrs = {
    id   = "ami-0wrongtagvalue00000"
    tags = {
      Approved = "false"
    }
    filter = [{ name = "image-id", values = ["ami-0wrongtagvalue00000"] }]
  }
}

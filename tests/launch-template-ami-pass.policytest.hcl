policytest {
  targets = ["../policies/ami.policy.hcl"]
}

inputs {
  ami_required_tags = { Approved = "true" }
}

# PASS: AMI carries all required tags (Approved=true) — tag check passes.

resource "aws_launch_template" "approved" {
  attrs = {
    image_id = "ami-0abcdef1234567890"
  }
}

data "aws_ami" "approved" {
  attrs = {
    id   = "ami-0abcdef1234567890"
    tags = {
      Approved = "true"
    }
    filter = [{ name = "image-id", values = ["ami-0abcdef1234567890"] }]
  }
}

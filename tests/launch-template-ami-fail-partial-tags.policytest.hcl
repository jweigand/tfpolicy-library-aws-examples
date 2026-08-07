policytest {
  targets = ["../policies/ami.policy.hcl"]
}

inputs {
  ami_required_tags = {
    Approved    = "true"
    Environment = "production"
    CostCenter  = "security"
  }
}

# FAIL: AMI has Approved=true but is missing Environment and CostCenter —
# the enforce block must fail and report both missing tags.

resource "aws_launch_template" "partial_tags" {
  expect_failure = true
  attrs = {
    image_id = "ami-0partialtags0000000"
  }
}

data "aws_ami" "partial_tags" {
  attrs = {
    id   = "ami-0partialtags0000000"
    tags = {
      Approved = "true"
    }
    filter = [{ name = "image-id", values = ["ami-0partialtags0000000"] }]
  }
}

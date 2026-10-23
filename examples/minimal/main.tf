terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
  }
}

module "this" {
  source = "../../"

  name = "example-github-actions"
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }

  # Set to false when the account already has a GitHub OIDC provider.
  create_provider = true

  repositories = {
    "olensys/example" = {
      environments        = ["test"]
      branches            = ["main"]
      allow_pull_requests = true
    }
  }
}

output "subjects" {
  description = "Subjects allowed to assume the role."
  value       = module.this.subjects
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
  }
}

module "this" {
  source = "../../"

  name = "olensys-test-oidc"
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "oidc"
    owner        = "platform"
    cost_center  = "eng"
  }

  # The shared test account already owns the single GitHub OIDC provider.
  create_provider = false

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

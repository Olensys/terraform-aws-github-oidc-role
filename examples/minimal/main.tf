terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0, < 7.0" }
  }
}

module "naming" {
  source = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.1"

  context = local.context
}

locals {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "oidc"
    owner        = "platform"
    cost_center  = "eng"
  }
}

module "this" {
  source = "../../"

  name    = module.naming.name
  context = local.context
  tags    = module.naming.tags

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

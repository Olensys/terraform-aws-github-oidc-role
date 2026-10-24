output "id" {
  description = "Name of the IAM role, which is also its identifier. Null when create is false."
  value       = var.create ? module.this.name : null
}

output "name" {
  description = "Name of the IAM role. Null when create is false."
  value       = var.create ? module.this.name : null
}

output "arn" {
  description = "ARN of the IAM role. Null when create is false."
  value       = var.create ? module.this.arn : null

  precondition {
    condition     = !var.create || length(local.subjects) > 0
    error_message = "A created role must trust at least one subject: repositories must contain at least one repository, otherwise the trust policy would have no sub condition and any GitHub Actions workflow could assume the role."
  }

  precondition {
    condition     = !var.create || length(jsonencode(local.subjects)) <= 1800
    error_message = "Too many repositories/branches for one role's trust policy (IAM limit 2048 characters); split across roles or narrow the list."
  }
}

output "provider_arn" {
  description = "ARN of the GitHub OIDC identity provider the role trusts: the one created here, or the account's existing one. Null when create is false."
  value       = var.create ? (var.create_provider ? module.provider.arn : local.existing_provider_arn) : null
}

output "provider_created" {
  description = "Whether this instance created the GitHub OIDC identity provider."
  value       = local.create_provider
}

output "subjects" {
  description = "OIDC subject patterns (sub) allowed to assume the role, in the form(s) selected by subject_format (immutable repo:OWNER@*/REPO@*, legacy repo:OWNER/REPO, or both) for every environment, branch and pull request entry. Null when create is false."
  value       = var.create ? local.subjects : null
}

output "tags" {
  description = "Tags applied to every taggable resource, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.tags : null
}

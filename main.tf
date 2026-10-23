data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  tags = merge(var.context.extra_tags, var.tags)

  github_provider = "token.actions.githubusercontent.com"

  # Exact-match subjects only; a bare `repo:<repo>:*` is never emitted.
  subjects = flatten([
    for repo, cfg in var.repositories : concat(
      [for env in cfg.environments : "repo:${repo}:environment:${env}"],
      [for branch in cfg.branches : "repo:${repo}:ref:refs/heads/${branch}"],
      cfg.allow_pull_requests ? ["repo:${repo}:pull_request"] : [],
    )
  ])

  create_provider = var.create && var.create_provider

  # Keyed by the ARN's resource part so the for_each keys stay stable and readable.
  policies = { for arn in var.policy_arns : replace(element(split(":", arn), length(split(":", arn)) - 1), "/[^A-Za-z0-9_-]/", "_") => arn }

  existing_provider_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.github_provider}"
}

module "provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"
  version = "6.8.2"

  create = local.create_provider
  url    = "https://${local.github_provider}"
  tags   = local.tags
}

module "this" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.2"

  create          = var.create
  name            = var.name
  use_name_prefix = false
  description     = "Assumable by GitHub Actions through OIDC for ${join(", ", sort(keys(var.repositories)))}."

  enable_github_oidc = true
  github_provider    = local.github_provider
  oidc_subjects      = local.subjects

  policies             = local.policies
  permissions_boundary = var.permissions_boundary_arn
  max_session_duration = var.max_session_duration_s

  tags = local.tags

  depends_on = [module.provider]
}

resource "aws_iam_role_policy" "inline" {
  count = var.create && var.policy_json != null ? 1 : 0

  name   = var.name
  role   = module.this.name
  policy = var.policy_json
}

data "aws_partition" "current" {
  count = var.create ? 1 : 0
}

data "aws_caller_identity" "current" {
  count = var.create ? 1 : 0
}

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

  # Keyed by position: keys must be known at plan even when an ARN is not, and cannot collide.
  policies = { for i, arn in var.policy_arns : format("policy-%02d", i) => arn }

  existing_provider_arn = "arn:${try(data.aws_partition.current[0].partition, "aws")}:iam::${try(data.aws_caller_identity.current[0].account_id, "")}:oidc-provider/${local.github_provider}"
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

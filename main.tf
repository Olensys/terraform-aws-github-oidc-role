data "aws_partition" "current" {
  count = var.create ? 1 : 0
}

data "aws_caller_identity" "current" {
  count = var.create ? 1 : 0
}

locals {
  tags = merge(var.context.extra_tags, var.tags)

  github_provider = "token.actions.githubusercontent.com"

  # subject_format selects the forms. GitHub issues either `repo:OWNER/REPO:...` or, with immutable subjects,
  # `repo:OWNER@OWNER_ID/REPO@REPO_ID:...`. Both forms are trusted. Wildcards
  # only stand in for the numeric IDs; owner, repository, branch and
  # environment names stay exact, and a bare `repo:<repo>:*` is never emitted.
  subjects = flatten([
    for repo, cfg in var.repositories : [
      for suffix in concat(
        [for env in cfg.environments : "environment:${env}"],
        [for branch in cfg.branches : "ref:refs/heads/${branch}"],
        cfg.allow_pull_requests ? ["pull_request"] : [],
        ) : [
        for s in concat(
          contains(["legacy", "both"], var.subject_format) ? ["repo:${repo}:${suffix}"] : [],
          contains(["immutable", "both"], var.subject_format) ? ["repo:${split("/", repo)[0]}@*/${split("/", repo)[1]}@*:${suffix}"] : [],
        ) : s
      ]
    ]
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
  description     = substr("Assumable by GitHub Actions through OIDC for ${join(", ", sort(keys(var.repositories)))}.", 0, 1000)

  enable_github_oidc = true
  github_provider    = local.github_provider
  # StringLike: the immutable form carries wildcards for the numeric IDs.
  oidc_wildcard_subjects = local.subjects

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

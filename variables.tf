variable "name" {
  description = "Resource name. Lowercase letters, digits and hyphens."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,64}$", var.name))
    error_message = "name must match ^[a-z0-9-]{1,64}$."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "create" {
  description = "Whether to create any resources. Set false to create nothing."
  type        = bool
  default     = true
}

variable "create_provider" {
  description = "Create the account's GitHub OIDC identity provider (token.actions.githubusercontent.com). An account can hold only one, so enable this in exactly one module instance per account."
  type        = bool
  default     = false
}

variable "repositories" {
  description = "Repositories (keyed as owner/repo) allowed to assume the role, each with the environments, branches and pull requests that may do so."
  type = map(object({
    environments        = optional(list(string), [])
    branches            = optional(list(string), [])
    allow_pull_requests = optional(bool, false)
  }))
  validation {
    condition     = alltrue([for repo in keys(var.repositories) : can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", repo))])
    error_message = "Each repositories key must be in the form owner/repo, using letters, digits, underscore, dot and hyphen."
  }
  validation {
    condition = alltrue([
      for cfg in values(var.repositories) :
      length(cfg.environments) > 0 || length(cfg.branches) > 0 || cfg.allow_pull_requests
    ])
    error_message = "Each repository must declare at least one environment, at least one branch, or allow_pull_requests = true."
  }
  validation {
    condition = alltrue(flatten([
      for cfg in values(var.repositories) : [
        for e in concat(cfg.environments, cfg.branches) : length(e) > 0 && !strcontains(e, "*")
      ]
    ]))
    error_message = "Environment and branch names must be non-empty and must not contain a wildcard (*)."
  }
}

variable "policy_arns" {
  description = "ARNs of managed policies attached to the role."
  type        = list(string)
  default     = []
}

variable "policy_json" {
  description = "Inline policy document (JSON) attached to the role. Null attaches none."
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "ARN of the permissions boundary policy for the role. Null sets none."
  type        = string
  default     = null
}

variable "max_session_duration_s" {
  description = "Maximum session duration in seconds, 3600 to 43200."
  type        = number
  default     = 3600
  validation {
    condition     = var.max_session_duration_s >= 3600 && var.max_session_duration_s <= 43200
    error_message = "max_session_duration_s must be between 3600 and 43200."
  }
}

variable "tags" {
  description = "Tags merged onto every taggable resource, applied last."
  type        = map(string)
  default     = {}
}

variable "subject_format" {
  description = "Which sub claim form the trust policy accepts: immutable (repo:<owner>@*/<repo>@*:...), legacy (repo:<owner>/<repo>:...) or both. Both is the default and doubles the policy size; use immutable when the repositories have use_immutable_subject enabled, legacy when they do not."
  type        = string
  default     = "both"
  validation {
    condition     = contains(["immutable", "legacy", "both"], var.subject_format)
    error_message = "subject_format must be one of immutable, legacy, both."
  }
}

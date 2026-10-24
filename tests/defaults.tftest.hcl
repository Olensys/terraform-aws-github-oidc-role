mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

mock_provider "tls" {}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name = "example"
  repositories = {
    "olensys/app" = { environments = ["prod", "staging"] }
  }
}

run "test_subjects_from_environments" {
  command = plan

  variables {
    repositories = {
      "olensys/app" = { environments = ["prod", "staging"], branches = ["main"] }
    }
  }

  assert {
    condition = toset(output.subjects) == toset([
      "repo:olensys/app:environment:prod", "repo:olensys@*/app@*:environment:prod",
      "repo:olensys/app:environment:staging", "repo:olensys@*/app@*:environment:staging",
      "repo:olensys/app:ref:refs/heads/main", "repo:olensys@*/app@*:ref:refs/heads/main",
    ])
    error_message = "subjects must list the legacy and the immutable form for every environment and branch."
  }

  assert {
    condition     = alltrue([for s in output.subjects : startswith(s, "repo:olensys/app:") || startswith(s, "repo:olensys@*/app@*:")])
    error_message = "Wildcards must only replace the owner and repository IDs; the names stay exact."
  }
}

run "test_pull_request_subject_only_when_allowed" {
  command = plan

  variables {
    repositories = {
      "olensys/open" = { branches = ["main"], allow_pull_requests = true }
      "olensys/shut" = { branches = ["main"] }
    }
  }

  assert {
    condition     = contains(output.subjects, "repo:olensys/open:pull_request") && contains(output.subjects, "repo:olensys@*/open@*:pull_request")
    error_message = "pull_request subjects (both forms) must be present when allow_pull_requests is true."
  }

  assert {
    condition     = !contains(output.subjects, "repo:olensys/shut:pull_request") && !contains(output.subjects, "repo:olensys@*/shut@*:pull_request")
    error_message = "pull_request subjects must be absent by default."
  }
}

run "test_provider_not_created_by_default" {
  command = plan

  assert {
    condition     = output.provider_created == false
    error_message = "The OIDC provider must not be created unless create_provider is true."
  }

  assert {
    condition     = endswith(output.provider_arn, ":oidc-provider/token.actions.githubusercontent.com")
    error_message = "provider_arn must reference the account's existing provider."
  }
}

run "test_provider_created_when_requested" {
  command = plan

  variables {
    create_provider = true
  }

  assert {
    condition     = output.provider_created == true
    error_message = "provider_created must be true when create_provider is true."
  }
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create          = false
    create_provider = true
    policy_json     = "{}"
  }

  assert {
    condition     = output.id == null && output.name == null && output.arn == null && output.provider_arn == null && output.subjects == null && output.tags == null
    error_message = "All outputs must be null when create is false."
  }

  assert {
    condition     = output.provider_created == false
    error_message = "provider_created must be false when create is false."
  }

  assert {
    condition     = length(aws_iam_role_policy.inline) == 0
    error_message = "No inline policy may be planned when create is false."
  }
}

run "test_repository_format_validation" {
  command = plan

  variables {
    repositories = { "not-a-repo" = { branches = ["main"] } }
  }

  expect_failures = [var.repositories]
}

run "test_repository_needs_a_subject" {
  command = plan

  variables {
    repositories = { "olensys/app" = {} }
  }

  expect_failures = [var.repositories]
}

run "test_session_duration_validation" {
  command = plan

  variables {
    max_session_duration_s = 100
  }

  expect_failures = [var.max_session_duration_s]
}

run "test_inline_policy_when_json" {
  command = plan

  variables {
    policy_json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }

  assert {
    condition     = length(aws_iam_role_policy.inline) == 1
    error_message = "An inline policy must be planned when policy_json is set."
  }
}

run "test_no_inline_policy_by_default" {
  command = plan

  assert {
    condition     = length(aws_iam_role_policy.inline) == 0
    error_message = "No inline policy without policy_json."
  }
}

run "test_create_false_outputs_null" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = output.id == null
    error_message = "id must be null when create is false."
  }
}

run "test_name_validation_rejects_uppercase" {
  command = plan

  variables {
    name = "Bad-Name"
  }

  expect_failures = [var.name]
}

run "test_tags_contract" {
  command = plan

  variables {
    tags = { Owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { Owner = "y", Team = "z" }
    }
  }

  assert {
    condition     = output.tags.Owner == "x"
    error_message = "var.tags must win over context.extra_tags."
  }

  assert {
    condition     = output.tags.Team == "z"
    error_message = "context.extra_tags must be merged in."
  }
}

run "test_empty_repositories_rejected" {
  command = plan

  variables {
    repositories = {}
  }

  expect_failures = [output.arn]
}

run "test_empty_repositories_allowed_when_not_creating" {
  command = plan

  variables {
    create       = false
    repositories = {}
  }

  assert {
    condition     = output.arn == null
    error_message = "create = false must accept an empty repositories map."
  }
}

run "test_wildcard_branch_rejected" {
  command = plan

  variables {
    repositories = { "olensys/app" = { branches = ["release/*"] } }
  }

  expect_failures = [var.repositories]
}

run "test_policy_arns_with_same_last_segment" {
  command = plan

  variables {
    policy_arns = ["arn:aws:iam::111111111111:policy/shared/readonly", "arn:aws:iam::222222222222:policy/other/readonly"]
  }

  assert {
    condition     = output.name == "example"
    error_message = "Two policy ARNs with the same last segment must not collide."
  }
}

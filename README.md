# terraform-aws-github-oidc-role

IAM role assumable by GitHub Actions through OIDC, scoped to named repositories, environments and branches

## Opinions

- One GitHub OIDC provider per account: create it once with `create_provider = true` in a single instance; every other instance leaves it `false` and trusts the account's existing provider.
- No wildcard subjects. Subjects are built as `repo:<repo>:environment:<env>` and `repo:<repo>:ref:refs/heads/<branch>`; a repository with no environment, branch or pull-request entry is rejected rather than trusted broadly.
- Pull request runs (`repo:<repo>:pull_request`) are trusted only when `allow_pull_requests = true` for that repository.
- Permissions come from managed policy ARNs (`policy_arns`) and, optionally, one inline policy (`policy_json`) named after the role. Prefer managed ARNs for shared permissions and the inline policy for permissions specific to this role.
- The role name is exactly `name` (no generated suffix), and `max_session_duration_s` defaults to 3600 seconds (1 hour).
- The trust policy requires audience `sts.amazonaws.com` and issuer `token.actions.githubusercontent.com`.

## Usage

```hcl
module "this" {
  source = "git::https://github.com/Olensys/terraform-aws-github-oidc-role.git?ref=v1.0.0"

  name = "example"
  context = {
    organization = "olensys"
    environment  = "dev"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }

  repositories = {
    "olensys/app" = { environments = ["prod"], branches = ["main"] }
  }
}
```

The upstream `iam-github-oidc-*` submodules do not exist in `terraform-aws-modules/iam/aws` 6.8.2; the module wraps `modules/iam-oidc-provider` and `modules/iam-role` (with `enable_github_oidc`) instead. The OIDC provider submodule reads the endpoint certificate through the `tls` provider, which Terraform installs automatically when `create_provider = true`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.70.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_provider"></a> [provider](#module\_provider) | terraform-aws-modules/iam/aws//modules/iam-oidc-provider | 6.8.2 |
| <a name="module_this"></a> [this](#module\_this) | terraform-aws-modules/iam/aws//modules/iam-role | 6.8.2 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role_policy.inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Resource name. Lowercase letters, digits and hyphens. | `string` | n/a | yes |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Repositories (keyed as owner/repo) allowed to assume the role, each with the environments, branches and pull requests that may do so. | <pre>map(object({<br/>    environments        = optional(list(string), [])<br/>    branches            = optional(list(string), [])<br/>    allow_pull_requests = optional(bool, false)<br/>  }))</pre> | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to create nothing. | `bool` | `true` | no |
| <a name="input_create_provider"></a> [create\_provider](#input\_create\_provider) | Create the account's GitHub OIDC identity provider (token.actions.githubusercontent.com). An account can hold only one, so enable this in exactly one module instance per account. | `bool` | `false` | no |
| <a name="input_max_session_duration_s"></a> [max\_session\_duration\_s](#input\_max\_session\_duration\_s) | Maximum session duration in seconds, 3600 to 43200. | `number` | `3600` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | ARN of the permissions boundary policy for the role. Null sets none. | `string` | `null` | no |
| <a name="input_policy_arns"></a> [policy\_arns](#input\_policy\_arns) | ARNs of managed policies attached to the role. | `list(string)` | `[]` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | Inline policy document (JSON) attached to the role. Null attaches none. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged onto every taggable resource, applied last. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the IAM role. Null when create is false. |
| <a name="output_id"></a> [id](#output\_id) | Name of the IAM role, which is also its identifier. Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Name of the IAM role. Null when create is false. |
| <a name="output_provider_arn"></a> [provider\_arn](#output\_provider\_arn) | ARN of the GitHub OIDC identity provider the role trusts: the one created here, or the account's existing one. Null when create is false. |
| <a name="output_provider_created"></a> [provider\_created](#output\_provider\_created) | Whether this instance created the GitHub OIDC identity provider. |
| <a name="output_subjects"></a> [subjects](#output\_subjects) | OIDC subject claims (sub) allowed to assume the role. Null when create is false. |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to every taggable resource, with context.extra\_tags merged in. Null when create is false. |
<!-- END_TF_DOCS -->

# Changelog

## [1.0.4](https://github.com/Olensys/terraform-aws-github-oidc-role/compare/v1.0.3...v1.0.4) (2026-10-24)


### Bug Fixes

* accept immutable OIDC subjects in the trust policy ([#2](https://github.com/Olensys/terraform-aws-github-oidc-role/issues/2)) ([86f9e3e](https://github.com/Olensys/terraform-aws-github-oidc-role/commit/86f9e3e258e4db85d264ac4e2edb5e0e01875e9a))
* **examples:** reuse the account's existing OIDC provider ([676f608](https://github.com/Olensys/terraform-aws-github-oidc-role/commit/676f6083bc53d1fcdca07e5c11ecf4fbbc75d227))
* **examples:** unique application slug so concurrent integration runs do not collide ([#5](https://github.com/Olensys/terraform-aws-github-oidc-role/issues/5)) ([676f608](https://github.com/Olensys/terraform-aws-github-oidc-role/commit/676f6083bc53d1fcdca07e5c11ecf4fbbc75d227))
* subject_format input and trust-policy size guard ([#4](https://github.com/Olensys/terraform-aws-github-oidc-role/issues/4)) ([c15375e](https://github.com/Olensys/terraform-aws-github-oidc-role/commit/c15375e64d56228da08f5fc3a13aa8242009b85a))

## [1.0.3](https://github.com/Olensys/terraform-aws-github-oidc-role/compare/v1.0.2...v1.0.3) (2026-10-24)


### Bug Fixes

* run integration on change and weekly instead of nightly ([dd5565d](https://github.com/Olensys/terraform-aws-github-oidc-role/commit/dd5565d9b6ee4a3bbae19c9811c998b144b71ae9))

## 1.0.2

### Fixes

- `metadata.yaml` `upstream` now lists both pinned upstream modules (`iam-role` and `iam-oidc-provider`, 6.8.2), formatted like the other multi-upstream modules (joined with ` + `).

### Docs

- README Usage shows the naming module.

## 1.0.1

### Fixes

- render declared provider constraints and skip .terraform in trivy scans

## 1.0.0

- IAM role assumable by GitHub Actions through OIDC, trusting exact subjects built from named repositories, environments and branches; pull request subjects are opt-in.
- Optional creation of the account GitHub OIDC provider, managed policy ARNs, an inline policy, a permissions boundary and a session duration.

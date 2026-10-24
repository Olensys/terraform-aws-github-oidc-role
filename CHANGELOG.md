# Changelog

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

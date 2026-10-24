# Run only by the nightly integration workflow, against real cloud credentials.
# Applies the example, which reuses the account's existing GitHub OIDC provider
# (create_provider = false), so the target account must already have one.
run "apply_minimal" {
  command = apply

  module {
    source = "./examples/minimal"
  }

  assert {
    condition     = contains(output.subjects, "repo:olensys/example:environment:test")
    error_message = "The environment subject must be in the trust policy."
  }

  assert {
    condition     = alltrue([for s in output.subjects : !strcontains(s, "*")])
    error_message = "No wildcard subject may be emitted."
  }
}

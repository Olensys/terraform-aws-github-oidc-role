# Run only by the nightly integration workflow, against real cloud credentials.
# Applies the example, which also creates the account's GitHub OIDC provider, so the
# target account must not already have one.
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
    condition     = contains(output.subjects, "repo:olensys@*/example@*:environment:test")
    error_message = "The immutable environment subject must be in the trust policy under the default subject_format."
  }
}

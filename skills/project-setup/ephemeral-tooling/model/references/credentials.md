# Credentials in the ephemeral model

Every migration hits this. Decision per credential, cheapest first:

- Host system keyring (e.g. a gh token): unreachable from containers.
  Red: gh-authenticated push steps broke silently after migration
  because the container could not read the keyring. The model default
  applies: pushes and credentials tooling stay host-side. The
  alternative is moving the credential to a file, an explicit security
  decision, never a silent step.
- Credential as a file: bind-mount read-only. Single-consumer mount,
  so it takes `:Z` (private label), not `:z`. Repo-agnostic tool config
  pointing at the mounted path belongs in the Containerfile.
- Never baked into the image: images get pushed or shared, tokens do
  not.

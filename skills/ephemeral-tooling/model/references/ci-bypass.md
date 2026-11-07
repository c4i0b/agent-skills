# Variant: CI parity via the DIRECT bypass

CI runners install their own toolchain and cannot assume podman compose.
Give the justfile a direct-execution escape hatch:

```just
runner := `[ "${PROJECT_DIRECT:-}" = 1 ] || printf 'podman compose run --rm tooling'`
```

- CI sets `PROJECT_DIRECT=1` and installs the same packages the
  Containerfile bakes (keep the two lists in sync manually; the Containerfile
  is the source of truth).
- Every recipe works identically both ways because the runner prefix is the
  only difference.
- Scripts invoked by recipes must not assume container-only paths when
  running direct: keep them environment-agnostic (no `/app` literals except
  where the compose working_dir provides them in both modes — and prefer
  deriving paths from the script location instead).

Validated example: `/home/caio/Projects/fedora-packages`
(`FEDORA_PACKAGES_DIRECT=1` in `.github/workflows/validate.yml`).

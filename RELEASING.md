# Releasing Pan Out

## Pre-release checklist

1. **Changelog** — `CHANGELOG.md` has an `[Unreleased]` section with all changes since last release
2. **Docs site** — any new skills or changed behavior reflected in `docs/`
3. **README** — install instructions and feature list still accurate

## Release steps

Given a version `X.Y.Z`:

### 1. Finalize the changelog

In `CHANGELOG.md`, rename `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD` and add a fresh empty `[Unreleased]` section above it.

### 2. Bump version in plugin manifests

Two files, three values:

| File | Field | Value |
|------|-------|-------|
| `.claude-plugin/plugin.json` | `version` | `X.Y.Z` |
| `.claude-plugin/marketplace.json` | `version` | `X.Y.Z` |
| `.claude-plugin/marketplace.json` | `source.ref` | `vX.Y.Z` |

### 3. Commit

```bash
git add CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "release: vX.Y.Z"
```

### 4. Tag

```bash
git tag vX.Y.Z
```

### 5. Push

```bash
git push origin main && git push origin vX.Y.Z
```

### 6. GitHub release

```bash
gh release create vX.Y.Z --title "vX.Y.Z" --notes-file - <<< "$(changelog section for this version)"
```

Or create it in the GitHub UI using the tag, pasting the changelog section as the body.

## Version scheme

[Semver](https://semver.org/). While pre-1.0, minor bumps can include breaking changes to protocol format or skill behavior.

# SH-01 Release gates: pinned Actions, security policy, release checklist

DATE: 2026-10-21
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
FINDINGS: F05, F06, and the checklist line of F10
DEPENDS ON: nothing
ONE PR: yes

## Scope

Make the repository's release posture explicit before public distribution: CI runs only
commit-pinned actions, a reporter has a private route, and the release procedure says what to
check on the build machine. No shipping code changes.

## Verified at the baseline

- `.github/workflows/ci.yml` uses `actions/checkout@v4`, `ruby/setup-ruby@v1`,
  `pnpm/action-setup@v4`, `actions/setup-node@v4`, `astral-sh/setup-uv@v5`. Triggers are
  `pull_request` and `push` to `main`; no secrets; the job installs and runs `make ci`.
- No `.github/dependabot.yml`.
- No `SECURITY.md`. `.github/ISSUE_TEMPLATE/config.yml` has `blank_issues_enabled: true` and one
  contact link to `docs/HELP.md`.
- `gh api repos/bldgtyp/ph-composer/private-vulnerability-reporting` answered `{"enabled":false}`
  on 2026-10-21.
- `docs/DEVELOPMENT.md` "Answering a support report" ends with the one release sentence: publishing
  updates "Current release" in `docs/HELP.md`. "Driving SketchUp from a terminal" explains
  `make bridge-install` and `make bridge-uninstall`.

## Steps

### 1. Pin the actions

For each `uses:` line, resolve the newest release tag under the same major and its commit, and
write `owner/repo@<40-hex> # vX.Y.Z`. Annotated tags need one more hop:

```bash
tag=$(gh api repos/actions/checkout/releases/latest --jq .tag_name)
sha=$(gh api "repos/actions/checkout/git/ref/tags/$tag" --jq .object.sha)
type=$(gh api "repos/actions/checkout/git/ref/tags/$tag" --jq .object.type)
[ "$type" = "tag" ] && sha=$(gh api "repos/actions/checkout/git/tags/$sha" --jq .object.sha)
echo "$tag $sha"
```

Keep the existing comments in the workflow. If the newest release under a major changed an input
name (check the action's release notes for `with:` keys the workflow uses: `ruby-version`,
`bundler-cache`, `version`, `node-version`, `cache`, `enable-cache`), stay on the tag the workflow
used and say so in the PR.

### 2. Dependabot for the actions

Add `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "ci"
```

Only `github-actions`. npm already has a minimum release age in `.npmrc`; Python is pinned by
`uv.lock` and the runtime manifest, and a bump there is a runtime decision, not a bot's.

### 3. `SECURITY.md`

At the repository root, in the client-facing register (`docs/` rules apply: no em dashes, no
partnership or licensing posture). Sections:

- **Reporting a vulnerability.** Use GitHub's private vulnerability reporting at
  `https://github.com/bldgtyp/ph-composer/security/advisories/new`. Do not open a public issue for
  a security problem. What to include: the build (from Help & Diagnostics), SketchUp version and
  platform, steps, and whether an agent token or a library file is involved. Never attach a client
  Model.
- **What is in scope.** The shipped extension (the RBZ): the panel and dialogs, the loopback agent
  listener, the export runtime, file reads and writes through approved locations. The development
  tooling under `tools/` never ships and is out of scope.
- **Supported versions.** Until the first release: `main`. After it: the latest release.
- **What to expect.** An acknowledgement within a stated window (Ed's choice; suggest seven days)
  and a fix or a documented decision in the next release.

If Ed names an email route as well, add it; the default is GitHub only.

### 4. Issue template config

Add a second contact link in `.github/ISSUE_TEMPLATE/config.yml`:

```yaml
  - name: Report a security problem privately
    url: https://github.com/bldgtyp/ph-composer/security/advisories/new
    about: Use this instead of a public issue for anything that could affect other users.
```

### 5. Enable private vulnerability reporting

Needs repository admin. Leave this in the PR description for Ed:

```bash
gh api -X PUT repos/bldgtyp/ph-composer/private-vulnerability-reporting
gh api repos/bldgtyp/ph-composer/private-vulnerability-reporting
```

The second line must answer `{"enabled":true}` (SH-01-A4).

### 6. Pre-release checklist

In `docs/DEVELOPMENT.md`, turn the "Publishing a release" sentence into a short checklist:

1. `make bridge-uninstall` on the machine that builds the release candidate, then a fresh
   SketchUp launch to confirm no `ph_composer_host_bridge.json` reappears.
2. `make ci` and `make rbz-check` green on the release commit; `build.json` records a commit
   without `-dirty`.
3. "Current release" updated in `docs/HELP.md`, then `make help`.
4. `SECURITY.md` supported versions line updated.
5. The actions in `.github/workflows/ci.yml` are commit-pinned (CI itself does not check this;
   Dependabot keeps them current).

## Tests and gate

No new tests. `make ci` must pass; the `lint-citations` target excludes root files, so
`SECURITY.md` and `.github/` are free to say "release". Check `make lint-citations` anyway, since
the stage touches `docs/DEVELOPMENT.md`.

## Acceptance

SH-01-A1 to SH-01-A5 in [ACCEPTANCE.md](../ACCEPTANCE.md).

## Decisions

| Decision | Who |
| --- | --- |
| Action versions and SHAs | Agent |
| Contact route beyond GitHub, acknowledgement window | Ed |
| Enabling private reporting | Ed, after merge or before, either order |

## Out of scope

Pinning the Playwright, Chrome or Pyodide downloads differently: already by exact version and, for
Pyodide and the wheels, by SHA-256.

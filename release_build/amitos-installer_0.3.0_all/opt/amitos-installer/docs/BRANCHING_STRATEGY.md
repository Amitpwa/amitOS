# Branching Strategy

This document defines the **Git branching model** for amitOS and the corresponding **branch protection rules** to configure on GitHub.

---

## Branch Model

amitOS uses a simplified **Gitflow-inspired** branching strategy optimized for an open-source OS project.

```
main / production (stable releases)
        ▲
        │  merge via PR (squash or merge commit)
        │
       dev (integration branch — always working)
        ▲
        │  merge via PR (squash)
        │
  feature/* / fix/* / docs/* / chore/*  (short-lived branches)
```

---

## Branch Definitions

### `production` — Stable Release Branch

- **Purpose**: The official, stable release of amitOS. Always deployable.
- **Who merges**: Only project maintainers via PR from `dev`
- **Protection rules**: See below
- **Tags**: Every merge creates a version tag (e.g., `v0.2.0`)

### `dev` — Integration Branch

- **Purpose**: Ongoing development integration. All feature branches merge here first.
- **Who merges**: Maintainers (after PR review)
- **Stability**: Must be passing CI at all times
- **Protection rules**: See below

### `feature/*` — Feature Branches

- **Purpose**: New features or significant enhancements
- **Naming**: `feature/<short-kebab-description>` (e.g., `feature/opcua-session-pooling`)
- **Branched from**: `dev`
- **Merges into**: `dev`
- **Lifetime**: Short-lived — delete after merge

### `fix/*` — Bug Fix Branches

- **Purpose**: Bug fixes for issues in `dev`
- **Naming**: `fix/<issue-id>-short-desc` (e.g., `fix/42-modbus-timeout`)
- **Branched from**: `dev`
- **Merges into**: `dev`

### `hotfix/*` — Emergency Hotfix Branches

- **Purpose**: Critical production bugs that cannot wait for the next normal release
- **Naming**: `hotfix/<short-desc>` (e.g., `hotfix/opcua-crash-on-reconnect`)
- **Branched from**: `production`
- **Merges into**: `production` AND `dev`

### `docs/*` — Documentation-Only Branches

- **Purpose**: Documentation improvements with no code changes
- **Naming**: `docs/<topic>` (e.g., `docs/adapter-guide-update`)
- **Branched from**: `dev`
- **Merges into**: `dev`

### `release/*` — Release Preparation Branches

- **Purpose**: Version bumps, changelog updates, final testing before releasing
- **Naming**: `release/<version>` (e.g., `release/v0.3.0`)
- **Branched from**: `dev`
- **Merges into**: `production` AND `dev`

### `chore/*` — Maintenance Branches

- **Purpose**: Tooling updates, dependency upgrades, CI changes
- **Naming**: `chore/<desc>` (e.g., `chore/upgrade-python-deps`)
- **Branched from**: `dev`
- **Merges into**: `dev`

---

## Branch Naming Rules

| Rule | Detail |
|---|---|
| Use kebab-case | `feature/my-feature` ✅ — `feature/my_feature` ❌ |
| Keep short | ≤ 50 characters total |
| Use the right prefix | `feature/`, `fix/`, `hotfix/`, `docs/`, `release/`, `chore/` |
| Reference issue IDs | `fix/123-opcua-timeout` when linked to an issue |
| No personal names | Use descriptive task names, not contributor names |

---

## GitHub Branch Protection Rules

Configure the following in **GitHub → Settings → Branches → Branch protection rules**.

### `production` Branch Rules

| Rule | Setting |
|---|---|
| Require pull request before merging | ✅ Enabled |
| Required approving reviews | **2 reviewers** |
| Dismiss stale PR approvals on new commits | ✅ Enabled |
| Require review from Code Owners | ✅ Enabled |
| Require status checks to pass | ✅ Enabled (CI pipeline) |
| Require branches to be up to date | ✅ Enabled |
| Restrict pushes | ✅ Maintainers only |
| Allow force pushes | ❌ Disabled |
| Allow deletions | ❌ Disabled |

### `dev` Branch Rules

| Rule | Setting |
|---|---|
| Require pull request before merging | ✅ Enabled |
| Required approving reviews | **1 reviewer** |
| Dismiss stale PR approvals on new commits | ✅ Enabled |
| Require status checks to pass | ✅ Enabled |
| Require branches to be up to date | ✅ Enabled |
| Allow force pushes | ❌ Disabled |
| Allow deletions | ❌ Disabled |

---

## Merge Strategy

| Target Branch | Merge Strategy | Reason |
|---|---|---|
| `dev` ← `feature/*` | **Squash and merge** | Clean, linear history |
| `dev` ← `fix/*` | **Squash and merge** | Clean, linear history |
| `dev` ← `docs/*` | **Squash and merge** | Single commit per doc update |
| `production` ← `release/*` | **Merge commit** | Preserve release history |
| `production` ← `hotfix/*` | **Merge commit** | Traceable emergency fix |
| `dev` ← `hotfix/*` | **Merge commit** | Keep hotfix in dev history |

---

## Tagging & Releases

- Tags are applied to `production` after each merge
- Use **annotated tags**: `git tag -a v0.2.0 -m "Release v0.2.0 — AI & GPU Runtime"`
- Tags follow [Semantic Versioning](https://semver.org/): `vMAJOR.MINOR.PATCH`
- Create a GitHub Release for each tag with CHANGELOG excerpt

---

## Diagram

```
production ────────────────────────────────────── v0.1.0 ──── v0.2.0
                                                      ▲           ▲
                                                      │           │
dev ──────────────────────────────────────────────────────────────────►
         ▲    │    ▲    │    ▲    │
         │    │    │    │    │    │
  feature/A ──┘  fix/B ──┘  docs/C ──┘
```

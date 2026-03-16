# Pull Request Rules

This document defines the **PR policy and merge governance** for amitOS. All contributors and maintainers must follow these rules.

---

## Core Principles

1. **No direct pushes** to `production` or `dev` — everything goes through a PR
2. **Small, focused PRs** — one concern per PR, easier to review and revert
3. **CI must pass** — all automated checks must be green before review begins
4. **Linked issues** — PRs must reference the issue they address
5. **Descriptive PRs** — fully filled PR template is required

---

## PR Checklist (Required Before Requesting Review)

Before marking a PR as "Ready for Review", confirm the following:

- [ ] PR title follows Conventional Commits format: `feat(scope): summary`
- [ ] PR description is fully filled (using the [PR template](.github/PULL_REQUEST_TEMPLATE.md))
- [ ] Linked to a GitHub Issue (`Closes #<id>` or `Fixes #<id>`)
- [ ] Branched from `dev` (not `production`)
- [ ] All CI checks pass
- [ ] Code follows the [style guidelines](../CONTRIBUTING.md#code-style-guidelines)
- [ ] No unrelated changes included
- [ ] Documentation updated if behavior changed
- [ ] CHANGELOG.md updated under `[Unreleased]` section

---

## PR Size Guidelines

| Size | Lines Changed | Policy |
|---|---|---|
| **Ideal** | < 200 lines | Preferred — fast review |
| **Acceptable** | 200–400 lines | Acceptable with good description |
| **Large** | 400–800 lines | Requires justification in PR description |
| **Too Large** | > 800 lines | Must be split into smaller PRs |

> **Why?** Research shows that reviewers become less effective after 400 lines. Small PRs = better reviews = fewer bugs.

---

## Review Requirements

### Merging into `dev`

| Requirement | Detail |
|---|---|
| **Approvals required** | 1 maintainer approval |
| **CI checks** | All must pass |
| **Stale approval policy** | Approval dismissed if new commits are pushed after review |
| **Draft PRs** | Cannot be merged while in draft state |

### Merging into `production`

| Requirement | Detail |
|---|---|
| **Approvals required** | 2 maintainer approvals (including 1 Code Owner) |
| **CI checks** | All must pass |
| **Branch up-to-date** | Must be up-to-date with `production` |
| **Stale approval policy** | All approvals dismissed if new commits are pushed |
| **Who can merge** | Maintainers only |

---

## Draft PRs

Use **Draft PRs** to:
- Share work-in-progress for early feedback
- Block accidental merging while still in development
- Signal that the PR is not yet ready for formal review

```
# Convert to draft when creating
gh pr create --draft

# Mark ready for review when done
gh pr ready
```

Draft PRs **cannot be merged** until converted to "Ready for Review."

---

## Force Push Policy

| Branch | Force Push Allowed? |
|---|---|
| `production` | ❌ Never |
| `dev` | ❌ Never |
| `feature/*` | ✅ Allowed on your own branch |
| `fix/*` | ✅ Allowed on your own branch |

> On shared/protected branches, force pushes permanently rewrite history and break collaborators' local copies.

---

## Merge Strategy

| From → To | Strategy | Reason |
|---|---|---|
| `feature/*` → `dev` | Squash and Merge | Clean, linear dev history |
| `fix/*` → `dev` | Squash and Merge | One commit per fix |
| `docs/*` → `dev` | Squash and Merge | Single doc update commit |
| `release/*` → `production` | Merge Commit | Preserve full release history |
| `hotfix/*` → `production` | Merge Commit | Traceable emergency fix |
| `hotfix/*` → `dev` | Merge Commit | Keep hotfix visible in dev |

---

## PR Title Format

PR titles must follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary in imperative mood>
```

**Examples:**

```
feat(adapters): add EtherNet/IP adapter
fix(opcua): resolve session timeout on reconnect
docs(networking): add VLAN configuration guide
chore(ci): add shellcheck to GitHub Actions
```

---

## PR Review Etiquette

### For Authors
- Respond to all review comments within **5 business days**
- Mark resolved comments as "Resolved" after addressing them
- Don't resolve reviewer's comments — let the reviewer do it
- Be open to feedback — code quality matters

### For Reviewers
- Review within **3 business days** of being assigned
- Use [Conventional Comments](https://conventionalcomments.org/) for structured feedback
- Distinguish blocking (`blocking:`) from non-blocking (`nit:`) comments
- Approve only when you are genuinely satisfied

---

## Stale PR Policy

| Age | Action |
|---|---|
| 14 days with no activity | Labeled `stale` |
| 21 days with no activity | Labeled `needs-author-action` and pinged |
| 30 days with no activity | Closed with a comment (can be reopened) |

---

## Hotfix PRs

Hotfixes follow a special fast-track process:

1. Branch from `production`: `git checkout -b hotfix/critical-bug production`
2. Fix the bug and commit
3. Open PR targeting **`production`** AND **`dev`** (two separate PRs or a merge into both)
4. Requires 1 maintainer approval (expedited)
5. After merge, tag the new patch version on `production`

---

## Questions?

- 💬 Ask in [Discussions](https://github.com/Amitpwa/amitOS/discussions)
- 📧 Email: ashutoshpandeyies@gmail.com

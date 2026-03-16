# Contributing to amitOS

Thank you for your interest in contributing to **amitOS**! 🎉  
Whether you're fixing a bug, adding an adapter, improving documentation, or suggesting a feature — every contribution matters.

---

## 📋 Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How to Contribute](#how-to-contribute)
3. [Setting Up Your Development Environment](#setting-up-your-development-environment)
4. [Branch Naming Conventions](#branch-naming-conventions)
5. [Commit Message Format](#commit-message-format)
6. [Pull Request Process](#pull-request-process)
7. [Code Style Guidelines](#code-style-guidelines)
8. [Reporting Bugs](#reporting-bugs)
9. [Requesting Features](#requesting-features)

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).  
By participating, you agree to uphold these standards. Please report any unacceptable behavior to **ashutoshpandeyies@gmail.com**.

---

## How to Contribute

### 1. Fork & Clone

```bash
# Fork the repo on GitHub, then clone your fork
git clone https://github.com/<your-username>/amitOS.git
cd amitOS

# Add the upstream remote
git remote add upstream https://github.com/Amitpwa/amitOS.git
```

### 2. Create a Branch

Always branch off from `dev` (never `production`):

```bash
git checkout dev
git pull upstream dev

# Create your feature/fix branch
git checkout -b feature/opcua-session-pooling
```

See [Branch Naming Conventions](#branch-naming-conventions) below.

### 3. Make Your Changes

- Keep changes focused — one feature or fix per PR
- Write or update relevant documentation
- Test your changes on the target hardware or a VM if possible

### 4. Commit Your Changes

Follow [Conventional Commits](#commit-message-format):

```bash
git add .
git commit -m "feat(adapters): add OPC UA session pooling"
```

### 5. Push & Open a PR

```bash
git push origin feature/opcua-session-pooling
```

Then open a Pull Request on GitHub targeting the **`dev`** branch.  
Fill in the [PR template](.github/PULL_REQUEST_TEMPLATE.md) completely.

---

## Setting Up Your Development Environment

### Prerequisites

- Linux (Debian 11+) or a Debian VM
- Git ≥ 2.35
- Bash ≥ 5.1
- Python ≥ 3.10 *(for AI/adapter development)*
- Docker *(optional, for containerized testing)*

### Initial Setup

```bash
# Install system dependencies (Debian/Ubuntu)
sudo apt-get update
sudo apt-get install -y git curl python3 python3-pip

# Clone and explore
git clone https://github.com/Amitpwa/amitOS.git
cd amitOS
```

### Testing Your Changes

```bash
# Run shell script linter
shellcheck scripts/*.sh

# Run Python linter (if modifying Python components)
pip install flake8
flake8 adapters/ --max-line-length=120
```

---

## Branch Naming Conventions

| Branch Type | Pattern | Example |
|---|---|---|
| Feature | `feature/<short-desc>` | `feature/mqtt-tls-support` |
| Bug fix | `fix/<issue-id>-short-desc` | `fix/123-opcua-crash` |
| Documentation | `docs/<topic>` | `docs/adapter-guide` |
| Hotfix | `hotfix/<short-desc>` | `hotfix/security-patch` |
| Release | `release/<version>` | `release/v0.2.0` |
| Chore / Refactor | `chore/<desc>` | `chore/cleanup-scripts` |

**Rules:**
- Use lowercase with hyphens only (no underscores or spaces)
- Keep names short and descriptive (≤ 50 chars)
- Always branch from `dev`, not `production`

---

## Commit Message Format

We follow **[Conventional Commits](https://www.conventionalcommits.org/)** specification.

### Format

```
<type>(<scope>): <short summary>

[optional body]

[optional footer(s)]
```

### Types

| Type | When to use |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code restructuring, no behavior change |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `chore` | Build process, dependency updates |
| `ci` | CI/CD configuration |

### Examples

```bash
feat(adapters): add BACnet/IP auto-discovery
fix(opcua): resolve session timeout on reconnect
docs(networking): add VLAN configuration guide
chore(deps): upgrade Python dependencies
```

### Rules
- Use the **imperative mood** in the summary: "add feature" not "added feature"
- Limit the summary line to **72 characters**
- Reference issues in the footer: `Closes #42` or `Fixes #17`

---

## Pull Request Process

1. **Target branch**: Always target `dev` (never `production` directly)
2. **Fill the PR template**: All checklist items must be addressed
3. **Link issues**: Reference any related issues with `Closes #<id>`
4. **Keep it small**: Aim for < 400 lines changed per PR. Large PRs are hard to review and slower to merge
5. **Pass CI**: All automated checks must pass before review is requested
6. **Respond to feedback**: Address review comments within a reasonable time

See [docs/PR_RULES.md](docs/PR_RULES.md) for the full merge policy.

---

## Code Style Guidelines

### Shell Scripts (`.sh`)
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use `#!/usr/bin/env bash`
- All variables in `"double quotes"`
- Use `set -euo pipefail` at the top of scripts
- Run `shellcheck` before committing

### Python
- Follow [PEP 8](https://peps.python.org/pep-0008/)
- Max line length: 120 characters
- Use type hints where possible
- Docstrings on all public functions

### Markdown / Documentation
- Use ATX-style headings (`# H1`, `## H2`)
- One sentence per line for easier diffs
- Verify links aren't broken before submitting

---

## Reporting Bugs

1. Check [existing issues](https://github.com/Amitpwa/amitOS/issues) first
2. Open a new issue using the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md)
3. Include: OS version, hardware spec, steps to reproduce, expected vs actual behavior, and logs

---

## Requesting Features

1. Check the [Roadmap](docs/ROADMAP.md) — it may already be planned
2. Open a new issue using the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md)
3. Describe the use case clearly — "what problem does this solve?"

---

## Questions?

- Open a [Discussion](https://github.com/Amitpwa/amitOS/discussions)
- Email: **ashutoshpandeyies@gmail.com**
- LinkedIn: [ashutosh12](https://linkedin.com/in/ashutosh12)

---

*Thank you for helping make amitOS better for the industrial community! ⚡*

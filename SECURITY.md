# Security Policy

## Supported Versions

The following versions of amitOS currently receive security updates:

| Version | Supported |
|---|---|
| `dev` (latest) | ✅ Active support |
| `production` | ✅ Active support |
| Older releases | ❌ Not supported |

---

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

If you discover a security vulnerability in amitOS, we ask that you disclose it responsibly. Here's how:

### 📧 Private Disclosure (Preferred)

Send an email to **ashutoshpandeyies@gmail.com** with the subject line:

```
[SECURITY] <Brief description of the issue>
```

Please include:

- **Description**: A clear description of the vulnerability
- **Impact**: What an attacker could achieve by exploiting it
- **Steps to Reproduce**: Detailed reproduction steps
- **Affected Components**: Which part of amitOS is affected (e.g., OPC UA stack, adapter framework, networking)
- **Suggested Fix** *(optional)*: If you have a patch or mitigation in mind

### 🔐 Encrypted Communication

If your report is sensitive, you may request our PGP key via email before sending details.

---

## Response Timeline

| Stage | Timeline |
|---|---|
| Acknowledgement of report | Within **48 hours** |
| Initial assessment & severity rating | Within **5 business days** |
| Fix development & testing | Within **30 days** (critical issues prioritized) |
| Public disclosure | After fix is released and users have time to update |

---

## Severity Levels

We use the [CVSS v3.1](https://www.first.org/cvss/v3-1/) scoring system to rate vulnerabilities:

| Severity | CVSS Score | Response Priority |
|---|---|---|
| **Critical** | 9.0 – 10.0 | Immediate (< 7 days) |
| **High** | 7.0 – 8.9 | High (< 14 days) |
| **Medium** | 4.0 – 6.9 | Standard (< 30 days) |
| **Low** | 0.1 – 3.9 | Scheduled release |

---

## Out of Scope

The following are **not** considered security vulnerabilities for this project:

- Bugs without security impact
- Issues in third-party dependencies (report to their respective maintainers)
- Social engineering attacks
- Issues requiring physical access to the machine

---

## Recognition

We sincerely appreciate responsible disclosure. Contributors who report valid security issues will be acknowledged in the release notes (unless they prefer to remain anonymous).

---

## Contact

**Security Team Lead**: Ashutosh Pandey  
📧 ashutoshpandeyies@gmail.com  
🔗 [LinkedIn](https://linkedin.com/in/ashutosh12)

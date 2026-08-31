<div align="center">

# Azure Cloud Security WAF Lab

[![CI](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-ci.yml)
[![CD](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-cd.yml/badge.svg)](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-cd.yml)
![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoftazure&logoColor=white)

</div>

<sub>

An end-to-end Azure cloud security and DevSecOps lab, built with Terraform. It deploys an intentionally vulnerable web app behind Azure Application Gateway WAF, adds network segmentation and backend health monitoring, and wires everything into a GitHub Actions pipeline that validates the infrastructure, the security controls, and the WAF telemetry on every change.

</sub>

---

## Project Goals and Architecture

<sub>

The core objective is to establish a vulnerable environment, defend it with a WAF, and capture attack telemetry, all provisioned via Infrastructure as Code (IaC).

- **The Target (DVWA):** A Dockerized PHP application deliberately configured with common web vulnerabilities, hosted on internal Azure Linux virtual machines.
- **The Defense (WAF):** An Azure Application Gateway (v2) acting as a reverse proxy, inspecting all incoming traffic against the OWASP Core Rule Set to detect and block malicious payloads.
- **The Telemetry (SIEM):** A Log Analytics Workspace configured to ingest `ApplicationGatewayFirewallLog` events, providing visibility into attack vectors and blocked requests.

</sub>

---

## DevSecOps Pipeline Lifecycle

<sub>

Rather than manual provisioning, the entire architecture is managed through GitHub Actions, enforcing security checks before code is merged and validating defenses post-deployment.

</sub>

### Continuous Integration (Pull Requests)

<sub>

- **Secret Scanning:** Gitleaks scans the commit history to prevent hardcoded credentials.
- **Code Formatting:** `terraform fmt` and `validate` ensure syntax consistency.
- **Static Application Security Testing (SAST):** Checkov scans the Terraform code against CIS Azure benchmarks to block insecure cloud configurations before deployment.
- **Plan Visibility:** The pipeline generates a speculative deployment plan and posts it as a PR comment for reviewer approval.

</sub>

### Continuous Delivery (Main Branch)

<sub>

- **Passwordless Authentication:** Utilizes Azure OpenID Connect (OIDC) to generate short-lived tokens, eliminating the need for stored service principal secrets.
- **State Management:** Infrastructure state is securely locked and tracked in an encrypted Azure Storage Account.
- **Automated Security Testing:** Post-deployment, the pipeline automatically fires a live SQL Injection payload (`1' OR '1'='1`) against the WAF to trigger a security event.
- **Telemetry Validation:** The pipeline automatically queries the Log Analytics Workspace to guarantee the WAF successfully detected and logged the automated attack.

</sub>

---

## Repository Structure

<sub>

```
.
├── .github/workflows/
│   ├── terraform-ci.yml        # Pull Request security and planning
│   └── terraform-cd.yml        # Main branch deployment and WAF testing
├── terraform/
│   ├── main.tf                 # Remote state and provider config
│   ├── network.tf              # VNet, Subnets, NSGs
│   ├── compute.tf              # VMs, NICs, Docker payload execution
│   ├── appgateway.tf           # Application Gateway and WAF Policy
│   ├── monitoring.tf           # Log Analytics Workspace and Diagnostics
│   ├── variables.tf            # Input variables
│   └── outputs.tf              # Exported values
└── README.md
```

</sub>

---

## Manual Attack Simulation

<sub>

Once the CI/CD pipeline successfully deploys the infrastructure, manual attacks can be simulated against the Application Gateway Public IP to generate further SIEM logs.

**Cross-Site Scripting (XSS):**

</sub>

```bash
curl "http://<APP_GW_IP>/?search=<script>alert('XSS')</script>"
```

<sub>

**SQL Injection (SQLi):**

</sub>

```bash
curl "http://<APP_GW_IP>/login.php?id=1'%20OR%20'1'='1"
```

---

## Log Querying

<sub>

Navigate to the Log Analytics Workspace in the Azure Portal and use Kusto Query Language (KQL) to view the WAF interventions:

</sub>

```kql
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| project TimeGenerated, clientIp_s, ruleId_s, Message, action_s
```

---

<div align="center">
<sub>

## Author

**Olana Kenea**

</sub>
</div>
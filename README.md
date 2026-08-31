# Azure Cloud Security WAF Lab

[![Terraform CI](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-ci.yml)
[![Terraform CD](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-cd.yml/badge.svg)](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-cd.yml)
![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoftazure&logoColor=white)
![OIDC](https://img.shields.io/badge/Auth-OIDC-2E7D32)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

An end-to-end Azure cloud security and DevSecOps lab, built with Terraform. It deploys an intentionally vulnerable web app behind Azure Application Gateway WAF, adds network segmentation and backend health monitoring, and wires everything into a GitHub Actions pipeline that validates the infrastructure, the security controls, and the WAF telemetry on every change.

## What it does

Traffic comes in through a public IP and hits Azure Application Gateway, running the WAF_v2 SKU with the OWASP Core Rule Set in detection mode. From there it's routed to a backend pool of two DVWA VMs on Ubuntu, which Application Gateway continuously health-checks. Every WAF event is streamed to Log Analytics through Azure Monitor, so there's a real audit trail to check against.

On top of that sits a two-stage GitHub Actions pipeline. Pull requests trigger a CI run that scans for secrets and misconfigurations and posts a Terraform plan back to the PR. Merges to `main` trigger a CD run that applies the change and then actively tests it — checking backend health, hitting the app over HTTP, firing a controlled SQL injection at it, and confirming the WAF actually logged it.

```
Internet → Public IP → Application Gateway (WAF_v2, OWASP CRS, Detection Mode)
                              │
                        Backend Pool
                        ┌─────┴─────┐
                     DVWA VM 1   DVWA VM 2
                        └─────┬─────┘
                        Health Probe

WAF events → Azure Monitor → Log Analytics

GitHub Actions: CI (Gitleaks, Checkov, validate, plan)
                CD (apply, health test, app test, WAF test)
```

## Why it exists

This project is meant to show a realistic cloud security workflow end to end, not just a pile of Terraform resources. That means:

- Provisioning real Azure infrastructure — a segmented VNet, an Application Gateway WAF, NSGs, health probes — entirely through code.
- Actually enforcing security controls (OWASP managed rules) and proving they work, rather than just declaring them.
- Scanning the infrastructure code itself for secrets and misconfigurations before anything gets deployed.
- Authenticating GitHub Actions to Azure with OIDC instead of a long-lived client secret.
- Verifying, automatically and after every deploy, that the WAF is not just present but genuinely producing telemetry.

## Azure infrastructure

```
Resource Group
├── Virtual Network
│   ├── Application Gateway Subnet (10.0.1.0/24)
│   └── Backend Subnet (10.0.2.0/24)
├── Network Security Group
├── Application Gateway (WAF_v2, Public IP, Listener, Backend Pool, Health Probe)
├── WAF Policy (OWASP Managed Rules)
├── Availability Set
├── DVWA VM 1 + NIC
├── DVWA VM 2 + NIC
└── Log Analytics Workspace
```

## The WAF, in practice

The WAF policy runs in detection mode on purpose — this is a lab meant for testing, not a locked-down production gateway. To prove it's working, the pipeline sends a controlled SQL injection request:

```
GET /login.php?id=1' OR '1'='1
```

That request flows through Application Gateway, into the WAF, gets flagged by OWASP rule detection, and lands in Log Analytics as a WAF log entry. The CD pipeline then queries Log Analytics to confirm the event actually showed up — the test isn't considered passed until the log entry is there.

## Backend health

Application Gateway probes both DVWA VMs continuously over HTTP. You can check the same thing manually:

```bash
az network application-gateway show-backend-health \
  --resource-group rg-cloudsec-lab-dev \
  --name appgw-cloudsec-lab-dev \
  --output json
```

If either backend comes back unhealthy, the deployment pipeline fails the run rather than reporting a false success.

## CI pipeline

Runs on every pull request that touches Terraform:

1. Checkout
2. Gitleaks — catches committed secrets
3. `terraform fmt -check -recursive`
4. `terraform init`
5. `terraform validate`
6. Checkov — flags cloud misconfigurations
7. `terraform plan`, posted straight to the PR

A failing plan shows up in the PR thread and fails the check — nothing gets merged blind.

## CD pipeline

Runs on merge to `main`:

1. `terraform init` / `terraform apply`
2. Authenticate to Azure via OIDC
3. Pull the Application Gateway's public IP
4. Confirm backend health
5. Test application connectivity over HTTP
6. Fire the controlled SQL injection test
7. Poll Log Analytics for WAF telemetry and confirm detection
8. Post a deployment summary

## Authentication

GitHub Actions authenticates to Azure with OpenID Connect instead of a stored client secret:

```
GitHub Actions → OIDC → Microsoft Entra ID → Azure Service Principal → Azure Resources
```

Enabled with `ARM_USE_OIDC: true`. The workflow needs three repository secrets:

```
AZURE_CLIENT_ID
AZURE_SUBSCRIPTION_ID
AZURE_TENANT_ID
```

No long-lived Azure credentials are ever stored in GitHub.

## Security checks, at a glance

| Stage | Control |
|---|---|
| Pull Request | Gitleaks |
| Pull Request | Checkov |
| Pull Request | Terraform Validate |
| Pull Request | Terraform Plan |
| Deployment | Azure OIDC |
| Deployment | Backend Health |
| Deployment | Application Connectivity |
| Deployment | Controlled SQL Injection Test |
| Post-Deployment | WAF Telemetry Verification |
| Ongoing | Log Analytics Monitoring |

## Repository structure

```
azure-cloudsec-waf-lab/
├── .github/workflows/
│   ├── terraform-ci.yml
│   └── terraform-cd.yml
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── resource-group.tf
│   ├── network.tf
│   ├── compute.tf
│   ├── appgateway.tf
│   ├── waf.tf
│   └── outputs.tf
├── scripts/
│   └── setup_dvwa.sh
└── README.md
```

## Getting started

You'll need Terraform, the Azure CLI, Git, and an Azure subscription.

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"

git clone https://github.com/olanak/azure-cloudsec-waf-lab.git
cd azure-cloudsec-waf-lab/terraform

terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
terraform apply
```

## Testing it manually

**Check backend health**

```bash
az network application-gateway show-backend-health \
  --resource-group rg-cloudsec-lab-dev \
  --name appgw-cloudsec-lab-dev \
  --output json
```

**Hit the app**

```bash
curl http://$(terraform output -raw appgw_public_ip)
```

**Trigger the WAF**

```bash
curl --get \
  --data-urlencode "id=1' OR '1'='1" \
  "http://<APPGW_PUBLIC_IP>/login.php"
```

## Observability

WAF and diagnostic events land in Log Analytics via Azure Monitor. Here's the KQL query the CD pipeline uses to confirm telemetry showed up:

```kql
AzureDiagnostics
| where TimeGenerated > ago(10m)
| where Category == "ApplicationGatewayFirewallLog"
| where action_s contains "Detected" or action_s contains "Blocked"
| where message_s contains "SQL" or message_s contains "Injection" or message_s contains "942"
| order by TimeGenerated desc
| take 5
```

## Concepts demonstrated

Infrastructure as Code, Terraform, Azure networking and segmentation, Application Gateway, Web Application Firewall (OWASP CRS), Linux administration, availability sets, load balancing and health probes, Network Security Groups, Azure Monitor and Log Analytics, KQL, CI/CD with GitHub Actions, OIDC authentication, security-as-code, IaC scanning, secret detection, and automated security validation.

## Author

**Olana Kenea Lemesa**
Cloud Security Engineer · GRC · Infrastructure as Code

Focused on cloud security, Azure, Terraform, DevSecOps, IAM, and security automation.
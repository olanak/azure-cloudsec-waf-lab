# Azure Cloud Security WAF Lab




\

An end-to-end **Azure Cloud Security and DevSecOps lab** built with Terraform.

The project deploys an intentionally vulnerable web application behind **Azure Application Gateway WAF**, implements network segmentation and backend health monitoring, and uses **GitHub Actions CI/CD** to automatically validate infrastructure, security controls, application availability, and WAF telemetry.

---

## 🔗 Project Links

| Resource        | Link                                                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------------------------------------- |
| 📦 Repository   | [Azure Cloud Security WAF Lab](https://github.com/olanak/azure-cloudsec-waf-lab)                                          |
| 🔍 Terraform CI | [Terraform CI & Security](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-ci.yml)            |
| 🚀 Terraform CD | [Terraform CD & Security Validation](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-cd.yml) |
| 🏗️ Terraform   | [`terraform/`](./terraform)                                                                                               |
| ⚙️ CI Workflow  | [`terraform-ci.yml`](./.github/workflows/terraform-ci.yml)                                                                |
| 🚀 CD Workflow  | [`terraform-cd.yml`](./.github/workflows/terraform-cd.yml)                                                                |

---

# 🏗️ Architecture

```text
                         Internet
                            │
                            │ HTTP
                            ▼
                  ┌─────────────────────┐
                  │    Azure Public IP   │
                  └──────────┬──────────┘
                             │
                             ▼
              ┌─────────────────────────────┐
              │    Azure Application         │
              │       Gateway WAF_v2         │
              │                             │
              │   ┌──────────────────────┐  │
              │   │    Azure WAF Policy  │  │
              │   │     OWASP CRS 3.2   │  │
              │   │    Detection Mode    │  │
              │   └──────────────────────┘  │
              └──────────────┬──────────────┘
                             │
                       Backend Pool
                             │
                  ┌──────────┴──────────┐
                  │                     │
                  ▼                     ▼
          ┌───────────────┐     ┌───────────────┐
          │    DVWA VM 1  │     │    DVWA VM 2  │
          │ Ubuntu Linux  │     │ Ubuntu Linux  │
          │   10.0.2.x    │     │   10.0.2.x    │
          └───────────────┘     └───────────────┘
                  │                     │
                  └──────────┬──────────┘
                             │
                             ▼
                  Application Gateway
                     Health Probe
                             │
                             ▼
                    Backend Health


       ┌─────────────────────────────────────┐
       │          Security Telemetry         │
       │                                     │
       │ WAF → Azure Monitor → Log Analytics │
       └─────────────────────────────────────┘


                    GitHub Actions
                          │
             ┌────────────┴────────────┐
             │                         │
             ▼                         ▼
      ┌──────────────┐          ┌──────────────┐
      │ Terraform CI │          │ Terraform CD │
      │              │          │              │
      │ Gitleaks     │          │ Apply        │
      │ Checkov      │          │ Health Test  │
      │ Validate     │          │ App Test     │
      │ Plan         │          │ WAF Test     │
      └──────────────┘          └──────────────┘
```

---

# 🎯 Project Objectives

This project demonstrates practical **Cloud Security, Infrastructure as Code, and DevSecOps** capabilities.

### Infrastructure

* Provision Azure infrastructure using Terraform
* Build a segmented Azure Virtual Network
* Deploy Application Gateway WAF
* Deploy two Linux-based DVWA backend servers
* Configure backend health probes
* Configure Network Security Groups
* Implement Application Gateway routing

### Security

* Implement Azure Web Application Firewall
* Use OWASP managed rules
* Perform controlled SQL injection testing
* Generate WAF security telemetry
* Verify security events through Log Analytics
* Scan Terraform for security misconfigurations
* Detect accidentally committed secrets

### DevSecOps

* Automate Terraform validation
* Automate infrastructure security scanning
* Generate Terraform plans for pull requests
* Post Terraform plan results directly to PRs
* Automatically deploy approved changes
* Perform post-deployment security validation
* Authenticate GitHub Actions to Azure using OIDC

---

# ☁️ Azure Infrastructure

The environment is built using Terraform and consists of the following components:

```text
Resource Group
│
├── Virtual Network
│   │
│   ├── Application Gateway Subnet
│   │   └── 10.0.1.0/24
│   │
│   └── Backend Subnet
│       └── 10.0.2.0/24
│
├── Network Security Group
│   └── Backend HTTP Rule
│
├── Application Gateway
│   ├── WAF_v2
│   ├── Public IP
│   ├── HTTP Listener
│   ├── Backend Pool
│   ├── HTTP Settings
│   └── Health Probe
│
├── WAF Policy
│   └── OWASP Managed Rules
│
├── Availability Set
│
├── DVWA VM 1
│   └── Network Interface
│
├── DVWA VM 2
│   └── Network Interface
│
└── Log Analytics Workspace
```

---

# 🛡️ Web Application Firewall

Azure Application Gateway is configured with the `WAF_v2` SKU.

The WAF policy uses the OWASP managed rule set and operates in **Detection mode**.

This mode is intentional for the security-testing portion of the lab.

The pipeline sends a controlled SQL injection request:

```text
GET /login.php?id=1' OR '1'='1
```

The request passes through:

```text
Internet
    │
    ▼
Application Gateway
    │
    ▼
Azure WAF
    │
    ▼
OWASP Rule Detection
    │
    ▼
WAF Log
    │
    ▼
Log Analytics
```

The CI/CD pipeline then verifies that the security event was recorded.

---

# ❤️ Backend Health Monitoring

Application Gateway continuously checks the backend servers using a custom HTTP health probe.

```text
Application Gateway
        │
        ├── Health Probe
        │
        ├── VM 1 → Healthy
        │
        └── VM 2 → Healthy
```

The deployment pipeline queries Azure:

```bash
az network application-gateway show-backend-health
```

If one or more backend servers are unhealthy, the deployment validation fails.

---

# 🔄 CI Pipeline

The CI pipeline runs automatically when Terraform files are changed in a Pull Request.

### Workflow

```text
Pull Request
     │
     ▼
Checkout
     │
     ▼
Gitleaks
     │
     ▼
Terraform fmt
     │
     ▼
Terraform init
     │
     ▼
Terraform validate
     │
     ▼
Checkov
     │
     ▼
Terraform plan
     │
     ▼
Plan posted to PR
     │
     ▼
Pass / Fail
```

### CI Security Controls

#### Gitleaks

Detects accidentally committed credentials and secrets.

#### Terraform Format

```bash
terraform fmt -check -recursive
```

Ensures Terraform configuration follows consistent formatting.

#### Terraform Validate

```bash
terraform validate
```

Checks Terraform configuration for structural and configuration errors.

#### Checkov

Scans the Terraform configuration for cloud security misconfigurations and insecure infrastructure patterns.

#### Terraform Plan

The pipeline generates a Terraform execution plan and posts the result directly into the Pull Request.

If the plan fails, the failure is reported in the PR while the workflow still ultimately returns a failed status.

### 🔍 View CI Runs

**[Terraform CI & Security → GitHub Actions](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-ci.yml)**

---

# 🚀 CD Pipeline

Once changes are merged into `main`, the CD pipeline deploys the infrastructure.

```text
Merge to main
      │
      ▼
Terraform Init
      │
      ▼
Terraform Apply
      │
      ▼
Azure OIDC Authentication
      │
      ▼
Get Application Gateway IP
      │
      ▼
Backend Health Validation
      │
      ▼
Application Connectivity Test
      │
      ▼
Controlled SQL Injection Test
      │
      ▼
Wait / Poll for WAF Telemetry
      │
      ▼
Verify WAF Detection
      │
      ▼
Deployment Summary
```

### Post-Deployment Validation

The pipeline automatically verifies:

* Application Gateway deployment
* Backend server health
* Application availability
* HTTP connectivity
* WAF security testing
* WAF telemetry
* Log Analytics events

### 🔍 View CD Runs

**[Terraform CD & Security Validation → GitHub Actions](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-cd.yml)**

---

# 🔐 Azure Authentication

GitHub Actions authenticates to Azure using **OpenID Connect (OIDC)**.

Instead of storing an Azure client secret in GitHub, the workflow uses:

```text
GitHub Actions
      │
      │ OIDC
      ▼
Microsoft Entra ID
      │
      ▼
Azure Service Principal
      │
      ▼
Azure Resources
```

The workflow uses:

```yaml
ARM_USE_OIDC: true
```

This eliminates the need for long-lived Azure client secrets.

Required GitHub repository secrets:

```text
AZURE_CLIENT_ID
AZURE_SUBSCRIPTION_ID
AZURE_TENANT_ID
```

---

# 🔒 Security Validation

The project implements security validation at multiple stages.

| Stage        | Security Control         |
| ------------ | ------------------------ |
| Pull Request | Gitleaks                 |
| Pull Request | Checkov                  |
| Pull Request | Terraform Validate       |
| Pull Request | Terraform Plan           |
| Deployment   | Azure OIDC               |
| Deployment   | Backend Health           |
| Deployment   | Application Connectivity |
| Deployment   | Controlled SQL Injection |
| Post-Test    | WAF Telemetry            |
| Monitoring   | Log Analytics            |

This creates a security-focused deployment lifecycle:

```text
Code
 │
 ▼
Security Scan
 │
 ▼
Validation
 │
 ▼
Terraform Plan
 │
 ▼
Review
 │
 ▼
Merge
 │
 ▼
Deployment
 │
 ▼
Infrastructure Validation
 │
 ▼
Security Testing
 │
 ▼
Telemetry Verification
```

---

# 📁 Repository Structure

```text
azure-cloudsec-waf-lab/
│
├── .github/
│   └── workflows/
│       ├── terraform-ci.yml
│       └── terraform-cd.yml
│
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── resource-group.tf
│   ├── network.tf
│   ├── compute.tf
│   ├── appgateway.tf
│   ├── waf.tf
│   ├── outputs.tf
│   └── ...
│
├── scripts/
│   └── setup_dvwa.sh
│
└── README.md
```

---

# 🚀 Getting Started

## Prerequisites

Install:

* Terraform
* Azure CLI
* Git
* An Azure subscription

Authenticate to Azure:

```bash
az login
```

Select the appropriate subscription:

```bash
az account set --subscription "<SUBSCRIPTION_ID>"
```

---

## Clone the Repository

```bash
git clone https://github.com/olanak/azure-cloudsec-waf-lab.git

cd azure-cloudsec-waf-lab
```

---

## Initialize Terraform

```bash
cd terraform

terraform init
```

---

## Validate Configuration

```bash
terraform fmt -check -recursive

terraform validate
```

---

## Review the Deployment

```bash
terraform plan
```

---

## Deploy

```bash
terraform apply
```

---

# 🧪 Security Testing

After deployment, the environment can be validated manually using Azure CLI.

### Check Application Gateway Backend Health

```bash
az network application-gateway show-backend-health \
  --resource-group rg-cloudsec-lab-dev \
  --name appgw-cloudsec-lab-dev \
  --output json
```

Expected result:

```text
VM 1 → Healthy
VM 2 → Healthy
```

### Test Application Gateway

Retrieve the public IP:

```bash
terraform output -raw appgw_public_ip
```

Then:

```bash
curl http://<APPGW_PUBLIC_IP>
```

### Controlled WAF Test

```bash
curl --get \
  --data-urlencode "id=1' OR '1'='1" \
  "http://<APPGW_PUBLIC_IP>/login.php"
```

The request is intended to generate WAF security telemetry.

---

# 📊 Observability

Security events are sent to Azure Monitor / Log Analytics.

The CD pipeline verifies WAF telemetry using Azure CLI and KQL.

Example query:

```kql
AzureDiagnostics
| where TimeGenerated > ago(10m)
| where Category == "ApplicationGatewayFirewallLog"
| where action_s contains "Detected"
    or action_s contains "Blocked"
| where message_s contains "SQL"
    or message_s contains "Injection"
    or message_s contains "942"
| order by TimeGenerated desc
| take 5
```

This allows the deployment pipeline to verify not only that the WAF exists, but that it is actually producing security telemetry.

---

# 💡 Key Engineering Concepts Demonstrated

This project demonstrates practical experience with:

* Infrastructure as Code
* Terraform
* Azure networking
* Network segmentation
* Application Gateway
* Web Application Firewall
* OWASP CRS
* Linux administration
* Availability Sets
* Load balancing
* Health probes
* Network Security Groups
* Azure Monitor
* Log Analytics
* KQL
* DevSecOps
* CI/CD
* GitHub Actions
* OIDC authentication
* Security-as-Code
* Infrastructure security scanning
* Secret detection
* Automated security validation

---

# 🎓 What This Project Demonstrates

This is more than a Terraform deployment.

It demonstrates a complete **cloud security engineering workflow**:

```text
                    ┌─────────────────┐
                    │ Infrastructure  │
                    │      Code       │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Security Scan   │
                    │ Gitleaks/       │
                    │ Checkov         │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Terraform Plan  │
                    └────────┬────────┘
                             │
                             ▼
                         Code Review
                             │
                             ▼
                    ┌─────────────────┐
                    │ Terraform Apply │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Infrastructure  │
                    │   Validation    │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Security Test   │
                    │      WAF        │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Security Logs   │
                    │ Log Analytics   │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Automated       │
                    │ Verification    │
                    └─────────────────┘
```

The result is an automated **Cloud Security + Infrastructure as Code + DevSecOps** workflow rather than simply a collection of Azure resources.



---

# 👤 Author

**Olana Kenea Lemesa**

Cloud Security Engineer | GRC | Infrastructure-as-Code

Focused on:

* Cloud Security
* Azure
* Terraform
* DevSecOps
* Infrastructure Security
* IAM
* Security Automation

---

## ⭐ If you find this project useful

Feel free to explore the repository, review the Terraform configuration, and inspect the **GitHub Actions CI/CD workflows** to see how infrastructure security and post-deployment validation are automated.

**[View Repository →](https://github.com/olanak/azure-cloudsec-waf-lab)**
**[View CI Pipeline →](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-ci.yml)**
**[View CD Pipeline →](https://github.com/olanak/azure-cloudsec-waf-lab/actions/workflows/terraform-cd.yml)**

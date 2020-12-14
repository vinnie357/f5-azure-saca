# F5 & Azure Secure Cloud Computing Architecture

<!--TOC-->

- [F5 & Azure Secure Cloud Computing Architecture](#f5--azure-secure-cloud-computing-architecture)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Important configuration notes](#important-configuration-notes)
  - [Variables](#variables)
  - [Deployment](#deployment)
    - [Docker](#docker)
  - [Destruction](#destruction)
    - [Docker](#docker-1)
  - [Development](#development)

<!--TOC-->

## Introduction

Moving to the Cloud can be tough. The Department of Defense (DoD) has requirements to protect the Defense Information System Networks (DISN) and DoD Information Networks (DoDIN), even for workloads residing in a Cloud Service Provider (CSP). Per the SCCA Functional Requirements Document, the purpose of SCCA is to provide a barrier of protection between the DISN and commercial cloud services used by the DoD.

“It specifically addresses attacks originating from mission applications that reside within the Cloud Service Environment (CSE) upon both the DISN infrastructure and neighboring tenants in a multi-tenant environment. It provides a consistent CSP independent level of security that enables the use of commercially available Cloud Service Offerings (CSO) for hosting DoD mission applications operating at all DoD Information System Impact Levels (i.e. 2, 4, 5, & 6).” * [https://iasecontent.disa.mil/stigs/pdf/SCCA_FRD_v2-9.pdf](https://iasecontent.disa.mil/stigs/pdf/SCCA_FRD_v2-9.pdf)

This solution uses Terraform to launch a Single Tiered or Three Tier deployment of three NIC cloud-focused BIG-IP VE cluster(s) (Active/Standby) in Microsoft Azure. This is the standard cloud design where the BIG-IP VE instance is running with three interfaces, where both management and data plane traffic is segregated.

The BIG-IP VEs have the following features / modules enabled:

- [Local / Global Availability](https://f5.com/products/big-ip/local-traffic-manager-ltm)

- [Firewall](https://www.f5.com/products/security/advanced-firewall-manager)
  - Firewall with Intrusion Protection and IP Intelligence only available with BYOL deployments today.

- [Web Application Firewall](https://www.f5.com/products/security/advanced-waf)

## Prerequisites

- **Important**: When you configure the admin password for the BIG-IP VE in the template, you cannot use the character **#**.  Additionally, there are a number of other special characters that you should avoid using for F5 product user accounts.  See [K2873](https://support.f5.com/csp/article/K2873) for details.
- This template requires a service principal, one will be created in the provided script at ./prepare/setupAzureGovVars_local.sh.
  - **Important** For gov cloud deployments its important to run this script to prepare your environment, whether local or Azure Cloud CLI based.  There are extra env variables that ned to be passed by TF to Gov Cloud Regions.
- This deployment will be using the Terraform Azurerm provider to build out all the neccessary Azure objects. Therefore, Azure CLI is required. for installation, please follow this [Microsoft link](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest)
- If this is the first time to deploy the F5 image, the subscription used in this deployment needs to be enabled to programatically deploy. For more information, please refer to [Configure Programatic Deployment](https://azure.microsoft.com/en-us/blog/working-with-marketplace-images-on-azure-resource-manager/)
- You need to set your region and log in to azure ahead of time, the scripts will map your authenitcation credentials and create a service principle, so you will not need to hardcode any credentials in the files.

## Important configuration notes

- All variables are configured in variables.tf
- **MOST** STIG / SRG configurations settings have been addressed in the Declarative Onboarding and Application Services templates used in this example.
- An Example application is optionally deployed with this template.  The example appliation includes several apps running in docker on the host:
  - Juiceshop on port 3000
  - F5 Demo app by Eric Chen on ports 80 and 443
  - rsyslogd with PimpMyLogs on port 808
  - **Note** Juiceshop and PimpMyLogs URLS are part of the terraform output when deployed.
- All Configuration should happen at the root level; auto.tfvars or variables.tf.

## Variables

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
Error: unknown flag: --required
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Deployment

For deployment you can do the traditional terraform commands or use the provided scripts.

```bash
terraform init
terraform plan
terraform apply
```

OR

```bash
./demo.sh
```

### Docker
There is also a dockerfile provided, use make [options] to build as needed.

```bash
make build
make shell || make azure || make gov
```

## Destruction

For destruction / tear down you can do the trafitional terraform commands or use the provided scripts.

```bash
terraform destroy
```

OR

```bash
./cleanup.sh
```

### Docker

```bash
make destroy || make revolution
```

## Development

Outline any requirements to setup a development environment if someone would like to contribute.  You may also link to another file for this information.

  ```bash
  # test pre commit manually
  pre-commit run -a -v
  ```

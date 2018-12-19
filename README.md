# Setup

## Setup Azure
Sign up for an [Azure account](https://azure.microsoft.com/free/)

Install the [Azure CLI](https://azure.microsoft.com/documentation/articles/xplat-cli-install/), then login and initialize providers we'll use with
```
az login
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
```

## Setup Local Credentials
Set environment variables and create a [service principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest) ([jq](https://stedolan.github.io/jq/) makes this easier)
```
export azure_subscription_id=$(az account show | jq -r .id)
export azure_tenant_id=$(az account show | jq -r .tenantId)
azure_client_name=<name>
export azure_client_secret=<password>
az ad sp create-for-rbac --name $azure_client_name --password $azure_client_secret
export azure_client_id="http://${azure_client_name}"
```

## Install Dependencies
Install the [azure_arm](https://forge.puppet.com/puppetlabs/azure_arm) module with
```
bolt puppetfile install
```

Puppet Agent must be installed on the host you use to run Bolt.

## Create some VMs

Note: this plan requires Bolt 1.7+

Run the plan
```
bolt plan run example admin_user=testAdmin admin_password=<make-a-password>
```

Note: you can pass arguments via a file to prevent them appearing in your shell history.

The plan will wait until machines are provisioned and print their hostnames. You can also get their IP addresses and run more commands directly with Bolt
```
ipaddresses=$(az vm list-ip-addresses | jq -r '.[].virtualMachine.network.publicIpAddresses[].ipAddress')
bolt command run hostname -n $ipaddresses --transport winrm --user testAdmin --no-ssl --password
```

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
Install the [facets](https://rubygems.org/gems/facets) gem with
```
/opt/puppetlabs/bolt/bin/gem install facets
```
or
```
"C:/Program Files/Puppet Labs/Bolt/bin/gem.bat" install facets
```

Install the [azure_arm](https://forge.puppet.com/puppetlabs/azure_arm) module with
```
bolt puppetfile install
```

## Create some VMs
Run the plan
```
bolt plan run example admin_password=<make-a-password>
```

Get IP addresses and test with Bolt
```
ipaddresses=$(az vm list-ip-addresses | jq -r '.[].virtualMachine.network.publicIpAddresses[].ipAddress')
bolt command run hostname -n $ipaddresses --transport winrm --user testAdmin --no-ssl --password
```

Note that VMs may not initially respond. Give them up to a minute to be ready and try again.

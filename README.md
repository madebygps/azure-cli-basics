# Azure CLI Basics

## What's the advantage of using an Azure command-line tool?

Azure runs on automation. Every action inside the portal translates to code being executed to read, create, modify, or delete resources. Azure command-line tools automate routine operations, standardize database failover, and pull data that provide powerful insight. 

## Chose the right Azure Command Line Tool

 You have two options when it comes to Azure command-lines: Azure CLI and Azure Powershell. Both are cross-platform, installable on Windows, macOS, and Linux. The most significant difference is that Azure CLI runs in Windows PowerShell, Cmd, Bash, and Unix shells. Azure Powershell requires Windows PowerShell or Powershell to run. Choose the tool that uses your experience and shortens your learning curve but use a different tool when it makes sense. 

Read more about this [here](https://learn.microsoft.com/cli/azure/choose-the-right-azure-command-line-tool)

## How to install the Azure CLI

The Azure CLI is available to install in Windows, macOS and Linux environments. It can also be run in a Docker container and Azure Cloud Shell. I personally use Azure CLI in Ubuntu on [WSL](https://learn.microsoft.com/en-us/windows/wsl/install). Pick whatever option is best for you. View them all [here](https://learn.microsoft.com/cli/azure/install-azure-cli)

# Commands you should know

## az login

Before using any Azure CLI commands with a local install, you need to sign in with az login. If you're using the Azure Cloud Shell, you don't need to login.

If a browser is not available for you to sign in, use `az login --use-device-code`

## Set your subscription

It's important to set the CLI to work within the subscription you want to. When you login, a default subscription is set for you but you can change that using the `az account` commands.

- `az account set --subscription {subscription-name}`: Will set the subscription. You must provide the name.
- `az account list`: Will give you a list of available subscriptions.
- `az account show`: will display the current set subscription

## The Anatomy of an Azure CLI command

![command-diagram](command-diagram.png)

- **Prefix:** All CLIs have prefixes. Azure's is `az`.
- **Group:** Commands are organized into command groups. Each group represents an Azure service.
- **Subgroup:** If a service has various types or services, it will have a or various subgroups.
- **Command:** An operation on the service.
- **Arguments:** Values you provide the command for context. Arguments can be required, optional, and/or global. The words arguments and parameters are often used interchangeably.

## az config and az init

The Azure CLI allows for user configuration for settings such as logging, data collection, and default argument values. The CLI offers a convenience command for managing some defaults, az config, and an interactive option through az init.

az init is an extension that is intended to quickly set up global configurations suitable for your current environment. It adjusts the same configuration file as az config and is meant to help simplify the configuration process whereas az config allows you to go a bit deeper. 
```sh
az init
```

You can set defaults for the CLI with the az config set command. This command takes a space-separated list of key=value pairs as an argument. The provided values are used by the Azure CLI in place of required arguments.

```sh
az config set defaults.location=eastus2 defaults.group=MyResourceGroup
```

## Interactive mode

You can use Azure CLI in interactive mode by running the az interactive command. The Azure CLI interactive mode places you in an interactive shell with auto-completion, command descriptions, and examples.

![me](interactive.png)

## Finding commands and help

To search for commands, use `az find`. For example, to search for command names containing secret, use the following command:

```sh 
az find secret
```

## Globally available arguments

There are some arguments that are available for every Azure CLI command.

- `--help` prints CLI reference information about commands and their arguments and lists available subgroups and commands.
- `--output` changes the output format. The available output formats are json, jsonc (colorized JSON), tsv (Tab-Separated Values), table (human-readable ASCII tables), and yaml. By default the CLI outputs json.
- `--query` uses the JMESPath query language to filter the output returned from Azure services. 
- `--verbose` prints information about resources created in Azure during an operation, and other useful information.
- `--debug` prints even more information about CLI operations, used for debugging purposes. If you find a bug, provide output generated with the --debug flag on when submitting a bug report.

## Persisted Parameters

Azure CLI offers persisted parameters that enable you to store parameter values for continued use. Persisted parameter values are stored in the working directory of the Azure storage account used by Azure Cloud Shell. If you are using a local install of the Azure CLI, values are stored in the working directory on your machine.

```sh
# Reminder: function app and storage account names must be unique.

# turn persisted parameters on
az config param-persist on

# Create a resource group which will store "resource group" and "location" in persisted parameter.
az group create --name RGlocalContext --location westeurope

# Create an Azure storage account omitting location and resource group.
az storage account create \
  --name sa1localcontext \
  --sku Standard_LRS

# Create a serverless function app in the resource group omitting storage account and resource group.
az functionapp create \
  --name FAlocalContext \
  --consumption-plan-location westeurope \
  --functions-version 2

# See the stored parameter values
az config param-persist show
```

| Reference                | Scope                                          | Set                                                       | Use                                                                            |   |
|--------------------------|------------------------------------------------|-----------------------------------------------------------|--------------------------------------------------------------------------------|---|
| az config set defaults.= | Scoped globally across the CLI                 | Set explicitly using az config set defaults.=             | Use for settings such as logging, data collection, and default argument values |   |
| az config param-persist  | Scoped locally to a specific working directory | Set automatically once persisted parameters are turned on | Use for individual workload sequential commands.                               |   |

## Querying 

The Azure CLI uses the `--query` parameter to execute a JMESPath query on the results of commands. JMESPath is a query language for JSON, giving you the ability to select and modify data from CLI output.

The `--query` parameter is supported by all commands in the Azure CLI.

Even when using an output format other than JSON, CLI command results are first treated as JSON for queries. CLI results are either a JSON array or dictionary. Arrays are sequences of objects that can be indexed, and dictionaries are unordered objects accessed with keys. Commands that could return more than one object return an array, and commands that always return only a single object return a dictionary.

### A few examples:

``` sh
# The following command gets the SSH public keys authorized to connect to the VM by adding a query:

az vm show --resource-group rg-demo1 --name vm1 --query "osProfile.linuxConfiguration.ssh.publicKeys"
```

```sh
# To get multiple values, put expressions separated by commas in square brackets [ ] (a multiselect list)

az vm show --resource-group rg-demo1 --name TestVM --query "[name, osProfile.adminUsername, osProfile.linuxConfiguration.ssh.publicKeys[0].keyData]"
```

```sh
# To get a dictionary instead of an array when querying for multiple values, use the { } (multiselect hash) operator.

az vm show --resource-group rg-demo1 --name TestVM --query "{VMName:name, admin:osProfile.adminUsername, sshKey:osProfile.linuxConfiguration.ssh.publicKeys[0].keyData}"
```

```sh
# To access the properties of elements in an array, you do one of two operations: flattening or filtering. Flattening an array is done with the [] JMESPath operator. All expressions after the [] operator are applied to each element in the current array. If [] appears at the start of the query, it flattens the CLI command result.

az vm list --resource-group rg-demo1 --query "[].{Name:name, OS:storageProfile.osDisk.osType, admin:osProfile.adminUsername}"
```

```sh

# We can also use filters

az vm list --resource-group rg-demo1 --query "[?storageProfile.osDisk.osType=='Linux'].{Name:name,  admin:osProfile.adminUsername}" --output table
```

## Formatting

### TSV output format
The tsv output format returns tab- and newline-separated values without additional formatting, keys, or other symbols. This is useful when the output is consumed by another command.

```sh
USER=$(az vm show --resource-group QueryDemo --name TestVM --query "osProfile.adminUsername")
echo $USER
```

### Table output format
The table format prints output as an ASCII table, making it easy to read and scan. Not all fields are included in the table so this format is best used as a human-searchable overview of data. Fields that are not included in the table can still be filtered for as part of a query.
```sh
az vm show --resource-group QueryDemo --name TestVM --query "{objectID:id}" --output table
```

## More resources
- https://github.com/Azure/azure-cli
- https://learn.microsoft.com/cli/azure/reference-index?view=azure-cli-latest

# Azure CLI and Bash

## Formatting

```sh
az account show
az account show --output json # JSON is the default format

az account show --output yaml

az account show --query name # Querying a single value
az account show --query name -o tsv # Removes quotation marks from the output

az account show --query [name,user.name] # return multiple values
az account show --query [name,user.name] -o table # return multiple values as a table

az account show --query "{SubscriptionName: name, UserName: user.name}" # Rename the values returned
az account show --query "{SubscriptionName: name, UserName: user.name}" -o table # Rename the values returned in a table
```

## Querying boolean values 

```sh

az account list --query "[?isDefault].{SubscriptionName: name, SubscriptionId: id}" -o table # Returns the name and id of the default subscription as a table with friendly names

az account list --query "[?isDefault == \`false\`].name" -o table # Returns all non-default subscriptions, if any, as a table

subscriptionId="$(az account list --query "[?isDefault].name" -o tsv)" # Captures the subscription name as a variable.

echo $subscriptionId # Returns the contents of the variable.

az account list --query "[? contains(name, 'Microsoft')].name" -o tsv # Returns the subscription id of a non-default subscription containing the substring 'Microsoft'

subscriptionId=$(az account list --query "[? contains(name, 'Visual')].id" -o tsv)

 # Captures the subscription id as a variable. 
az account set -s $subscriptionId # Sets the current active subscription

```

## Creating objects using variables and randomization

### Setting a random value 

```sh

let "randomIdentifier=$RANDOM*$RANDOM"

```

### Spaces and quotation marks

Use quote marks to tell the Bash shell to ignore special characters. Use double quotes to parse them. 

```sh

resourceGroup='learn-bash-$randomIdentifier'
echo $resourceGroup # The $ is ignored in the creation of the $resourceGroup variable

resourceGroup="learn-bash-$randomIdentifier"
echo $resourceGroup # The $randomIdentifier is evaluated when defining the $resourceGroup variable

location="East US 2" # The space is ignored when defining the $location variable
echo The value of the location variable is $location # The value of the $location variable is evaluated

echo "The value of the location variable is $location" # The value of the $location variable is evaluated

echo "The value of the location variable is \$location" # The value of the $location variable is not evaluated

echo 'The value of the location variable is $location' # The value of the $location variable is not evaluated

az group create --name $resourceGroup --location $location # Notice that the space in the $location variable is not ignored and the command fails as it treats the value after the space as a new command 

az group create --name $resourceGroup --location "$location" # Notice that the space in the $location variable is ignored and the location argument accepts the entire string as the value

```

## Using If Then Else to determine if variable is null

```sh
if [ $resourceGroup != '' ]; then
   echo $resourceGroup
else
   resourceGroup="learn-bash-$randomIdentifier"
fi
```

```sh
# create a new resource group only if one with the specified name does not already exist.
if [ $(az group exists --name $resourceGroup) = false ]; then 
   az group create --name $resourceGroup --location "$location" 
else
   echo $resourceGroup
fi
```

```sh
# delete an existing new resource group if one with the specified name already exists
if [ $(az group exists --name $resourceGroup) = true ]; then 
   az group delete --name $resourceGroup -y # --no-wait
else
   echo The $resourceGroup resource group does not exist
fi
```
## Use grep to determine if a resource group exists, and create if it doesn't

```sh
az group list -o tsv | grep $resourceGroup -q || az group create --name $resourceGroup --location "$location"
```

## Using for loops and querying arrays

```sh

# Define an array
rgArray=("rg-devenvironment" "rg-testingenvironment" "rg-stagingenvironment")

for i in "${rgArray[@]}; do
    az group create -g $i -l eastus2
done

```

## Create a scaleset and loadbalancer with Bash and Azure CLI

[Script can be found here](create-vm-lb.sh)

![Script-diagram](create-vm-lb.png)
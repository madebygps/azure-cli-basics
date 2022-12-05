#!/bin/bash

# Variable block
let "randomIdentifier=$RANDOM*$RANDOM"
location="East US 2"
resourceGroup="rg-$randomIdentifier"
tag="create-vm-nlb"
vNet="vnet-lb-$randomIdentifier"
subnet="subnet-lb-$randomIdentifier"
loadBalancerPublicIp="public-ip-lb-$randomIdentifier"
loadBalancer="load-balancer-$randomIdentifier"
frontEndIp="front-end-ip-lb-$randomIdentifier"
backEndPool="backend-pool-lb-$randomIdentifier"
probe80="health-probe-lb-$randomIdentifier"
loadBalancerRuleWeb="lb-rule-port80-$randomIdentifier"
loadBalancerRuleSSH="lb-rule-port22-$randomIdentifier"
networkSecurityGroup="nsg-lb-$randomIdentifier"
networkSecurityGroupRuleSSH="nsg-rule-port22-lb-$randomIdentifier"
networkSecurityGroupRuleWeb="nsg-rule-port80-lb-$randomIdentifier"
nic="nic-lb-$randomIdentifier"
availabilitySet="availablity-set-lb-$randomIdentifier"
vm="vm-lb-$randomIdentifier"
image="UbuntuLTS"
ipSku="Standard"
login="azureuser"

# Create a resource group
echo "Creating $resourceGroup in "$location"..."
az group create --name $resourceGroup --location "$location" --tags $tag

# Create a virtual network and a subnet.
echo "Creating "
az network vnet create --resource-group $resourceGroup --location "$location" --name $vNet --subnet-name $subnet

# Create a public IP address for load balancer.
echo "Creating $loadBalancerPublicIp"
az network public-ip create --resource-group $resourceGroup --name $loadBalancerPublicIp

# Create an Azure Load Balancer.
echo "Creating $loadBalancer with $frontEndIP and $backEndPool"
az network lb create --resource-group $resourceGroup --name $loadBalancer --public-ip-address $loadBalancerPublicIp --frontend-ip-name $frontEndIp --backend-pool-name $backEndPool

# Create an LB probe on port 80.
echo "Creating $probe80 in $loadBalancer"
az network lb probe create --resource-group $resourceGroup --lb-name $loadBalancer --name $probe80 --protocol tcp --port 80

# Create an LB rule for port 80.
echo "Creating $loadBalancerRuleWeb for $loadBalancer"
az network lb rule create --resource-group $resourceGroup --lb-name $loadBalancer --name $loadBalancerRuleWeb --protocol tcp --frontend-port 80 --backend-port 80 --frontend-ip-name $frontEndIp --backend-pool-name $backEndPool --probe-name $probe80

# Create three NAT rules for port 22.
echo "Creating three NAT rules named $loadBalancerRuleSSH"
for i in `seq 1 3`; do
    az network lb inbound-nat-rule create --resource-group $resourceGroup --lb-name $loadBalancer --name $loadBalancerRuleSSH$i --protocol tcp --frontend-port 422$i --backend-port 22 --frontend-ip-name $frontEndIp
done

# Create a network security group
echo "Creating $networkSecurityGroup"
az network nsg create --resource-group $resourceGroup --name $networkSecurityGroup

# Create a network security group rule for port 22.
echo "Creating $networkSecurityGroupRuleSSH in $networkSecurityGroup for port 22"
az network nsg rule create --resource-group $resourceGroup --nsg-name $networkSecurityGroup --name $networkSecurityGroupRuleSSH --protocol tcp --direction inbound --source-address-prefix '*' --source-port-range '*'  --destination-address-prefix '*' --destination-port-range 22 --access allow --priority 1000

# Create a network security group rule for port 80.
echo "Creating $networkSecurityGroupRuleWeb in $networkSecurityGroup for port 22"
az network nsg rule create --resource-group $resourceGroup --nsg-name $networkSecurityGroup --name $networkSecurityGroupRuleWeb --protocol tcp --direction inbound --priority 1001 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 --access allow --priority 2000

# Create three virtual network cards and associate with public IP address and NSG.
echo "Creating three NICs named $nic for $vNet and $subnet"
for i in `seq 1 3`; do
    az network nic create --resource-group $resourceGroup --name $nic$i --vnet-name $vNet --subnet $subnet --network-security-group $networkSecurityGroup --lb-name $loadBalancer --lb-address-pools $backEndPool --lb-inbound-nat-rules $loadBalancerRuleSSH$i
done

# Create an availability set.
echo "Creating $availabilitySet"
az vm availability-set create --resource-group $resourceGroup --name $availabilitySet --platform-fault-domain-count 3 --platform-update-domain-count 3

# Create three virtual machines, this creates SSH keys if not present.
echo "Creating three VMs named $vm with $nic using $image"
for i in `seq 1 3`; do
    az vm create --resource-group $resourceGroup --name $vm$i --availability-set $availabilitySet --nics $nic$i --image $image --public-ip-sku $ipSku  --admin-username $login --generate-ssh-keys --no-wait
done

# List the virtual machines
az vm list --resource-group $resourceGroup

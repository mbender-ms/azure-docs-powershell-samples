if ($login) {
    Clear-AzContext
    Login-AzAccount -UseDeviceAuthentication
}

$location = "<your resource location>"
$rgname = "<your resource group>" # use RG name as "*" to fetch all VNets from all RGs within subscription
$sub = "<your subscription id>"

# select subscription
Set-AzContext -Subscription $sub

# Create 100 VNets using ipamPool
Write-Output "Starting creation of new VNets with IpamPool reference at: " (Get-Date).ToString("HH:mm:ss")
$ipamPoolPrefixAllocation = [PSCustomObject]@{
    Id = "<your ipam pool reference arm id>"
    NumberOfIpAddresses = "8"
}
for ($i = 0; $i -lt 100; $i++) {
    $subnetName = "defaultSubnet"
    $vnetName = "bulk-ipam-vnet-$i"
    $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -IpamPoolPrefixAllocation $ipamPoolPrefixAllocation -DefaultOutboundAccess $false
    $job = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -IpamPoolPrefixAllocation $ipamPoolPrefixAllocation -Subnet $subnet -AsJob
    $job | Wait-Job
    $actual = $job | Receive-Job
}
Write-Output "Starting creation of new VNets with IpamPool reference at: " (Get-Date).ToString("HH:mm:ss")

# fetch all virtual networks from a resource group
$vnetList = Get-AzVirtualNetwork -ResourceGroupName $rgname

# bulk disassociation update
Write-Output "Starting bulk disassociation for existing VNets at: " (Get-Date).ToString("HH:mm:ss")
$ipamPoolPrefixAllocation = $null
for ($i = 0; $i -lt @($vnetList).Count; $i++) {
    $vnetList[$i].AddressSpace.IpamPoolPrefixAllocations = $ipamPoolPrefixAllocation
    foreach ($subnet in $vnetList[$i].Subnets) {
        $subnet.IpamPoolPrefixAllocations = $ipamPoolPrefixAllocation
    }
    $job = Set-AzVirtualNetwork -VirtualNetwork $vnetList[$i] -AsJob
    $job | Wait-Job
    $actual = $job | Receive-Job
}
Write-Output "Starting bulk disassociation for existing VNets at: " (Get-Date).ToString("HH:mm:ss")

# bulk association update
Write-Output "Starting bulk association for existing VNets at: " (Get-Date).ToString("HH:mm:ss")
$ipamPoolPrefixAllocation = [PSCustomObject]@{
    Id = "<your ipam pool reference arm id>"
    NumberOfIpAddresses = "8"
}
for ($i = 0; $i -lt @($vnetList).Count; $i++) {
    $vnetList[$i].AddressSpace.IpamPoolPrefixAllocations = $ipamPoolPrefixAllocation
    foreach ($subnet in $vnetList[$i].Subnets) {
        $subnet.IpamPoolPrefixAllocations = $ipamPoolPrefixAllocation
    }
    $job = Set-AzVirtualNetwork -VirtualNetwork $vnetList[$i] -AsJob
    $job | Wait-Job
    $actual = $job | Receive-Job
}
Write-Output "Finished bulk association for existing VNets at: " (Get-Date).ToString("HH:mm:ss")

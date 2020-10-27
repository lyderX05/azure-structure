# Powershell to Install the Virtual Machine

function Add-VM {
    param (
        [Parameter(Mandatory=$true, HelpMessage="Enter the Resource Group name")]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true, HelpMessage="Enter the Resource Group Location")]
        [string]$ResourceGroupLocation,
        [Parameter(Mandatory=$true, HelpMessage="Enter the VM Username")]
        [string]$Username,
        [Parameter(Mandatory=$true, HelpMessage="Enter the VM Password")]
        [string]$Password,
        [Parameter(Mandatory=$false, HelpMessage="Provide the Tag for Resource")]
        [hashtable]$tags

    )
    try {
        $VmName = "$($ResourceGroupName)VM"
        New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Tag $tags
        $subnet = New-AzVirtualNetworkSubnetConfig -Name "$($VmName)-Subnet" -AddressPrefix "10.1.0.0/24"
        $vnetwork = New-AzVirtualNetwork -Name "$($VmName)-VNetwork" -ResourceGroupName $ResourceGroupName -Location $ResourceGroupLocation -AddressPrefix "10.1.0.0/16" -Subnet $subnet -Tag $tags
        $storagename = $ResourceGroupName.ToLower().Replace("-", "").Replace("_", "").Replace(".", "")
        $storage_account = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName "$($storagename)storage" -Location $ResourceGroupLocation -SkuName "Standard_GRS"

        $publicIP = New-AzPublicIpAddress -Name "$($VmName)-PublicIP" -ResourceGroupName $ResourceGroupName -Location $ResourceGroupLocation -AllocationMethod Dynamic -DomainNameLabel "$($ResourceGroupName)-dns" -Tag $tags

        $network = New-AzNetworkInterface -Name "$($VmName)-Network" -ResourceGroupName $ResourceGroupName -Location $ResourceGroupLocation -SubnetId $vnetwork.Subnets[0].Id -PublicIpAddressId $publicIP.Id

        $VirtualMachine = New-AzVMConfig -VMName $VmName -VMSize "Standard_B1s"
        [securestring]$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)
        $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -DisablePasswordAuthentication -ComputerName $VmName -Credential $Credential 
        $PublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDp9dTwKQi+lcwO8zSDg7GKOh0u0YeuQxPcRKf+zOOME+LJ6tFaB291tob7drlTVBW8Grit/kNMFzUMftgeF24KB8n71+/Uv2ez5HGngifKp2luQqwR6hg2yGZXNra3tICqnN4pS/+b1JEPlUkZW/fqVj41IyrA4f/2KFDICfy83iCVGgP5a4EkE4QOsNabZkLjuDdtPECkpHVEmIAkD6Zo78uYyTM+xsnj/IUbhi03fYhwyRUfHrTJLEtC4wDluEfx2eNzW6uS7yE3CvxbZMwgnrqhfybm+pGArNHFin+DyvSj4vdE2u0fY7VcBQS958GTtZqs1hpjQwtdpg6xoaHu4rmwmUNK4csUofaVS4cCg7K2eCFsuapDEovDZI2qF1VvSeIqM7o2czrozuINat720zP6jYnZ9PkWUJOReX60ndFUU+eelAD+7kUQ4ZvqF2hf95UJwkc06tnfU6nIItjh8whhvbqId2L+Ybq4M+BybJxMCua+slWGq78okwOpDrk= shubham@lyderx"

        $VirtualMachine = Add-AzVMSshPublicKey -VM $VirtualMachine -KeyData $PublicKey -Path "/home/$Username/.ssh/authorized_keys" 
        $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $network.Id
        $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "18.04-LTS" -Version "latest"
        $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name "$($VmName)Disk" -CreateOption "FromImage" -Caching "ReadWrite" -VhdUri "https://$($storage_account.StorageAccountName).blob.core.windows.net/os-disk/$($VmName)Disk.vhd"
        New-AzVM -VM $VirtualMachine -ResourceGroupName $ResourceGroupName -Location $ResourceGroupLocation -Tag $tags -Verbose 
        
    } catch {
        Write-Host "Error Occur During Run $($_.Exception)"
        Remove-AzResourceGroup -Name $ResourceGroupName -Force -Verbose
    }
        
}

Add-VM -ResourceGroupName "unreal-grp" -ResourceGroupLocation "eastus" -Username "azureuser" -Password "Passw0rd!@#$%"
# This file implements IAzureUtility for Azure PowerShell version <= 0.9.8

function Create-AzureResourceGroupIfNotExist
{
    param([string]$resourceGroupName,
          [string]$location)

    Switch-AzureMode AzureResourceManager
    if(-not [string]::IsNullOrEmpty($resourceGroupName))
    {
        try
        {
            Write-Verbose "[Azure Resource Manager]Getting resource group:$resourceGroupName"
            $azureResourceGroup = Get-AzureResourceGroup -ResourceGroupName $resourceGroupName -ErrorAction silentlyContinue
            Write-Verbose "[Azure Resource Manager]Got resource group:$resourceGroupName"
        }
        catch
        {
            #Ignoring the exception
        }

        if(-not $azureResourceGroup -and -not [string]::IsNullOrEmpty($location))
        {
            Write-Verbose "[Azure Resource Manager]Creating resource group $resourceGroupName in $location"
            $azureResourceGroup = New-AzureResourceGroup -Name $resourceGroupName -Location $location -Verbose -ErrorAction Stop
            Write-Host (Get-VstsLocString -Key "ARG_CreatedResourceGroup" -ArgumentList $resourceGroupName)
        }
        return $azureResourceGroup
    }
}

<#function Validation_Deploy-AzureResourceGroup
{
    param([string]$csmFile,
          [string]$csmParametersFile,
          [string]$resourceGroupName,
          [string]$overrideParameters,
          [string]$deploymentMode)

    Switch-AzureMode AzureResourceManager

    $deploymentName = [System.IO.Path]::GetFileNameWithoutExtension($csmFile) + '-' + ((Get-Date).ToUniversalTime()).ToString('yyyyMMdd-HHmm')

    Write-Host "[Azure Resource Manager]Creating resource group deployment with name $deploymentName in validation mode"

    if (!$csmParametersFile)
    {
        $finalCommand = "`$azureResourceGroupDeployment = Test-AzureRMResourceGroupDeployment -ResourceGroupName `"$resourceGroupName`" -Mode `"$deploymentMode`" -TemplateFile `"$csmFile`" $overrideParameters -Verbose -ErrorAction silentlycontinue -ErrorVariable deploymentError"
    }
    else
    {
        $finalCommand = "`$azureResourceGroupDeployment = Test-AzureRMResourceGroupDeployment -ResourceGroupName `"$resourceGroupName`" -Mode `"$deploymentMode`" -TemplateFile `"$csmFile`" -TemplateParameterFile `$csmParametersFile $overrideParameters -Verbose -ErrorAction silentlycontinue -ErrorVariable deploymentError"
    }
    Write-Verbose "$finalCommand"
    Write-Verbose "Validating Deployment Template File"
    Invoke-Expression -Command $finalCommand

    @{"azureResourceGroupDeployment" = $($azureResourceGroupDeployment); "deploymentError" = $($deploymentError)}
}
#>

function Deploy-AzureResourceGroup
{
    param([string]$csmFile,
          [string]$csmParametersFile,
          [string]$resourceGroupName,
          [string]$overrideParameters,
          [string]$deploymentMode)

    Switch-AzureMode AzureResourceManager

    $deploymentName = [System.IO.Path]::GetFileNameWithoutExtension($csmFile) + '-' + ((Get-Date).ToUniversalTime()).ToString('yyyyMMdd-HHmm')

    Write-Host "[Azure Resource Manager]Creating resource group deployment with name $deploymentName"

    if (!$csmParametersFile)
    {
        $finalCommand = "`$azureResourceGroupDeployment = New-AzureRMResourceGroupDeployment -Name `"$deploymentName`" -ResourceGroupName `"$resourceGroupName`" -Mode `"$deploymentMode`" -TemplateFile `"$csmFile`" $overrideParameters -Verbose -ErrorAction silentlycontinue -ErrorVariable deploymentError -force"
    }
    else
    {
        $finalCommand = "`$azureResourceGroupDeployment = New-AzureRMResourceGroupDeployment -Name `"$deploymentName`" -ResourceGroupName `"$resourceGroupName`" -Mode `"$deploymentMode`" -TemplateFile `"$csmFile`" -TemplateParameterFile `$csmParametersFile $overrideParameters -Verbose -ErrorAction silentlycontinue -ErrorVariable deploymentError -force"
    }

    Write-Verbose "$finalCommand"
    Invoke-Expression -Command $finalCommand

    @{"azureResourceGroupDeployment" = $($azureResourceGroupDeployment); "deploymentError" = $($deploymentError)}
}

function Get-AllVMInstanceView
{
    param([string]$resourceGroupName)

    Switch-AzureMode AzureResourceManager
    $VmInstanceViews = @{}
    if (-not [string]::IsNullOrEmpty($resourceGroupName))
    {
        Write-Verbose "[Azure Call]Getting resource group:$resourceGroupName RM virtual machines type resources"
        $azureVMResources = Get-AzureVM -ResourceGroupName $resourceGroupName -ErrorAction Stop -Verbose
        Write-Verbose "[Azure Call]Count of resource group:$resourceGroupName RM virtual machines type resource is $($azureVMResources.Count)"

        if($azureVMResources)
        {
            foreach($resource in $azureVMResources)
            {
                $name = $resource.Name
                Write-Verbose "[Azure Resource Manager]Getting VM $name from resource group $resourceGroupName"
                $vmInstanceView = Get-AzureVM -Name $resource.Name -ResourceGroupName $resourceGroupName -Status -Verbose -ErrorAction Stop
                Write-Verbose "[Azure Resource Manager]Got VM $name from resource group $resourceGroupName"
                $VmInstanceViews.Add($name, $vmInstanceView)
            }
        }
    }

    return $VmInstanceViews
}

function Start-Machine
{
    param([string]$resourceGroupName,
          [string]$machineName)

    Switch-AzureMode AzureResourceManager
    if(-not [string]::IsNullOrEmpty($resourceGroupName) -and -not [string]::IsNullOrEmpty($machineName))
    {
        Write-Host (Get-VstsLocString -Key "ARG_StartingMachine" -ArgumentList $machineName)
        $response = Start-AzureVM -Name $machineName -ResourceGroupName $resourceGroupName -ErrorAction Stop -Verbose
        Write-Host (Get-VstsLocString -Key "ARG_StartedMachine" -ArgumentList $machineName)
    }
    return $response
}

function Stop-Machine
{
    param([string]$resourceGroupName,
          [string]$machineName)

    Switch-AzureMode AzureResourceManager
    if(-not [string]::IsNullOrEmpty($resourceGroupName) -and -not [string]::IsNullOrEmpty($machineName))
    {
        Write-Host (Get-VstsLocString -Key "ARG_StoppingMachine" -ArgumentList $machineName)
        $response = Stop-AzureVM -Name $machineName -ResourceGroupName $resourceGroupName -Force -ErrorAction Stop -Verbose
        Write-Host (Get-VstsLocString -Key "ARG_StoppedMachine" -ArgumentList $machineName)
    }
    return $response
}

function Delete-Machine
{
    param([string]$resourceGroupName,
          [string]$machineName)

    Switch-AzureMode AzureResourceManager
    if(-not [string]::IsNullOrEmpty($resourceGroupName) -and -not [string]::IsNullOrEmpty($machineName))
    {
        Write-Host (Get-VstsLocString -Key "ARG_DeletingMachine" -ArgumentList $machineName)
        $response = Remove-AzureVM -Name $machineName -ResourceGroupName $resourceGroupName -Force -ErrorAction Stop -Verbose
        Write-Host (Get-VstsLocString -Key "ARG_DeletedMachine" -ArgumentList $machineName)
    }
    return $response
}

function Delete-ResourceGroup
{
    param([string]$resourceGroupName)

    Switch-AzureMode AzureResourceManager
    if(-not [string]::IsNullOrEmpty($resourceGroupName))
    {
        Write-Host (Get-VstsLocString -Key "ARG_DeletingResourceGroup" -ArgumentList $resourceGroupName)
        Remove-AzureResourceGroup -Name $resourceGroupName -Force -ErrorAction Stop -Verbose
        Write-Host (Get-VstsLocString -Key "ARG_DeletedResourceGroup" -ArgumentList $resourceGroupName)
    }
}

function Get-AzureRMVMsInResourceGroup
{
    param([string]$resourceGroupName)

    Switch-AzureMode AzureResourceManager
    If(-not [string]::IsNullOrEmpty($resourceGroupName))
    {
        try
        {
            Write-Verbose "[Azure Call]Getting resource group:$resourceGroupName RM virtual machines type resources"
            $azureVMResources = Get-AzureVM -ResourceGroupName $resourceGroupName -ErrorAction Stop -Verbose
            Write-Verbose "[Azure Call]Count of resource group:$resourceGroupName RM virtual machines type resource is $($azureVMResources.Count)"
        }
        catch [Microsoft.WindowsAzure.Commands.Common.ComputeCloudException],[System.MissingMethodException], [System.Management.Automation.PSInvalidOperationException], [Hyak.Common.CloudException]
        {
            Write-Verbose $_.Exception.Message
            throw (Get-VstsLocString -Key "ARG_EnsureResourceGroupWithMachine" -ArgumentList $resourceGroupName)
        }
        catch
        {
            throw
        }

        return $azureVMResources
    }
}

function Get-AzureRMResourceGroupResourcesDetails
{
    param([string]$resourceGroupName,
          [object]$azureRMVMResources)

    Switch-AzureMode AzureResourceManager
    [hashtable]$ResourcesDetails = @{}
    [hashtable]$LoadBalancerDetails = @{}
    if(-not [string]::IsNullOrEmpty($resourceGroupName) -and $azureRMVMResources)
    {
        Write-Verbose "[Azure Call]Getting network interfaces in resource group $resourceGroupName"
        $networkInterfaceResources = Get-AzureNetworkInterface -ResourceGroupName $resourceGroupName -ErrorAction Stop -Verbose
        Write-Verbose "[Azure Call]Got network interfaces in resource group $resourceGroupName"
        $ResourcesDetails.Add("networkInterfaceResources", $networkInterfaceResources)

        Write-Verbose "[Azure Call]Getting public IP Addresses in resource group $resourceGroupName"
        $publicIPAddressResources = Get-AzurePublicIpAddress -ResourceGroupName $resourceGroupName -ErrorAction Stop -Verbose
        Write-Verbose "[Azure Call]Got public IP Addresses in resource group $resourceGroupName"
        $ResourcesDetails.Add("publicIPAddressResources", $publicIPAddressResources)

        Write-Verbose "[Azure Call]Getting load balancers in resource group $resourceGroupName"
        $lbGroup = Get-AzureLoadBalancer -ResourceGroupName $resourceGroupName -ErrorAction Stop -Verbose
        Write-Verbose "[Azure Call]Got load balancers in resource group $resourceGroupName"

        if($lbGroup)
        {
            foreach($lb in $lbGroup)
            {
                $lbDetails = @{}
                Write-Verbose "[Azure Call]Getting load balancer in resource group $resourceGroupName"
                $loadBalancer = Get-AzureLoadBalancer -Name $lb.Name -ResourceGroupName $resourceGroupName -ErrorAction Stop -Verbose
                Write-Verbose "[Azure Call]Got load balancer in resource group $resourceGroupName"

                Write-Verbose "[Azure Call]Getting LoadBalancer Frontend Ip Config"
                $frontEndIPConfigs = Get-AzureLoadBalancerFrontendIpConfig -LoadBalancer $loadBalancer -ErrorAction Stop -Verbose
                Write-Verbose "[Azure Call]Got LoadBalancer Frontend Ip Config"

                Write-Verbose "[Azure Call]Getting Azure LoadBalancer Inbound NatRule Config"
                $inboundRules = Get-AzureLoadBalancerInboundNatRuleConfig -LoadBalancer $loadBalancer -ErrorAction Stop -Verbose
                Write-Verbose "[Azure Call]Got Azure LoadBalancer Inbound NatRule Config"

                $lbDetails.Add("frontEndIPConfigs", $frontEndIPConfigs)
                $lbDetails.Add("inboundRules", $inboundRules)
                $LoadBalancerDetails.Add($lb.Name, $lbDetails)
            }

            $ResourcesDetails.Add("loadBalancerResources", $LoadBalancerDetails)
        }
    }

    return $ResourcesDetails
}

function Get-AzureClassicVMsInResourceGroup
{
    param([string]$resourceGroupName)

    Switch-AzureMode AzureServiceManagement
    if(-not [string]::IsNullOrEmpty($resourceGroupName))
    {
        Write-Verbose "[Azure Call]Getting resource group:$resourceGroupName classic virtual machines type resources"
        $azureClassicVMResources = Get-AzureVM -ServiceName $resourceGroupName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        Write-Verbose "[Azure Call]Count of resource group:$resourceGroupName classic virtual machines type resource is $($azureClassicVMResources.Count)"
    }

    return $azureClassicVMResources
}

function Get-AzureClassicVMsConnectionDetailsInResourceGroup
{
    param([string]$resourceGroupName,
          [object]$azureClassicVMResources)

    Switch-AzureMode AzureServiceManagement
    [hashtable]$classicVMsDetails = @{}
    if(-not [string]::IsNullOrEmpty($resourceGroupName) -and $azureClassicVMResources)
    {
        Write-Verbose "Trying to get FQDN and WinRM HTTPS Port for the classic azureVM resources from resource Group $resourceGroupName"
        foreach($azureClassicVm in $azureClassicVMResources)
        {
            $resourceName = $azureClassicVm.Name

            Write-Verbose "[Azure Call]Getting classic virtual machine:$resourceName details in resource group $resourceGroupName"
            $azureClassicVM = Get-AzureVM -ServiceName $resourceGroupName -Name $resourceName -ErrorAction Stop -Verbose
            Write-Verbose "[Azure Call]Got classic virtual machine:$resourceName details in resource group $resourceGroupName"
            
            Write-Verbose "[Azure Call]Getting classic virtual machine:$resourceName endpoint with localport 5986 in resource group $resourceGroupName"
            $azureClassicVMEndpoint = $azureClassicVM | Get-AzureEndpoint | Where-Object {$_.LocalPort -eq '5986'}
            Write-Verbose "[Azure Call]Got classic virtual machine:$resourceName endpoint with localport 5986 in resource group $resourceGroupName"

            $fqdnUri = [System.Uri]$azureClassicVM.DNSName
            $resourceFQDN = $fqdnUri.Host

            $resourceWinRmHttpsPort = $azureClassicVMEndpoint.Port
            if([string]::IsNullOrWhiteSpace($resourceWinRMHttpsPort))
            {
                Write-Verbose "Defaulting WinRMHttpsPort of $resourceName to 5986"
                $resourceWinRMHttpsPort = "5986"
            }

            Write-Verbose "FQDN value for resource $resourceName is $resourceFQDN"
            Write-Verbose "WinRM HTTPS Port for resource $resourceName is $resourceWinRmHttpsPort"

            $resourceProperties = @{}
            $resourceProperties.Name = $resourceName
            $resourceProperties.fqdn = $resourceFQDN
            $resourceProperties.winRMHttpsPort = $resourceWinRmHttpsPort
            $classicVMsDetails.Add($resourceName, $resourceProperties)
        }
    }

    return $classicVMsDetails
}

function Get-AzureMachineStatus
{
    param([string]$resourceGroupName,
          [string]$name)

    Switch-AzureMode AzureResourceManager
    if(-not [string]::IsNullOrEmpty($resourceGroupName) -and -not [string]::IsNullOrEmpty($name))
    {
        Write-Host (Get-VstsLocString -Key "ARG_GettingVmStatus" -ArgumentList $name)
        $status = Get-AzureVM -ResourceGroupName $resourceGroupName -Name $name -Status -ErrorAction Stop -Verbose
        Write-Host (Get-VstsLocString -Key "ARG_GotVmStatus" -ArgumentList $name)
    }
	
    return $status
}

function Get-AzureMachineCustomScriptExtension
{
    param([string]$resourceGroupName,
          [string]$vmName,
          [string]$name)

    Switch-AzureMode AzureResourceManager
    if(-not [string]::IsNullOrEmpty($resourceGroupName) -and -not [string]::IsNullOrEmpty($vmName))
    {
        Write-Host (Get-VstsLocString -Key "ARG_GettingExtensionStatus" -ArgumentList $name, $vmName)
        $customScriptExtension = Get-AzureVMCustomScriptExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $name -ErrorAction Stop -Verbose     
        Write-Host (Get-VstsLocString -Key "ARG_GotExtensionStatus" -ArgumentList $name, $vmName)
    }
	
    return $customScriptExtension
}

function Set-AzureMachineCustomScriptExtension
{
    param([string]$resourceGroupName,
          [string]$vmName,
          [string]$name,
          [string[]]$fileUri,
          [string]$run,
          [string]$argument,
          [string]$location)

    Switch-AzureMode AzureResourceManager
    if(-not [string]::IsNullOrEmpty($resourceGroupName) -and -not [string]::IsNullOrEmpty($vmName) -and -not [string]::IsNullOrEmpty($name))
    {
        Write-Host (Get-VstsLocString -Key "ARG_SettingExtension" -ArgumentList $name, $vmName)
        $result = Set-AzureVMCustomScriptExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $name -FileUri $fileUri  -Run $run -Argument $argument -Location $location -ErrorAction Stop -Verbose		
        Write-Host (Get-VstsLocString -Key "ARG_SetExtension" -ArgumentList $name, $vmName)
    }
	
    return $result
}

function Remove-AzureMachineCustomScriptExtension
{
    param([string]$resourceGroupName,
          [string]$vmName,
          [string]$name)

    Switch-AzureMode AzureResourceManager
    if(-not [string]::IsNullOrEmpty($resourceGroupName) -and -not [string]::IsNullOrEmpty($vmName) -and -not [string]::IsNullOrEmpty($name))
    {
        Write-Host (Get-VstsLocString -Key "ARG_RemovingExtension" -ArgumentList $name, $vmName)
        $response = Remove-AzureVMCustomScriptExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name $name -Force -ErrorAction SilentlyContinue -Verbose		
        Write-Host (Get-VstsLocString -Key "ARG_RemovedExtension" -ArgumentList $name, $vmName)
    }

    return $response
}

function Get-NetworkSecurityGroups
{
     param([string]$resourceGroupName,
           [string]$vmId)

    $securityGroups = New-Object System.Collections.Generic.List[System.Object]

    Switch-AzureMode AzureResourceManager
    if(-not [string]::IsNullOrEmpty($resourceGroupName) -and -not [string]::IsNullOrEmpty($vmId))
    {
        Write-Verbose "[Azure Call]Getting network interfaces in resource group $resourceGroupName for vm $vmId"
        $networkInterfaces = Get-AzureNetworkInterface -ResourceGroupName $resourceGroupName | Where-Object { $_.VirtualMachine.Id -eq $vmId }
        Write-Verbose "[Azure Call]Got network interfaces in resource group $resourceGroupName"
        
        if($networkInterfaces)
        {
            $noOfNics = $networkInterfaces.Count
            Write-Verbose "Number of network interface cards present in the vm: $noOfNics"

            foreach($networkInterface in $networkInterfaces)
            {
                $networkSecurityGroupEntry = $networkInterface.NetworkSecurityGroup
                if($networkSecurityGroupEntry)
                {
					$nsId = $networkSecurityGroupEntry.Id
					Write-Verbose "Network Security Group Id: $nsId"
					
                    $securityGroupName = $nsId.Split('/')[-1]
                    $sgResourceGroup = $nsId.Split('/')[4]                    
                    Write-Verbose "Security Group name is $securityGroupName and the related resource group $sgResourceGroup"

                    # Get the network security group object
                    Write-Verbose "[Azure Call]Getting network security group $securityGroupName in resource group $sgResourceGroup"
                    $securityGroup = Get-AzureNetworkSecurityGroup -ResourceGroupName $sgResourceGroup -Name $securityGroupName                    
                    Write-Verbose "[Azure Call]Got network security group $securityGroupName in resource group $sgResourceGroup"

                    $securityGroups.Add($securityGroup)
                }
            }
        }
        else
        {
            throw (Get-VstsLocString -Key "ARG_NetworkInterfaceNotFound" -ArgumentList $vmid , $resourceGroupName)
        }
    }
    else
    {
        throw (Get-VstsLocString -Key "ARG_EmptyRGName")
    }
    
    return $securityGroups
}

function Add-NetworkSecurityRuleConfig
{
    param([string]$resourceGroupName,
          [object]$securityGroups,
          [string]$ruleName,
          [string]$rulePriotity,
          [string]$winrmHttpsPort)

    Switch-AzureMode AzureResourceManager
    if($securityGroups.Count -gt 0)
    {
        foreach($securityGroup in $securityGroups)
        {
            $securityGroupName = $securityGroup.Name
            try
            {
                $winRMConfigRule = $null

                Write-Verbose "[Azure Call]Getting network security rule config $ruleName under security group $securityGroupName"
                $winRMConfigRule = Get-AzureNetworkSecurityRuleConfig -NetworkSecurityGroup $securityGroup -Name $ruleName -EA SilentlyContinue
                Write-Verbose "[Azure Call]Got network security rule config $ruleName under security group $securityGroupName"
            }
            catch
            { 
                #Ignore the exception
            }

            # Add the network security rule if it doesn't exists
            if(-not $winRMConfigRule)                                                              
            {           
                $maxRetries = 3
                for($retryCnt=1; $retryCnt -le $maxRetries; $retryCnt++)
                {
                    try
                    {
                        Write-Verbose "[Azure Call]Adding inbound network security rule config $ruleName with priority $rulePriotity for port $winrmHttpsPort under security group $securityGroupName"
                        $securityGroup = Add-AzureNetworkSecurityRuleConfig -NetworkSecurityGroup $securityGroup -Name $ruleName -Direction Inbound -Access Allow -SourceAddressPrefix '*' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange $winrmHttpsPort -Protocol * -Priority $rulePriotity
                        Write-Verbose "[Azure Call]Added inbound network security rule config $ruleName with priority $rulePriotity for port $winrmHttpsPort under security group $securityGroupName"                         

                        Write-Verbose "[Azure Call]Setting the azure network security group"
                        $result = Set-AzureNetworkSecurityGroup -NetworkSecurityGroup $securityGroup
                        Write-Verbose "[Azure Call]Set the azure network security group"
                    }
                    catch
                    {
                        Write-Verbose "Failed to add inbound network security rule config $ruleName with priority $rulePriotity for port $winrmHttpsPort under security group $securityGroupName : $_.Exception.Message"
                            
                        $newPort = [convert]::ToInt32($rulePriotity, 10) + 50;
                        $rulePriotity = $newPort.ToString()

                        Write-Verbose "[Azure Call]Getting network security group $securityGroupName in resource group $resourceGroupName"
                        $securityGroup = Get-AzureNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $securityGroupName
                        Write-Verbose "[Azure Call]Got network security group $securityGroupName in resource group $resourceGroupName"
                        

                        if($retryCnt -eq $maxRetries)
                        {
                            throw $_
                        }

                        continue
                    }           
                        
                    Write-Verbose "Successfully added the network security group rule $ruleName with priority $rulePriotity for port $winrmHttpsPort"
                    break             
                }
            }
        }
    }
}

# Used only in test code
function Remove-NetworkSecurityRuleConfig
{
    param([object] $securityGroups,
          [string] $ruleName)

    Switch-AzureMode AzureResourceManager
    foreach($securityGroup in $securityGroups)
    {
        Write-Verbose "[Azure Call]Removing the Rule $ruleName"
        $result = Remove-AzureNetworkSecurityRuleConfig -NetworkSecurityGroup $securityGroup -Name $ruleName | Set-AzureNetworkSecurityGroup
        Write-Verbose "[Azure Call]Removed the Rule $ruleName"
    }
}

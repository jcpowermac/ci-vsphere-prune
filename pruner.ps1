#!/usr/bin/pwsh

Set-PowerCLIConfiguration -InvalidCertificateAction:Ignore -Confirm:$false

try {
    $terraform = Get-Content -Raw -Path /var/run/secrets/ci.openshift.io/cluster-profile/vmc.secret.auto.tfvars
    $terraform -match 'vsphere_password\s=\s"(?<password>[\S]+)"'
    $password = $Matches.password
    $terraform -match 'vsphere_user\s=\s"(?<username>[\S]+)"'
    $username = $Matches.username
    $server = "vcenter.sddc-44-236-21-251.vmwarevmc.com"
    Connect-VIServer -Server $server -User $username -Password $password
}
catch {
    Write-Error "Unable to connect to vCenter: "
    Write-Error $_
    exit
}

$rps = Get-ResourcePool | Where-Object { $_.Name -match 'ci' }

foreach ($rp in $rps) {

    $folder = @{}
    $remove = $False
    [array]$rpvms = $rp | Get-VM

    if ($rpvms.Length -gt 0) {
        foreach ($vm in $rpvms) {
            $remove = $True
            # first check how long the vm has been around
            $createdTime = (Get-VIEvent $vm | Sort-Object createdTime | Select-Object -first 1).createdTime
            Write-Host "Checking when virtual machine: $($vm.Name) was created: $($createdTime)"
            $totalHours = (New-TimeSpan -Start $createdTime.ToUniversalTime() -End (Get-Date).ToUniversalTime()).TotalHours
            if( $totalHours -lt 5 ) {
                Write-Host "Continuing..."
                $remove = $False
                continue
            }

            $folder[$vm.Folder] = ""
            $vm | Stop-VM -Confirm:$false
            $vm | Remove-VM -DeletePermanently:$true -Confirm:$false
        }
        if($remove) {
                Remove-Folder -Folder $folder.Keys -Confirm:$false -DeletePermanently:$true
        }
    }

    if($remove) {
      $rp | Remove-ResourcePool -Confirm:$false
    }
}

$vms = get-vm | Where-Object {$_.Name -match 'ci-' }

foreach ($vm in $vms) {
            $createdTime = (Get-VIEvent $vm | Sort-Object createdTime | Select-Object -first 1).createdTime
            Write-Host "Checking when virtual machine: $($vm.Name) was created: $($createdTime)"
            $totalHours = (New-TimeSpan -Start $createdTime.ToUniversalTime() -End (Get-Date).ToUniversalTime()).TotalHours
            if( $totalHours -lt 4 ) {
                Write-Host "Continuing..."
                continue
            }

            $vm | Stop-VM -Confirm:$false
            $vm | Remove-VM -DeletePermanently:$true -Confirm:$false
}

Disconnect-VIServer -Confirm:$false -Force:$true

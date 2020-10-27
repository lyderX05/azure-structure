# Run Script as Administrator 
# Moudle Az - latest
function Add-Az-Method-Machine {
    param (
        [Parameter(Mandatory=$true,
        HelpMessage="Enter the VM name")]
        [string]$VmName
    )

    if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
        Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
          'Az modules installed at the same time is not supported.')
    } else {
        Install-Module -Name Az -AllowClobber -Scope CurrentUser -AcceptLicense 
    }
    Connect-AzAccount
}

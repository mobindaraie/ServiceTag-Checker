# Azure Service Tag Checker

This repository contains a PowerShell script that retrieves the Azure service tag(s) for a given IP address. The script uses the `Get-AzNetworkServiceTag` cmdlet to retrieve service tags and their address prefixes, and then tests if the IP address falls within any of the CIDR ranges.

## Prerequisites

- PowerShell 5.1 or later
- Azure PowerShell module (`Az`)

## Installation

1. Install the Azure PowerShell module if you haven't already:

  ```powershell
  Install-Module -Name Az -AllowClobber -Scope CurrentUser
  ```

2. Clone this repository or download the script `AzureServiceTagByIP.ps1`.

## Usage

1. Open PowerShell and navigate to the directory containing the script.
2. Run the script with the required parameters:

  ```powershell
  .\AzureServiceTagByIP.ps1 -IPAddress <YourIPAddress> [-Location <AzureLocation>]
  ```

  Replace `<YourIPAddress>` with the IP address you want to check. The `<AzureLocation>` parameter is optional.

  Please note that the Azure region information you specify will be used as a reference for version (not as a filter based on location). For example, even if you specify `-Location eastus2` you will get the list of service tags with prefix details across all regions but limited to the cloud that your subscription belongs to (i.e. Public, US government, China or Germany).

## Example

```powershell
$targetIP = "168.62.0.1"
$location = "eastus2"
$result = Get-AzureServiceTagByIP -IPAddress $targetIP -Location $location

if ($result) {
  Write-Host "IP $targetIP belongs to the following service tag(s):"
  $result | ForEach-Object {
    [PSCustomObject]@{
      Name            = $_.Name
      AddressPrefixes = ($_.Properties.AddressPrefixes -join ", ")
    }
  } | Format-Table Name, AddressPrefixes
}
else {
  Write-Host "IP $targetIP was not found in any service tag's address prefixes."
```

## Functions

### Test-IPInCIDR

Tests if an IP address falls within a given CIDR range.

#### Parameters

- `IPAddress`: The IP address to check.
- `CIDR`: The CIDR range to check against.

### Get-AzureServiceTagByIP

Retrieves the Azure service tag(s) for a given IP address.

#### Parameters

- `IPAddress`: The IP address to check against the Azure service tags.
- `Location`: will be used as a reference for version (not as a filter based on location). For example, even if you specify -Location eastus2 you will get the list of service tags with prefix details across all regions but limited to the cloud that your subscription belongs to (i.e. Public, US government, China or Germany)..

## License

This project is licensed under the MIT License.

<#
.SYNOPSIS
  Retrieves the Azure service tag(s) for a given IP address.

.DESCRIPTION
  This script defines a function `Get-AzureServiceTagByIP` that checks which Azure service tag(s) a given IP address belongs to. It uses the `Get-AzNetworkServiceTag` cmdlet to retrieve service tags and their address prefixes, and then tests if the IP address falls within any of the CIDR ranges.

.PARAMETER IPAddress
  The IP address to check against the Azure service tags.

.PARAMETER Location
  The Azure location to retrieve the service tags from.

.EXAMPLE
  $targetIP = "168.62.0.1"
  $location = "eastus2"
  $result = Get-AzureServiceTagByIP -IPAddress $targetIP -Location $location

  if ($result) {
    Write-Host "IP $targetIP belongs to the following service tag(s):"
    $result | Format-Table Name, "Address Prefixes"
  }
  else {
    Write-Host "IP $targetIP was not found in any service tag's address prefixes."
#>
function Test-IPInCIDR {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$IPAddress,
    [Parameter(Mandatory)]
    [string]$CIDR
  )

  $parts = $CIDR.Split('/')
  $networkAddress = $parts[0]
  $prefixLength = [int]$parts[1]

  $ipBytes = [System.Net.IPAddress]::Parse($IPAddress).GetAddressBytes()
  $networkBytes = [System.Net.IPAddress]::Parse($networkAddress).GetAddressBytes()

  if ($ipBytes.Length -ne $networkBytes.Length) {
    return $false
  }

  $maskBytes = New-Object byte[] ($ipBytes.Length)
  for ($i = 0; $i -lt $maskBytes.Length; $i++) {
    if ($prefixLength -ge 8) {
      $maskBytes[$i] = 255
      $prefixLength -= 8
    }
    else {
      $maskBytes[$i] = [byte](256 - [math]::Pow(2, (8 - $prefixLength)))
      $prefixLength = 0
    }
  }

  for ($i = 0; $i -lt $ipBytes.Length; $i++) {
    if (($ipBytes[$i] -band $maskBytes[$i]) -ne ($networkBytes[$i] -band $maskBytes[$i])) {
      return $false
    }
  }
  return $true
}

function Get-AzureServiceTagByIP {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidatePattern('^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$')]
    [string]$IPAddress,
    [Parameter(Mandatory)]
    [string]$Location
  )

  $serviceTags = $null
  $retries = 0
  $maxRetries = 2

  while ($null -eq $serviceTags -and $retries -lt $maxRetries) {
    try {
      $serviceTags = Get-AzNetworkServiceTag -Location $Location -ErrorAction Stop
    }
    catch {
      if ($_.Exception.Message -like "*Connect-AzAccount*") {
        Write-Host "Azure connection issue detected. Attempting to log in again. (Attempt $($retries + 1) of $maxRetries)"
        Connect-AzAccount
      }
      else {
        Write-Error "Failed to retrieve service tags for location '$Location'. Error: $_"
        return
      }
      $retries++
    }
  } 

  $matches = @()
  foreach ($tag in $serviceTags.Values) {
    foreach ($cidr in $tag.Properties.AddressPrefixes) {
      if (Test-IPInCIDR -IPAddress $IPAddress -CIDR $cidr) {
        $matches += $tag
        break
      }
    }
  }
  return $matches
}

# Example usage:
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
}

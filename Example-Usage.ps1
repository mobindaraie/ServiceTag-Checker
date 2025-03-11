. .\Get-AzureServiceTagByIP.ps1

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
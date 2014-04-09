Start-Transcript "WINS_Enabled_Servers.log"

$ErrorActionPreference = "SilentlyContinue"

# Add QAD Snapin
Add-PSSnapin Quest.ActiveRoles.ADManagement

# Collect machine names
$servers = Get-QADComputer -SizeLimit 0 | select name,osname
$servers = $servers | where {$_.osname -like "*server*" -or $_.osname -like "Windows NT*"}
$servers = $servers | select name

# Connect to servers and do work
foreach ($server in $servers) {
    $server_name = $server.name
    write-host "Checking $server_name"
    # Determine if server has WINS setup
    $ip_info = gwmi -Class "Win32_NetworkAdapterConfiguration" -ComputerName "$server_name" -Filter IPEnabled=True
    if($? -ne $true) { write-host "Unable to connect to $server_name" }
    $wins_primary = $ip_info.WINSPrimaryServer
    $wins_secondary = $ip_info.WINSSecondaryServer
    if($wins_primary -ne $null -or $wins_secondary -ne $null) {
        write-host "$server_name,$wins_primary,$wins_secondary"
        }
    write-host "Finished checking $server_name"
    }

Stop-Transcript

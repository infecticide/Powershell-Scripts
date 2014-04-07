$ErrorActionPreference = "silentlycontinue"
# Setup CSV
"Server,Last Boot Up Time,Uptime in Hours" | out-file -file "Server Uptime on $ENV:USERDOMAIN domain.csv"
$computer_array = $null

# Get list of all computer object in current domain
$objDomain = New-Object System.DirectoryServices.DirectoryEntry
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.PageSize = 10000
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = ("(objectCategory=computer)")
$objSearcher.PropertiesToLoad.Add("name") | out-null
$colResults = $objSearcher.FindAll()
foreach ($objResult in $colResults) {
    $objComputer = $objResult.Properties
    $computer_array += $objComputer.name
    }

# Query Servers
foreach ($machine in $computer_array) {
    Write-Output "Checking $machine"
    # Is machine in DNS?
    nslookup $machine | out-null
    if($? -eq $false) {
        "$machine,not found in DNS" | Out-File -file "Server Uptime on $ENV:USERDOMAIN domain.csv" -Append
        Write-Output "Finished checking $machine"
        continue
        }
    # Is machine reachable?
    ping -n 1 $machine | out-null
    if($? -eq $false) {
        "$machine,not reachable" | Out-File -file "Server Uptime on $ENV:USERDOMAIN domain.csv" -Append
        Write-Output "Finished checking $machine"
        continue
        }
    # Get uptime
    $wmi = Get-WmiObject -ComputerName $machine -Class Win32_OperatingSystem
    $lastbootuptime = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
    $difference = ($wmi.ConvertToDateTime($wmi.LocalDateTime) – $wmi.ConvertToDateTime($wmi.LastBootUpTime))
    $hours_up = $difference.TotalHours
    # Output to CSV
    "$machine,$lastbootuptime,$hours_up" | out-file -File "Server Uptime on $ENV:USERDOMAIN domain.csv" -Append
}

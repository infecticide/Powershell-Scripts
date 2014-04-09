Start-Transcript uptime_transcript.log

# Setup CSV
"sep=," | Out-File -file "Server Uptime on $ENV:USERDOMAIN domain.csv"
"Server,Last Boot Up Time,Uptime in Hours" | out-file -file "Server Uptime on $ENV:USERDOMAIN domain.csv" -Append

# Clear variables
$computer_array = $null

# Get list of all computer object in current domain
Write-Host "Getting server list from domain $ENV:USERDOMAIN"
$objDomain = New-Object System.DirectoryServices.DirectoryEntry
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.PageSize = 10000
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = ("(OperatingSystem=Window*Server*)")
$objSearcher.PropertiesToLoad.Add("name") | Out-Null
$colResults = $objSearcher.FindAll()
foreach ($objResult in $colResults) {
    $objComputer = $objResult.Properties
    $computer_array += $objComputer.name
    }

$computercount = $computer_array.Count
write-host "$computercount computers found"

# Query Servers
foreach ($machine in $computer_array) {
    Write-Output "$machine - Looking up hostname"
    # Is machine in DNS?
    $ErrorActionPreference = "silentlycontinue"
    $lookup = [System.Net.Dns]::GetHostAddresses($machine)
    $ErrorActionPreference = "continue"
    if($lookup -eq $null) {
        "$machine,not found in DNS" | Out-File -file "Server Uptime on $ENV:USERDOMAIN domain.csv" -Append
        $computercount = $computercount - 1
        Write-Host "$machine - Hostname not found" -ForegroundColor Red
        Write-Host "$computercount computers left to check"
        continue
        } ELSE {
        Write-Host "$machine - DNS lookup successful" -ForegroundColor Green
        } # End nslookup IF
    # Is machine reachable?
    if(test-connection -ComputerName $machine -Count 1 -Quiet) {
        Write-Host "$machine - is reachable" -ForegroundColor Green
        } ELSE {
        "$machine,not reachable" | Out-File -file "Server Uptime on $ENV:USERDOMAIN domain.csv" -Append
        $computercount = $computercount - 1
        Write-Host "$machine - did not respond" -ForegroundColor Red
        Write-Host "$computercount computers left to check"
        continue
        }
    # Get uptime
    $wmi = Get-WmiObject -ComputerName $machine -Class Win32_OperatingSystem -ea silentlycontinue
    if($? -eq $false) {
        "$machine,WMI encountered an error" | Out-File -File "Server Uptime on $ENV:USERDOMAIN domain.csv" -Append
        $computercount = $computercount - 1
        Write-Host "$machine - encountered an error in WMI" -ForegroundColor Red
        Write-Host "$computercount computers left to check"
        continue
        } ELSE {
        Write-Host "$machine - queried successfully" -ForegroundColor Green
        } # End WMI IF
    $lastbootuptime = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
    $difference = ($wmi.ConvertToDateTime($wmi.LocalDateTime) – $wmi.ConvertToDateTime($wmi.LastBootUpTime))
    $hours_up = $difference.TotalHours
    # Output to CSV
    "$machine,$lastbootuptime,$hours_up" | Out-File -File "Server Uptime on $ENV:USERDOMAIN domain.csv" -Append
    $computercount = $computercount - 1
    Write-Host "$computercount computers left to check"
} # End ForEach $machine IF
Stop-Transcript

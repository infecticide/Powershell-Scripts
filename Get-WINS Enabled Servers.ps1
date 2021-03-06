Start-Transcript "WINS Enabled Servers in $ENV:USERDOMAIN.log"

# Clear variables
$computers = $null

# Setup CSV
"sep=," | Out-File -file "WINS Enabled Servers in $ENV:USERDOMAIN.csv"
"Hostname" | Out-File -File "WINS Enabled Servers in $ENV:USERDOMAIN.csv" -Append

# Get list of servers in AD
$objDomain = New-Object System.DirectoryServices.DirectoryEntry
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.PageSize = 100000
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = ("(OperatingSystem=Windows*Server*)")
$objSearcher.PropertiesToLoad.Add("name") | out-null
$colResults = $objSearcher.FindAll()
foreach ($objResult in $colResults) {
    $objComputer = $objResult.Properties
    $computers += $objComputer.name
    }
$computercount = $computers.Count

Write-Host "$computercount computers found"

foreach ($machine in $computers) {
    Write-Host "$machine - Looking up hostname"
    # Is machine in DNS?
    $lookup = $NULL
    $ErrorActionPreference = "silentlycontinue"
    $lookup = [System.Net.Dns]::GetHostAddresses("$machine")
    $ErrorActionPreference = "continue"
    if($lookup -eq $NULL) {
        "$machine,not found in DNS" | Out-File -file "WINS Enabled Servers in $ENV:USERDOMAIN.csv" -Append
        $computercount = $computercount - 1
        Write-Host "$machine - Hostname not found" -ForegroundColor Red
        Write-Host "$computercount computers left to check"
        continue
        } ELSE {
        Write-Host "$machine - DNS lookup successful" -ForegroundColor Green
        } # End DNS IF
    # Is machine reachable?
    if(Test-Connection -ComputerName $machine -Count 1 -Quiet) {
        Write-Host "$machine - is reachable" -ForegroundColor Green
        } ELSE {
        "$machine,not reachable" | Out-File -file "WINS Enabled Servers in $ENV:USERDOMAIN.csv" -Append
        $computercount = $computercount - 1
        Write-Host "$machine - did not respond" -ForegroundColor Red
        Write-Host "$computercount computers left to check"
        continue
        } # End ICMP IF
    # Determine if server has WINS setup
    $ip_info = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" -ComputerName "$machine" -Filter IPEnabled=True -ea silentlycontinue
    if($? -eq $false) {
        "$machine,WMI encountered an error" | Out-File -File "WINS Enabled Servers in $ENV:USERDOMAIN.csv" -Append
        $computercount = $computercount - 1
        Write-Host "$machine - encountered an error in WMI" -ForegroundColor Red
        Write-Host "$computercount computers left to check"
        continue
        } ELSE {
        Write-Host "$machine - queried successfully" -ForegroundColor Green
        } # End WMI IF
    $wins_primary = $ip_info.WINSPrimaryServer
    $wins_secondary = $ip_info.WINSSecondaryServer
    if($wins_primary -eq $NULL -and $wins_secondary -eq $NULL) {
        "$machine,WINS not enabled" | Out-File -file "WINS Enabled Servers in $ENV:USERDOMAIN.csv" -Append
        } ELSE {
        "$machine,$wins_primary,$wins_secondary" | Out-File -file "WINS Enabled Servers in $ENV:USERDOMAIN.csv" -Append
        }
    $computercount = $computercount - 1
    Write-Host "$computercount computers left to check"
} # End ForEach $machine
Stop-Transcript

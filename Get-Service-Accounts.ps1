Start-Transcript "Services in $ENV:USERDOMAIN.log"

# Clear variables
$computers = $null

# Setup CSV
"sep=," | Out-File -file "Services in $ENV:USERDOMAIN.csv"
"Hostname,Service Name,Start-Up Account" | Out-File -File "Services in $ENV:USERDOMAIN.csv" -Append

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

write-host "$computercount computers found"

foreach ($machine in $computers) {
    Write-Output "$machine - Looking up hostname"
    # Is machine in DNS?
    $ErrorActionPreference = "silentlycontinue"
    $lookup = [System.Net.Dns]::GetHostAddresses($machine)
    $ErrorActionPreference = "continue"
    if($lookup -eq $null) {
        "$machine,not found in DNS" | Out-File -file "Services in $ENV:USERDOMAIN.csv" -Append
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
        "$machine,not reachable" | Out-File -file "Services in $ENV:USERDOMAIN.csv" -Append
        $computercount = $computercount - 1
        Write-Host "$machine - did not respond" -ForegroundColor Red
        Write-Host "$computercount computers left to check"
        continue
        } # End ICMP IF
    # Get services on remote machine
    $services = Get-WmiObject win32_service -ComputerName $machine -ea silentlycontinue
    if($? -eq $false) {
        "$machine,WMI encountered an error" | Out-File -File "Services in $ENV:USERDOMAIN.csv" -Append
        $computercount = $computercount - 1
        Write-Host "$machine - encountered an error in WMI" -ForegroundColor Red
        Write-Host "$computercount computers left to check"
        continue
        } ELSE {
        Write-Host "$machine - queried successfully" -ForegroundColor Green
        } # End WMI IF
    foreach($service in $services) {
        $service_name = $service.DisplayName
        $service_account = $service.StartName
        # Output to CSV
        "$machine,$service_name,$service_account" | Out-File "Services in $ENV:USERDOMAIN.csv" -Append
        } # End ForEach Service
    $computercount = $computercount - 1
    write-host "$computercount remaining"
} # End ForEach Machine
Stop-Transcript

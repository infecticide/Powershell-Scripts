Start-Transcript "$ENV:USERPROFILE\Scheduled Tasks in the $ENV:USERDOMAIN domain.log"
$ErrorActionPreference = "silentlycontinue"
# Setup CSV
"Hostname,Task Name,Enabled,LastRunTime,NextRunTime,LastTaskResult,UserID,Description" | out-file -file "Scheduled Tasks in the $ENV:USERDOMAIN domain.csv"
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

# Connect to each machine and get a list of scheduled tasks
foreach ($machine in $computer_array) {
    Write-Output "Checking $machine"
    # Is machine in DNS?
    nslookup $machine | out-null
    if($? -eq $false) {
        "$machine,not found in DNS" | Out-File -file "Scheduled Tasks in the $ENV:USERDOMAIN domain.csv" -Append
        Write-Output "Finished checking $machine"
        continue
        }
    # Is machine reachable?
    ping -n 1 $machine | out-null
    if($? -eq $false) {
        "$machine,not reachable" | Out-File -file "Scheduled Tasks in the $ENV:USERDOMAIN domain.csv" -Append
        Write-Output "Finished checking $machine"
        continue
        }
    # Get tasks on machine
    $schedule = new-object -com("Schedule.Service")
    $schedule.connect($machine)
    if($error.Count -gt 0) {
        "$machine,COM Error" | Out-File -file "Scheduled Tasks in the $ENV:USERDOMAIN domain.csv" -Append
        $error.Clear()
        Write-Output "Finished checking $machine"
        continue
        }
    $tasks = $schedule.getfolder("\").gettasks(0)
    $tasks | Foreach-Object {
	           $PSProp = New-Object -TypeName PSCustomObject -Property @{
	           'Host' = $machine
               'Name' = $_.name
               'Enabled' = $_.enabled
               'LastRunTime' = $_.lastruntime
               'LastTaskResult' = $_.lasttaskresult
               'NextRunTime' = $_.nextruntime
               'UserId' = ([xml]$_.xml).Task.Principals.Principal.UserID
               'Description' = ([xml]$_.xml).Task.RegistrationInfo.Description
             } # End of property definition
    # Put tasks into CSV
    $hostname = $PSProp.Host
    $name = $PSProp.Name
    $enabled = $PSProp.Enabled
    $lastruntime = $PSProp.LastRunTime
    $lasttaskresult = $PSProp.LastTaskResult
    $nextruntime = $PSProp.NextRunTime
    $userid = $PSProp.UserId
    $description = $PSProp.Description
    "$hostname,$name,$enabled,$lastruntime,$nextruntime,$lasttaskresult,$userid,$description" | Out-File -file "Scheduled Tasks in the $ENV:USERDOMAIN domain.csv" -Append
    } # End of ForEach $tasks
    Write-Output "Finished checking $machine"
} # End of ForEach $machine
Stop-Transcript

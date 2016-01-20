# Clear Jobs Queue
Get-Job | Remove-Job

# Get Credentials
$cr = Get-Credential
clear

# Start timer
$sw = [system.diagnostics.stopwatch]::startNew()

# Get server list
$Servers_UAT = Get-ADGroup Citrix-XA-AppV-T | Get-ADGroupMember | Select Name
$Servers_PRD = Get-ADGroup Citrix-XA-AppV-P | Get-ADGroupMember | Select Name
$servers = $Servers_UAT + $Servers_PRD
$ErrorActionPreference = "SilentlyContinue"

# Setup array to capture data
$results = @()

# Run command on each machine
foreach($server in $servers) { 
	$server = $server.Name
    #write-host "[INF] Running against $server" -Foreground Cyan
    # Run command as jobs and capture output
    Invoke-Command -AsJob -HideComputerName -ComputerName $server -Credential $cr -ScriptBlock { get-process -IncludeUserName | Where-Object {$_.ProcessName -like "*iexplore*" -or $_.ProcessName -like "*firefox*" -or $_.ProcessName -like "*chrome*"} | select UserName,Id,ProcessName,PM} | Out-Null
    }
  
Write-host "Waiting for all jobs to complete"
# Are all jobs completed?
Get-Job | Wait-Job | out-null
Write-host "All jobs completed"
# Get job list
$jobs = Get-Job


foreach($job in $jobs) {
    # Were there errors running the job?
    if($job.State -eq "Failed") {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Server' -MemberType NoteProperty -Value $job.Location
        $object | Add-Member -Name 'User' -MemberType NoteProperty -Value "Unable to query server"
        $results += $object
        continue
    }
    # Is Job Data empty? Package does not exist.
    if($job.HasMoreData -eq $FALSE) {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Server' -MemberType NoteProperty -Value $job.Location
        $object | Add-Member -Name 'User' -MemberType NoteProperty -Value "No browsers running"
        $results += $object
        continue
    }
    # No errors, job data is not empty, app must be found
    # Put Job output into variable
    $jobdata = Receive-Job $job.Id
    foreach ($line in $jobdata) {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Server' -MemberType NoteProperty -Value $job.Location
        $object | Add-Member -Name 'User' -MemberType NoteProperty -Value $line.UserName
        $object | Add-Member -Name 'Process' -MemberType NoteProperty -Value $line.ProcessName
        # Convert memory from B to MB
        $memory_usage = [Math]::Round($(($line.PM / 1024) / 1024),2)
        $object | Add-Member -Name 'Memory' -MemberType NoteProperty -Value $memory_usage
        $results += $object
        }
}

# Show $results
$sw.Stop()
$results | ft Server,User,Process,Memory

# Separate browsers into lists
$ie_list = $results | Where-Object {$_.Process -like "*iexplore*"}
$ff_list = $results | Where-Object {$_.Process -like "*firefox*"}
$gc_list = $results | Where-Object {$_.Process -like "*chrome*"}

$ie_sum = 0
$ff_sum = 0
$gc_sum = 0

# Sum up the memory they are using
foreach ($item in $ie_list) { $ie_sum = $ie_sum + $item.Memory }
foreach ($item in $ff_list) { $ff_sum = $ff_sum + $item.Memory }
foreach ($item in $gc_list) { $gc_sum = $gc_sum + $item.Memory }

# Round to 2 decimal places
$ie_sum = [math]::Round($ie_sum,2)
$ff_sum = [math]::Round($ff_sum,2)
$gc_sum = [math]::Round($gc_sum,2)

# Get instance counts
$ie_count = $ie_list.Count
$ff_count = $ff_list.Count
$gc_count = $gc_list.Count

# Do the math
$ie_avg = [math]::Round($($ie_sum / $ie_count),2)
$ff_avg = [math]::Round($($ff_sum / $ff_count),2)
$gc_avg = [math]::Round($($gc_sum / $gc_count),2)

Write-Output "$ie_count instances of Internet Explorer using $ie_sum MB of RAM, averaging $ie_avg MB"
Write-Output "$ff_count instances of Mozilla Firefox   using $ff_sum MB of RAM, averaging $ff_avg MB"
Write-Output "$gc_count instances of Google Chrome     using $gc_sum MB of RAM, averaging $gc_avg MB"

write-host " "
write-host "Script ran: $($sw.Elapsed.TotalSeconds) seconds"

Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

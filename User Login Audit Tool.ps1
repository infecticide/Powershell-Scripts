# Get username to audit
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
$username = [Microsoft.VisualBasic.Interaction]::InputBox("Enter username without domain prefix", "Name", "")

Start-Transcript "$ENV:USERPROFILE\Desktop\$username Login Audit.log"

# Get list of DCs
$Forest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest()
$DCs = $forest.Domains | ForEach-Object {$_.DomainControllers} | ForEach-Object {$_.Name}

# Query each DC for eventids related to logon events 
# Successful login: 4768
# Unsuccessful login: Fails auth [bad passwd, time sync](4771) or Audit Failure [account expired](4768)
ForEach ($DC in $DCs) {
    $date = get-date
    write-host "[ $date ] - Searching $DC"
    $FoundLogs = Get-WinEvent -FilterHashTable @{ LogName="Security";ID=4771,4768;Data=$username } -ComputerName $DC -EA "silentlycontinue"
    $date = get-date
    write-host "[ $date ] - Finished Searching DC"
    # Output found information to console so Transcription Log can capture it
    If ($FoundLogs -eq $NULL) {
        Write-Host "No Account Logon Events were found on $DC for $ENV:USERDOMAIN\$username"
        Write-Host " "
        } ELSE {
        write-host "The following logon events were found on $DC for $ENV:USERDOMAIN\$username"
        write-host " "
        foreach($log in $FoundLogs) {
            $log | fl
        } # End foreach $log
    } # End If $FoundLogs
} # End foreach $DC
Stop-Transcript

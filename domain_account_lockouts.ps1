Start-Transcript -Path "$ENV:USERPROFILE\Desktop\Account Lockouts on $ENV:USERDOMAIN.log"

# Get list of DCs
$Forest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest()
$DCs = $forest.Domains | ForEach-Object {$_.DomainControllers} | ForEach-Object {$_.Name}

# Connect to each DC and search for eventID 4740
ForEach ($DC in $DCs) {
    $date = get-date
    write-host "[ $date ] - Searching $DC"
    $FoundLogs = Get-WinEvent -FilterHashTable @{logname='Security';id=4740} -ComputerName $DC -EA "SilentlyContinue"
    $date = get-date
    write-host "[ $date ] - Finished Searching DC"
    # Output found information to console so Transcription Log can capture it
    If ($FoundLogs -eq $NULL) {
        Write-Host "No Account Lockouts were found on $DC"
        Write-Host " "
        } ELSE {
        write-host "The following logs were found on $DC"
        write-host " "
        $FoundLogs | fl
    } # End If $FoundLogs
} # End foreach $DC
Stop-Transcript

# Email logs to Keenan
Send-MailMessage -From "Steven.Brown@gov.sk.ca" -To "Keenan.Antonini@gov.sk.ca" -Subject "Account Lockout Report" -Body "Here is the lockout report, it will run every 30 minutes." -SmtpServer "mail.gos.ca" -Attachments "$ENV:USERPROFILE\Desktop\Account Lockouts on $ENV:USERDOMAIN.log"

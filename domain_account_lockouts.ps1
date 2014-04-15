Start-Transcript -Path "$ENV:TEMP\AccountLockouts.log"

#$ErrorActionPreference = "SilentlyContinue"

# List of DCs
$DCs = "ads1-co","ads2-co","ads9-co"

# Connect to each DC and search for eventID 4740
ForEach ($DC in $DCs) {
    $date = get-date
    write-host "[ $date ] - Searching $DC"
    $FoundLogs = Get-WinEvent -ComputerName $DC -FilterHashTable @{logname='Security';id=4740}
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
#Send-MailMessage -From "Steven.Brown@gov.sk.ca" -To "Keenan.Antonini@gov.sk.ca" -Subject "Account Lockout Report" -Body "Here is the lockout report, it will run every 30 minutes." -SmtpServer "mail.gos.ca" -Attachments "$ENV:TEMP\AccountLockouts.log"

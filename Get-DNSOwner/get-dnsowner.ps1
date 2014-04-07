$sw = [Diagnostics.Stopwatch]::StartNew()
Import-Module C:\Users\browns2\Documents\WindowsPowerShell\DnsShell\DnsShell.psd1
# Setup array
[array]$records_array = "Record DN;Owner"
# Get list of DNS Records
$records = Get-ADDnsRecord -SearchRoot "CN=MicrosoftDNS,CN=System,DC=fcc,DC=ca" | Where-Object { $_.RecordType -eq "A" } | Where-Object { $_.TimeStamp -ne "Static" }
$records | ForEach-Object { 
    # Parse record data for DN
    $record_dn = $_.DN
    # Get owner
    [string]$record_owner = dsacls "$record_dn" /A | Select-String "Owner: " 
    # Condense string down to owner
    $record_owner = $record_owner.Replace("Owner: ","")
    [array]$records_array = $records_array + "$record_dn;$record_owner"
    }
$sw.Stop()
# Determine number of seconds so we can calculate rate
$seconds = ($sw.Elapsed.Minutes*60)+$sw.Elapsed.Seconds
$rate = $records.Count / $seconds
write-host $records.Count "Records in"$sw.Elapsed "($rate per Second)"

# Generate output
$records_array | Out-File "C:\users\browns2\Documents\get-dnsowner.csv"

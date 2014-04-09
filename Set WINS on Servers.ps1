Start-Transcript -path "Set WINS on Servers.log"

# Import CSV
$servers = Import-Csv 'WINS Enabled Servers in $ENV:USERDOMAIN.csv' | Select-Object Hostname

# Connect to server and set WINS entries
foreach ($server in $servers) {
    $server = $server.Hostname
    $NICs = gwmi -Class Win32_NetworkAdapterConfiguration -ComputerName $server -Filter "IPEnabled=TRUE"
    foreach($NIC in $NICs) {
        $NIC.SetWINSServer("10.204.1.2","10.204.1.3")
        if($? -ne $TRUE) {
            write-host "Failed to set WINS on $server"
            } ELSE {
            write-host "Set WINS successfully on $server"
        } # End IF
    } # End ForEach $NIC
} # End ForEach $server     

Stop-Transcript

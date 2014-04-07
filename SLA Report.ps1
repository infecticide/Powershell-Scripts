# Output location
$file = "Z:\server_eventlogs.csv"

# Setup Headers
"sep=," | out-file $file
"ServerName,TimeDate,UserName,Reason,Comment,Source" | out-file $file -append

# Days to search back
$days = 31

# Server list
$servers = @(
"server1",
"server2",
"server3"
)

# Get eventlogs from servers requested
$ErrorActionPreference = "silentlycontinue"
$servers | foreach {
                    # Clear variables
                    $machinename = $null
                    $logs = $null
                    $timegenerated = $null
                    $username = $null
                    $reason = $null
                    $comment = $null
                    $source = $null

                    # Grab server name
                    $machinename = $_
                    # Clear Error counter
                    $error.Clear()
                    write-host "Processing $_"
                    # Get Logs
                    $logs = Get-EventLog "System" -ComputerName $_ -Source USER32,EventLog -After ((Get-Date).Date.AddDays(-$days))| ?{$_.EventID -eq 6008 -or $_.EventID -eq 1074 -or $_.EventID -eq 1076} | Select-Object TimeGenerated,ReplacementStrings,Source -ErrorAction SilentlyContinue
                    if($? -ne $true) {
                        "$_,,,An error occured connecting to the server : $error" | out-file $file -Append
                        # Go to next server
                        return
                        }
                    
                    # Process Logs
                    if($logs -ne $null) {
                        $logs | foreach {
                            $timegenerated = $_.TimeGenerated
                            $username = $_.ReplacementStrings[6]
                            $reason = $_.ReplacementStrings[2]
                            $comment = $_.ReplacementStrings[5]
                            $source = $_.Source
                            if($reason -contains "No title for this reason could be found") {
                                return
                            }
                            "$machinename,$timegenerated,$username,$reason,$comment,$source" | out-file $file -Append
                            }
                        }ELSE{
                        "$machinename, no issues" | out-file $file -Append 
                        }
}

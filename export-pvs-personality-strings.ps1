# This script assumes there is only one personality string defined

Add-PSSnapin mclipssnapin
# Get list of devices
$devices = mcli-get device | Select-String "deviceName"
$devices = foreach ($device in $devices) {$device -Replace "deviceName: ",""}

# Prep array
$personality_array = @()
# Prep CSV with headers
"deviceName,value" | out-file pvsservers.csv
# Get Personality Strings for devices
foreach ($device in $devices) {
    $personality = mcli-get devicepersonality -p deviceName=$device | Select-String "value"
    $personality = $personality.Replace("value: ","")
    # Create CSV output
    "$device,$personality" | Out-File -Append pvsservers.csv
    }

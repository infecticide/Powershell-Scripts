# This script assumes there is only one personality string defined

Add-PSSnapin mclipssnapin
# Get list of devices
$pvs_input = Import-CSV -Path pvsservers.csv

# Set personality strings for each device
foreach ($item in $pvs_input) {
    $devicename = $item.deviceName
    $value = $item.Value
    mcli-setlist devicepersonality -p deviceName=$devicename -r name=hwid,value=$value
    }

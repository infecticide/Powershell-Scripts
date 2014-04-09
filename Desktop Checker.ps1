param($servers="localhost")

$ErrorActionPreference = "silentlycontinue"

# List of servers to check
if(test-path serverlist.txt) {
    $servers = get-content "serverlist.txt"
    }

foreach ($server in $servers) {
$remoteserver = $server
$file = "$ENV:TEMP\$remoteserver`.html"

# Setup HTML Header
$header_datetime = get-date
$html_header = "
<body>
<h1><center>Server/Workstation/Laptop Diagnostic Tool</center></h1>
<p>Account running this script is $ENV:USERDOMAIN\$ENV:USERNAME @ $header_datetime from workstation $ENV:COMPUTERNAME
<p>Information on remote machine <b>\\$remoteserver</b></p>
<p><font color=red>To see information as it loads hit the REFRESH button on your web browser.</font></p>
<hr>
"
# Output HTML to File
$html_header | out-file $file

# Section 0, Ping test
"<h3>Connectivity Test</h3>" | out-file -Append $file
"<table border=1><b><tr><td>Test</td><td>Result</td></tr></b>" | Out-File -Append $file
& ping -n 1 $remoteserver | out-null
if($? -eq $true) {
    "<tr><td>PING</td><td>OK</td></tr>" | out-file -Append $file
    } ELSE {
    "<tr><td>PING</td><td>Failed</td></tr>" | out-file -Append $file
    }
gwmi Win32_OperatingSystem -ComputerName $remoteserver | out-null
if($? -eq $true) {
    "<tr><td>WMI</td><td>OK</td></tr>" | out-file -Append $file
    } ELSE {
    "<tr><td>WMI</td><td>Failed</td></tr>" | out-file -Append $file
    continue
    }
Get-EventLog System -ComputerName $remoteserver -Newest 1 | out-null
if($? -eq $true) {
    "<tr><td>EventLog</td><td>OK</td></tr>" | Out-File -Append $file
    } ELSE {
    "<tr><td>EventLog</td><td>Failed</td></tr>" | Out-File -Append $file
    }
"</table><hr>" | Out-File -Append $file

# Section one, OS
$os = Get-WmiObject win32_operatingsystem -ComputerName $remoteserver
$os_version = $os.Version
$os_caption = $os.Caption
$os_servicepack = $os.ServicePackMajorVersion
$os_lastbootup = $os.ConvertToDateTime($os.LastBootUpTime)
$os_sysdir = $os.SystemDirectory
# Generate HTML for this section
$section1_html = "
<h3>1 - Operating System</h3>
Operating System Version = $os_version<br>
Operating System Caption = $os_caption<br>
Operating System Service Pack = $os_servicepack<br>
Operating System LastBootUpTime = $os_lastbootup<br>
Operating System Directory = $os_sysdir<br>
<hr>
"
# Output HTML to file
$section1_html | out-file -Append $file



# Section 2, Members of local admin group
$propername = @()
$localadmins = @()
$wmi = Get-WmiObject -ComputerName $remoteserver -Query "SELECT * FROM Win32_GroupUser WHERE GroupComponent=`"Win32_Group.Domain='$remoteserver',Name='Administrators'`"" 
# Parse out the username from each result and append it to the array. 
if ($wmi -ne $null) { 
    foreach ($item in $wmi) { 
         $info = ($item.PartComponent.Substring($item.PartComponent.IndexOf('Domain'))).Split(',')
         $userdomain = (($info[0]).Replace('Domain=','')).Replace('"','')
         $username = (($info[1]).Replace('Name=','')).Replace('"','')
         $propername = "$userdomain\$username"
         $localadmins += "<tr><td>$propername</td></tr>"
        } 
    } 
$section2_html = "
<h3>2 - Members of the local administrators group</h3>
<table border=1><tr><td><b>Name</b></td></tr>
"
$section2_html | out-file -Append $file
$localadmins | out-file -Append $file
"</table><hr>" | out-file -Append $file

# Section 3, Services status
$section3_html = "
<h3>3 - Status of vital services</h3>
<table border=1><tr><td><b>Service Name</b></td><td><b>Display Name</b></td><td><b>Status</b></td></tr>
"
$section3_html | out-file -Append $file
$services = @("WinMgmt","AvSynMgr","McShield","clisvc","Wuser32","Dhcp")
foreach ($service in $services) {
    # Existant services
    $service_check = Get-Service $service -ComputerName $remoteserver -ErrorAction silentlycontinue | select Name,DisplayName,Status
    if($? -eq $true) {
        $servicename = $service_check.Name
        $servicedname = $service_check.DisplayName
        $servicestatus = $service_check.Status
        "<tr><td>$servicename</td><td>$servicedname</td><td>$servicestatus</td></tr>" | out-file -Append $file
        } ELSE {
        "<tr><td>$service</td><td> </td><td><b><font color=FF0000>NOT PRESENT</font></b></td>" | Out-File -Append $file
        }
    
}
"</table><hr>" | Out-File -Append $file


# Section 4, status of admin shares
$section4_html = "
<h3>4 - Status of administrative shares</h3>
<table border=1><tr><td><b>Share Name</b></td><td><b>Share Path</b></td><td><b>ACL</b></td><td><b>Status</b></td></tr>
"
$section4_html | Out-File -Append $file
# Function to get share ACLs
function get-shareacl ($share) {
    #$shares = gwmi -Class win32_share -ComputerName $remoteserver | select -ExpandProperty Name  
        $acl = $null  
        $objShareSec = Get-WMIObject -Class Win32_LogicalShareSecuritySetting -Filter "name='$share'"  -ComputerName $remoteserver
        try {  
            $SD = $objShareSec.GetSecurityDescriptor().Descriptor    
            foreach($ace in $SD.DACL){   
                $UserName = $ace.Trustee.Name      
                If ($ace.Trustee.Domain -ne $Null) {$UserName = "$($ace.Trustee.Domain)\$UserName"}    
                If ($ace.Trustee.Name -eq $Null) {$UserName = $ace.Trustee.SIDString }      
                [Array]$ACL += New-Object Security.AccessControl.FileSystemAccessRule($UserName, $ace.AccessMask, $ace.AceType)  
                } #end foreach ACE            
        } # end try  
        catch {  }
        $ACL
}

$shares = get-wmiobject -class "Win32_Share" -namespace "root\CIMV2" -computername $remoteserver
foreach ($share in $shares) {
    $share_name = $share.Name
    $share_path = $share.Path
    $share_status = $share.Status
    $share_acl = get-shareacl $share_name | Out-String
    $share_acl = $share_acl.Replace("`n","<br>")
    "<tr><td>$share_name</td><td>$share_path</td><td>$share_acl</td><td>$share_status</td>" | out-file -Append $file
}
"</table><hr>" | Out-File -Append $file

# Section 5, current time and date
$section5_html = "
<h3>5 - Current date and time</h3>
<table border=1><tr><td><b>System</b></td><td><b>Time</b></td></tr>
"
$section5_html | Out-File -Append $file
$remoteserver_time = $os.ConvertToDateTime($os.LocalDateTime)
$dc_time = Get-WmiObject win32_operatingsystem -ComputerName dc1
$dc_time = $dc_time.ConvertToDateTime($dc_time.LocalDateTime)
"<tr><td>$remoteserver</td><td>$remoteserver_time" | Out-File -Append $file
"<tr><td>DC1</td><td>$dc_time</td></tr></table><hr>" | Out-File -Append $file

# Section 6, Registry Information
"<h3>6 - Registry Information</h3>" | out-file -Append $file
$reg_current_size = (gwmi Win32_Registry -ComputerName $remoteserver).CurrentSize
$reg_max_size = (gwmi Win32_Registry -ComputerName $remoteserver).MaximumSize
"Current Registry Size (MB): $reg_current_size<br>" | Out-File -Append $file
"Maximum Registry Size (MB): $reg_max_size" | out-file -Append $file
"<hr>" | Out-File -Append $file


# Section 7, Hardware Info
"<h3>7 - Hardware Information</h3>" | Out-File -Append $file
$drives = (gwmi win32_logicaldisk -ComputerName $remoteserver) | Where-Object {$_.DriveType -eq 3}
$comp_manuf = (gwmi win32_computersystem -ComputerName $remoteserver).Manufacturer
$comp_model = (gwmi win32_computersystem -ComputerName $remoteserver).Model
$total_ram = (gwmi win32_computersystem -ComputerName $remoteserver).TotalPhysicalMemory
$asset_tag = (gwmi win32_systemenclosure -ComputerName $remoteserver).SMBIOSAssetTag
$serial_num = (gwmi win32_systemenclosure -ComputerName $remoteserver).SerialNumber
$proc_name = (gwmi win32_processor -ComputerName $remoteserver).Name
$proc_speed = (gwmi win32_processor -ComputerName $remoteserver).CurrentClockSpeed
$proc_voltage = (gwmi win32_processor -ComputerName $remoteserver).CurrentVoltage
$proc_load = (gwmi win32_processor -ComputerName $remoteserver).LoadPercentage
"<table border=1>" | Out-File -Append $file
"<tr><td>Computer Manufacturer</td><td>$comp_manuf</td></tr>" | Out-File -Append $file
"<tr><td>Computer Model</td><td>$comp_model</td></tr>" | out-file -Append $file
"<tr><td>Asset Tag</td><td>$asset_tag</td></tr>" | Out-File -Append $file
"<tr><td>Serial Number</td><td>$serial_num</td></tr>" | Out-File -Append $file
"<tr><td>Total Physical Memory</td><td>$total_ram</td></tr>" | Out-File -Append $file
"<tr><td>Processor Name</td><td>$proc_name</td></tr>" | out-file -Append $file
"<tr><td>Processor Speed</td><td>$proc_speed</td></tr>" | Out-File -Append $file
"<tr><td>Processor Voltage</td><td>$proc_voltage</td></tr>" | Out-File -Append $file
"<tr><td>Processor Load</td><td>$proc_load</td></tr></table>" | Out-File -Append $file
"<table border=1><b><tr><td>Drive</td><td>Total Space</td><td>Space Used</td><td>Space Free</td></tr></b>" | Out-File -Append $file
foreach ($drive in $drives) {
    $free_space = $drive.FreeSpace
    $vol_size = $drive.Size
    $used_space = ($vol_size - $free_space)    
    $free_space = (((($drive.FreeSpace) / 1024) / 1024) / 1024)
    $free_space = "{0:N2}" -f $free_space
    $vol_size = (((($drive.Size) / 1024) / 1024) / 1024)
    $vol_size = "{0:N2}" -f $vol_size
    $used_space = (((($used_space) / 1024) / 1024) / 1024)
    $used_space = "{0:N2}" -f $used_space
    $vol_letter = $drive.Name
    "<tr><td>$vol_letter</td><td>$vol_size</td><td>$used_space</td><td>$free_space</td></tr>" | Out-File -Append $file
    }
"</table><hr>" | Out-File -Append $file


# Section 8, Network information
"<h3>8 - Network Information</h3>" | Out-File -Append $file
$adapters = gwmi win32_networkadapterconfiguration -computername $remoteserver -Filter 'ipenabled = "true"'
foreach ($adapter in $adapters) {
    $ip = $adapter.IPAddress
    $subnet = $adapter.IPSubnet
    $gateway = $adapter.DefaultIPGateway
    $dns_servers = $adapter.DNSServerSearchOrder
    $name = $adapter.Description
    $dhcp = $adapter.DHCPEnabled
    $mac = $adapter.MACAddress
    $hostname = $adapter.DNSHostName
    "<table border=1><tr><td><b>Attribute</b></td><td><b>Value</b></td></tr>" | out-file -Append $file
    "<tr><td>Name of card</td><td>$name</td></tr>" | out-file -Append $file
    "<tr><td>DHCP Enabled</td><td>$dhcp</td></tr>" | Out-File -Append $file
    "<tr><td>IP Address</td><td>$ip</td></tr>" | Out-File -Append $file
    "<tr><td>Subnet Mask</td><td>$subnet</td></tr>" | out-file -append $file
    "<tr><td>MAC Address</td><td>$mac</td></tr>" | Out-File -Append $file
    "<tr><td>Hostname</td><td>$hostname</td></td>" | Out-File -Append $file
    "<tr><td>DNS Servers</td><td>$dns_servers</td></tr>" | Out-File -Append $file
    "</table>" | Out-File -Append $file
}
    "<hr>" | out-file -Append $file

# Section 9, Software Info
"<h3>9 - Software Information</h3>" | Out-File -Append $file
$hklm = "2147483650"
$wmi = [wmiclass]"\\$remoteserver\root\default:stdRegProv"
$regclass = gwmi -Namespace "Root\Default" -List -ComputerName $remoteserver | Where-Object { $_.Name -eq "StdRegProv" }

# Internet Explorer
$IEkey = "SOFTWARE\Microsoft\Internet Explorer"
$IEVersion = ($regclass.GetStringValue($hklm,$IEkey,"Version")).sValue

"<b>Internet Explorer</b><br>" | out-file -Append $file
"Version: $IEVersion <br><br>" | out-file -Append $file

# Mcafee
$mcafee_key="SOFTWARE\McAfee\AVEngine"
$mcafee_DATVersion = ($regclass.GetDWORDValue($hklm,$mcafee_key,"AVDATVersion")).uValue
$mcafee_AVEngineVer_Major = ($regclass.GetDWORDValue($hklm,$mcafee_key,"EngineVersionMajor")).uValue
$mcafee_AVEngineVer_Minor = ($regclass.GetDWORDValue($hklm,$mcafee_key,"EngineVersionMinor")).uValue
"<b>Mcafee Information</b><br>" | Out-File -Append $file
"Mcafee DAT Version: $mcafee_DATVersion <br>" | Out-File -Append $file
"Mcafee Engine Version: $mcafee_AVEngineVer_Major`.$mcafee_AVEngineVer_Minor <br><br><br>" | Out-File -Append $file

# Installed Apps
"<b>Installed Applications</b><br>" | Out-File -Append $file
$UninstallKey="SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$installed_apps = ($wmi.EnumKey($HKLM, $UninstallKey)).sNames
"<table border=1><tr><td><b>Application</b></td><td><b>Version</b></td></tr>" | out-file -Append $file
foreach ($app in $installed_apps) {
    if ($app.StartsWith("{")) {
        } ELSE {
        continue
        }
    $appkey = "$uninstallKey\$app"
    $app_name = ($regclass.GetStringValue($hklm,$appkey,"DisplayName")).sValue
    $app_version = ($regclass.GetStringValue($hklm,$appkey,"DisplayVersion")).sValue
    "<tr><td>$app_name</td><td>$app_version</td></tr>" | Out-File -Append $file
    }
"</table><br><br>" | out-file -Append $file

# Installed Windows Patches
"<b>Windows Patches</b>" | out-file -Append $file
"<table border=1><tr><td><b>Name</b></td><td><b>Description</b></td><td><b>Installation Date</b></td></tr>" | Out-File -Append $file
$patches = gwmi win32_quickfixengineering -ComputerName $remoteserver | select HotFixID, Description, InstalledOn
foreach ($patch in $patches) {
    $kb = $patch.HotFixID
    $desc = $patch.Description
    $install = $patch.InstalledOn
    "<tr><td>$kb</td><td>$desc</td><td>$install</td></tr>" | Out-File -Append $file
    }
"</table><hr>" | out-file -Append $file

# Section 10, EventLog Errors
"<h3>10 - First 25 Errors in the EventLogs</h3>"| Out-File -Append $file
$events = Get-EventLog System -ComputerName $remoteserver -EntryType Error -Newest 25 | select TimeGenerated, Source, Message
if($? -ne $true) {
    "Unable to connect to remote EventViewer data" | out-file -Append $file
    continue
    }
"<table border=1><tr><td><b>Time</b></td><td><b>Source</b><td><b>Message</b></td></tr>" | Out-File -Append $file
foreach ($event in $events) {
    $time = $event.TimeGenerated
    $source = $event.Source
    $message = $event.Message
    "<tr><td>$time</td><td>$source</td><td>$message</td></tr>" | out-file -Append $file
    }   
} # ForEach $Server Loop, close

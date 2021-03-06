Start-Transcript -Path "C:\DR.txt"

# Hardware Profile (IMM+RAID)

# Drive Sizes
$drives = gwmi win32_logicaldisk | select DeviceID,Size
write-host "`n`nDrive sizes in MegaBytes"
write-host "========================"

foreach ($drive in $drives) {
    $drive_gb = $drive.size / 1000000000
    if($drive_gb -eq 0) {write-host $drive.DeviceID "- CDROM"} ELSE {write-host $drive.DeviceID "-" $drive_gb "GB"}
    }

# IP Addresses + MAC
write-host "`n`nNetwork Adapter Configs"
write-host "======================="
ipconfig /all | out-default

# Software + Patch Levels
write-host "Software Catalog"
write-host "================"
write-host "Base Installs"
write-host "============="
gwmi win32_product
write-host "`n`n"
write-host "Windows / Microsoft Patches"
write-host "==========================="
gwmi win32_quickfixengineering | select Description,HotFixID | where-object {$_.HotFixID -ne "File 1"}

# Services
write-host "`n`n"
write-host "Services and Service State Information"
write-host "======================================"
gwmi win32_service | select Name,StartMode,StartName
write-host "`n`n"

# Local user and group information
write-host "Local Users"
write-host "======================"
net user | out-default


write-host "Local Group Information"
write-host "======================="
$computer = [ADSI]"WinNT://$env:computername,computer"
$computer.psbase.Children | Where-Object {$_.psbase.schemaclassname -eq 'group'} | select Name,Description
$localgroups = $computer.psbase.Children | Where-Object {$_.psbase.schemaclassname -eq 'group'}

write-host "Local Group Memberships"
write-host "======================="
$groups = net localgroup | ?{ $_ -match "^\*.*" } | %{ $_.SubString(1) };
foreach ($groupName in $groups) {
#    net localgroup $group | out-default
#    write-host "`n`n"
#    }

$lines = net localgroup $groupName
  $found = $false
  write-host "`"$groupName`"" "Group"
  for ($i = 0; $i -lt $lines.Length; $i++ ) {
    if ( $found ) {
      if ( -not $lines[$i].StartsWith("The command completed")) {
        $lines[$i]
      }
    } elseif ( $lines[$i] -match "^----" ) {
      $found = $true;
    }
  }
}

$osversion = Get-WmiObject win32_operatingsystem
$a = (Get-Date).Year
$b = (Get-Date).Month
$c = (Get-Date).Day
$backupdate = "$a" + "$b" + "$c"

# Win2K8 Specific
if($osversion.Version -like "6.0*") {

}

# Win2K8R2 Specific
if($osversion.Version -like "6.1*") {
    # Backup IIS Config if IIS is installed
    Import-module WebAdministration
    Backup-WebConfiguration -Name C:\DR\iis_config_$backupdate.bak
}

# Win2K3 Specific
if($osversion.Version -like "5.2*") {

}




Stop-Transcript
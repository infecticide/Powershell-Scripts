Start-Transcript -Path $ENV:TEMP\Profile_Permissions.log
$domain = $USERDOMAIN
$Profile_location = "\\server\share"

$locations = @("$Profile_location")

foreach($location in $locations) {
    # Get list of folders and scrub out the garbage
    Set-Location $location
    $folders = gci $location | select Name | Where-Object { $_.Name -like "z*" }
    $folders_count = $folders.Count
    write-host "$folders_count folders found in $location"
    $folders_sanitized = @()
    foreach($folder in $folders) {
        $folder = $folder.Name
        if(($folder.Contains("#")) -or ($folder.Contains("%")) -or ($folder.Contains("_")) -or ($folder.Contains("."))) {
            continue
            } ELSE {
            $folders_sanitized += $folder
            }
    }
    $folders_sanitized_count = $folders_sanitized.Count
    write-host "$folders_sanitized_count folders found after sanitization"
    foreach($folder in $folders_sanitized) {
        write-host "Setting NT Authority\SYSTEM with Full Control to $location\$folder"
        icacls "$location\$folder" /grant "NT AUTHORITY\SYSTEM:(F)"
        
        $user = "$domain\$folder"
        write-host "Setting $user as owner of $location\$folder"
        icacls "$location\$folder" /setowner $user /c /t

        write-host "Setting Full Permissions for $user on $location\$folder"
        $new=$user,”FullControl”,”ContainerInherit,ObjectInherit”,”InheritOnly”,”Allow”
        $accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $new
        $acl.AddAccessRule($accessRule)
        Set-Acl $folder $acl
        }
}

Stop-Transcript

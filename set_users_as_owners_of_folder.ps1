# Go to base location
$base_location = "\\server\share\folder"
Set-Location $base_location
$domain = "domain"

# Get list of directories only
$folders = Get-ChildItem | ?{ $_.PSIsContainer }

# Get to work
$folders | ForEach-Object {
    # Whose dir is it?
    $dir_name = $_.Name
    # Add the domain on the front
    $user_name = "$domain\$dir_name"
    # Format permission string
    $perm = """$user_name"":(OI)(CI)MRX"
    # Set the permissions\inheritance on the folder
    icacls.exe $base_location\$dir_name /grant:r $perm
    }

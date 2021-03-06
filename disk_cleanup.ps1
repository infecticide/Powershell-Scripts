# Get OS
$os = gwmi win32_operatingsystem

$cleanup = @(
    "c:\`$Recycle.Bin\",
    "c:\RECYCLER\",
    "c:\windows\temp\",
    "c:\users\",
    "c:\temp\",
    "c:\Documents and Settings\"    
    )

foreach ($location in $cleanup) {
    # If Path EXISTS and IS ACCESSIBLE, continue, else return to FOREACH for next location
    if(test-path $location) {cd $location} ELSE {return}
    
    if($location -eq "c:\users\") {
        # We don't want to delete ALL user profiles, just most of them, filter out the ones we want to keep
        gci -force -exclude "LocalService","NetworkService","Administrator","#citrix_prod","`$Adminutil","All Users","ctx_*","Default","Default User","Public","$env:username" | Remove-Item -force -recurse -ErrorAction SilentlyContinue
        if($? -ne $true) {write-host "Some files could not be deleted from" $location} ELSE {}
        } ELSE {}
    
    if($location -eq "c:\Documents and Settings\") {
        # We don't want to delete ALL user profiles, just most of them, filter out the ones we want to keep
        gci -force -exclude "LocalService","NetworkService","Administrator","#citrix_prod","`$Adminutil","All Users","ctx_*","Default","Default User","Public" | Remove-Item -force -recurse -ErrorAction SilentlyContinue
        if($? -ne $true) {write-host "Some files could not be deleted from" $location} ELSE {}
        } ELSE {}
    
    
    gci -force | Remove-Item -force -recurse -ErrorAction SilentlyContinue
    if($? -ne $true) {write-host "Some files could not be deleted from" $location} ELSE {}
}

# Disable hibernation and delete the c:\hibernat.sys file
& powercfg -H OFF

# If machine is Windows 2008 non-r2, run compcln
if($os.Version.Contains("6.0")) {& compcln /quiet | out-null}

# If Machine is Windows 2008 R2, run DISM
if($os.Version.Contains("6.1")) {& dism /online /cleanup-image /spsuperseded | out-null}

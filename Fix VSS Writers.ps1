# Delete Registry info
if(test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EventSystem\{26c409cc-ae86-11d1-b616-00805fc79216}") {
    Set-Location -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EventSystem\{26c409cc-ae86-11d1-b616-00805fc79216}"
    if(test-path "Subscriptions") {
        Remove-Item "Subscriptions"
        if($? -ne $TRUE) {
            write-host "Subscriptions Key Could Not Be Deleted, exiting..."
            exit 1
            } ELSE {
            write-host "Subscriptions Key Deleted"
            } # end IF $?
        } ELSE {
        write-host "Subscriptions Key Does Not Exist, continuing..."
        } # End IF test-path Subscriptions
    } ELSE {
    write-host "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EventSystem\{26c409cc-ae86-11d1-b616-00805fc79216} location does not exist, exiting..."
    exit1
    } # End IF test-path HKEY_LOCAL_MACHINE
# Restart services
write-host "Restarting Services"
Restart-Service -DisplayName "COM+ Event System" -Force -ea SilentlyContinue
Restart-Service -DisplayName "COM+ System Application" -Force -ea SilentlyContinue
Restart-Service -DisplayName "Cryptographic Services" -Force -ea SilentlyContinue
Restart-Service -DisplayName "Microsoft Software Shadow Copy Provider" -Force -ea SilentlyContinue
Restart-Service -DisplayName "Volume Shadow Copy" -Force -ea SilentlyContinue

# Reinstall VSS Writers
write-host "Reinstalling Writers"
Takeown /f c:\windows\winsxs\filemaps /a
icacls "c:\windows\winsxs\filemaps" /grant "NT AUTHORITY\SYSTEM:(RX)"
icacls "c:\windows\winsxs\filemaps" /grant "NT Service\trustedinstaller:(F)"
icacls "c:\windows\winsxs\filemaps" /grant "BUILTIN\Users:(RX)"

set-location "c:\windows\system32"
Stop-Service -DisplayName "Volume Shadow Copy" -Force -ea SilentlyContinue
Stop-Service -DisplayName "Microsoft Software Shadow Copy Provider" -Force -ea SilentlyContinue
regsvr32 /s ole32.dll
regsvr32 /s oleaut32.dll
regsvr32 /s /i eventcls.dll
regsvr32 /s vss_ps.dll
vssvc /register
regsvr32 /s /i swprv.dll
regsvr32 /s es.dll 
regsvr32 /s stdprov.dll
regsvr32 /s vssui.dll 
regsvr32 /s msxml.dll
regsvr32 /s msxml3.dll 
regsvr32 /s msxml4.dll
Sleep 5

# List VSS Writers
$writers = vssadmin list writers | Select-String '^writer name'
write-host "The following writers are installed:"
$writers

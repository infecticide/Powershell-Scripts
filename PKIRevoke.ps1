# Functions

function verification{
# Verify certificate has been deleted
write-host "Verifying certificate has been revoked"
del server1.csv
del server2.csv
del allcerts.csv
invoke-command -computer server1 {certutil -view -out "User Principal Name,Serial Number,Request Disposition" csv} > server1.csv
invoke-command -computer server2 {certutil -view -out "User Principal Name,Serial Number,Request Disposition" csv} > server2.csv
type server1.csv | find /i /v "Issued Common Name" > allcerts.csv
type server2.csv | find /i /v "Issued Common Name" >> allcerts.csv
'"Machine","SerialNumber","Status"' | Insert-Content allcerts.csv
$sortedlist = @(import-csv allcerts.csv | sort Machine)
$sortedlist = $sortedlist -match "20 -- Issued"
$foundresult = $sortedlist -match $machine
if($foundresult.length -eq 0)
    {
        write-host "Certificate revoked successfully"
        Write-Host "Press any key to continue ..."
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
    ELSE
    {
        write-host -foregroundcolor red ERROR: "Certificate could not be revoked!  Please revoke manually!"
        Write-Host "Press any key to continue ..."
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

function Insert-Content {
# Insert text in first line of file
process {
$( ,$_; Get-Content allcerts.csv -ea SilentlyContinue) | Out-File allcerts.csv
     }
}

# Prompt user for machine name
$machine = read-host "Please enter machine host name"
if($machine.length -eq 0) {
    write-host -foregroundcolor red "Invalid host name entered"
    Write-Host "Press any key to continue ..."
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
    }
# Set working dir to temp
cd c:\windows\temp

# Set revoke code to certificate hold, only code that can be un-revoked
$code = 6

write-host "Retrieving Certificate List from server1"
invoke-command -computer server1 {certutil -view -out "User Principal Name,Serial Number,Request Disposition" csv} > server1.csv

write-host "Retrieving Certificate List from server2"
invoke-command -computer server2 {certutil -view -out "User Principal Name,Serial Number,Request Disposition" csv} > server2.csv

type server1.csv | find /i /v "Issued Common Name" > allcerts.csv
type server2.csv | find /i /v "Issued Common Name" >> allcerts.csv

# Insert CSV headers
'"Machine","SerialNumber","Status"' | Insert-Content

# Import CSV and sort by machine name
$sortedlist = @(import-csv allcerts.csv | sort Machine)

# Removing non-issued certs from the list
$sortedlist = $sortedlist -match "20 -- Issued"

# Find certs issued to machine if any
$foundresult = $sortedlist -match $machine
if($foundresult.length -ge 1) 
    {
        write-host "Machine certificates found"
        if($foundresult.Length -gt 1) 
            {
                write-host -foregroundcolor red WARNING: $foundresult.length certificates found for this machine
                for ($i=0; $i -le $foundresult.Length - 1; $i++) {
                    Invoke-Command -computer server1 -Script {certutil -revoke $args[0] $args[1]} -Args $foundresult[$i].serialnumber,$code | out-null
                    Invoke-Command -computer server2 -Script {certutil -revoke $args[0] $args[1]} -Args $foundresult[$i].serialnumber,$code | out-null
                    }
                    
                    verification;
            }
        Invoke-Command -computer server1 -Script {certutil -revoke $args[0] $args[1]} -Args $foundresult[0].serialnumber,$code | out-null
        Invoke-Command -computer server2 -Script {certutil -revoke $args[0] $args[1]} -Args $foundresult[0].serialnumber,$code | out-null
        verification;
     }
     ELSE
     {
        write-host -foregroundcolor red "No certificates could be found for this machine"
        Write-Host "Press any key to continue ..."
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
     }

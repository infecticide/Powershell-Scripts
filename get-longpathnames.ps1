function Dig {
    $path = "Z:\"
    $length = 245
    $tmp_fptl = @()
    $tmp_dptlf = "./dptl.txt"
    $command = "dir `"$path`" /A:-D /B /S"
    Write-Host $command
    cmd /C $command 2> $tmp_dptlf | % {
        if($_.length -gt $length){$tmp_fptl+=$_}
    }
    $tmp_fptl | Out-File -FilePath $env:temp/dig.log
}
Dig
Remove-Item ./dptl.txt
notepad $env:temp/dig.log

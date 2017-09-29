param(
    [parameter(Mandatory=$true)]
    [string]$sql_version_num,
    [parameter(Mandatory=$true)]
    [string]$setup_file,
    [parameter(Mandatory=$false)]
    [string]$arg_list
)

Start-Process -FilePath $setup_file -ArgumentList $arg_list -Wait

#Parse execution result from summary log
$summary = "C:\Program Files\Microsoft SQL Server\" + $sql_version_num + "\Setup Bootstrap\Log\summary.txt"  

$ec = (Get-Content $summary) | Select-String -Pattern "Exit code \(Decimal\):" | %{$_ -replace "\s+Exit code \(Decimal\):\s+", ""}

$logfile = "C:\tmp\Install-Mssql-" + (get-date -uformat %s) + ".log"
"Last exit code is: $ec " > $logfile
if ($ec -ne "0")
{
  $err = (Get-Content $summary) | Select-String -Pattern "Exit message:" | %{$_ -replace "\s+Exit message:\s+", ""}
  $err += "`n Check installation logs at $summary"
  $err >> $logfile
  Throw $err
}

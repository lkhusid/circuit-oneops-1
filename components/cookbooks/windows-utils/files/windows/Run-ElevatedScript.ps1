param(
    [parameter(Mandatory=$true)]
    [string]$ExeFile,
    [parameter(Mandatory=$false)]
    [int]$Timeout = 1500,
    [parameter(Mandatory=$false)]
    [string]$User = "NT AUTHORITY\SYSTEM",
    [parameter(Mandatory=$false)]
    [String]$Password
)
$ErrorActionPreference = 'Stop'

$ps_exe = "powershell.exe"
$taskname = (Get-Item $ExeFile).BaseName + "-" + (get-date -uformat %s)
$ErrFile = Join-Path (Get-Item $ExeFile).Directory ((Get-Item $ExeFile).BaseName + ".err")

$ExtendedArgList = "-NoLogo -NonInteractive -NoProfile -ExecutionPolicy Bypass -InputFormat None" + " -File $ExeFile"
$action = New-ScheduledTaskAction -Execute $ps_exe -Argument $ExtendedArgList

if ($Password)
{
  $Password_enc = $Password | ConvertTo-SecureString
  $Credential = New-Object System.Management.Automation.PSCredential($User,$Password_enc)
  Register-ScheduledTask -Action $action -TaskName $taskname -Description "Temporary task to execute a command as $User" -User $User -Password $Credential.GetNetworkCredential().Password |Start-ScheduledTask
}
else
{
  Register-ScheduledTask -Action $action -TaskName $taskname -Description "Temporary task to execute a command as $User" -User $User |Start-ScheduledTask
}

start-sleep 10

$duration = 0
$start = get-date -uformat %s

#wait until the task either finishes or times out
while ((schtasks.exe /query /TN "$taskname" /FO CSV | ConvertFrom-Csv | select -expandproperty Status -first 1) -ne "Ready")
{
  $duration = (get-date -uformat %s) - $start
  if ($duration -gt $Timeout)
  {
    $msg = "Stopping task ${$taskname}: Timeout has expired."
    Stop-ScheduledTask -TaskName $taskname
  }
  else
    {start-sleep 30}
}

$TaskResult = (Get-ScheduledTask -TaskName $taskname |Get-ScheduledTaskInfo).LastTaskResult

if ($TaskResult -ne 0)
{
  Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
  
  #Search for error file
  If (Test-Path $ErrFile)
    { $ErrorMessage = Get-Content -Path $ErrFile}
  else
  { if ($msg) 
      { $ErrorMessage = $msg }
    else
      { $ErrorMessage = "Unspecified error $TaskResult" }
  }

  throw $ErrorMessage
}

Unregister-ScheduledTask -TaskName $taskname -Confirm:$false

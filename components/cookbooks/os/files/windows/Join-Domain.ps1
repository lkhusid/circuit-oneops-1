param(
    [parameter(Mandatory=$true)]
    [string]$domain,
    [parameter(Mandatory=$true)]
    [string]$password,
    [parameter(Mandatory=$true)]
    [string]$username
)

$password2 = $password | ConvertTo-SecureString -asPlainText -Force
$username2 = $domain +"\" + $username
$credential = New-Object System.Management.Automation.PSCredential($username2,$password2)

#Generate OU path
$oupath = 'OU=Servers,'
foreach ($a in $domain.Split('.')) { $oupath += 'DC='+$a + ',' }
$oupath = $oupath.Substring(0,$oupath.Length-1)
  
Add-Computer -DomainName $domain -Credential $credential -Force -ErrorAction Stop -OUPath $oupath

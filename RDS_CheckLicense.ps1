# Author : VCNTQA (November 2021)
# Description : Get RDS License Info
# Parameters :
#           -server    : Target server name
#           -username  : Account to connect to target server
#           -password  : Password for the account
# Return codes of script:
# 		0 OK
#			1 Target server connection error
#			2 Cannot get RDS Key Pack info
# Update : VCNTQA (May 2022)
#          - solve the problem of remote session return value
param (
    [string]$server   ,
    [string]$username ,
    [string]$password 
)

$ErrorPreference = "Stop"

# check parameters
if (!$server -or !$username -or !$password)
{
	$output  = @'
<prtg>
<error>1</error>
<text>1 or more missing parameters. Expected parameters are : -server &lt;server&gt; -domain &lt;domain&gt; -username &lt;username&gt; -password &lt;password&gt; -taskpath &lt;taskpath&gt; -taskname &lt;taskname&gt; </text>
</prtg>
'@
	write-output $output
	exit 2
}

$encPwd = ConvertTo-SecureString "$password" -AsPlainText -Force
$cred   = New-Object System.Management.Automation.PSCredential ($username, $encPwd )
try{
    $pss = New-PSSession -ComputerName "$server" -Credential $cred
}catch{
    $output = @"
<prtg>
<error>1</error>
<text>Unable to establish connection to remote server $server</text>
</prtg>
"@
    Write-output $output
    exit 1
}

try{
	$WarningPreference = "SilentlyContinue"
    $LicenseInfo= Invoke-Command -Session $pss -ScriptBlock{
		Get-WmiObject Win32_TSLicenseKeyPack | where TypeAndModel -eq 'RDS Per User CAL' | select AvailableLicenses,IssuedLicenses,TotalLicenses
    }
}catch{
		$output  = @'
<prtg>
<error>1</error>
<text>Error retrieving license key pack information from RDS Manager.</text>
</prtg>
'@
		Write-output $output
		exit 2
}
	
if (!$LicenseInfo){
		$output  = @"
<prtg>
<error>1</error>
<text>No license key pack found in RDS Manager.</text>
</prtg>
"@
		Write-output $output
		exit 2
}

$AvailableLicense_NO = $LicenseInfo.AvailableLicenses
$IssuedLicenses_NO   = $LicenseInfo.IssuedLicenses
$TotalLicenses_NO    = $LicenseInfo.TotalLicenses

$output = @"
<prtg>
<result>
<channel>AvailableLicenses</channel>
<value>$AvailableLicense_NO</value>
<LimitMode>1</LimitMode>
<LimitMinError>0.5</LimitMinError>
<LimitErrorMsg>No available RDS license.</LimitErrorMsg>
</result>

<result>
<channel>IssuedLicenses</channel>
<value>$IssuedLicenses_NO</value>
</result>

<result>
<channel>TotalLicenses</channel>
<value>$TotalLicenses_NO</value>
</result>

<text>TotalLicenses: $TotalLicenses_NO; AvailableLicenses: $AvailableLicense_NO.</text>
</prtg>
"@

Write-output $output
exit 0

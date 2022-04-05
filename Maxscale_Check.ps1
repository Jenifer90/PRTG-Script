# Author      : VCNTAQ       (Mars 2022)
# Description :
#            PRTG custom script sensor with the following information on Maxscale service (MariaDB) :
#             - Role   : Maxscale server role (Master, Slave, Maintenance)
#             - Status : Server status (Running, Down)
# Parameters:
#           - server       : The DNS name of server with floating IP
#           - username     : Username to connect to Maxscale Rest API
#           - password     : Password of the login account
#           - node         : The DNS name of the node(server) of Maxscale
#           - expectedrole : Expected role of the node (Master, Slave, Maintenance)
# Display   : XML PRTG Custom Sensor
# Exit Code :
#           0 : ok
#           1 : Connection Error
#           2 : Impossible to get required information
# Creation Date : 2022-03-28
# Modification :
#           2022-03-29 :
#           Add parameters $expectedrole, $seconds_behind_master,$gtid

param (
    [string]$server      ,
    [string]$username    ,
    [string]$password    ,
    [string]$node        , 
    [string]$expectedrole 
)

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'SilentlyContinue'

# check parameters
if (!$server -or !$username -or !$password -or !$node -or !$expectedrole)
{
	$output  = @'
<prtg>
<error>1</error>
<text>1 or more missing parameters. Expected parameters are : -server &lt;server&gt; -username &lt;username&gt; -password &lt;password&gt;-node &lt;node&gt; -expectedrole &lt;expectedrole&gt;</text>
</prtg>
'@
	write-output $output
	exit 2
}

$url_template = 'http://{0}:8989/v1/servers/{1}'

$encPwd = ConvertTo-SecureString "$password" -AsPlainText -Force
$cred   = New-Object System.Management.Automation.PSCredential ($username, $encPwd )

try{
    $url = $url_template -f $server,$node
    $response = Invoke-RestMethod -Uri $url -Credential $cred
}catch{
    $status_code = $_.Exception.Response.StatusCode.value__ 
    $status_description = $_.Exception.Response.StatusDescription
	$output  = @"
<prtg>
<error>1</error>
<text>Can not get the requested URL $url. $status_code $status_description. </text>
</prtg>
"@
    write-output $output
    exit 1
}

try{
    $attributes   = $response.data.attributes
    $server_state = $attributes.state
    $gtid         = $attributes.gtid_current_pos

    $states = $server_state -split ',' 
    $role   = $states[0]
}catch {
	$output  = @"
<prtg>
<error>1</error>
<text>Can not get maxscale server information. </text>
</prtg>
"@
    write-output $output
    exit 2
}

#Parse data
$ErrorFound = $false
$text       = "$server_state / GTID = $gtid"

# switch seconde behind master depends on role       
switch ($role)
{
    'Master'     { $seconds_behind_master = 0 }                                                       
    'Slave'      { $seconds_behind_master = $attributes.slave_connections[0].seconds_behind_master }
	  'Maintenance'{ $seconds_behind_master = 0 }
   	default      { $IsErrorFound=$true }
}

# switch result to PRTG result:
switch ($server_state)
{
    'Master, Running'      { $server_role_prtg_text=0; $server_state_prtg = 0; } 
    'Master, Down'         { $server_role_prtg_text=0; $server_state_prtg = 1; }
    'Slave, Running'       { $server_role_prtg_text=1; $server_state_prtg = 0; }  
    'Slave, Down'          { $server_role_prtg_text=1; $server_state_prtg = 1; }
    'Maintenance, Running' { $server_role_prtg_text=2; $server_state_prtg = 0; } 
    'Maintenance, Down'    { $server_role_prtg_text=2; $server_state_prtg = 1; }
	  default       {$IsErrorFound=$true }
}

if ($IsErrorFound)
{
    $output  = @"
<prtg>
<error>1</error>
<text>Unexpected format of node state. State: $server_state </text>
</prtg>
"@
    write-output $output
    exit 2
}

$expectedrole_prtg = if ($role -eq $expectedrole) {0} else {1}

$output = @"
<prtg>
<text>$text</text>

<result>
<channel>Node Role</channel>
<value>$server_role_prtg_text</value>
<ValueLookup>acmi.Maxscale.NodeRole</ValueLookup>
</result>

<result>
<channel>Node state</channel>
<value>$server_state_prtg</value>
<ValueLookup>acmi.Maxscale.NodeStatus</ValueLookup>
</result>

<result>
<channel>Seconds behind master</channel>
<value>$seconds_behind_master</value>
<unit>Custom</unit> 
<customunit>seconds</customunit>
<LimitMode>1</LimitMode>
<LimitMaxError>5</LimitMaxError>
</result>

<result>
<channel>Expected role</channel>
<value>$expectedrole_prtg</value>
<LimitMode>1</LimitMode>
<LimitMaxError>1</LimitMaxError>
</result>


</prtg>
"@
write-output $output
exit 0

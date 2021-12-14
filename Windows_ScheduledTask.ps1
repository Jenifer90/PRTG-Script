# Author      : VCNTAQ       (October 2021)
# Description : Get the last execution result and time of scheduled task
# Parameters  :
#     -server    : Target server name
#     -domain    : Domain name
#     -username  : Account to connect to target server
#     -password  : Password for the account
#     -taskname  : Scheduled task name
# Return codes of script:
#     - 0 OK
#     - 1 Target server connection error
#     - 2 Cannot get scheduled taskpath or taksname info
# PRTG Channel vlookup file:
#     - customized.WindowsScheduledTask.Status.ovl (https://github.com/VCNTQA/PRTG-Script/blob/main/customized.WindowsScheduledTask.Status.ovl)
# INFO (LastResult of scheduled task):
#     - 0 The operation completed successfully.
#     - 1 Incorrect function called or unknown function called.
#     - 2 File not found.
#     - 267009 (0x00041301) Currently running.
#     - more retunr codes could be found https://en.wikipedia.org/wiki/Windows_Task_Scheduler

param (
    [string]$server   ,
    [string]$username ,
    [string]$domain   ,
    [string]$password ,
    [string]$taskname 
)

$ErrorPreference = "Stop"

# check parameters
if (!$server -or !$username -or !$domain -or !$password -or !$taskname)
{
    $output  = @"
<prtg>
<error>1</error>
<text>1 or more missing parameters. Expected parameters are : -server &lt;server&gt; -domain &lt;domain&gt; -username &lt;username&gt; -password &lt;password&gt; -taskname &lt;taskname&gt; </text>
</prtg>
"@
    write-output $output
    exit 2
}

# Create Component object Schedule.Service
try{
    $schedule = new-object -com("Schedule.Service")
    $schedule.connect($server, $username, $domain, $password)
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

# Get task info
try{
    $task = $schedule.getfolder('\').gettask("\$taskname")
}catch{
    $output  = @"
<prtg>
<error>1</error>
<text>Error retrieving scheduled task $taskname from target server $server</text>
</prtg>
"@
    Write-output $output
    exit 2        
}

# Get LastRunTime and calculate task age
try{
    $task_lastruntime 	 = $task.LastRunTime 
    $task_lasttaskresult = $task.LastTaskResult
    $task_age_hours      = [math]::round(((Get-Date) - $task_lastruntime).Totalhours,2)
}catch{
   $output  = @"
<prtg>
<error>1</error>
<text>Error retrieving scheduled task information from target server $server</text>
</prtg>
"@
    Write-output $output
    exit 2    
}

# switch result to prtg result:
switch ($task_lasttaskresult)
{
    0       {$task_lasttaskresult_prtg=0; $task_lasttaskresult_text='is successful'}       # 0                    : 0 => Successful
    267009  {$task_lasttaskresult_prtg=1; $task_lasttaskresult_text='is running'}          # 267009 (0x00041301)  : 1 => Currently running
    default {$task_lasttaskresult_prtg=2; $task_lasttaskresult_text='is in error'}         # default              : 2 => Error
}

    $output = @"
<prtg>

<result>
<channel>Last Run Result</channel>
<value>$task_lasttaskresult_prtg</value>
<valuelookup>customized.WindowsScheduledTask.Status</valuelookup>
</result>

<result>
<channel>Task Age</channel>
<value>$task_age_hours</value>
<Float>1</Float>
<unit>Custom</unit> 
<customunit>hours</customunit>
</result>

<text>Task $($task.Name) $task_lasttaskresult_text (Last Run Time $task_lastruntime)</text>
</prtg>
"@

Write-output $output
exit 0

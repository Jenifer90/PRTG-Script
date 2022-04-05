# Adavanced Script Examples
Adavanced script examples for PRTG administrators to monitor systems and applications

## Python scripts list
### VMware
- Get VCSA availables updates via VMware api [VCSA_Updates.py](https://github.com/VCNTQA/PRTG-Script/blob/main/VCSA_Updates.py)


## Powershell scripts list
### Windows
- Get Windows scheduled task last result and task age

  >If there is more than one action in the scheduled task, the last result may be another code:
  -2147020576 ([0x800710E0](https://windows-hexerror.linestarve.com/0x800710E0) *The operator or administrator has refused the request*) during the execution.
  The recommanded solution is to merge these actions into one action if possible.
  
  - [Windows_ScheduledTask.ps1](https://github.com/VCNTQA/PRTG-Script/blob/main/Windows_ScheduledTask.ps1)
  - [customized.WindowsScheduledTask.Status.ovl](https://github.com/VCNTQA/PRTG-Script/blob/main/customized.WindowsScheduledTask.Status.ovl)
  
### Linux
- Get Maxscale servers information (node role, node status, and replication info).
 
  -  [Maxscale_check.ps1](https://github.com/VCNTQA/PRTG-Script/blob/main/Maxscale_Check.ps1)
  - [customized.WindowsScheduledTask.Status.ovl]()


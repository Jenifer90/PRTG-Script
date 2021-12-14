# Adavanced Script Examples
Adavanced Script Examples for PRTG administrators to monitor systems and applications

## Python scripts list
### VMware
- Get VCSA availables updates via VMware api [PYTHON - VCSA_Updates](https://github.com/Jenifer90/PRTG-Script/commit/62336114510bc96d77ba61f92d1a6f91d3d60210)


## Powershell scripts list
### Windows
- Get Windows scheduled task last result and task age
  - [Windows_ScheduledTask.ps1](https://github.com/VCNTQA/PRTG-Script/blob/main/Windows_ScheduledTask.ps1)
  - [customized.WindowsScheduledTask.Status.ovl](https://github.com/VCNTQA/PRTG-Script/blob/main/customized.WindowsScheduledTask.Status.ovl)

    If there is more than one action in the scheduled task, the last result may be another code -2147020576 ([0x800710E0](https://windows-hexerror.linestarve.com/0x800710E0)
    *The operator or administrator has refused the request*) during the execution.
    The recommanded solution is to merge these actions into one action if possible.

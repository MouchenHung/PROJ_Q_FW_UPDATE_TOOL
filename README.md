# PROJ_Q_FW_UPDATE_TOOL
Automatic process from firmware transfer to update.

### Purpose:
    Automatic process from firmware transfer to update..

### First rlease date:
    * v1.0.0 - 2023/01/31

### Version:
- 1.0.0 - First commit - 2023/01/31
  - Feature:
  	- Support **--force** while running script
    - Support new ssh tab while running script
    - Support IP customized from default 10.10.15.166
  - Bug:
  	- none

### Required:
- OS
  - Linux: support
  - Windows: none
- Enviroment
  - script

### Usage
  Format: ./fwupdate.sh **<fru_name>** **<comp_name>** **<fw_path>** **<(optional)server_ip>**
    - fru_name: See BMC's spec
    - comp_name: See BMC's spec
    - fw_path: local fw path
    - server_ip: (optional)server's ip
```
mouchen@mouchen-System-Product-Name:~$ ./fwupdate.sh slot1 1ou_bic ~/Desktop/Y35BRF.bin 10.10.14.171
==================================
APP NAME: FW UPDATE TOOL
APP VERSION: 1.1.0
APP RELEASE DATE: 2023/01/31
==================================
Modify default ip from 10.10.15.166 to 10.10.14.171

Need new tab(y/others)?
y
Open new ssh tab...

Need force update(y/others)?
y
Force update enable...

<SCRIPT START>
<inf> Initial LOG.

[STEP0]. Check info...
Server info:
* ip:       10.10.14.171
* account:  root
* password: 0penBmc

Image info:
* fw fru:       slot1
* fw component: 1ou_bic
* fw name:      Y35BRF.bin

[STEP1]. Do pre-task work...
SCP image to target...
Start MCTP daemon...
[2023/01/31 17:36:22] <wrn> Failed to start mctp daemon!
[STEP2]. Do main-task work...
[2023/01/31 17:36:22] <inf> Start update!
slot_id: 1, comp: e, intf: 0, img: /Y35BRF.bin, force: 1
This image is not for Yv3.5 platform 
There is no valid platform signature in image. 
file size = 229288 bytes, slot = 1, intf = 0x5
updating fw on slot 1:
updated bic: 100 %ok: run: sensord: (pid 5196) 0s

Elapsed time:  14   sec.

get new SDR cache from BIC 
Force upgrade of slot1 : 1ou_bic succeeded
[2023/01/31 17:36:44] <inf> PASS!
[STEP3]. Do post-task work...
1OU Bridge-IC Version: oby35-rf-v2023.03.01
<inf> Exit LOG.

<SCRIPT END>
```

### Note
- 1: none.

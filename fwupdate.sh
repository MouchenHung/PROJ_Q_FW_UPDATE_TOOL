#!/bin/bash

APP_VERSION="1.1.0"
APP_DATE="2023/01/31"

echo "=================================="
echo "APP NAME: FW UPDATE TOOL"
echo "APP VERSION: $APP_VERSION"
echo "APP RELEASE DATE: $APP_DATE"
echo "=================================="

ip="10.10.15.166"
account="root"
password="0penBmc"

if [ $# -lt 3 ]; then
    echo "Usage: $0 [fru_name] [comp_name] [fw_path] [(optional)server_ip]"
	echo "Server info:"
	echo "  * ip:       $ip"
	echo "  * account:  $account"
	echo "  * password: $password"
	echo "Note:"
	echo "  1. [fw_path] means local fw path"
	echo "  2. fwupdate command format"
	echo "     fw-util [fru_name] --update [comp_name] /fw_name"
	echo "  3. Given [server_ip] to replace default ip"
    exit
fi

if [ "$4" != "" ]; then
	echo "Modify default ip from $ip to $4"
	echo ""
	ip=$4
fi

SCRIPT_NAME=$0
FRU_NAME=$1
COMP_NAME=$2
LOCAL_FW_PATH=$3
FW_NAME=`echo $LOCAL_FW_PATH | rev | cut -d "/" -f 1 | rev`
FORCE_UPDATE_FLAG="n"

remote_fw_path="/"

sshpass_cmd="sshpass -p $password ssh $account@$ip"
scp_cmd="sshpass -p $password scp $LOCAL_FW_PATH $account@$ip:$remote_fw_path"

fw_util_cmd="/usr/bin/fw-util"
pwr_util_cmd="/usr/local/bin/power-util"
sol_util_cmd="/usr/local/bin/sol-util"
sv_cmd="/usr/bin/sv"

daemon_mctp="mctpd_3"
daemon_sensor="sensord"

# --------------------------------- LOG lib --------------------------------- #
LOG_FILE="./log.txt"
rec_lock=0

# Reset
COLOR_OFF='\033[0m'       # Text Reset

# Regular Colors
COLOR_BLACK='\033[0;30m'        # Black
COLOR_RED='\033[0;31m'          # Red
COLOR_GREEN='\033[0;32m'        # Green
COLOR_YELLOW='\033[0;33m'       # Yellow
COLOR_BLUE='\033[0;34m'         # Blue
COLOR_PURPLE='\033[0;35m'       # Purple
COLOR_CYAN='\033[0;36m'         # Cyan
COLOR_WHITE='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White

HDR_LOG_ERR="err"
HDR_LOG_WRN="wrn"
HDR_LOG_INF="inf"
HDR_LOG_DBG="dbg"

COLOR_PRINT() {
	local text=$1
	local text_color=$2

	if [[ "$text_color" == "BLACK" ]]; then
		echo -e ${COLOR_BLACK}${text}${COLOR_OFF}
	elif [[ "$text_color" == "RED" ]]; then
		echo -e ${COLOR_RED}${text}${COLOR_OFF}
	elif [[ "$text_color" == "GREEN" ]]; then
		echo -e ${COLOR_GREEN}${text}${COLOR_OFF}
	elif [[ "$text_color" == "YELLOW" ]]; then
		echo -e ${COLOR_YELLOW}${text}${COLOR_OFF}
	elif [[ "$text_color" == "BLUE" ]]; then
		echo -e ${COLOR_BLUE}${text}${COLOR_OFF}
	elif [[ "$text_color" == "PURPLE" ]]; then
		echo -e ${COLOR_PURPLE}${text}${COLOR_OFF}
	elif [[ "$text_color" == "CYAN" ]]; then
		echo -e ${COLOR_CYAN}${text}${COLOR_OFF}
	elif [[ "$text_color" == "WHITE" ]]; then
		echo -e ${COLOR_WHITE}${text}${COLOR_OFF}
	else
		echo $text
	fi
}

RECORD_INIT() {
	if [[ "$rec_lock" != 0 ]]; then
		COLOR_PRINT "<err> Log record already on going!" "RED"
		return
	fi

	local script_name=$1
	COLOR_PRINT "<inf> Initial LOG." "BLUE"
	echo ""
	local now="$(date +'%Y/%m/%d %H:%M:%S')"
	echo "[$now] <$HDR_LOG_INF> Start record log for script $script_name" > $LOG_FILE
	rec_lock=1
}

RECORD_EXIT() {
	if [[ "$rec_lock" != 1 ]]; then
		COLOR_PRINT "<err> Log record havn't init yet!" "RED"
		return
	fi

	local script_name=$1
	COLOR_PRINT "<inf> Exit LOG." "BLUE"
	echo ""
	local now="$(date +'%Y/%m/%d %H:%M:%S')"
	echo "[$now] <$HDR_LOG_INF> Stop record log for script $script_name" >> $LOG_FILE
	rec_lock=0
}

RECORD_LOG() {
	if [[ "$rec_lock" != 1 ]]; then
		COLOR_PRINT "<err> Log record havn't init yet!" "RED"
		return
	fi

	local hdr=$1
	local msg=$2
	local flag=$3
	local color

	if [[ "$hdr" == "$HDR_LOG_ERR" ]]; then
		hdr="<$hdr>"
		color="RED"
	elif [[ "$hdr" == "$HDR_LOG_WRN" ]]; then
		hdr="<$hdr>"
		color="YELLOW"
	elif [[ "$hdr" == "$HDR_LOG_DBG" ]]; then
		hdr="<$hdr>"
		color="PURPLE"
	elif [[ "$hdr" == "$HDR_LOG_INF" ]]; then
		hdr="<$hdr>"
		color="WHITE"
	fi

	local now="$(date +'%Y/%m/%d %H:%M:%S')"
	if [[ "$flag" == 0 ]]; then
		COLOR_PRINT "[$now] $hdr $msg" $color
	elif [[ "$flag" == 1 ]]; then
		echo "[$now] $hdr $msg" >> $LOG_FILE
	else
		COLOR_PRINT "[$now] $hdr $msg" $color
		echo "[$now] $hdr $msg" >> $LOG_FILE
	fi
}
# --------------------------------- LOG lib --------------------------------- #

# --------------------------------- TIMER lib --------------------------------- #
TIMER_COUNT_DOWN() {
	local mode=$1
	local counter=$2
	local unit
	local unit_name

	if [[ "$mode" == "sec" ]]; then
		unit=1
		unit_name="seconds"
	elif [[ "$mode" == "min" ]]; then
		unit=60
		unit_name="minutes"
	else
		COLOR_PRINT "<err> TIMER_COUNT_DOWN: Invalid mode!" "RED"
		return
	fi

	COLOR_PRINT "<inf> Start timer count down with $counter $unit_name" "WHITE"
	while((1)); do
		echo -e "wait for $counter $unit_name...\r\c" 0
		sleep $unit

		counter=$((counter-1))
		if [[ "$counter" == "0" ]]; then
			COLOR_PRINT "<inf> Count down finish!" "WHITE"
			break
		fi
	done
}
# --------------------------------- TIMER lib --------------------------------- #

# --------------------------------- PLATFORM TASK func --------------------------------- #
OPEN_NEW_SSH_WITH_TAB() {
	tab_title=$1
	gnome-terminal --tab --title="$tab_title" -- bash -c "$sshpass_cmd ;bash"
}
# --------------------------------- PLATFORM TASK func --------------------------------- #

# --------------------------------- COMMON TASK func --------------------------------- #
PRE_TASK() {
	COLOR_PRINT "SCP image to target..." "BLUE"
	$scp_cmd >> $LOG_FILE
	if [[ "$?" != 0 ]]; then
		RECORD_LOG $HDR_LOG_ERR "failed to scp image to target!" 2
		exit 1
	fi

	COLOR_PRINT "Start MCTP daemon..." "BLUE"
	$sshpass_cmd $sv_cmd start $daemon_mctp >> $LOG_FILE
	if [[ "$?" != 0 ]]; then
		RECORD_LOG $HDR_LOG_WRN "Failed to start mctp daemon!" 2
		#exit 1
	fi
}

POST_TASK() {
	$sshpass_cmd $fw_util_cmd $FRU_NAME --version $COMP_NAME

	if [[ "$?" != 0 ]]; then
		RECORD_LOG $HDR_LOG_ERR "Failed to read version from $COMP_NAME!" 2
		break
	fi
}

MAIN_TASK() {
	RECORD_LOG $HDR_LOG_INF "Start update!"
	if [ "$FORCE_UPDATE_FLAG" != "y" ]; then
		$sshpass_cmd $fw_util_cmd $FRU_NAME --update $COMP_NAME $remote_fw_path$FW_NAME
	else
		$sshpass_cmd $fw_util_cmd $FRU_NAME --force --update $COMP_NAME $remote_fw_path$FW_NAME
	fi

	if [[ "$?" != 0 ]]; then
		RECORD_LOG $HDR_LOG_ERR "Failed to update $COMP_NAME!" 2
		break
	fi

	RECORD_LOG $HDR_LOG_INF "PASS!"
}
# --------------------------------- COMMON TASK func --------------------------------- #

echo "Need new tab(y/others)?"
read -r b
if [ "$b" == "y" ]; then
	echo "Open new ssh tab..."
	OPEN_NEW_SSH_WITH_TAB "bmc console"
else
	echo "Skip creating new tab"
fi
echo ""

echo "Need force update(y/others)?"
read -r b
if [ "$b" == "y" ]; then
	echo "Force update enable..."
	FORCE_UPDATE_FLAG="y"
else
	echo "Do normal update"
fi
echo ""

COLOR_PRINT "<SCRIPT START>" "GREEN"
RECORD_INIT $SCRIPT_NAME

COLOR_PRINT "[STEP0]. Check info..." "BLUE"
echo "Server info:"
echo "* ip:       $ip"
echo "* account:  $account"
echo "* password: $password"
echo ""
echo "Image info:"
echo "* fw fru:       $FRU_NAME"
echo "* fw component: $COMP_NAME"
echo "* fw name:      $FW_NAME"
echo ""

COLOR_PRINT "[STEP1]. Do pre-task work..." "BLUE"
PRE_TASK

COLOR_PRINT "[STEP2]. Do main-task work..." "BLUE"
MAIN_TASK

sleep 3

COLOR_PRINT "[STEP3]. Do post-task work..." "BLUE"
POST_TASK

RECORD_EXIT $SCRIPT_NAME
COLOR_PRINT "<SCRIPT END>" "GREEN"

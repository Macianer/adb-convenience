#!/bin/sh

source bashUtils/sub_script/dir_helper.sh
source bashUtils/sub_script/text_helper.sh

export ADB_LOG_DIR="logs"
createDir $ADB_LOG_DIR

log(){
	if [ -z "$1" ]; then
		echo "missing command name or missing device"
		exit 1
	fi

	COMMAND=$1
	DEVICE=$2
	LOG_FILE="command_log.csv"
	TIMESTAMP=$(date +"%F %T")
	echo "$TIMESTAMP;$DEVICE;$COMMAND" >> $ADB_LOG_DIR/$LOG_FILE
}

copyLogFromPath(){
	if [ -z "$1" ]; then
		echo "missing path name"
		exit 1
	fi
	PATH=$1
for DEVICE in `adb devices | grep -v "List" | awk '{print $1}'`
do
	adb -s $DEVICE pull $PATH/. $ADB_LOG_DIR/${DEVICE}/copied_logs/.
	log "${DEVICE}" "copyLog"
done
}

# only works after display is off
stepIdleDeviceMode(){
	print_info "dd"
for DEVICE in `adb devices | grep -v "List" | awk '{print $1}'`
do
	# required battery unplug
	adb -s $DEVICE shell dumpsys battery unplug
	STATE=$(adb -s $DEVICE shell dumpsys deviceidle step)
	print_info ${STATE}
	log "${DEVICE}" "stepIdleDeviceMode ${STATE}"
done
}


# require no unplug and display off
#
forceIdleDeviceMode(){
for DEVICE in `adb devices | grep -v "List" | awk '{print $1}'`
do
	STATE=$(adb -s $DEVICE shell dumpsys deviceidle force-idle)
	print_info ${STATE}
	log "${DEVICE}" "forceIdleDeviceMode ${STATE}"
done


}
# invoke doze for a specific package name
# usage: invokeDoze "com.package.xy"
invokeDoze() {
	if [ -z "$1" ]; then
		echo "missing package name"
		exit 1
	fi
	PackageName=$1
	for DEVICE in `adb devices | grep -v "List" | awk '{print $1}'`
	do
		adb -s $DEVICE shell dumpsys battery unplug
		adb -s $DEVICE shell am set-inactive $PackageName true
		log "$DEVICE" "invokeDoze $state"
	done
}

# revoke doze for a specific package name
# usage: invokeDoze "com.package.xy"
revokeDoze(){
	if [ -z "$1" ]; then
		echo "missing package name"
		exit 1
	fi
	PackageName=$1
	for DEVICE in `adb devices | grep -v "List" | awk '{print $1}'`
	do

	adb -s $DEVICE shell am set-inactive $PackageName false
	adb -s $DEVICE shell am get-inactive $PackageName
	log "$DEVICE" "revokeDoze $state"
	done

}

sendBatteryChanged(){
	for DEVICE in `adb devices | grep -v "List" | awk '{print $1}'`
	do
		adb shell am broadcast -a android.intent.action.BATTERY_CHANGED --ez present false --ei state 2 --ei level 50
		log "$DEVICE" "sendBatteryChanged"
	done
}

grantLocationPermissions(){
	if [ -z "$1" ]; then
		echo "missing package name"
		exit 1
	fi
	PackageName=$1
	adb shell pm grant ACCESS_FINE_LOCATION $PackageName
}

revokeLocationPermissions(){
	if [ -z "$1" ]; then
		echo "missing package name"
		exit 1
	fi
	PackageName=$1
	adb shell pm revoke ACCESS_FINE_LOCATION $PackageName
}

sendBootCompleted(){
	for DEVICE in `adb devices | grep -v "List" | awk '{print $1}'`
		do
		if [ -z "$1" ]; then
			echo "reboot without package name"
			adb shell am broadcast -a android.intent.action.BOOT_COMPLETED
			log "$DEVICE" "sendBootCompleted full"
		exit 1
		fi
		PackageName=$1
  	adb shell am broadcast -a android.intent.action.BOOT_COMPLETED -p $PackageName
  	log "$DEVICE" "sendBootCompleted $PackageName"
	done
}

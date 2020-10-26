#!/system/bin/sh

# Installation script customize.sh for Magisk Module Systemless Debloater (REPLACE).
# XDA thread: https://forum.xda-developers.com/mi-9t/how-to/magisk-module-systemless-debloater-t4180083
# Module debloates /system, /vendor and /product apps by searching (at the time of module installation) and listing their paths to the Magisk Module Installer REPLACE variable. 
# Magisk then creates local system tree that will be (systemlessly) overlaid into the /system at every (re)boot. 
# It can be used for any Android - just add/remove your unwanted stock app names to /Download/SystemlessDebloaterList.sh script on Internal memory, (re)install the module and reboot.
# Log will be saved to /Download/SystemlessDebloater.log also to Internal memory.
# Before debloating the apps, from Settings/Applications, Uninstall (updates) and Clear Data!
# Copyright (c) zgfg @ xda, 2020

# Magisk Module Installer variable
REPLACE=""

# Module's folder
MyFolder=/storage/emulated/0/Download
# Alternative path to Internal memory
# MyFolder=/sdcard/Download

# Module's version
MyVersion=v1.3.5

# Log file
LogFile=$MyFolder/SystemlessDebloater.log
LogLine="Magisk Module Systemless Debloater (REPLACE) $MyVersion"
echo $LogLine
echo "$LogLine log file." > $LogFile
echo ${0} >> $LogFile
echo $(date +%c) >> $LogFile
Prop=$(getprop ro.build.version.release)
LogLine='Android '$Prop
Prop=$(getprop ro.build.system_root_image)
if [ ! -z "$Prop" ] && [ "$Prop" ]
then
	LogLine=$LogLine' SAR'
fi
Prop=$(getprop ro.build.ab_update)
if [ ! -z "$Prop" ] && [ "$Prop" ]
then
	LogLine=$LogLine' A/B'
fi
echo $LogLine >> $LogFile
echo $LogLine

# Default/empty list of app names for debloating 
DebloatList=""

# Input file with a list of app names for debloating
DebloatListFile=$MyFolder/SystemlessDebloaterList.sh

#Simple example for DebloatList var for the input file SystemlessDebloaterList.sh:
#DebloatList="EasterEgg CatchLog Traceur wps_lite"

# Check if the input list file exists
if [ -f $DebloatListFile ]
then
	# Log the file path
	LogLine="$DebloatListFile - input debloat list file"
	echo $LogLine >> $LogFile
	echo $LogLine
	# Source the input file
	. $DebloatListFile
else
	# Log error
	LogLine="$DebloatListFile --- input debloat list not found, creating a template file!"
	echo $LogLine >> $LogFile
	echo $LogLine
	echo "# Input debloat list $DebloatListFile for Magisk Module Systemless Debloater (REPLACE) $MyVersion" > $DebloatListFile
	echo '# Before debloating the apps, from Settings/Applications, Uninstall (updates) and Clear Data!' >> $DebloatListFile
	echo "# Systemless Debloater log: $LogFile" >> $DebloatListFile
	echo '# Copyright (c) zgfg @ xda, 2020' >> $DebloatListFile
	echo ' ' >> $DebloatListFile
	echo '# Define a list of stock apps for debloating:' >> $DebloatListFile
	echo 'DebloatList=""' >> $DebloatListFile
	echo ' ' >> $DebloatListFile
	echo '# MIUI Example (commented out):' >> $DebloatListFile
	echo '# DebloatList="AnalyticsCore BasicDreams BookmarkProvider ' >> $DebloatListFile 
	echo '# CatchLog EasterEgg facebook-appmanager FileExplorer_old ' >> $DebloatListFile
	echo '# HybridAccessory HybridPlatform IdMipay InMipay Joyose ' >> $DebloatListFile
	echo '# MiPicks MiuiBugReport MiuiDaemon MiWallpaper MSA-Global ' >> $DebloatListFile 
	echo '# Netflix_activation PartnerBookmarksProvider PaymentService ' >> $DebloatListFile 
	echo '# Stk TouchAssistant Traceur Zman MiCreditInStub ' >> $DebloatListFile
	echo '# facebook-installer facebook-services GameCenterGlobal ' >> $DebloatListFile
	echo '# GlobalMinusScreen MiBrowserGlobal MiDrop MiRcs MiRecycle ' >> $DebloatListFile
	echo '# MiService MiuiBrowserGlobal YellowPage PhotoTable ' >> $DebloatListFile
	echo '# GoogleFeedback GooglePartnerSetup Turbo SoterService ' >> $DebloatListFile
	echo '# GlobalFashiongallery MiBrowserGlobalVendor wps_lite"' >> $DebloatListFile
fi

# Log the list of app names for debloating 
echo DebloatList='"'$DebloatList'"' >> $LogFile

# Iterate through the app names for debloating
for AppName in $DebloatList
do
	FilePath=""; FolderPath=""
	# Search for the system application path
	# Look for the apk name if the app was not debloated yet, or dummy .replace file if already debloated
	for FileName in $AppName.apk .replace
	do
		SubPath=*app/$AppName/$FileName
		if [ -z "$FilePath" ]
		then
			FilePath=$(readlink -f /system/$SubPath)
			if [ -z "$FilePath" ]
			then
				FilePath=$(readlink -f /system/*/$SubPath)
				for MountPoint in /product /vendor
				do
					if [ -z "$FilePath" ]
					then
						FilePath=$(readlink -f $MountPoint/$SubPath)					
					fi
				done
			fi
		fi

		# Check if the path was found
		if [ -z "$FolderPath" ] && [ ! -z "$FilePath" ]
		then
			# Remove /filename from the end
			FolderPath=$(echo $FilePath | sed "s,/$FileName$,,g")
			# Prepend /system if not beginning with
			if [ -z $(echo $FolderPath | grep "^/system") ]
			then
				FolderPath=/system$FolderPath
			fi
			# Log the path
			echo "$FolderPath - debloat" >> $LogFile
			# Append to the REPLACE var
			REPLACE="$REPLACE$FolderPath "	
		fi
	done

	if [ -z "$FilePath" ]
	then
		# Log app name if not found
		LogLine="$AppName --- app not found!"
		echo $LogLine >> $LogFile
		echo $LogLine
	fi
done

if [ -z "$REPLACE" ]
then
	LogLine="No app for debloating found!"
	echo $LogLine >> $LogFile
	echo $LogLine
	LogLine='Before debloating the apps, from Settings/Applications, Uninstall (updates) and Clear Data!'
	echo $LogLine >> $LogFile
	echo $LogLine
fi

# Log the REPLACE var
echo REPLACE='"'$REPLACE'"' >> $LogFile

# Note to read the log
echo "Systemless Debloater log: $LogFile"

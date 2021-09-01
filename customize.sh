#!/system/bin/sh

# Installation script customize.sh for Magisk Module Systemless Debloater (REPLACE).
# XDA thread: https://forum.xda-developers.com/mi-9t/how-to/magisk-module-systemless-debloater-t4180083
# Module debloates /system, /system_ext, /product, /vendor and /india apps by searching (at the time of module installation) and listing their paths to the Magisk Module Installer REPLACE variable. 
# Magisk then creates local system tree that will be (systemlessly) overlaid into the /system at every (re)boot. 
# It can be used for any Android - just add/remove your unwanted stock app names to /Download/SystemlessDebloaterList.sh script on Internal memory, (re)install the module and reboot.
# Log will be saved to /Download/SystemlessDebloater.log also to Internal memory.
# Before debloating the apps, from Settings/Applications, Uninstall (updates) and Clear Data for them!
# Copyright (c) zgfg @ xda, 2020-2021

# Magisk Module Installer variable
REPLACE=""

# Module's folder
MyFolder=/storage/emulated/0/Download

# Alternative path to Internal memory
# MyFolder=/sdcard/Download

# Module's version
MyVersion=v1.4.2

# Log file
LogFile=$MyFolder/SystemlessDebloater.log
LogLine="Magisk Module Systemless Debloater (REPLACE) $MyVersion"
echo "$LogLine"
echo "$LogLine log file." > $LogFile
LogLine='Copyright (c) zgfg @ xda, 2020-2021' 
echo "$LogLine"
echo "$LogLine" >> $LogFile
echo '' >> $LogFile
# Log date and system info
echo "$(date +%c)" >> $LogFile
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
echo "$LogLine"
echo "$LogLine" >> $LogFile
echo '' >> $LogFile

# Default/empty list of app names for debloating and debloated app names 
DebloatList=""
DebloatedList=""

#Simple example for DebloatList var for the input file SystemlessDebloaterList.sh:
#DebloatList="EasterEgg CatchLog Traceur wps_lite"

# Input file with a list of app names for debloating
DebloatListFile=$MyFolder/SystemlessDebloaterList.sh
LogLine="Input debloat list file: $DebloatListFile"												 					  
echo "$LogLine"
echo "$LogLine" >> $LogFile
echo '' >> $LogFile

# Check if the input list file exists
if [ -f $DebloatListFile ]
then
	# Source the input file
	. $DebloatListFile
else
	# Log error
	LogLine='Input file not found, creating a template file!'																					   
	echo "$LogLine"
	echo "$LogLine" >> $LogFile
	echo "# Input debloat list $DebloatListFile for Magisk Module Systemless Debloater (REPLACE) $MyVersion" > $DebloatListFile
	echo '# Before debloating the apps, from Settings/Applications, Uninstall (updates) and Clear Data for them!' >> $DebloatListFile
	echo "# Systemless Debloater log: $LogFile" >> $DebloatListFile
	echo '# Copyright (c) zgfg @ xda, 2020-2021' >> $DebloatListFile
	echo ' ' >> $DebloatListFile
	echo '# Define a list of stock apps for debloating:' >> $DebloatListFile
	echo 'DebloatList=""' >> $DebloatListFile
	echo ' ' >> $DebloatListFile
	echo '# MIUI Example (commented out):' >> $DebloatListFile	
	echo '# DebloatList="AnalyticsCore AntHalService BasicDreams ' >> $DebloatListFile 
	echo '# BookmarkProvider CatchLog Chrome CneApp EasterEgg ' >> $DebloatListFile
	echo '# facebook-appmanager facebook-installer facebook-services ' >> $DebloatListFile
	echo '# FileExplorer_old GlobalFashiongallery GlobalMinusScreen ' >> $DebloatListFile 
	echo '# Gmail2 GoogleFeedback GooglePartnerSetup HybridAccessory ' >> $DebloatListFile 
	echo '# HybridPlatform IdMipay InMipay Joyose MiBrowserGlobal ' >> $DebloatListFile
	echo '# MiBrowserGlobalVendor MiCreditInStub MiDrop ' >> $DebloatListFile
	echo '# MiLinkService2 MiPicks MiPlayClient MiRcs MiRecycle ' >> $DebloatListFile
	echo '# MiService MiuiBrowserGlobal MiuiBugReport MiuiDaemon ' >> $DebloatListFile
	echo '# MSA-Global Netflix_activation PartnerBookmarksProvider ' >> $DebloatListFile
	echo '# PaymentService PhotoTable Stk TouchAssistant Traceur ' >> $DebloatListFile
	echo '# Turbo uceShimService Velvet VsimCore wps_lite YellowPage ' >> $DebloatListFile
	echo '# Zman"' >> $DebloatListFile
fi

# Log input DebloatList 
echo 'Input-DebloatList="'"$DebloatList"'"' >> $LogFile
echo '' >> $LogFile

# List installed packages
Packages=$(pm list packages -f | sed 's!^package:!!g')
PackageInfoList=""
for PackageInfo in $Packages
do
	# Skip user applications
	if [ ! -z $(echo "$PackageInfo" | grep '^/data') ]
	then
		continue
	fi				
			
	# Prepend /system to package path if not beginning with
	if [ -z $(echo "$PackageInfo" | grep '^/system/') ]
	then
		PackageInfo=/system$PackageInfo
	fi				
			
	# Append to the PackageInfoList
	PackageInfoList="$PackageInfoList$PackageInfo"$'\n'
done

# SAR mount-points
MountPointList="/product /system_ext /vendor /india"

# Iterate through the app names for debloating
echo 'Debloating:' >> $LogFile
for AppName in $DebloatList
do
	FilePath=""
	FolderPath=""
	
	# Search for the system application path
	# Look for the apk name if the app was not debloated yet, or dummy .replace file if already debloated
	SubPathList="*app/*/$AppName.apk *app/$AppName/.replace"
	for SubPath in $SubPathList 
	do
		if [ -z "$FilePath" ]
		then
			FilePath=$(readlink -f /system/$SubPath)
			if [ -z "$FilePath" ]
			then
				FilePath=$(readlink -f /system/*/$SubPath)
				for MountPoint in $MountPointList 
				do
					if [ ! -z "$FilePath" ]
					then
						break					
					fi
					FilePath=$(readlink -f $MountPoint/$SubPath)					
				done
			fi
		fi

		# Check if the path was found
		if [ -z "$FolderPath" ] && [ ! -z "$FilePath" ]
		then

			# Prepend /system if file path not beginning with
			if [ -z $(echo "$FilePath" | grep '^/system/') ]
			then
				FilePath=/system$FilePath
			fi
			
			# Find the corresponding package
			PackageInfo=$(echo "$PackageInfoList" | grep "$FilePath")
			PackageName=""

			# Extract package name
			if [ ! -z "$PackageInfo" ]
			then
				PackageName=$(echo "$PackageInfo" | sed "s!^$FilePath=!!")
				PackageName="($PackageName) "
			fi

			# Remove /filename from the end of the path
			FileName=${FilePath##*/}
			FolderPath=$(echo "$FilePath" | sed "s,/$FileName$,,")
			
			# Log the path and package name
			echo "$FolderPath $PackageName" >> $LogFile
			
			# Append to REPLACE var
			REPLACE="$REPLACE$FolderPath"$'\n'
			
			# Append to DebloatedList
			DebloatedList="$DebloatedList$AppName"$'\n'
		fi
	done

	if [ -z "$FilePath" ]
	then
		# Log app name if not found
		LogLine="$AppName --- app not found!"
		echo "$LogLine"
		echo "$LogLine" >> $LogFile
	fi
done
echo '' >> $LogFile

if [ -z "$REPLACE" ]
then
	LogLine="No app for debloating found!"
	echo "$LogLine"
	echo "$LogLine" >> $LogFile
	LogLine='Before debloating the apps, from Settings/Applications, Uninstall (updates) and Clear Data for them!'
	echo "$LogLine"
	echo "$LogLine" >> $LogFile
	echo '' >> $LogFile
fi

# Sort and log DebloatedList
DebloatedList=$(echo "$DebloatedList" | sort -fu )
echo 'DebloatedList="'"$DebloatedList"$'\n"' >> $LogFile
echo '' >> $LogFile

# Sort and log REPLACE list
REPLACE=$(echo "$REPLACE" | sort -fu )
#echo 'REPLACE="'"$REPLACE"$'\n"' >> $LogFile
#echo '' >> $LogFile

# List system apps
lsCommand='ls -l'
SubPath=*app/*/*.apk
AppList=$(echo "$lsCommand /system/$SubPath" | sed "s!^$lsCommand!!")
AppList="$AppList "$(echo "$lsCommand /system/*/$SubPath" | sed "s!^$lsCommand!!")

# Log system apps, not debloated
echo 'System apps, not debloated:' >> $LogFile
for FilePath in $AppList
do
	# Remove /filename from the end of the path
	FileName=${FilePath##*/}
	FolderPath=$(echo "$FilePath" | sed "s,/$FileName$,,")

	# Skip if debloated
	if [ ! -z $(echo "$REPLACE" | grep "$FolderPath") ]
	then
		continue
	fi

	# Find the corresponding package
	PackageInfo=$(echo "$PackageInfoList" | grep "$FilePath")
	PackageName=""
	if [ ! -z $PackageInfo ]
	then
		# Extract package name
		PackageName=$(echo "$PackageInfo" | sed "s!^$FilePath=!!")
		PackageName="($PackageName) "
	fi

	# Log the path and package name
	echo "$FolderPath $PackageName" >> $LogFile
 
done
echo '' >> $LogFile

# Replace newline delimiters by spaces in the REPLACE list
#REPLACE=$(echo "$REPLACE" | tr "\n" " ")

# Note for the log file
echo "Systemless Debloater log: $LogFile"

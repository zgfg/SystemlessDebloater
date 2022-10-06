f#!/system/bin/sh

# Installation script customize.sh for Magisk Module Systemless Debloater (REPLACE).
# XDA thread: https://forum.xda-developers.com/mi-9t/how-to/magisk-module-systemless-debloater-t4180083
# GitHub source: https://github.com/zgfg/SystemlessDebloater
# Module debloates /system, /system_ext, /product, /vendor and /india apps by searching (at the time of module installation) and listing their paths to the Magisk Module Installer REPLACE variable. 
# Magisk then creates local system tree that will be (systemlessly) overlaid into the /system at every (re)boot. 
# It can be used for any Android - just add/remove your unwanted Stock app names to /Download/SystemlessDebloaterList.sh script on Internal memory, (re)install the module and reboot.
# Log will be saved to /Download/SystemlessDebloater.log also to Internal memory.
# Before debloating the apps, from Settings/Applications, Uninstall (updates) and Clear Data for them!
# Copyright (c) zgfg @ xda, 2020-2022

# Magisk Module Installer variable
REPLACE=""

# Module's folder
LogFolder=/storage/emulated/0/Download

# Alternative path to Internal memory
# LogFolder=/sdcard/Download

# Module's version
MyVersion=v1.4.9


# Log file
LogFile=$LogFolder/SystemlessDebloater.log
LogLine="Magisk Module Systemless Debloater (REPLACE) $MyVersion"
#echo "$LogLine"
echo "$LogLine log file." > $LogFile
LogLine='Copyright (c) zgfg @ xda, 2020-2022' 
#echo "$LogLine"
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
Prop=$(getprop ro.boot.slot_suffix)
if [ ! -z "$Prop" ] && [ "$Prop" ]
then
	LogLine=$LogLine" ($Prop)"
fi
echo "$LogLine"
echo "$LogLine" >> $LogFile
LogLine=$(magisk -c)
echo "$LogLine"
echo "$LogLine" >> $LogFile
echo '' >> $LogFile

echo "MODPATH: $MODPATH" >> $LogFile
echo '' >> $LogFile

# Default SAR mount-points (SAR partitions to search for debloating)
SarMountPointList="/product /vendor /system_ext /india /my_bigball"

# Default/empty list of app names for debloating and debloated app names 
DebloatList=""
DebloatedList=""

# Verbose logging 
VerboseLog="true"

# Searching for possible several instances of Stock apps for debloating  
MultiDebloat="true"


# Simple example for DebloatList var for the input file SystemlessDebloaterList.sh:
#DebloatList="EasterEgg CatchLog Traceur wps_lite"

# Input file with a list of app names for debloating
DebloatListFile=$LogFolder/SystemlessDebloaterList.sh
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
	echo '# Copyright (c) zgfg @ xda, 2020-2022' >> $DebloatListFile
	echo ' ' >> $DebloatListFile
	echo '# Define a list of Stock apps for debloating:' >> $DebloatListFile
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

# Log input SarMountPointList 
echo 'Input-SarMountPointList="'"$SarMountPointList"'"' >> $LogFile
echo '' >> $LogFile

# Log input DebloatList 
echo 'Input-DebloatList="'"$DebloatList"'"' >> $LogFile
echo '' >> $LogFile

echo "Verbose logging: $VerboseLog" >> $LogFile
echo '' >> $LogFile
echo "Multiple search/debloat: $MultiDebloat" >> $LogFile
echo '' >> $LogFile


# Add /system to SarMountPointList, sort and log
TempList="/system $SarMountPointList"
SarMountPointList=""
for SarMountPoint in $TempList
do		
	SarMountPointList="$SarMountPointList$SarMountPoint"$'\n'
done

SarMountPointList=$(echo "$SarMountPointList" | sort -bu )

# List Stock packages
Packages=$(pm list packages -f | sed 's!^package:!!g')
PackageInfoList=""
for PackageInfo in $Packages
do
	# Skip user applications
	if [ ! -z $(echo "$PackageInfo" | grep '^/data') ]
	then
		continue
	fi

	# Include applications from SAR mount points
	for SarMountPoint in $SarMountPointList
	do		
		if [ -z $(echo "$PackageInfo" | grep '^$SarMountPoint/') ]
		then
			PrepPackageInfo=$PackageInfo

			# Append to the PackageInfoList
			PackageInfoList="$PackageInfoList$PrepPackageInfo"$'\n'
			
			break
		fi
	done
done

# Sort PackageInfoList
PackageInfoList=$(echo "$PackageInfoList" | sort -bu )


#Search for Stock apps
StockAppList=""
for SarMountPoint in $SarMountPointList
do
	NewList=$(find "$SarMountPoint/" -type f -name "*.apk" 2> /dev/null)

	if [ ! -z "$NewList" ]
	then
		StockAppList="$StockAppList$NewList"$'\n'
	fi
done

# Sort StockAppList
#StockAppList=$(echo "$StockAppList" | sort -bu )


#Search for previously debloated Stock apps
ReplacedAppList=""
for SarMountPoint in $SarMountPointList 
do
	NewList=$(find "$SarMountPoint/" -type f -name ".replace" 2> /dev/null)

	if [ ! -z "$NewList" ]
	then
		ReplacedAppList="$ReplacedAppList$NewList"$'\n'
	fi
done

# Sort and log ReplacedAppList
#ReplacedAppList=$(echo "$ReplacedAppList" | sort -bu )

echo "Previously debloated Stock apps:"$'\n'"$ReplacedAppList" >> $LogFile


# Prepare service.sh file to debloat Stock but not System apps
ServiceFile="$MODPATH/service.sh"
echo "ServiceFile: $ServiceFile" >> $LogFile
echo '' >> $LogFile

touch $ServiceFile

if [ ! -z "$VerboseLog" ]
then
	# Log file for service.sh
	ServiceLine='ServiceLogFolder=/data/local/tmp'
	echo "$ServiceLine" >> $ServiceFile
	ServiceLine='ServiceLogFile="$ServiceLogFolder/SystemlessDebloater-service.log"'
	echo "$ServiceLine" >> $ServiceFile
	echo '' >> $ServiceFile

	ServiceLine='echo "$(date +%c)" > $ServiceLogFile'
	echo "$ServiceLine" >> $ServiceFile
	ServiceLine='echo "" >> $ServiceLogFile'
	echo "$ServiceLine" >> $ServiceFile
	echo '' >> $ServiceFile
fi

# Module's folder
MODDIR=$(echo "$MODPATH" | sed "s!/modules_update/!/modules/!")
ServiceLine="MODDIR=$MODDIR"
echo "$ServiceLine" >> $ServiceFile

if [ ! -z "$VerboseLog" ]
then	
	ServiceLine='echo "MODDIR: $MODDIR" >> $ServiceLogFile'
	echo "$ServiceLine" >> $ServiceFile
	ServiceLine='echo "" >> $ServiceLogFile'
	echo "$ServiceLine" >> $ServiceFile
	echo '' >> $ServiceFile
fi

# Dummy apk used for debloating
ServiceLine='DummyApk=$MODDIR/dummy.apk'
echo "$ServiceLine" >> $ServiceFile
ServiceLine='touch $DummyApk'
echo "$ServiceLine" >> $ServiceFile
echo '' >> $ServiceFile

if [ ! -z "$VerboseLog" ]
then
	ServiceLine='echo "DummyApk: $DummyApk" >> $ServiceLogFile'
	echo "$ServiceLine" >> $ServiceFile
	ServiceLine='echo "" >> $ServiceLogFile'
	echo "$ServiceLine" >> $ServiceFile
	echo '' >> $ServiceFile
fi

# Mount and bind for debloating
ServiceLine='MountBind="mount -o bind"'
echo "$ServiceLine" >> $ServiceFile

# List of apps to debloat by mounting
MountList=""


# Sort DebloatList
DebloatList=$(echo "$DebloatList" | sort -bu )

# Iterate through apps for debloating
echo 'Debloating:' >> $LogFile
for AppName in $DebloatList
do
	AppFound=""

	#Search through previously debloated Stock apps	
	SearchName=/"$AppName"/.replace
	SearchList=$(echo "$ReplacedAppList" | grep "$SearchName$")
	for FilePath in $SearchList
	do
		# Break if app already found
		if [ -z "$MultiDebloat" ]
		then
			if [ ! -z "$AppFound" ] 
			then
				break					
			fi
		fi
	
		# Remove /filename from the end of the path
		FileName=${FilePath##*/}
		FolderPath=$(echo "$FilePath" | sed "s,/$FileName$,,")
					
		if [ ! -z "FolderPath" ]
		then
			AppFound="true"

			# Log the full path
			echo "found: $FilePath" >> $LogFile
				
			if [ -z $(echo "$FolderPath" | grep '^/system/') ]
			then
				# Append to MountList with appended AppName
				MountList="$MountList$FolderPath/$AppName.apk"$'\n'			
			else
				# Append to REPLACE list
				REPLACE="$REPLACE$FolderPath"$'\n'			
			fi
			
			# Append to DebloatedList
			DebloatedList="$DebloatedList$AppName"$'\n'
		fi
	done

	#Search through Stock apps	
	SearchName=/"$AppName".apk
	SearchList=$(echo "$StockAppList" | grep "$SearchName$")
	for FilePath in $SearchList
	do
		if [ -z "$MultiDebloat" ]
		then
			if [ ! -z "$AppFound" ] 
			then
				break					
			fi
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
					
		if [ ! -z "FolderPath" ]
		then
			AppFound="true"

			# Log the full path and package name
			echo "found: $FilePath $PackageName" >> $LogFile

			if [ -z $(echo "$FolderPath" | grep '^/system/') ]
			then
				# Append to MountList
				MountList="$MountList$FilePath"$'\n'			
			else
				# Append to REPLACE list
				REPLACE="$REPLACE$FolderPath"$'\n'			
			fi
			
			# Append to DebloatedList
			DebloatedList="$DebloatedList$AppName"$'\n'
		fi
	done
	
	if [ -z "$AppFound" ]
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
DebloatedList=$(echo "$DebloatedList" | sort -bu )
echo 'DebloatedList="'"$DebloatedList"$'\n"' >> $LogFile
echo '' >> $LogFile

# Sort and log REPLACE list
REPLACE=$(echo "$REPLACE" | sort -bu )
echo 'REPLACE="'"$REPLACE"$'\n"' >> $LogFile
echo '' >> $LogFile

# Sort and log MountList 
MountList=$(echo "$MountList" | sort -bu )
echo 'MountList="'"$MountList"$'\n"' >> $LogFile
echo '' >> $LogFile

# Debloat by mounting in servise.sh
for MountApk in $MountList
do
	ServiceLine='$MountBind $DummyApk '"$MountApk"
	echo "$ServiceLine" >> $ServiceFile
done


# Log Stock apps and packages
if [ ! -z "$VerboseLog" ]
then
	echo "Stock apps:"$'\n'"$StockAppList" >> $LogFile
	echo "Stock packages: $PackageInfoList" >> $LogFile
fi


# Note for the log file
echo "Systemless Debloater log: $LogFile"

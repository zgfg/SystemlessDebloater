#!/system/bin/sh

# Installation script customize.sh for Magisk Module Systemless Debloater (REPLACE).
# XDA thread: https://forum.xda-developers.com/mi-9t/how-to/magisk-module-systemless-debloater-t4180083
# GitHub source: https://github.com/zgfg/SystemlessDebloater
# Module debloates /system, /system_ext, /product, /vendor and /india apps by searching (at the time of module installation) and listing their paths to the Magisk Module Installer REPLACE variable. 
# Magisk then creates local system tree that will be (systemlessly) overlaid into the /system at every (re)boot. 
# It can be used for any Android - just add/remove your unwanted stock app names to /Download/SystemlessDebloaterList.sh script on Internal memory, (re)install the module and reboot.
# Log will be saved to /Download/SystemlessDebloater.log also to Internal memory.
# Before debloating the apps, from Settings/Applications, Uninstall (updates) and Clear Data for them!
# Copyright (c) zgfg @ xda, 2020-2022

# Magisk Module Installer variable
REPLACE=""

# Module's folder
MyFolder=/storage/emulated/0/Download

# Alternative path to Internal memory
# MyFolder=/sdcard/Download

# Module's version
MyVersion=v1.4.8

# Log file
LogFile=$MyFolder/SystemlessDebloater.log
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


# Default SAR mount-points (system partitions to search for debloating)
SarMountPointList="/product /vendor /system_ext /india"

# Default/empty list of app names for debloating and debloated app names 
DebloatList=""
DebloatedList=""

# Verbose logging 
VerboseLog="true"

# Searching for possible several instances of system apps for debloating  
MultiDebloat="true"


# Simple example for DebloatList var for the input file SystemlessDebloaterList.sh:
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
	echo '# Copyright (c) zgfg @ xda, 2020-2022' >> $DebloatListFile
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

# Log input SarMountPointList 
echo 'Input-SarMountPointList="'"$SarMountPointList"'"' >> $LogFile
echo '' >> $LogFile

# Log input DebloatList 
echo 'Input-DebloatList="'"$DebloatList"'"' >> $LogFile
echo '' >> $LogFile

if [ ! -z "$VerboseLog" ]
then
	echo "Verbose logging: $VerboseLog" >> $LogFile
	echo "Multiple search/debloat: $MultiDebloat" >> $LogFile
	echo '' >> $LogFile
fi

# List system packages
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
	for SarMountPoint in "/system $SarMountPointList"
	do		
		if [ -z $(echo "$PackageInfo" | grep '^$SarMountPoint') ]
		then
			PrepPackageInfo=$PackageInfo
			# Prepend /system to package path if not beginning with
			if [ -z $(echo "$PrepPackageInfo" | grep '^/system/') ]
			then
				PrepPackageInfo=/system$PrepPackageInfo
			fi				
			
			# Append to the PackageInfoList
			PackageInfoList="$PackageInfoList$PrepPackageInfo"$'\n'
			
			break
		fi
	done
done

# Sort PackageInfoList
PackageInfoList=$(echo "$PackageInfoList" | sort -fu )


#Search for mounted system apps
AppList=""
for SarMountPoint in $SarMountPointList 
do
	AppList="$AppList "$(find "$SarMountPoint" -type f -name "*.apk" 2> /dev/null)
done

#List system apps
SystemAppList=""
for FilePath in $AppList
do
	AppPath=$FilePath

	# Prepend /system if file path not beginning with
	if [ -z $(echo "$AppPath" | grep '^/system/') ]
	then
		AppPath=/system$AppPath
	fi

	# Append to the SystemAppList
	SystemAppList="$SystemAppList $AppPath"$'\n'
done
SystemAppList="$SystemAppList "$(find /system -type f -name "*.apk" 2> /dev/null)

# Sort and log SystemAppList
SystemAppList=$(echo "$SystemAppList" | sort -fu )
#echo "System apps: $SystemAppList" >> $LogFile
#echo '' >> $LogFile


#Search for mounted and previously debloated system apps
AppList=""
for SarMountPoint in $SarMountPointList 
do
	AppList="$AppList "$(find "$SarMountPoint" -type f -name ".replace" 2> /dev/null)
done

#List previously debloated system apps
ReplacedAppList=""
for FilePath in $AppList
do
	AppPath=$FilePath

	# Prepend /system if file path not beginning with
	if [ -z $(echo "$AppPath" | grep '^/system/') ]
	then
		AppPath=/system$AppPath
	fi

	# Append to the ReplacedAppList
	ReplacedAppList="$ReplacedAppList $AppPath"$'\n'
done
ReplacedAppList="$ReplacedAppList "$(find /system -type f -name ".replace" 2> /dev/null)

# Sort and log ReplacedAppList
ReplacedAppList=$(echo "$ReplacedAppList" | sort -fu )

if [ ! -z "$VerboseLog" ]
then
	echo "Previously debloated system apps:"$'\n'"$ReplacedAppList" >> $LogFile
	echo '' >> $LogFile
fi


# Sort DebloatList
DebloatList=$(echo "$DebloatList" | sort -fu )

# Iterate through apps for debloating
echo 'Debloating:' >> $LogFile
for AppName in $DebloatList
do
	AppFound=""

	#Search through previously debloated system apps	
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
				
			# Append to REPLACE var
			REPLACE="$REPLACE$FolderPath"$'\n'
			
			# Append to DebloatedList
			DebloatedList="$DebloatedList$AppName"$'\n'
		fi
	done

	#Search through system apps	
	SearchName=/"$AppName".apk
	SearchList=$(echo "$SystemAppList" | grep "$SearchName$")
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

			# Append to REPLACE var
			REPLACE="$REPLACE$FolderPath"$'\n'
			
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
DebloatedList=$(echo "$DebloatedList" | sort -fu )
echo 'DebloatedList="'"$DebloatedList"$'\n"' >> $LogFile
echo '' >> $LogFile

# Sort and log REPLACE list
REPLACE=$(echo "$REPLACE" | sort -fu )
echo 'REPLACE="'"$REPLACE"$'\n"' >> $LogFile
echo '' >> $LogFile

# Replace newline delimiters by spaces in the REPLACE list
#REPLACE=$(echo "$REPLACE" | tr "\n" " ")


if [ ! -z "$VerboseLog" ]
then
	# List not debloated system apps
	NotDebloatedList=""
	for FilePath in $SystemAppList
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

		# Append to the NotDebloatedList
		NotDebloatedList="$NotDebloatedList$FolderPath $PackageName"$'\n'
	done

	# Sort and log NotDebloatedList
	NotDebloatedList=$(echo "$NotDebloatedList" | sort -fu )
	echo "System apps, not debloated: $NotDebloatedList" >> $LogFile
	echo '' >> $LogFile

	# Log System packages:
	echo "System packages: $PackageInfoList" >> $LogFile
	echo '' >> $LogFile
fi


# Note for the log file
echo "Systemless Debloater log: $LogFile"

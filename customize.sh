#!/system/bin/sh

# Magisk Module: Systemless Debloater v1.5.4a
# Copyright (c) zgfg @ xda, 2020-
# Config file improvements provided by ipdev @ xda
# XDA thread: https://forum.xda-developers.com/t/magisk-module-systemless-debloater.4180083
# GitHub source: https://github.com/zgfg/SystemlessDebloater

if [ -z $BOOTMODE ] || [ "$BOOTMODE" != "true" ]
then
	abort "ERROR: Install from Magisk app, not from TWRP!"
fi


# Module's version
MyVersion=v1.5.4a

# Module's folder (upon the installation and reboot)
ModFolder=$(echo "$MODPATH" | sed "s!/modules_update/!/modules/!")

# Download folder
LogFolder=/sdcard/Download
# Alternative path to Internal memory
#LogFolder=/storage/emulated/0/Download

# Log file
LogFile=$LogFolder/SystemlessDebloater.log
echo "Magisk Module: Systemless Debloater $MyVersion log file." > $LogFile
echo 'Copyright (c) zgfg @ xda, 2020-' >> $LogFile
echo 'Config file improvements provided by ipdev @ xda' >> $LogFile
echo "Installation start time: $(date +%c)" >> $LogFile
echo '' >> $LogFile

# Log system info
Prop=$(getprop ro.product.cpu.abilist)
if [ ! -z "$Prop" ] && [ "$Prop" ]
then
	echo "$Prop" | tee -a $LogFile
fi
Prop=$(getprop ro.build.version.release)
PrintLine='Android '$Prop
Prop=$(getprop ro.build.system_root_image)
if [ ! -z "$Prop" ] && [ "$Prop" ]
then
	PrintLine=$PrintLine' SAR'
fi
Prop=$(getprop ro.build.ab_update)
if [ ! -z "$Prop" ] && [ "$Prop" ]
then
	PrintLine=$PrintLine' A/B'
fi
Prop=$(getprop ro.boot.slot_suffix)
if [ ! -z "$Prop" ] && [ "$Prop" ]
then
	PrintLine=$PrintLine" ($Prop)"
fi
echo "$PrintLine" | tee -a $LogFile
echo $(magisk -c) | tee -a $LogFile
echo '' >> $LogFile


# Verbose logging
VerboseLog="true"

# Default SAR mount-points (SAR partitions to search for debloating)
#SarMountPointList="/system product /vendor /system_ext /india /my_bigball"
SarMountPointList=""

# Invalid paths for (systemless) debloating
#InvalidMountPointList="/data /apex /framework"
InvalidMountPointList="/data /framework"

# Default/empty list of app names for debloating and debloated app names
DebloatList=""
DebloatedList=""

# Simple example for DebloatList var for the input file SystemlessDebloaterList.sh:
#DebloatList="EasterEgg CatchLog Traceur wps_lite"

# Searching for possible several instances of Stock apps for debloating
MultiDebloat="true"

# For Magisk v26, there is no more .replace file in REPLACEd folders on the /system side
# Potential problems when reinstalling/updating the module, to find the previously REPLACEd stock apps
# To avoid, force all debloating by mounting through service.sh
ForceMountList="true"


# Input and config files
InputFile=$LogFolder/SystemlessDebloaterList.sh
ConfigFile=$LogFolder/SystemlessDebloater.cfg
ExampleConfigFile=$MODPATH/SystemlessDebloater.cfg

# Check for the old input file
if [ -f "$InputFile" ]
then
	# Source the old input file
	echo 'Input source file: '$InputFile | tee -a $LogFile
	. $InputFile

	if [ ! -f "$ConfigFile" ]
	then
		echo 'Please delete your old '$InputFile | tee -a $LogFile
	fi

	echo '' >> $LogFile
fi

# Check for the config file
if [ -f "$ConfigFile" ]
then
	echo 'Input config file: '$ConfigFile | tee -a $LogFile
	echo '' >> $LogFile

	# Clean the config file format and save to a temporary file
	TmpConfigFile=$MODPATH/TmpSystemlessDebloater.cfg
	sed -e '/^#/d' -e 's/#.*//g' -e 's/\"//g' -e 's/[ \t ]//g' -e '/^$/d' $ConfigFile > $TmpConfigFile

	# Append new line to the temporary config if not present
	if [ -n "$(tail -c1 $TmpConfigFile)" ]
	then
		echo >> $TmpConfigFile
	fi

	# Read DebloatList
	DebloatList=$'\n'
	while read AppName
	do
		DebloatList="$DebloatList$AppName"$'\n'
	done < $TmpConfigFile

	# Delete the temprary file
	rm -f $TmpConfigFile
else
	# Create the config file
	cp $ExampleConfigFile $ConfigFile

	if [ ! -z "$DebloatList" ]
	then
		echo '## My list of stock apps for debloating:' >> $ConfigFile

		# Transfer DebloatList to the new config file
		for AppName in $DebloatList
		do
			echo $AppName >> $ConfigFile
		done
	fi

	echo 'New config file created: '$ConfigFile | tee -a $LogFile
	echo '' >> $LogFile
fi
rm -f $ExampleConfigFile

echo "Verbose logging: $VerboseLog" >> $LogFile
echo "Multiple search/debloat: $MultiDebloat" >> $LogFile
echo "Force mounting by service.sh: $ForceMountList" >> $LogFile
echo '' >> $LogFile


# List Stock packages
Packages=$(pm list packages -f | sed 's!^package:!!g')


# Log input SarMountPointList
if [ ! -z "$VerboseLog" ] && [ "$VerboseLog" = "true" ]
then
	echo 'Input SarMountPointList="'"$SarMountPointList"'"' >> $LogFile
	echo '' >> $LogFile
fi

# Log InvalidMountPointList
echo 'InvalidMountPointList="'"$InvalidMountPointList"'"' >> $LogFile
echo '' >> $LogFile

# Add /system to SarMountPointList
NewList=$SarMountPointList
SarMountPointList="/system"$'\n'
for Path in $NewList
do
	# Append to SarMountPointList
	SarMountPointList="$SarMountPointList$Path"$'\n'
done

# Search through packages to add potential mount points
for PackageInfo in $Packages
do
	# Extract potential mount point path from PackageInfo
	Path=$(echo "$PackageInfo" | cut -d '/' -f 2)

	# Append to SarMountPointList
	SarMountPointList="$SarMountPointList/$Path"$'\n'
done

# Sort SarMountPointList to remove duplicates
NewList=$(echo "$SarMountPointList" | sort -bu )

# Exclude not valid paths from SarMountPointList
SarMountPointList=""
for Path in $NewList
do
	# Skip not valid paths
	for InvalidPath in $InvalidMountPointList
	do
		if [ "$Path" = "$InvalidPath" ]
		then
			Path=""
			break
		fi
	done

	# Append to SarMountPointList
	if [ ! -z "$Path" ]
	then
		SarMountPointList="$SarMountPointList"$'\n'"$Path"
	fi
done

# Log final SarMountPointList
echo 'Final SarMountPointList="'"$SarMountPointList"'"' >> $LogFile
echo '' >> $LogFile


# Log input DebloatList
echo 'Input DebloatList="'"$DebloatList"'"' >> $LogFile
echo '' >> $LogFile

# Sort DebloatList
NewList=$DebloatList
DebloatList=""
for AppName in $NewList
do
	# Append to DebloatList
	DebloatList="$DebloatList$AppName"$'\n'
done
DebloatList=$(echo "$DebloatList" | sort -bu )

# Log final DebloatList
if [ ! -z "$VerboseLog" ] && [ "$VerboseLog" = "true" ]
then
	echo 'Final DebloatList="'"$DebloatList"'"' >> $LogFile
	echo '' >> $LogFile
fi


# List Stock packages
PackageInfoList=""
for PackageInfo in $Packages
do
	# Include only applications from SAR mount points
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


# Search for previously REPLACEd Stock apps
DotReplace='.replace'
ReplacedAppList=""
for SarMountPoint in $SarMountPointList
do
	NewList=$(find "$SarMountPoint/" -type f -name "$DotReplace" 2> /dev/null)

	if [ ! -z "$NewList" ]
	then
		ReplacedAppList="$ReplacedAppList"$'\n'"$NewList"
	fi
done

# For Magisk v26, there is no more .replace file in REPLACEd folders on the /system side
# When reinstalling the module, search for previously REPLACEd stock apps also in the module's folder
NewList=$(find "$ModFolder/system/" -type f -name "$DotReplace" 2> /dev/null)
if [ ! -z "$NewList" ]
then
	for FilePath in $NewList
	do
		# Extract the corresponding /system path
		FilePath=$(echo "$FilePath" | sed "s!^$ModFolder!!")
		FolderPath=$(echo "$FilePath" | sed "s!$DotReplace$!!")

		# Check if the corresponding /system folder exists
		if [ -d $FolderPath ]
		then
			ReplacedAppList="$ReplacedAppList"$'\n'"$FilePath"
		fi
	done
fi

# Sort ReplacedAppList
ReplacedAppList=$(echo "$ReplacedAppList" | sort -bu )

# Log ReplacedAppList
if [ ! -z "$VerboseLog" ] && [ "$VerboseLog" = "true" ]
then
	echo "Previously REPLACEd Stock apps:$ReplacedAppList"$'\n' >> $LogFile
fi


# List of apps to debloat by REPLACE and by mounting
REPLACE=""
MountList=""

# Iterate through apps for debloating
echo 'Debloating:' >> $LogFile
for AppName in $DebloatList
do
	AppFound=""

	# Search through previously REPLACEd Stock apps
	SearchName="/$AppName/$DotReplace"
	SearchList=$(echo "$ReplacedAppList" | grep "$SearchName$")
	for FilePath in $SearchList
	do
		# Break if app already found
		if [ "$AppFound" = "true" ] && [ "$MultiDebloat" != "true" ]
		then
			break
		fi

		# Remove /filename from the end of the path
		FileName=${FilePath##*/}
		FolderPath=$(echo "$FilePath" | sed "s,/$FileName$,,")

		if [ ! -z "$FolderPath" ]
		then
			AppFound="true"

			# Log the full path
			echo "found: $FilePath" >> $LogFile

			if [ "$ForceMountList" = "true" ] || [ -z $(echo "$FolderPath" | grep '^/system/') ]
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
		# Break if app already found
		if [ "$AppFound" = "true" ] && [ "$MultiDebloat" != "true" ]
		then
			break
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

		if [ ! -z "$FolderPath" ]
		then
			AppFound="true"

			# Log the full path and package name
			echo "found: $FilePath $PackageName" >> $LogFile

			if [ "$ForceMountList" = "true" ] || [ -z $(echo "$FolderPath" | grep '^/system/') ]
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
		echo "$AppName --- app not found!" | tee -a $LogFile
	fi
done
echo '' >> $LogFile

if [ -z "$REPLACE" ] && [ -z "$MountList"]
then
	echo 'No app for debloating found!' | tee -a $LogFile
	echo 'Make sure to uninstall updates and clear data for apps you want to debloat!' | tee -a $LogFile
	echo '' >> $LogFile
fi

# Sort and log DebloatedList
DebloatedList=$(echo "$DebloatedList" | sort -bu )
echo 'DebloatedList="'"$DebloatedList"$'\n"' >> $LogFile
echo '' >> $LogFile

# Sort and log REPLACE list
REPLACE=$(echo "$REPLACE" | sort -bu )
if [ "$ForceMountList" != "true" ]
then
	echo 'REPLACE="'"$REPLACE"$'\n"' >> $LogFile
echo '' >> $LogFile
fi

# Sort and log MountList
MountList=$(echo "$MountList" | sort -bu )
echo 'MountList="'"$MountList"$'\n"' >> $LogFile
echo '' >> $LogFile

# Prepare for debloating/mounting through servise.sh and mountList.sh
MountListFile='mountList.sh'
echo 'MountList="'"$MountList"$'\n"' >> $MODPATH/$MountListFile

# Log the MountListFile path
echo "MountListFile:"$'\n'"$ModFolder/$MountListFile" >> $LogFile
echo '' >> $LogFile


# Log Stock apps and packages
if [ ! -z "$VerboseLog" ] && [ "$VerboseLog" = "true" ]
then
	echo "Stock apps:"$'\n'"$StockAppList" >> $LogFile
	echo "Stock packages: $PackageInfoList" >> $LogFile
echo '' >> $LogFile
fi

# Log installation end time and note for the log file
echo "Installation end time: $(date +%c)" >> $LogFile
echo "Systemless Debloater log: $LogFile"

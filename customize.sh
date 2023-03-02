#!/system/bin/sh

# Magisk Module: Systemless Debloater v1.5.1
# Copyright (c) zgfg @ xda, 2020-
# Config file improvements provided by ipdev @ xda
# XDA thread: https://forum.xda-developers.com/t/magisk-module-systemless-debloater.4180083
# GitHub source: https://github.com/zgfg/SystemlessDebloater

if [ -z $BOOTMODE ] || [ "$BOOTMODE" != "true" ]
then
	abort "ERROR: Install from Magisk app, not from TWRP!"
fi


# Magisk Module Installer variable
REPLACE=""

# Module's folder
LogFolder=/storage/emulated/0/Download

# Alternative path to Internal memory
# LogFolder=/sdcard/Download

# Module's version
MyVersion=v1.5.1


# Log file
LogFile=$LogFolder/SystemlessDebloater.log
echo "Magisk Module: Systemless Debloater $MyVersion log file." > $LogFile
echo 'Copyright (c) zgfg @ xda, 2020-' >> $LogFile
echo 'Config file improvements provided by ipdev @ xda' >> $LogFile
echo "Installation time: $(date +%c)" >> $LogFile
echo '' >> $LogFile

# Log system info
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


# Default SAR mount-points (SAR partitions to search for debloating)
#SarMountPointList="/system product /vendor /system_ext /india /my_bigball"
SarMountPointList=""

# Invalid paths for (systemless) debloating
#InvalidMountPointList="/data /apex /framework"
InvalidMountPointList="/data /framework"

# Default/empty list of app names for debloating and debloated app names
DebloatList=""
DebloatedList=""

# Verbose logging
VerboseLog="true"

# Searching for possible several instances of Stock apps for debloating
MultiDebloat="true"


# Simple example for DebloatList var for the input file SystemlessDebloaterList.sh:
#DebloatList="EasterEgg CatchLog Traceur wps_lite"


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
	sed -e '/^#/d' -e 's/#.*//g' -e 's/\"//g' -e 's/[ \t ]//g' -e '/^\s*$/d' $ConfigFile > $TmpConfigFile

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

# Sort ReplacedAppList
#ReplacedAppList=$(echo "$ReplacedAppList" | sort -bu )

# Log ReplacedAppList
echo "Previously debloated Stock apps:"$'\n'"$ReplacedAppList" >> $LogFile


# Prepare service.sh file to debloat Stock but not System apps
ServiceScript="$MODPATH/service.sh"
echo "ServiceScript: $ServiceScript" >> $LogFile
echo '' >> $LogFile

echo '#!/system/bin/sh' > $ServiceScript
echo '' >> $ServiceScript

echo "# Magisk Module: Systemless Debloater $MyVersion" >> $ServiceScript
echo '# Copyright (c) zgfg @ xda, 2020-' >> $ServiceScript
echo "# Installation time: $(date +%c)" >> $ServiceScript
echo '' >> $ServiceScript

# Log file for service.sh
echo 'ServiceLogFolder=/data/local/tmp' >> $ServiceScript
echo 'ServiceLogFile=$ServiceLogFolder/SystemlessDebloater-service.log' >> $ServiceScript
echo '' >> $ServiceScript

if [ ! -z "$VerboseLog" ] && [ "$VerboseLog" = "true" ]
then
	echo 'echo "Execution time: $(date +%c)" > $ServiceLogFile' >> $ServiceScript
	echo 'echo "" >> $ServiceLogFile' >> $ServiceScript
else
	echo 'rm -f $ServiceLogFile' >> $ServiceScript
fi
echo '' >> $ServiceScript

# Module's own folder
MODDIR=$(echo "$MODPATH" | sed "s!/modules_update/!/modules/!")
echo "MODDIR=$MODDIR" >> $ServiceScript


if [ ! -z "$VerboseLog" ] && [ "$VerboseLog" = "true" ]
then
	echo 'echo "MODDIR: $MODDIR" >> $ServiceLogFile' >> $ServiceScript
	echo 'echo "" >> $ServiceLogFile' >> $ServiceScript
	echo '' >> $ServiceScript
fi

# Dummy apk used for debloating
echo 'DummyApk=$MODDIR/dummy.apk' >> $ServiceScript
echo 'touch $DummyApk' >> $ServiceScript
echo '' >> $ServiceScript

if [ ! -z "$VerboseLog" ] && [ "$VerboseLog" = "true" ]
then
	echo 'echo "DummyApk: $DummyApk" >> $ServiceLogFile' >> $ServiceScript
	echo 'echo "" >> $ServiceLogFile' >> $ServiceScript
	echo '' >> $ServiceScript
fi

# Mount and bind for debloating
echo 'MountBind="mount -o bind"' >> $ServiceScript
echo '' >> $ServiceScript

# List of apps to debloat by mounting
MountList=""


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
		if [ -z "$MultiDebloat" ] && [ "$MultiDebloat" = "true" ]
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
		if [ -z "$MultiDebloat" ] && [ "$MultiDebloatt" = "true" ]
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
		echo "$AppName --- app not found!" | tee -a $LogFile
	fi
done
echo '' >> $LogFile

if [ -z "$REPLACE" ]
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
echo 'REPLACE="'"$REPLACE"$'\n"' >> $LogFile
echo '' >> $LogFile

# Sort and log MountList
MountList=$(echo "$MountList" | sort -bu )
echo 'MountList="'"$MountList"$'\n"' >> $LogFile
echo '' >> $LogFile

# Debloat by mounting in servise.sh
for MountApk in $MountList
do
	PrintLine='$MountBind $DummyApk '"$MountApk"
	echo "$PrintLine" >> $ServiceScript
done


# Log Stock apps and packages
if [ ! -z "$VerboseLog" ] && [ "$VerboseLog" = "true" ]
then
	echo "Stock apps:"$'\n'"$StockAppList" >> $LogFile
	echo "Stock packages: $PackageInfoList" >> $LogFile
fi


# Note for the log file
echo "Systemless Debloater log: $LogFile"

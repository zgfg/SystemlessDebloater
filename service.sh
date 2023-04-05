#!/system/bin/sh

# Magisk Module: Systemless Debloater v1.5.2
# Copyright (c) zgfg @ xda, 2020-


# Module's own path (local path)
MODDIR=${0%/*}

# Log folder and file
ServiceLogFolder=/data/local/tmp
ServiceLogFile=$ServiceLogFolder/SystemlessDebloater-service.log

# Log the start time
echo "Run start time: $(date +%c)" > $ServiceLogFile
echo "" >> $ServiceLogFile

# List of stock apps for debloating by mounting
MountListFile=$MODDIR/mountList.sh
echo "MountListFile:"$'\n'"$MountListFile" >> $ServiceLogFile
echo '' >> $ServiceLogFile

# Source the MountListFile
MountList=""
if [ -f $MountListFile ]
then
  . $MountListFile
fi

# Dummy apk for debloating by mounting 
DummyApk=$MODDIR/dummy.apk
touch $DummyApk
echo "DummyApk:"$'\n'"$DummyApk" >> $ServiceLogFile
echo "" >> $ServiceLogFile

#Debloat by mounting
MountBind="mount -o bind"
for MountApk in $MountList
do
	$MountBind $DummyApk $MountApk >> $ServiceLogFile 2>&1
done

# Log the end time
echo "Run end time : $(date +%c)" >> $ServiceLogFile

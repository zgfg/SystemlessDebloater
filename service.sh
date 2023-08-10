#!/system/bin/sh

# Magisk Module: Systemless Debloater v1.5.3a
# Copyright (c) zgfg @ xda, 2020-

# Module's own path (local path)
MODDIR=${0%/*}

# Log file for debugging
LogFile="$MODDIR/service.log"
exec 3>&1 4>&2 2>$LogFile 1>&2
set -x
date +%c

# Log Magisk version and magisk --path
magisk -c
magisk --path

# Log dual-slots ROM info
getprop ro.product.cpu.abi
getprop ro.product.cpu.abilist

# List of stock apps for debloating by mounting
MountListFile=$MODDIR/mountList.sh

# Source the MountListFile
MountList=""
if [ -f $MountListFile ]
then
  . $MountListFile
fi

# Dummy apk for debloating by mounting 
DummyApk=$MODDIR/dummy.apk
touch $DummyApk

#Debloat by mounting
for MountApk in $MountList
do
	mount -o bind $DummyApk $MountApk
  ls -l $MountApk
done

set +x
exec 1>&3 2>&4 3>&- 4>&-

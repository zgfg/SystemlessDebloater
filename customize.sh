#!/system/bin/sh

# Magisk Module: ToyBox-Ext v1.0.4
# Copyright (c) zgfg @ xda, 2022-
# GitHub source: https://github.com/zgfg/ToyBox-Ext

if [ -z $BOOTMODE ] ||  [ "$BOOTMODE" != "true" ] 
then
	abort "ERROR: Install from Magisk app, not from TWRP!"
fi

# Module's own path (local path)
cd $MODPATH

# toybox ARMv7 and higher binaries
TBBINList="
toybox-aarch64
toybox-armv7m
toybox-armv7l
"

# Find the applicable binary
TBFound=""
for TBBIN in $TBBINList
do
  if [ -z $TBFound ]
  then
    chmod 755 $TBBIN

    # Test if binary executes 
    Applets=$(./$TBBIN)

    if [ ! -z "$Applets" ]
    then
      # Suitable binary found
      echo "Installing $TBBIN binary and applets"
      TBFound=true
      mv $TBBIN toybox-ext
      continue
    fi
  fi

  # Delete binary (already found or doesn't execute)
  rm -f $TBBIN
done

# Applicable binary not found
if [ -z $TBFound ]
then
  echo
  echo ERROR: Platform not supported!
  echo
  getprop | grep 'cpu\.abi'
  echo
  exit -1
fi

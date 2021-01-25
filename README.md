# Systemless Debloater (REPLACE)
### Copyright (c) zgfg @ xda, 2020-2021

### Links [Support]
(https://forum.xda-developers.com/mi-9t/how-to/magisk-module-systemless-debloater-t4180083)

### Description
Module debloates /system, /vendor and /product apps by searching (at the time of module installation) and listing their paths to the Magisk Module Installer REPLACE variable. 
Magisk then creates local system tree that will be (systemlessly) replaced into the /system at every (re)boot. 
It can be used for any Android - just add/remove your unwanted stock app names to DebloatList var in /Download/SystemlessDebloaterList.sh script on Internal memory, (re)install the module and reboot. 
Log will be saved to /Download/SystemlessDebloater.log also on Internal memory.
Before debloating the apps, from Settings/Applications, Uninstall (updates) and Clear Data!

Example for the input file /SystemlessDebloaterList.sh:
DebloatList="EasterEgg CatchLog Traceur wps_lite"

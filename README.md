# ToyBox-Ext

### Description
Systemless Magisk module
to install (additional) ToyBox applets, using **ARMv7 or higher** binaries from:
https://github.com/landley/toybox

**Supported**: ARMv7 and higher 

##### TEST

Ussually, **ToyBox** comes preinstalled to `/system/bin`, but with limited number of **applets**.
The module installes additional `toybox-ext` binary, with the additional applets (**UNIX/Linux command-line utilities**).

**Install** the module and **reboot**. Use **Terminal Emulator** - **Toybox applets** are for Terminal and **shell scripts**.

Make sure that `/system/bin` and/or `/system/xbin` (the latter might not be available on some devices) are in the `PATH`.
Check e.g. with (all commands are **case sensitive**):

```
su
echo $PATH
```

Check if `toybox-ext` was properly installed and is it installed to `/system/xbin` or `/system/bin`:

```
toybox-ext --help
which toybox-ext
```

If the responded toybox-ext path was `/system/xbin` then check:

```
ls -l /system/xbin | grep toybox-ext
```

whereas if the toybox-ext path was `/system/bin` then use:

```
ls -l /system/bin | grep toybox-ext
```

The command will show all toybox-ext applets as installed (symlinked to the toybox-ext binary).
Usually, `w` will be one of them, hence you can try:

```
w
```

**Note 1**: Some applets are common to **BusyBox** and **ToyBox**, e.g. `ascii`.

Hence, if you have also the `busybox` installed, `toybox-ext` will symlink less number of (additional) applets.

**Note 2**: Since ToyBox-Ext **v1.0.2**, the module also looks if there are not-symlinked applets available from the pre-installed toybox binary (ROMs usually come with the pre-installed ToyBox but with smaller or an older binary and with a less number of applets).

For me, the additionally found applets from the pre-installed ToyBox were e.g. `getfattr` and `iotop`.


#### Source 

[My Repo:](https://github.com/zgfg/ToyBox-Ext)

![GitHub release (latest by date)](https://img.shields.io/github/v/release/zgfg/ToyBox-Ext?label=Release&style=plastic) ![GitHub Release Date](https://img.shields.io/github/release-date/zgfg/ToyBox-Ext?label=Release%20Date&style=plastic) 
![GitHub Releases](https://img.shields.io/github/downloads/zgfg/ToyBox-Ext/latest/total?label=Downloads%20%28Latest%20Release%29&style=plastic)
![GitHub All Releases](https://img.shields.io/github/downloads/zgfg/ToyBox-Ext/total?label=Total%20Downloads%20%28All%20Releases%29&style=plastic)

[Alt-Repo:](https://github.com/Magisk-Modules-Alt-Repo/ToyBox-Ext)

![GitHub release (latest by date)](https://img.shields.io/github/v/release/Magisk-Modules-Alt-Repo/ToyBox-Ext?label=Release&style=plastic) ![GitHub Release Date](https://img.shields.io/github/release-date/Magisk-Modules-Alt-Repo/ToyBox-Ext?label=Release%20Date&style=plastic) 
![GitHub Releases](https://img.shields.io/github/downloads/Magisk-Modules-Alt-Repo/ToyBox-Ext/latest/total?label=Downloads%20%28Latest%20Release%29&style=plastic)
![GitHub All Releases](https://img.shields.io/github/downloads/Magisk-Modules-Alt-Repo/ToyBox-Ext/total?label=Total%20Downloads%20%28All%20Releases%29&style=plastic)

#### Copyright (c) zgfg @ xda, 2022-


# AM2R Autopatcher for Mac

```diff
- THIS IS AN UNOFFICIAL TOOL, DO NOT ASK THE COMMUNITY DEVELOPERS FOR SUPPORT!!! -
```

This utility patches the official AM2R 1.1 release (Windows) to the fan-made Community Update (***unofficial*** Mac).

## Patching process
First, download the patching tool and its data [here](https://github.com/Miepee/AM2R-Autopatcher-Mac/archive/refs/heads/main.zip) and extract it to somewhere.  
After that, to patch your copy of (Windows) AM2R v1.1, place the `AM2R_11.zip` (case-sensitive) file in the same folder as `patcher.command`. After that, you should be able to execute `patcher.commmand` by double clicking it or executing it via a terminal.  
MacOS may ask for confirmation if you really want to execute the script, in which case accept.  
During the patching process you will be asked if you want to patch for Mac or for Android. Press the corresponding number for that.  

The patcher requires xdelta to be installed for all patching processes and additionally java for Android patching. If you don't have xdelta installed, you will be automatically prompted if you want to install it via [Homebrew](https://brew.sh/). If you decline this, you have to install xdelta to a location that's inside of your PATH on your own.

If you want to install mods, simply place the Mac version .zip of the mod into the "Mods" folder and execute the `patcher.command` script again. It should now prompt you if you want to install Mods or the Community Updates. Simply choose your mod from there.

## After patching
After patching you'll find the newly generated `am2r_1X_X.app` or `AndroidM2R_1X_X-signed.apk` (or the name of the Mod) depending on if you patched for Mac or Android.  
For Mac, simply double-click the file.  
For Android, move it over to your Android phone and install it there.

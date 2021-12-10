#!/bin/bash

# exit on any error to avoid showing everything was successfull even tho it wasnt
set -e

VERSION="15_5"
OUTPUT="am2r_"${VERSION}
RESOURCES=${OUTPUT}"/Resources"
INPUT=""

#Since people are likely to double click on this, I need a way to get the script_dir
#Thanks SO: https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${SCRIPT_DIR}"

# Cleanup in case the dirs exists 
if [ -d "$OUTPUT" ]; then
    rm -r ${OUTPUT}
fi

echo "-------------------------------------------"
echo ""
echo "AM2R 1.5.5 Shell Autopatching Utility"
echo "Scripted by Miepee"
echo ""
echo "-------------------------------------------"

# Check if xdelta is installed
if ! command -v xdelta3 &> /dev/null; then
	#ask to install xdelta
    echo "xdelta could not be found in PATH. Do you want to automatically install Homebrew and xdelta? Declining this will make you have to install xdelta on your own."
    echo "(Y/N)"
    read -n1 INPUT
    echo ""

	if [[ $INPUT == "Y" || $INPUT == "y" ]]; then
		#check if brew is installed, if not install it
		if ! command -v brew &> /dev/null; then
			echo "Homebrew could not be found. Installing homebrew...."
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		fi
		#we know xdelta isnt installed and brew is, so we can install xdelta via brew now
		brew install xdelta
    else
    	#user wants to install xdelta on their own
    	echo "Exiting program..."
    	echo "Press any key to exit..."
    	read -n1 INPUT
    	exit
   	fi
fi

#check for AM2R_11.zip
if [ -f "AM2R_11.zip" ]; then
    echo "AM2R_11.zip found! Extracting to ${OUTPUT}"
    #extract the content to the am2r_xx folder
    unzip -q AM2R_11.zip -d "${OUTPUT}"
else
    #if the zip is not found, maybe the directory is
    #in which case, copy that one to the am2r_xx folder
    if [ -d "AM2R_11" ]; then
        echo "AM2R_11 folder found! Copying to ${OUTPUT}"
        cp -R AM2R_11 ${OUTPUT}
    else
        echo "AM2R_11 not found. Place AM2R_11.zip (case sensitive) in this folder and try again."
        echo "Press any key to quit..."
        read -n1 INPUT
        exit -1
    fi
fi

#check mods exists
if ls ./mods/*.zip &> /dev/null ; then
	echo "Mods found!"
	echo "Do you want to install the Community Updates or a Mod?"
	echo ""
	echo "1 - Community Updates"
	echo "2 - Mod"
	echo ""
	echo "Awating input:"
	read -n1 INPUT
	echo ""
	echo ""
	if [ $INPUT = "1" ]; then
		echo "Community Updates selected"
	elif [ $INPUT = "2" ]; then
	
		echo "The following mods exist:"		
		files="$(ls ./mods/*.zip)"
		PS3="Enter a number: "
		select mod in ${files};
		do
			echo ""
			# if invalid selection we exit out
			if [ -z "$mod" ]; then echo "Invalid suggestion!"; break; fi

			# Check if we have remaints
			MODDIR="${mod%.*}"
			if [ -d "$MODDIR" ]; then
			    rm -r ${MODDIR}
			fi
			
			 #extract the content to the mod to its own folder folder
    		unzip -q "${mod}" -d "${MODDIR}"

    		# check if profile.xml exists and if it contains OS=Mac
    		if [ -f "${MODDIR}"/profile.xml ] && grep -q "OperatingSystem=\"Mac\"" "${MODDIR}/profile.xml" ; then

				echo "Mod is valid!"

				#delete mod if it exists
				if [ -d  $(basename ${mod%.*}).app ]; then
				    rm -r  $(basename ${mod%.*}).app
				fi
				
			    echo "Applying AM2R patch..."
			    mkdir "${OUTPUT}/MacOS/"
			    mkdir "${RESOURCES}"
			    xdelta3 "-dfs" "${OUTPUT}/AM2R.exe" "${MODDIR}/AM2R.xdelta" "${OUTPUT}/MacOS/Mac_Runner"
			    
			    echo "Applying data patch..."
			    xdelta3 "-dfs" "${OUTPUT}/data.win" "${MODDIR}/game.xdelta" "${RESOURCES}/game.ios"
			    
			    #clean up Windows files
			    echo "Cleaning up residual AM2R 1.1 files..."
			    rm "${OUTPUT}/AM2R.exe" "${OUTPUT}/data.win" "${OUTPUT}/D3DX9_43.dll"
			
			    #structure for Mac
			    echo "Formatting Game directory..."
			    mv ${OUTPUT}/*.* "${RESOURCES}/"
			    
			    #install new datafiles...
			    echo "Installing new datafiles..."
			    #copy music
			    cp "${MODDIR}"/files_to_copy/*.ogg "${RESOURCES}/"
			    
			    #format music for mac aka lowercase it
			    #https://stackoverflow.com/a/25590300 for clarification. Was the most simple way to do it
			    zip -0qr temp.zip "${RESOURCES}"/*.ogg
			    rm "${RESOURCES}"/*.ogg
			    unzip -qLL temp.zip
			    rm temp.zip

				
				#TODO: Why not just recursively copy the whole files_to_copy folder?
			    #remove old lang and install new lang, mods, text, modifiers and icons and other stuff
			    rm -R "${OUTPUT}"/lang
			    cp -R "${MODDIR}"/files_to_copy/lang "${RESOURCES}"/lang
			    #but remove the fonts folder!
			    if [ -d "${RESOURCES}/lang/fonts" ]; then
			        rm -R "${RESOURCES}/lang/fonts"
			    fi
			    cp -R "${MODDIR}"/files_to_copy/mods "${RESOURCES}"/mods
			    cp -R "${MODDIR}"/files_to_copy/English.lproj "${RESOURCES}"/English.lproj
			    cp "${MODDIR}"/files_to_copy/*.txt "${MODDIR}"/files_to_copy/modifiers.ini data/files_to_copy/icon.png "${MODDIR}"/files_to_copy/splash.png "${MODDIR}"/files_to_copy/yoyorunner.config "${RESOURCES}"/

			    #copy Info.plist and pkgInfo
			    cp data/PkgInfo "${MODDIR}"/Info.plist "${OUTPUT}"
			    
			    #make game executable just in case
			    chmod +x "${OUTPUT}/MacOS/Mac_Runner"
			
			    #copy Frameworks folder over
			    cp -R data/Frameworks "${OUTPUT}/Frameworks"
			
			    #rename output to Contents, create a new OUTPUT directory and move it in there
			    mv "${OUTPUT}" Contents
			    mkdir "${OUTPUT}"_.app
			    mv Contents "${OUTPUT}"_.app/Contents

			    #rename output to actual mod name
			    mv "${OUTPUT}"_.app $(basename ${mod%.*}).app

			    #clean old folder
			    rm -R "${MODDIR}"

				#Succesfully done
				if [[ $(basename ${mod%.*}) == Multitroid_* ]]; then

					echo -e "          \033[2;31m▒▒▒▒▒▒\033[0;31m▒▒▒▒▒▒          
      \033[2;31m▒▒▒▒▓▓▓▓▓▓\033[0;31m▓▓▓▓▓▓▒▒▒▒      
    \033[2;31m▒▒▓▓▓▓▓▓▓▓▓▓\033[0;31m▓▓▓▓▓▓▓▓▓▓▒▒    
    \033[2;31m▒▒▓▓▓▓▓▓▓▓▓▓\033[0;31m▓▓▓▓▓▓▓▓▓▓▒▒    
  \033[2;31m▒▒▓▓▓▓▓▓▓▓▓▓▒▒\033[0;31m▒▒▓▓▓▓▓▓▓▓▓▓▒▒  
\033[2;31m▒▒▒▒▓▓▓▓▓▓▒▒▒▒▓▓\033[0;31m▓▓▒▒▒▒▓▓▓▓▓▓▒▒▒▒
\033[2;31m▒▒▓▓▒▒▓▓▒▒▓▓▓▓▓▓\033[0;31m▓▓▓▓▓▓▒▒▓▓▒▒▓▓▒▒
\033[2;31m▒▒▓▓▒▒\033[0;34m██\033[2;31m▓▓▓▓▓▓▓▓\033[0;31m▓▓▓▓▓▓▓▓\033[1;32m██\033[1;31m▒▒▓▓▒▒
\033[2;31m▒▒▓▓▒▒\033[0;34m████\033[2;31m▓▓▓▓▓▓\033[0;31m▓▓▓▓▓▓\033[1;32m████\033[1;31m▒▒▓▓▒▒
\033[2;31m▒▒▓▓▓▓\033[0;34m████████\033[2;31m▓▓\033[0;31m▓▓\033[1;32m████████\033[1;31m▓▓▓▓▒▒
\033[2;31m▒▒▓▓▓▓\033[0;34m██████████\033[1;32m██████████\033[1;31m▓▓▓▓▒▒
\033[2;31m▒▒▒▒▓▓▒▒\033[0;34m████████\033[1;32m████████\033[1;31m▒▒▓▓▒▒▒▒
\033[2;31m▒▒▓▓▒▒▓▓▒▒\033[0;34m██████\033[1;32m██████\033[1;31m▒▒▓▓▒▒▓▓▒▒
  \033[2;31m▒▒▓▓▒▒▓▓▒▒\033[0;34m████\033[1;32m████\033[1;31m▒▒▓▓▒▒▓▓▒▒  
  \033[2;31m▒▒▒▒▓▓▒▒▓▓▒▒\033[0;34m██\033[1;32m██\033[1;31m▒▒▓▓▒▒▓▓▓▓▒▒  
    \033[2;31m▒▒▒▒▓▓▒▒▓▓▒▒\033[0;31m▒▒▓▓▒▒▓▓▒▒▒▒    
        \033[2;31m▒▒▒▒▒▒▒▒\033[0;31m▒▒▒▒▒▒▒▒        \033[0m"
				else				
					echo -e "          \033[1;31m▒▒▒▒▒▒▒▒▒▒▒▒          
      ▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒      
    ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒    
    ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒    
  ▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒  
▒▒▒▒▓▓▓▓▓▓▒▒▒▒▓▓▓▓▒▒▒▒▓▓▓▓▓▓▒▒▒▒
▒▒▓▓▒▒▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▓▓▒▒
▒▒▓▓▒▒\033[1;34m██\033[1;31m▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\033[1;34m██\033[1;31m▒▒▓▓▒▒
▒▒▓▓▒▒\033[1;34m████\033[1;31m▓▓▓▓▓▓▓▓▓▓▓▓\033[1;34m████\033[1;31m▒▒▓▓▒▒
▒▒▓▓▓▓\033[1;34m████████\033[1;31m▓▓▓▓\033[1;34m████████\033[1;31m▓▓▓▓▒▒
▒▒▓▓▓▓\033[1;34m████████████████████\033[1;31m▓▓▓▓▒▒
▒▒▒▒▓▓▒▒\033[1;34m████████████████\033[1;31m▒▒▓▓▒▒▒▒
▒▒▓▓▒▒▓▓▒▒\033[1;34m████████████\033[1;31m▒▒▓▓▒▒▓▓▒▒
  ▒▒▓▓▒▒▓▓▒▒\033[1;34m████████\033[1;31m▒▒▓▓▒▒▓▓▒▒  
  ▒▒▒▒▓▓▒▒▓▓▒▒\033[1;34m████\033[1;31m▒▒▓▓▒▒▓▓▓▓▒▒  
    ▒▒▒▒▓▓▒▒▓▓▒▒\033[1;31m▒▒▓▓▒▒▓▓▒▒▒▒    
        ▒▒▒▒▒▒▒▒\033[1;31m▒▒▒▒▒▒▒▒        \033[0m"
        		fi
	    		echo "The operation was completed successfully. See you next mission!"
    		else
    			echo "This is either no AM2R-Mod or a mod not compatible with Mac!"
    			echo "Press any key to quit..."
		        read -n1 INPUT
		        exit -1
		    fi
			 break; 
		done
		echo "Press any key to quit..."
        read -n1 INPUT
		exit
	else
		echo "Invalid Input!"
		echo "Press any key to quit..."
		read -n1 INPUT
		exit
	fi
fi


#prompt if you want to install mac or android
echo "Select your patch type:"
echo ""
echo "1 - Mac"
echo "2 - Android"
echo ""
echo "Awating input:"

read -n1 INPUT
echo ""
#determine type
if [ $INPUT = "1" ]; then
	#cleanup in case it exists
	if [ -d "$OUTPUT".app ]; then
	    rm -r ${OUTPUT}.app
	fi
	
    echo "Mac selected"
    echo "Applying AM2R patch..."
    mkdir "${OUTPUT}/MacOS/"
    mkdir "${RESOURCES}"
    xdelta3 "-dfs" "${OUTPUT}/AM2R.exe" "data/AM2R.xdelta" "${OUTPUT}/MacOS/Mac_Runner"
    
    echo "Applying data patch..."
    xdelta3 "-dfs" "${OUTPUT}/data.win" "data/game.xdelta" "${RESOURCES}/game.ios"
    
    #clean up Windows files
    echo "Cleaning up residual AM2R 1.1 files..."
    rm "${OUTPUT}/AM2R.exe" "${OUTPUT}/data.win" "${OUTPUT}/D3DX9_43.dll"

    #structure for Mac
    echo "Formatting Game directory..."
    mv ${OUTPUT}/*.* "${RESOURCES}/"
    
    #install new datafiles...
    echo "Installing new datafiles..."
    #copy music
    cp data/files_to_copy/*.ogg "${RESOURCES}/"

    
    echo "Install high quality in-game music? Increases filesize by 194 MB!"
    echo "[y/n]"
    
    read -n1 INPUT
    echo ""
    if [ $INPUT = "y" ]; then
        echo "Copying HQ music..."
        cp data/HDR_HQ_in-game_music/*.ogg "${RESOURCES}/"
    fi
    
    #format music for mac aka lowercase it
    #https://stackoverflow.com/a/25590300 for clarification. Was the most simple way to do it
    zip -0qr temp.zip "${RESOURCES}"/*.ogg
    rm "${RESOURCES}"/*.ogg
    unzip -qLL temp.zip
    rm temp.zip

	#TODO: why not just recursievley copy the files_to_copy folder
    #remove old lang and install new lang, mods, text, modifiers and icons and other stuff
    rm -R "${OUTPUT}"/lang
    cp -R data/files_to_copy/lang "${RESOURCES}"/lang
    #but remove the fonts folder!
    if [ -d "${RESOURCES}/lang/fonts" ]; then
        rm -R "${RESOURCES}/lang/fonts"
    fi
    cp -R data/files_to_copy/mods "${RESOURCES}"/mods
    cp -R data/files_to_copy/English.lproj "${RESOURCES}"/English.lproj
    cp data/files_to_copy/*.txt data/files_to_copy/modifiers.ini data/files_to_copy/icon.png data/files_to_copy/splash.png data/files_to_copy/yoyorunner.config "${RESOURCES}"/

    #copy Info.plist and pkgInfo
    cp data/PkgInfo data/Info.plist "${OUTPUT}"
    
    #make game executable just in case
    chmod +x "${OUTPUT}/MacOS/Mac_Runner"

    #copy Frameworks folder over
    cp -R data/Frameworks "${OUTPUT}/Frameworks"

    #rename output to Contents, create a new OUTPUT directory and move it in there
    mv "${OUTPUT}" Contents
    mkdir "${OUTPUT}".app
    mv Contents "${OUTPUT}".app/Contents

elif [ $INPUT = "2" ]; then
    echo "Android selected."
	if ! command -v xdelta3 &> /dev/null; then
		#ask to install xdelta
	    echo "Java could not be found. Please make sure to install Java first."
		echo "Press any key to quit..."
        read -n1 INPUT
        exit -1
	fi
	
    echo "Applying data patch..."
    echo "Applying Android patch..."
    xdelta3 -dfs "${OUTPUT}"/data.win data/droid.xdelta  "${OUTPUT}"/game.droid
    cp data/android/AM2RWrapper.apk utilities/android/
    
    rm "${OUTPUT}"/D3DX9_43.dll "${OUTPUT}"/AM2R.exe "${OUTPUT}"/data.win 
    
    cp -Rp "${OUTPUT}"/ utilities/android/assets/
    if [ -f data/android/AM2R.ini ]; then
    	cp -p data/android/AM2R.ini utilities/android/assets/
   	fi
    
    # Install new datafiles...
    echo "Installing new datafiles..."
    
    # Music
    mkdir -p utilities/android/assets/lang
    cp data/files_to_copy/*.ogg utilities/android/assets/
    
    echo "Install high quality in-game music? Increases filesize by 194 MB!"
    echo ""
    echo "[y/n]"
    
    read -n1 INPUT
    echo ""
    
    if [ $INPUT = "y" ]; then
        echo "Copying HQ music..."
        cp data/HDR_HQ_in-game_music/*.ogg utilities/android/assets/
    fi
    #remove old lang
    rm -R utilities/android/assets/lang/
    #install new lang
    cp -Rp data/files_to_copy/lang/ utilities/android/assets/lang/
    #copy text and modifiers
    cp -p data/files_to_copy/*.txt data/files_to_copy/modifiers.ini utilities//android/assets/
    
    #zip -0qr temp.zip utilities/android/assets/*.ogg
    #rm utilities/android/assets/*.ogg
    #unzip -qLL temp.zip
    #rm temp.zip
    
    cd utilities/android/
    
    echo "Packaging APK..."
    echo "If Java JDK 8 or newer is not present, this will fail!"
    #decompile the apk
    java -jar ./apktool.jar d -f AM2RWrapper.apk
    #copy
    cp -Rp assets AM2RWrapper
    #edited yaml thing to not compress ogg's
    echo "Editing apktool.yml..."
    sed -i "s/doNotCompress:/doNotCompress:\n- ogg/" AM2RWrapper/apktool.yml
    #build
    java -jar ./apktool.jar b AM2RWrapper -o AM2RWrapper.apk
    echo "Signing APK..."
    java -jar uber-apk-signer.jar -a AM2RWrapper.apk 
    # Cleanup
    rm -R AM2RWrapper.apk assets/ ../../"${OUTPUT}" AM2RWrapper/
    # Move APK
    mv AM2RWrapper-aligned-debugSigned.apk ../../AndroidM2R_"${VERSION}"-signed.apk 
else
    echo "Invalid input."
    echo "Press any key to quit..."
    read -n1 INPUT
    exit -1
fi

echo -e "          \033[1;31m▒▒▒▒▒▒▒▒▒▒▒▒          
      ▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒      
    ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒    
    ▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒    
  ▒▒▓▓▓▓▓▓▓▓▓▓▒▒▒▒▓▓▓▓▓▓▓▓▓▓▒▒  
▒▒▒▒▓▓▓▓▓▓▒▒▒▒▓▓▓▓▒▒▒▒▓▓▓▓▓▓▒▒▒▒
▒▒▓▓▒▒▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▒▒▓▓▒▒
▒▒▓▓▒▒\033[1;32m██\033[1;31m▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\033[1;32m██\033[1;31m▒▒▓▓▒▒
▒▒▓▓▒▒\033[1;32m████\033[1;31m▓▓▓▓▓▓▓▓▓▓▓▓\033[1;32m████\033[1;31m▒▒▓▓▒▒
▒▒▓▓▓▓\033[1;32m████████\033[1;31m▓▓▓▓\033[1;32m████████\033[1;31m▓▓▓▓▒▒
▒▒▓▓▓▓\033[1;32m████████████████████\033[1;31m▓▓▓▓▒▒
▒▒▒▒▓▓▒▒\033[1;32m████████████████\033[1;31m▒▒▓▓▒▒▒▒
▒▒▓▓▒▒▓▓▒▒\033[1;32m████████████\033[1;31m▒▒▓▓▒▒▓▓▒▒
  ▒▒▓▓▒▒▓▓▒▒\033[1;32m████████\033[1;31m▒▒▓▓▒▒▓▓▒▒  
  ▒▒▒▒▓▓▒▒▓▓▒▒\033[1;32m████\033[1;31m▒▒▓▓▒▒▓▓▓▓▒▒  
    ▒▒▒▒▓▓▒▒▓▓▒▒\033[1;31m▒▒▓▓▒▒▓▓▒▒▒▒    
        ▒▒▒▒▒▒▒▒\033[1;31m▒▒▒▒▒▒▒▒        \033[0m"

echo "The operation was completed successfully. See you next mission!"
echo "Press any key to quit..."
read -n1 INPUT

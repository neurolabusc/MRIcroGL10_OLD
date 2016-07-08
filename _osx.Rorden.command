#!/bin/sh

#typical users should use the "_osx.command" to build files
# this script builds other tools and special versions of MRIcroGL



find /Users/rorden/Documents/osx -name ‘*.DS_Store’ -type f -delete

#compile dcm2niix
cd ~/Documents/cocoa/dcm2niix/console
g++ -O3 -dead_strip -I. main_console.cpp nii_dicom.cpp nifti1_io_core.cpp nii_ortho.cpp nii_dicom_batch.cpp jpg_0XC3.cpp ujpeg.cpp -o dcm2niix  -I/usr/local/lib /usr/local/lib/libopenjp2.a
cp dcm2niix /Users/rorden/Documents/osx/dcm2niix
cp dcm2niix /Users/rorden/Documents/osx/MRIcroGL.app/Contents/MacOS/dcm2niix
#If we have a 32-bit executable...
#cp dcm2niix /Users/rorden/Documents/osx/MRIcroGL32.app/Contents/MacOS/dcm2niix

cd ~/Documents/pas/MRIcroGL/
#compile MRIcroGL64
# /Users/rorden/lazarus/lazbuild ./simplelaz.lpr --cpu=x86_64 --ws=cocoa --compiler="/usr/local/bin/ppcx64"
#Current FPC 3.0.0 can not compile on OSX 10.11 El Capitan, so use 3.1.1
 /Users/rorden/lazarus/lazbuild ./simplelaz.lpr --cpu=x86_64 --ws=cocoa --compiler="/usr/local/lib/fpc/3.1.1/ppcx64"


#compile MRIcroGL32
#/Developer/lazarus/lazbuild ./simplelaz.lpr --ws=cocoa

strip ./MRIcroGL
cp MRIcroGL /Users/rorden/Documents/osx/MRIcroGL.app/Contents/MacOS/MRIcroGL
#strip /Users/rorden/Documents/osx/MRIcroGL.app/Contents/MacOS/MRIcroGL


#compile MRIcroGL32
#lazbuild -B ./simplelaz.lpr
#cp MRIcroGL /Users/rorden/Documents/osx/MRIcroGL32.app/Contents/MacOS/MRIcroGL
#strip /Users/rorden/Documents/osx/MRIcroGL32.app/Contents/MacOS/MRIcroGL

# cp  -aR /Applications/MRIcro.app /Users/rorden/Documents/osx/MRIcro.app

./_xclean.bat

#clean up duplicate files for OSX/Linux/Windows so we do not duplicate files on Github
rm /Users/rorden/Documents/pas/MRIcroGL/DistroOSX/MRIcroGL.app/Contents/MacOS/MRIcroGL
rm /Users/rorden/Documents/pas/MRIcroGL/DistroOSX/*.pdf
rm /Users/rorden/Documents/pas/MRIcroGL/DistroOSX/*.gz


cd /Users/rorden/Documents/pas/
#get rid of symbolic link
rm /Users/rorden/Documents/pas/MRIcroGL/MRIcroGL.app/Contents/MacOS/MRIcroGL
zip -FSr /Users/rorden/Documents/source.zip MRIcroGL

cd /Users/rorden/Documents/
zip -FSr /Users/rorden/Documents/osx.zip osx


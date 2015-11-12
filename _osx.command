#!/bin/sh

find /Users/rorden/Documents/osx -name ‘*.DS_Store’ -type f -delete

#compile dcm2niix
cd ~/Documents/cocoa/dcm2niix/console
g++ -O3 -dead_strip -I. main_console.cpp nii_dicom.cpp nifti1_io_core.cpp nii_ortho.cpp nii_dicom_batch.cpp jpg_0XC3.cpp ujpeg.cpp -o dcm2niix  -I/usr/local/lib /usr/local/lib/libopenjp2.a
cp dcm2niix /Users/rorden/Documents/osx/dcm2niix
cp dcm2niix /Users/rorden/Documents/osx/MRIcroGL.app/Contents/MacOS/dcm2niix
cp dcm2niix /Users/rorden/Documents/osx/MRIcroGL64.app/Contents/MacOS/dcm2niix

cd ~/Documents/pas/raycast/
#compile MRIcroGL64
lazbuild ./simplelaz.lpr --cpu=x86_64 --ws=cocoa --compiler="/usr/local/bin/ppcx64"
cp MRIcroGL /Users/rorden/Documents/osx/MRIcroGL64.app/Contents/MacOS/MRIcroGL
strip /Users/rorden/Documents/osx/MRIcroGL64.app/Contents/MacOS/MRIcroGL


#compile MRIcroGL32
lazbuild -B ./simplelaz.lpr
cp MRIcroGL /Users/rorden/Documents/osx/MRIcroGL.app/Contents/MacOS/MRIcroGL
strip /Users/rorden/Documents/osx/MRIcroGL.app/Contents/MacOS/MRIcroGL

# cp  -aR /Applications/MRIcro.app /Users/rorden/Documents/osx/MRIcro.app




./_xclean.bat

cd /Users/rorden/Documents/pas/
#get rid of symbolic link
raycast/MRIcroGL.app/Contents/MacOS/MRIcroGL
zip -r /Users/rorden/Documents/source.zip raycast

cd /Users/rorden/Documents/
zip -r /Users/rorden/Documents/osx.zip osx


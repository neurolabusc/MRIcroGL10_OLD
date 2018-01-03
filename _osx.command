#!/bin/sh
# change to working directory to location of command file: http://hints.macworld.com/article.php?story=20041217111834902
here="`dirname \"$0\"`"
cd "$here" || exit 1
 ~/Lazarus/lazbuild ./simplelaz.lpr --cpu=x86_64 --ws=cocoa
strip ./MRIcroGL
mv ./MRIcroGL ./DistroOSX/MRIcroGL.app/Contents/MacOS/
cp ./Distro/*.gz ./DistroOSX
cp ./Distro/*.pdf ./DistroOSX


# MRIcroGL

##### About

MRIcroGL is an open source volume ray caster. For details and compiled versions visit the [NITRC wiki](https://www.nitrc.org/plugins/mwiki/index.php/mricrogl:MainPage). You can also visit the [MRIcroGL home pages](http://www.mccauslandcenter.sc.edu/mricrogl/) which include [videos](http://www.mccauslandcenter.sc.edu/mricrogl/tutorials), [notes on compiling](http://www.mccauslandcenter.sc.edu/mricrogl/source) and [troubleshooting advice](http://www.mccauslandcenter.sc.edu/mricrogl/notes).

http://www.mccauslandcenter.sc.edu/mricrogl/

![alt tag](https://github.com/neurolabusc/MRIcroGL/blob/master/clipping.jpg)

##### Recent Versions

7-February-2017
 - Looks better on Linux high-DPI screens
 - [Cubic b-spline interpolation](http://www.mccauslandcenter.sc.edu/mricrogl/beta-features).
 - [Threshold Detection](http://www.mccauslandcenter.sc.edu/mricrogl/beta-features).

30-September-2016
 - Ensure colorbars show active overlay colors. Improvements for macOS 10.11.

6-June-2016
 - Fix some shaders to ensure variable colorSample initialized to zero.

9-September-2015
 - Add retina and 64-bit support for macOS (aka OSX). Better compatibility with VirtualBox. New shaders. Retina quality screen captures.

##### Installation and Compiling

The easiest way to install MRIcroGL is to get pre-compiled binaries from [NITRC (macOS, Linux and Windows)](https://www.nitrc.org/projects/mricrogl/). You can also compile a copy yourself. Instructions are available on the [MRIcroGL website](http://www.mccauslandcenter.sc.edu/mricrogl/source). In brief, you need to install FreePascal and Lazarus. You also have to [install](http://wiki.freepascal.org/Install_Packages) the "LazOpenGL" package into Lazarus. Finally you need to compile the application. On most systems this is as simple as running the following from the terminal command line: `lazbuild ./simplelaz.lpr`. This will compile to the default widgetset for your operating system (Windows: WinAPI; macOS: Carbon; Linux: GTK2). You can also compile to other widgetsets (e.g. QT, Cocoa), but that is beyond the scope of these instructions.

A basic command line script for ensuring the required packages are installed and compiling this software would look like this (assuming you are using a Linux or macOS computer).

```
lazbuild --verbose-pkgsearch lazopenglcontext --verbose-pkgsearch pascalscript
if [ $? -eq 0 ]
then
    echo "required packages already installed"
else
    echo "installing packages"
    lazbuild --add-package lazopenglcontext --add-package pascalscript --build-ide=
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo "macOS compiling for Cocoa, instead of default Carbon widgetset"
	lazbuild  -B --ws=cocoa ./simplelaz.lpr
else
	lazbuild -B ./simplelaz.lpi
fi
```


##### License

This software includes a [BSD license](https://opensource.org/licenses/BSD-2-Clause)



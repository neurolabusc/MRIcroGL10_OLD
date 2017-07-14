# MRIcroGL

##### About

MRIcroGL is an open source volume ray caster. For details and compiled versions visit the [NITRC wiki](https://www.nitrc.org/plugins/mwiki/index.php/mricrogl:MainPage). You can also visit the [MRIcroGL home pages](http://www.mccauslandcenter.sc.edu/mricrogl/) which include [videos](http://www.mccauslandcenter.sc.edu/mricrogl/tutorials), [notes on compiling](http://www.mccauslandcenter.sc.edu/mricrogl/source) and [troubleshooting advice](http://www.mccauslandcenter.sc.edu/mricrogl/notes).

http://www.mccauslandcenter.sc.edu/mricrogl/

![alt tag](https://github.com/neurolabusc/MRIcroGL/blob/master/clipping.jpg)

##### Recent Versions

14-July-2017
 - [Display/Radiological menuitem](https://www.nitrc.org/forum/message.php?msg_id=21719) flips between neurological and radiological convention. The "L" and "R" symbols change in the "2D Slices" panel to remind user of current setting. Slices coordinates reflect MNI space (e.g. left side of brain is negative regardless of viewing convention). Rendering view not influenced: radiological view assumes camera is anterior/inferior to object for coronal/sagittal views while neurological assumes camera is posterior/superior.

24-June-2017
 - [Smooth](https://github.com/neurolabusc/OpenGLCoreTutorials) numbers in colorbars

21-June-2017
 - Preferences window now allows user to enable optional support for MacOS retina resolution. Slower but better quality.
 - [Screenshot fixes](http://www.nitrc.org/forum/message.php?msg_id=21504). Fix 'seams' when taking screenshots with high zoom factors, reduce blurriness of mosaic screenshots.
 - New script commands "sharpen" and "bmpzoom" (described in manual).
 - Better support for NRRD format images.

28-May-2017
 - [Better thresholding of binary overlays](https://www.nitrc.org/forum/message.php?msg_id=19974).
 - [DICOM import interface fix](https://www.nitrc.org/forum/forum.php?thread_id=7624&forum_id=4442).

1-April-2017
 - Better [Gentoo support](https://github.com/neurolabusc/MRIcroGL/issues/8): Allow supporting files to be stored in /usr/share/mricrogl/script, /usr/share/mricrogl/lut and /usr/share/mricrogl/shaders
 - Fix bug where drawing erase tool would get inadvertently activated.

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



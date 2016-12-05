# MRIcroGL

##### About

MRIcroGL is an open source volume ray caster. For details and compiled versions visit the [NITRC wiki](https://www.nitrc.org/plugins/mwiki/index.php/mricrogl:MainPage). You can also visit the [MRIcroGL home pages](http://www.mccauslandcenter.sc.edu/mricrogl/) which include [videos](http://www.mccauslandcenter.sc.edu/mricrogl/tutorials), [notes on compiling](http://www.mccauslandcenter.sc.edu/mricrogl/source) and [troubleshooting advice](http://www.mccauslandcenter.sc.edu/mricrogl/notes).

http://www.mccauslandcenter.sc.edu/mricrogl/

![alt tag](https://github.com/neurolabusc/MRIcroGL/blob/master/clipping.jpg)

##### Recent Versions

30-September-2016
 - Ensure colorbars show active overlay colors. Improvements for OSX 10.11.

6-June-2016
 - Fix some shaders to ensure variable colorSample initialized to zero.

9-September-2015
 - Add retina and 64-bit support for OSX. Better compatibility with VirtualBox. New shaders. Retina quality screen captures.

##### Installation and Compiling

The easiest way to install MRIcroGL is to get pre-compiled binaries from [NITRC (macOS, Linux and Windows)](https://www.nitrc.org/projects/mricrogl/). You can also compile a copy yourself. Instructions are available on the [MRIcroGL website](http://www.mccauslandcenter.sc.edu/mricrogl/source). In brief, you need to install FreePascal and Lazarus. You also have to [install](http://wiki.freepascal.org/Install_Packages) the "LazOpenGL" package into Lazarus. Finally you need to compile the application. On most systems this is as simple as running the following from the terminal command line: `lazbuild ./simplelaz.lpr`. This will compile to the default widgetset for your operating system (Windows: WinAPI; macOS: Carbon; Linux: GTK2). You can also compile to other widgetsets (e.g. QT, Cocoa), but that is beyond the scope of these instructions.


##### License

This software includes a [BSD license](https://opensource.org/licenses/BSD-2-Clause)



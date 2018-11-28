# MRIcroGL

##### About

MRIcroGL is an open source volume ray caster. For details and compiled versions visit the [NITRC wiki](https://www.nitrc.org/plugins/mwiki/index.php/mricrogl:MainPage). You can also visit the [MRIcroGL home pages](http://www.mccauslandcenter.sc.edu/mricrogl/) which include [videos](http://www.mccauslandcenter.sc.edu/mricrogl/tutorials), [notes on compiling](http://www.mccauslandcenter.sc.edu/mricrogl/source) and [troubleshooting advice](http://www.mccauslandcenter.sc.edu/mricrogl/notes).

http://www.mccauslandcenter.sc.edu/mricrogl/

![alt tag](https://github.com/neurolabusc/MRIcroGL/blob/master/clipping.jpg)



##### Installation

You can download the latest release for Windows, MacOS or Linux from either of these sites:
 - [Available from NITRC](https://www.nitrc.org/projects/mricrogl/).
 - [Available from Github](https://github.com/neurolabusc/MRIcroGL/releases).



##### Compiling

Most users will want to use the pre-compiled executable (see the previous section). However, you can compile this yourself. Lazarus 2.0 or later is recommended.

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



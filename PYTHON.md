# Python scripting for MRIcroGL

##### About

MRIcroGL allows the user to run scripts. This is useful to illustrate features or automate laborious and repetitive tasks. The scripts can be entered in the graphical interface (the View/Scripting menu item) or via the command line. These scripts can either be written in either the Python or Pascal languages. The default scripts that come with MRIcroGL are written in Pascal. The advantage of Pascal is that the compiler is built into MRIcroGL, so it will always work. On the other hand, Python requires your computer to have a Python compiler. On the other hand, Python has become a very popular language. By supporting both languages, users can choose their preferred language.

Scripting is described in the
[MRIcroGL wiki](https://www.nitrc.org/plugins/mwiki/index.php/mricrogl:MainPage#Scripting). A full list of the available functions is listed on [Github](https://github.com/neurolabusc/MRIcroGL/blob/master/COMMANDS.md).

Specific considerations for Python in MRIcroGL
 - Each Python script should include 'import gl' - this provides access to the MRIcroGL commands and also tells the software that this is a Python (rather than Pascal) program.
 - Python uses '#' for comments, while Pascal uses '//'
 - Python is case sensitive, and all the [MRIcroGL](https://github.com/neurolabusc/MRIcroGL/blob/master/COMMANDS.md) functions are lower cased. Therefore "gl.resetdefaults" is valid but "gl.ResetDefaults" will not compile.
 - Python uses "=" for assignments, while Pascal uses ":=". Therefore, the Python line "i = 1" is the same as the Pascal "i := 1;"
 - Python uses "==" to test equality, while Pascal uses "=". Therefore, the Python line "if rot == 1:" is the same as the Pascal "if rot = 1 then"
 - PyArg_ParseTuple requires that boolean values are either "0" (false) or "1" (true). In contrast, Pascal uses true/false, so the Python command "gl.colorbarvisible(1)" is the same as the Pascal "colorbarvisible(true);"

 Below each of the Pascal scripts that are provided with MRIcroGL have been ported to Python.

##### basic

```python
import gl
gl.resetdefaults()
gl.loadimage('mni152_2009bet')
gl.overlayload('motor')
gl.overlayminmax(1, 2.6, 4)
```

##### color


```python
import gl
gl.resetdefaults()
ktime= 15
ksteps= 36
gl.resetdefaults()
gl.loadimage('abdo256')
gl.contrastformvisible(1)
gl.colorname('ct_bones')
for x in range(1, ksteps):
  gl.azimuth(10)
  gl.wait(ktime)
gl.elevation(-30)
gl.contrastminmax(0, 300)
for x in range(1, ksteps):
  gl.azimuth(10)
  gl.wait(ktime)
gl.colorname('ct_kidneys')
for x in range(1, ksteps):
  gl.azimuth(10)
  gl.wait(ktime)
```

##### mosaic

```python
import gl
gl.resetdefaults()
gl.colorbarvisible(0)
gl.loadimage('mni152_2009_256')
gl.overlayload('motor')
gl.overlayminmax(1, -4, -4)
#clipazimuthelevation(0.5, 90, 0)
#mosaic('h -0.2 a -24 -16 40 50 60 70 s x r 20')
gl.mosaic('a r 20 a r -20 s r -20 c r 0 cr -20 s r 20')
```

##### mra
```python
import gl
gl.resetdefaults()
ktime= 15
ksteps= 36
gl.resetdefaults()
gl.loadimage('chris_mra')
gl.contrastminmax(40,100)
gl.backcolor(255, 255, 255)
for i in range(1, ksteps):
  gl.azimuthelevation(i*10, 30)
  gl.wait(ktime)
gl.modelessmessage('extracting arteries from background')
gl.extract(4,1,1)
for i in range(1, ksteps):
  gl.azimuthelevation(i*10, 30)
  gl.wait(ktime)
```

#####  overlay_clipping

```python
import gl
gl.resetdefaults()
gl.loadimage('mni152_2009bet')
gl.overlayloadsmooth(1)
gl.overlayload('motor')
gl.overlayminmax(1, 2.6, 2.6)
gl.backcolor(255, 255,255)
gl.shadername('overlay')
gl.clipazimuthelevation(0.4, 0, 120)
```

##### overlay_cutout

```python
import gl
gl.resetdefaults()
gl.loadimage('mni152_2009bet')
gl.backcolor(128, 169, 255)
gl.overlayloadsmooth(1)
gl.overlayload('motor')
gl.overlayminmax(1, -4, -4)
gl.overlayload('motor')
gl.overlayminmax(2, 4, 4)
gl.cutout(0.0, 0.45, 0.5, 0.75, 1.0, 1.0)
gl.shadername('overlay')
```

##### overlay_glass

```python
import gl
gl.resetdefaults()
gl.loadimage('mni152_2009bet')
gl.overlayloadsmooth(1)
gl.overlayload('motor')
gl.overlayminmax(1, 2.5, 2.5)
gl.backcolor(255, 255,255)
gl.shadername('overlay_glass')
gl.shaderadjust('edgethresh', 0.6)
gl.shaderadjust('edgeboundmix', 0.72)
gl.contrastminmax(30, 80)
```

##### overlay_shell

```python
import gl
gl.resetdefaults()
gl.loadimage('mni152_2009bet')
gl.backcolor(255, 255, 255)
gl.overlayloadsmooth(1)
gl.overlayload('motor')
gl.overlayminmax(1, 2, 2)
gl.shadername('overlay_shell')
gl.shaderadjust('colortemp', 0.0)
gl.clipazimuthelevation(0.35, 0, 140)
```
##### shader

```python
import gl
gl.resetdefaults()
ksteps = 120
kazispeed= 22
kazispeedf = 1.0/kazispeed
kelevspeed= 22
kelevspeedf = 1.0/kelevspeed
ktime = 1
gl.backcolor(255, 255, 255)
gl.loadimage('mni152_2009bet')
gl.colorname('surface')
gl.shadername('default')
gl.shaderadjust('specular',0.9)
for i in range(1, ksteps):
  a = abs (0.5- (i % kazispeed) * kazispeedf)*2
  e = abs (0.5- (i % kelevspeed) * kelevspeedf)*2
  gl.shaderlightazimuthelevation( round((a-0.5)*120),round((e-0.2)*120))
  gl.wait(ktime)
```

##### wobble

```python
import gl
gl.resetdefaults()
kloops=400
ktime= 15
kelevspeed= 33
kclipspeed= 51
kclipspeedf= 1.0 /kclipspeed
kazispeed=37
gl.loadimage('mni152_2009bet')
gl.colorname('bone')
for i in range(1, kloops):
  gl.azimuth(-1)
  a = abs(0.5- (i % kazispeed)/kazispeed)* 90+160
  e = abs(0.5- (i % kelevspeed)/kelevspeed) * 180+90
  depth =  0.1+abs(0.5 - (i % kclipspeed) * kclipspeedf)
  gl.clipazimuthelevation(depth, a, e)
  gl.wait(ktime)
```
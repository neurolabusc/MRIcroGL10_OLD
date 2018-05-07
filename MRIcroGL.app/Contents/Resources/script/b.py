import gl
gl.resetdefaults()
#gl.fontname('Ubuntu')
#gl.elevation(33)
#gl.linewidth(3)
#gl.linecolor(33,33,255)
#gl.loadimage('motor.nii')
#gl.maximumintensity(1)
#gl.modelessmessage('Hola')
#gl.modalmessage('Test')
#gl.overlaycloseall
#gl.orthoview(0.5, 0.5, 0.5)
#gl.orthoviewmm(0.5, 0.5, 0.5)
gl.shadername('phong')
gl.shaderadjust('specular',1)
gl.viewcoronal(1)
print(gl.version())
import sys
print(sys.version)
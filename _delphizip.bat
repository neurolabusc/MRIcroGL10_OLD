REM copy latest version of dcm2niix
copy c:\dcm2niix\console\dcm2niix.exe c:\mricrogl\dcm2niix.exe

REM COMPILE MRIcroGL

c:\lazarus\lazbuild --cpu=x86_64 -B simplelaz.lpi
move /Y "C:\pas\raycast\MRIcroGL.exe" "c:\mricrogl\MRIcroGL64.exe"

C:\PROGRA~2\BORLAND\DELPHI7\BIN\dcc32 -UC:\pas\FastMM;C:\pas\pascalscript\Source;C:\pas\raycast\pngimg;C:\pas\raycast\delphionly -B C:\pas\raycast\simple.dpr
c:\strip /B "C:\pas\raycast\simple.exe"
move /Y "C:\pas\raycast\simple.exe" "c:\mricrogl\MRIcroGL.exe"
REM copy new compilation to server
del c:\mricrogl\*.ini
c:\Progra~1\7-Zip\7z a -tzip c:\pas\windows.zip c:\mricrogl
REM copy c:\pas\windows.zip W:\mcbi\MCBI\CRNL\sw\mricrogl\windows.zip

 
 
call _clean.bat
c:\Progra~1\7-Zip\7z a -tzip c:\pas\source.zip c:\pas\raycast 
REM copy source to server
REM copy c:\pas\source.zip W:\mcbi\MCBI\CRNL\sw\mricrogl\source.zip


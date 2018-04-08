REM copy latest version of dcm2niix
REM cd c:\dcm2niix\console
REM g++ -O3 -DmyDisableOpenJPEG -I. main_console.cpp nii_dicom.cpp nifti1_io_core.cpp nii_ortho.cpp nii_dicom_batch.cpp jpg_0XC3.cpp ujpeg.cpp -s -o dcm2niix -static-libgcc
REM copy c:\dcm2niix\console\dcm2niix.exe c:\mricrogl\dcm2niix.exe

REM COMPILE MRIcroGL
cd c:\pas\MRIcroGL
c:\lazarus\lazbuild --cpu=x86_64 -B simplelaz.lpi
move /Y "C:\pas\MRIcroGL\MRIcroGL.exe" "c:\mricrogl\MRIcroGL64.exe"

REM copy new compilation to server
del c:\mricrogl\*.ini
c:\Progra~1\7-Zip\7z a -tzip c:\pas\mricrogl_windows.zip c:\mricrogl
REM copy c:\pas\windows.zip W:\mcbi\MCBI\CRNL\sw\mricrogl\windows.zip



call _clean.bat
c:\Progra~1\7-Zip\7z a -tzip c:\pas\mricrogl_source.zip c:\pas\MRIcroGL
REM copy source to server
REM copy c:\pas\source.zip W:\mcbi\MCBI\CRNL\sw\mricrogl\source.zip


#for MRIcroGL
# git clone https://github.com/neurolabusc/MRIcroGL.git
cd ~/MRIcroGL
git pull
lazbuild -B simplelaz.lpr
cp MRIcroGL ~/mricrogl_lx/MRIcroGL


#lazbuild --cpu=i386 -B ./simplelaz.lpr
#cp MRIcroGL ~/mricrogl_lx/MRIcroGL32

#for dcm2niix...
# git clone https://github.com/rordenlab/dcm2niix.git
cd ~/dcm2niix
git pull
cd ~/dcm2niix/console
make
cp dcm2niix ~/mricrogl_lx/dcm2niix

#g++ -s -O3 -I. main_console.cpp nii_dicom.cpp jpg_0XC3.cpp ujpeg.cpp nifti1_io_core.cpp nii_ortho.cpp nii_dicom_batch.cpp  -o dcm2niix32 -DmyDisableOpenJPEG -DmyDisableJasper -m32
#cp dcm2niix32 ~/mricrogl_lx/dcm2niix32

cd ~
zip -r gl_lx.zip mricrogl_lx

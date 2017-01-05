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

cd ~
zip -r mricrogl_linux.zip mricrogl_lx

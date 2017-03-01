{$IFNDEF FPC}  {$DEFINE DGL} {$ENDIF}
//{$DEFINE COREGL} //use Core OpenGL instead of Legacy OpenGL, uses glcorearb
//{$DEFINE DGL}  //uncomment to use dglOpenGL: incompatible with Core  https://github.com/SaschaWillems/dglOpenGL
 {$DEFINE ENABLECLIP}
{$DEFINE ENABLESHADER}
{$DEFINE ENABLECLUT}
{$DEFINE ENABLEMOSAIC}
//{$DEFINE USETRANSFERTEXTURE} //images loaded as simple 8-bit volumes with transfer texture. Overlays/Cutouts not supported.
//{$DEFINE ENABLEOVERLAY}
{$IFNDEF USETRANSFERTEXTURE}

         {$DEFINE ENABLECUTOUT}
   {$DEFINE ENABLEOVERLAY}
   {$DEFINE ENABLESCRIPT}
   {$DEFINE xENABLEEDGE} //replaced...
{$ENDIF}
{$DEFINE ENABLEMOSAICS}

//{$DEFINE ENABLEWATERMARK}

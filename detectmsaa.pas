unit detectmsaa;
interface
uses {$IFNDEF UNIX}Windows,{$ENDIF} dglOpenGL, Forms, dialogs;
function DetectMutliSampleMode(DesiredMutliSample: integer; Sender : TForm ): GLint;


implementation

procedure MutliSampleError ( code : Integer );
var
  Errstr : string;
begin
  case code of
    1 : errstr := 'Initializing OpenGL';
    2 : errstr := 'Getting Device Context';
    3 : errstr := 'Creating Rendering Context';
    4 : errstr := 'Activating Rendering Context';
    5 : errstr := 'Initializing pixel format';
    6 : errstr := 'Setting pixel format';
  end;
  Errstr := 'Multisample detection error: '+errstr + 'failed!';
  Showmessage(Errstr);
end;

function DetectMutliSampleMode(DesiredMutliSample: integer; Sender : TForm ): GLint;
var
  RC : HGLRC ;
  DC : HDC ;
  FallBackPFD : TPixelFormatDescriptor;
  FallBackPF : GLint;
  MultiPF , numPFs : GLint;
  multiARBSup , multiEXTSup : Boolean;
  IAtrib : array [ 0 .. 18] of GLint;
  FAtrib : GLfloat;
  tmpDC : HDC;
  // Array that stores all found the multisample PFs
  possiblePFs : array [ 0 .. 63 ] of GLint;
  // Property to be checked / variable in which the result Is saved
  QueryIAtrib , ResultIAtrib : GLint;
  // Counter variable / maximum number of supported samples found (the more
  // Samples are used, the better the anti-aliasing
  i , highestSamp : Integer;
begin
  result := 0;
  // Initialize OpenGL normal and get device context
  if not InitOpenGL then
    MutliSampleError ( 1 );
  DC := GetDC ( Sender.Handle );
  if DC = 0 then
    MutliSampleError ( 2 );
  // Fallback-pixel format set to define and
  with FallBackPFD do
  begin
    nSize := SizeOf ( FallBackPFD );
    nVersion := 1;
    dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
    iPixelType := PFD_TYPE_RGBA;
    cColorBits := 32;
    cDepthBits := 24;
  end;
  FallBackPF := ChoosePixelFormat ( DC , @ FallBackPFD );
  if FallBackPF = 0 then
    MutliSampleError ( 5 );
  if not SetPixelFormat ( DC , FallBackPF , @ FallBackPFD ) then
    MutliSampleError ( 6 );
  // Render the Create and Context
  RC := wglCreateContext ( DC );
  if RC = 0 then
    MutliSampleError ( 3 );
  if not wglMakeCurrent ( DC , RC ) then
    MutliSampleError ( 4 );
  // Read, which extensions are available
  ReadImplementationProperties;
  // Check whether the extensions are available and invite Exensions
  multiARBSup := false;
  multiEXTSup := false;
  if WGL_ARB_extensions_string and WGL_ARB_pixel_format
      and ( WGL_ARB_MULTISAMPLE or GL_ARB_MULTISAMPLE ) then
      multiARBSup := true;
    if WGL_EXT_extensions_string and WGL_EXT_pixel_format
      and ( WGL_EXT_MULTISAMPLE or GL_EXT_MULTISAMPLE ) then
      multiEXTSup := true;
  if multiARBSup then
    Read_WGL_ARB_pixel_format
  else if multiEXTSup then
    Read_WGL_EXT_pixel_format;
  // If multisampling is supported, it should also be implemented
  if multiARBSup or multiEXTSup then begin
    IAtrib [ 0 ] := WGL_DRAW_TO_WINDOW_ARB;
    IAtrib [ 1 ] := 1;
    IAtrib [ 2 ] := WGL_SUPPORT_OPENGL_ARB;
    IAtrib [ 3 ] := 1;
    IAtrib [ 4 ] := WGL_DOUBLE_BUFFER_ARB;
    IAtrib [ 5 ] := 1;
    IAtrib [ 6 ] := WGL_PIXEL_TYPE_ARB;
    IAtrib [ 7 ] := WGL_TYPE_RGBA_ARB;
    IAtrib [ 8 ] := WGL_COLOR_BITS_ARB;
    IAtrib [ 9 ] := 24;
    IAtrib [ 10 ] := WGL_ALPHA_BITS_ARB;
    IAtrib [ 11 ] := 0;
    IAtrib [ 12 ] := WGL_DEPTH_BITS_ARB;
    IAtrib [ 13 ] := 24;
    IAtrib [ 14 ] := WGL_STENCIL_BITS_ARB;
    IAtrib [ 15 ] := 0;
    IAtrib [ 16 ] := WGL_SAMPLE_BUFFERS_ARB;
    IAtrib [ 17 ] := 1;
    IAtrib [ 18 ] := 0;
    // Float attribute is set, the last (and only here) be an element must be 0
    FAtrib := 0;
    // Create temporary device context
    tmpDC := HDC(wglGetCurrentDC);
    //Check / search / multisample PF and whether at least one was found
    if multiARBSup then
      wglChoosePixelFormatARB ( tmpDC , @ IAtrib , @ FAtrib , Length ( possiblePFs ) ,
        @ possiblePFs , @ numPFs )
    else if multiEXTSup then
      wglChoosePixelFormatEXT ( tmpDC , @ IAtrib , @ FAtrib , Length ( possiblePFs ) ,
        @ possiblePFs , @ numPFs );
    // If not a multi-PF sample was found abandoned procedure simple,
    // The fallback-PF has indeed already been set
    if numPFs = 0 then
      exit;
    // In possiblePFs now all multi-sampled PFs are stored, it must now
    // Still be the one that supports most samples, found
    QueryIAtrib := WGL_SAMPLES_ARB;
    highestSamp := 0;
    MultiPF := 0;
    for i:=0 to Length(possiblePFs)-1 do begin
      // WGL_SAMPLES_ARB read out from the current pixel format
      if multiARBSup then
        wglGetPixelFormatAttribivARB ( tmpDC , possiblePFs [ i ] , 0 , 1 , @ QueryIAtrib ,
          @ ResultIAtrib )
      else if multiARBSup then
        wglGetPixelFormatAttribivEXT ( tmpDC , possiblePFs [ i ] , 0 , 1 , @ QueryIAtrib ,
          @ ResultIAtrib );
      // If the sample number is higher than before, then new set
      if (ResultIAtrib> highestSamp) and (ResultIAtrib <= desiredMutliSample) then
      begin
        highestSamp := ResultIAtrib;
        MultiPF := possiblePFs [ i ];
      end;
    end;
    // In MultiPF now is the ID of the multi-sample-PF, the most samples
    // Supports, so it must be placed only on the window.
    // The only problem is that the window already has a PF and we may
    // So set a new one. The existing window must be destroyed and therefore
    // Be re-created, then the multisample PF set
    result := (MultiPF);
    //caption := inttostr(MultiPF)+' '+inttostr(highestSamp);
  end;
end;

end.
 
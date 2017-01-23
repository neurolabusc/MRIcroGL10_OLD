unit raycast_common;
{$IFNDEF FPC} {$D-,L-,Y-}{$ENDIF}
{$O+,Q-,R-,S-}
{$IFDEF FPC}{$mode objfpc}{$H+}{$ENDIF}
//   Inspired by Peter Trier http://www.daimi.au.dk/~trier/?page_id=98
//   Philip Rideout http://prideout.net/blog/?p=64
//   and Doyub Kim Jan 2009 http://www.doyub.com/blog/759
//   Ported to Pascal by Chris Rorden Apr 2011
//   Tips for Shaders from
//      http://pages.cs.wisc.edu/~nowak/779/779ClassProject.html#bound
interface
{$include opts.inc}
uses
  {$IFDEF FPC}
    {$IFDEF UNIX} LCLIntf,{$ELSE} Windows, {$ENDIF}
  graphtype,
  {$ELSE}
  Windows,
  {$ENDIF}
  {$IFDEF ENABLEWATERMARK}watermark,{$ENDIF}
{$IFDEF USETRANSFERTEXTURE}texture_3d_unita, {$ELSE} texture_3d_unit,{$ENDIF}
           graphics,
  {$IFDEF DGL} dglOpenGL, {$ELSE} gl, glext, {$ENDIF} {$IFDEF COREGL}gl_core_matrix, {$ENDIF}
 define_types,
    sysutils, histogram2d, math, colorbar2d;
type
TRayCast =  RECORD
   backTexture,
  glslprogram, glslprogramSobel, glslprogramBlur: GLuint;
  ModelessColor: TGLRGBQuad;
  ScreenCapture: boolean;
  ClipAzimuth,ClipElevation,ClipDepth,
  LightAzimuth,LightElevation,
  Azimuth,Elevation,WINDOW_WIDTH,WINDOW_HEIGHT : integer;
  OrthoZoom,OrthoX,OrthoY,OrthoZ,Distance,slices: single;
{$IFDEF USETRANSFERTEXTURE}transferTexture1,
{$ENDIF}
  intensityOverlay3D,
  gradientTexture3D,gradientOverlay3D,
  intensityTexture3D,finalImage,
  renderBuffer, frameBuffer, //<--666 not needed {$IFNDEF COREGL} {$ENDIF}
  backFaceBuffer: TGLuint;
  MosaicString,ModelessString: string;
 end;

 const
  kDefaultDistance = 2.25;
  kMaxDistance = 40;
var
  AreaInitialized: boolean = false;


var
  gRayCast: TRayCast;
  procedure sph2cartDeg90x(Azimuth,Elevation,R: single; var lX,lY,lZ: single);
  procedure glUniform1ix(prog: GLuint; name: AnsiString; value: integer);
  procedure glUniform1fx(prog: GLuint; name: AnsiString; value: single );
  procedure uniform3fv( name: AnsiString; v1,v2,v3: single);
  procedure uniform1f( name: AnsiString; value: single );
  procedure LightUniforms;
  procedure ClipUniforms;
  function bindBlankGL(var lTex: TTexture): GLuint;
  function  initVertFrag(vert, frag: string): GLuint;
  procedure uniform1i( name: AnsiString; value: integer);
  function ComputeStepSize (Quality1to10: integer): single;
function WarningIfNoveau: boolean;

function gpuReport: string; //warning: must be called while in OpenGL context!
implementation
uses
  shaderu, mainunit,slices2d;

function WarningIfNoveau: boolean;
var
Vendor: AnsiString;
begin
  result := false;
  Vendor := glGetString(GL_VENDOR);
  if length(Vendor) < 2 then exit;
  if (upcase(Vendor[1]) <> 'N') or (upcase(Vendor[2]) <> 'O') then exit;
  GLForm1.ShowmessageError('If you have problems, switch from the Noveau to NVidia driver. Edit your preferences to hide this message.');
end;


 function gpuReport: string; //warning: must be called while in OpenGL context!
begin
  result := ' OpenGL '+glGetString(GL_VERSION)+' GLSL '+glGetString(GL_SHADING_LANGUAGE_VERSION);
end;

procedure DetectErrorGL(s: string);
var
  err: GLenum;
begin
 err:=glGetError();
 if err>0 then //ShowMessage(format('Model_before: glGetError, code: %d',[err]));
    GLForm1.ShowmessageError('OpenGL error '+s +' : '+inttostr(err));
end;

procedure GetError(p: integer);  //report OpenGL Error
var
  Error: GLenum;
  s: string;
begin
 Error := glGetError();
 if Error = GL_NO_ERROR then exit;
 s := inttostr(p)+'->' + inttostr(Error);
 GLForm1.ShowmessageError('OpenGL error : '+s );
end;

procedure ReportCompileShaderError(glObjectID: GLuint);
var
  s : string;
  maxLength, status : GLint;
begin
  status := 0;
    glGetShaderiv(glObjectID, GL_COMPILE_STATUS, @status);
    if (status <> 0) then exit; //report compiling errors.
    glGetError;
    glGetShaderiv(glObjectID, GL_INFO_LOG_LENGTH, @maxLength);
     setlength(s, maxLength);
     {$IFDEF DGL}
     glGetShaderInfoLog(glObjectID, maxLength, maxLength, @s[1]);
     {$ELSE}
     glGetShaderInfoLog(glObjectID, maxLength, @maxLength, @s[1]);
     {$ENDIF}
     s:=trim(s);
     showDebug('Compile Shader error '+s);
     GLForm1.ShowmessageError('Shader compile error '+s);
end;

procedure ReportCompileProgramError(glObjectID: GLuint);
var
  s : string;
  maxLength : GLint;
begin
  glGetProgramiv(glObjectID, GL_LINK_STATUS, @maxLength);
  if (maxLength = GL_TRUE) then exit;
  maxLength := 4096;
  setlength(s, maxLength);
  {$IFDEF DGL}
  glGetProgramInfoLog(glObjectID, maxLength, maxLength, @s[1]);
  {$ELSE}
  glGetProgramInfoLog(glObjectID, maxLength, @maxLength, @s[1]);
  {$ENDIF}
  s:=trim(s);
  if length(s) < 2 then exit;
  GLForm1.ShowmessageError('Program compile error '+s);
end;

function compileShaderOfType (shaderType: GLEnum;  shaderText: string): GLuint;
begin
   result := glCreateShader(shaderType);
   {$IFDEF DGL}
   glShaderSource(result, 1, PPGLChar(@shaderText), nil);
   {$ELSE}
   glShaderSource(result, 1, PChar(@shaderText), nil);
   {$ENDIF}
   glCompileShader(result);
   ReportCompileShaderError(result);
end;

function  initVertFrag(vert, frag: string): GLuint;
var
   fs, vs: GLuint;
begin
  result := 0;
  glGetError(); //clear errors

  result := glCreateProgram();
  if (length(vert) > 0) then begin
     vs := compileShaderOfType(GL_VERTEX_SHADER, vert);
     if (vs = 0) then exit;
     glAttachShader(result, vs);
  end;
  fs := compileShaderOfType(GL_FRAGMENT_SHADER, frag);
  if (fs = 0) then exit;
  glAttachShader(result, fs);
  glLinkProgram(result);
  ReportCompileProgramError(result);
  if (length(vert) > 0) then begin
     glDetachShader(result, vs);
     glDeleteShader(vs);
  end;
  glDetachShader(result, fs);
  glDeleteShader(fs);
  //glUseProgram(result);  // <- causes flicker on resize with OSX
  glUseProgram(0);
  GetError(1);
end;

function bindBlankGL(var lTex: TTexture): GLuint;
begin //creates an empty texture in VRAM without requiring memory copy from RAM
    //later run glDeleteTextures(1,&oldHandle);
    glGenTextures(1, @result);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glBindTexture(GL_TEXTURE_3D, result);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); //, GL_CLAMP_TO_BORDER) will wrap
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glTexImage3D(GL_TEXTURE_3D, 0, GL_RGBA8, lTex.FiltDim[1], lTex.FiltDim[2], lTex.FiltDim[3], 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
end;

procedure glUniform1fx(prog: GLuint; name: AnsiString; value: single );
begin
    glUniform1f(glGetUniformLocation(prog, pAnsiChar(Name)), value) ;
end;

procedure glUniform1ix(prog: GLuint; name: AnsiString; value: integer);
begin
    glUniform1i(glGetUniformLocation(prog, pAnsiChar(Name)), value) ;
end;

procedure uniform1f( name: AnsiString; value: single );
begin
  glUniform1f(glGetUniformLocation(gRayCast.GLSLprogram, pAnsiChar(Name)), value) ;
end;

procedure uniform1i( name: AnsiString; value: integer);
begin
  glUniform1i(glGetUniformLocation(gRayCast.GLSLprogram, pAnsiChar(Name)), value) ;
end;

procedure uniform3fv( name: AnsiString; v1,v2,v3: single);
begin
  glUniform3f(glGetUniformLocation(gRayCast.GLSLprogram, pAnsiChar(Name)), v1,v2,v3) ;
end;

function lerp (p1,p2,frac: single): single;
begin
  result := round(p1 + frac * (p2 - p1));
end;//linear interpolation

function ComputeStepSize (Quality1to10: integer): single;
var
  f: single;
begin
  f := Quality1to10;
  if f <= 1 then
    f := 0.25;
  if f > 10 then
    f := 10;
  f := f/10;
  f := lerp (gRayCast.slices*0.25,gRayCast.slices*2.0,f);
  if f < 10 then
    f := 10;
  result := 1/f;
  //glForm1.Caption := floattostr(gRayCast.slices);
end;

 FUNCTION  Defuzz(CONST x:  DOUBLE):  DOUBLE;
 const
  fuzz : double = 1.0E-6;
 BEGIN
    IF  ABS(x) < fuzz THEN
        RESULT := 0.0
    ELSE
      RESULT := x
 END {Defuzz};

procedure sph2cartDeg90(Azimuth,Elevation: single; var lX,lY,lZ: single);
//convert spherical AZIMUTH,ELEVATION,RANGE to Cartesion
//see Matlab's [x,y,z] = sph2cart(THETA,PHI,R)
// reverse with cart2sph
var
  E,Phi,Theta: single;
begin
  E := Azimuth;
  while E < 0 do
    E := E + 360;
  while E > 360 do
    E := E - 360;
  Theta := DegToRad(E);
  E := Elevation;
  while E > 90 do
    E := E - 90;
  while E < -90 do
    E := E + 90;
  Phi := DegToRad(E);
  lX := cos(Phi)*cos(Theta);
  lY := cos(Phi)*sin(Theta);
  lZ := sin(Phi);
end;

procedure LightUniforms;
var
  lA,lB,lC,
  lX,lY,lZ: single;
  {$IFDEF COREGL}
  lmv: TnMat44;
  {$ELSE}
  lMgl: array[0..15] of  GLfloat;
  {$ENDIF}
begin
  sph2cartDeg90(gRayCast.LightAzimuth,gRayCast.LightElevation,lX,lY,lZ);
  if gPrefs.RayCastViewCenteredLight then begin
    //Could be done in GLSL with following lines of code, but would be computed once per pixel, vs once per volume
	  //vec3 lightPosition =  normalize(gl_ModelViewMatrixInverse * vec4(lightPosition,0.0)).xyz ;

    lA := lY;
    lB := lZ;
    lC := lX;
    {$IFDEF COREGL}
    lmv := transposeMat(ngl_ModelViewMatrix);
    (*lX := defuzz(lA*lmv[0,0]+lB*lmv[0,1]+lC*lmv[0,2]);
    lY := defuzz(lA*lmv[1,0]+lB*lmv[1,1]+lC*lmv[1,2]);
    lZ := defuzz(lA*lmv[2,0]+lB*lmv[2,1]+lC*lmv[2,2]);  *)
    lX := defuzz(lA*lmv[0,0]+lB*lmv[1,0]+lC*lmv[2,0]);
    lY := defuzz(lA*lmv[0,1]+lB*lmv[1,1]+lC*lmv[2,1]);
    lZ := defuzz(lA*lmv[0,2]+lB*lmv[1,2]+lC*lmv[2,2]);
    {$ELSE}
    glGetFloatv(GL_TRANSPOSE_MODELVIEW_MATRIX, @lMgl);
    lX := defuzz(lA*lMgl[0]+lB*lMgl[4]+lC*lMgl[8]);
    lY := defuzz(lA*lMgl[1]+lB*lMgl[5]+lC*lMgl[9]);
    lZ := defuzz(lA*lMgl[2]+lB*lMgl[6]+lC*lMgl[10]);
    {$ENDIF}


  end;
  lA := sqrt(sqr(lX)+sqr(lY)+Sqr(lZ));
  if lA > 0 then begin //normalize
    lX := lX/lA;
    lY := lY/lA;
    lZ := lZ/lA;
  end;
  uniform3fv('lightPosition',lX,lY,lZ);
end;

procedure sph2cartDeg90x(Azimuth,Elevation,R: single; var lX,lY,lZ: single);
//convert spherical AZIMUTH,ELEVATION,RANGE to Cartesion
//see Matlab's [x,y,z] = sph2cart(THETA,PHI,R)
// reverse with cart2sph
var
  n: integer;
  E,Phi,Theta: single;
begin
  Theta := DegToRad(Azimuth-90);
  E := Elevation;
  if (E > 360) or (E < -360)  then begin
    n := trunc(E / 360) ;
    E := E - (n * 360);
  end;
  if ((E > 89) and (E < 91)) or (E < -269) and (E > -271) then
    E := 90;
  if ((E > 269) and (E < 271)) or (E < -89) and (E > -91) then
    E := -90;
  Phi := DegToRad(E);
  lX := r * cos(Phi)*cos(Theta);
  lY := r * cos(Phi)*sin(Theta);
  lZ := r * sin(Phi);
end;

procedure ClipUniforms;
var
  lD,lX,lY,lZ: single;
begin
  sph2cartDeg90x(gRayCast.ClipAzimuth,gRayCast.ClipElevation,1,lX,lY,lZ);
  uniform3fv('clipPlane',-lX,-lY,-lZ);
  if gRaycast.ClipDepth < 1 then
     lD := -1
  else
    lD := 0.5-(gRayCast.ClipDepth/1000);
  uniform1f( 'clipPlaneDepth', lD);
end;


initialization
with gRayCast do begin
  OrthoZoom := 1.0;
  OrthoX := 0.5;
  OrthoY := 0.5;
  OrthoZ := 0.5;
  MosaicString:='';
  ModelessString := '';
  ScreenCapture := false;
  ModelessColor := RGBA(192,192,192,255);
  LightAzimuth := 0;
  LightElevation := 70;
  ClipAzimuth := 180;
  ClipElevation := 0;
  ClipDepth := 0;
  Azimuth := 110;
  Elevation := 15;
  Distance := kDefaultDistance;
  slices := 256;
  gradientTexture3D := 0;
  intensityTexture3D := 0;
  intensityOverlay3D := 0;
  gradientOverlay3D := 0;
  glslprogram := 0;
  glslprogramBlur := 0;
  glslprogramSobel := 0;
  finalImage := 0;
  renderBuffer := 0;
  frameBuffer := 0;
  backFaceBuffer := 0;
  backTexture := 0;
end;//set gRayCast defaults

end.


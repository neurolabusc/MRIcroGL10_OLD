unit raycastglsl;
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
{$include options.inc}
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
  {$IFDEF DGL} dglOpenGL, {$ELSE} gl, glext, {$ENDIF}
 define_types,
    sysutils, histogram2d, math, colorbar2d;
type
TRayCast =  RECORD
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
  renderBuffer, frameBuffer,backFaceBuffer: TGLuint;
  MosaicString,ModelessString: string;
 end;

 const
  kDefaultDistance = 2.25;
  kMaxDistance = 40;
var
  AreaInitialized: boolean = false;


var
  gRayCast: TRayCast;
  procedure glUniform1ix(prog: GLuint; name: AnsiString; value: integer);  //GLHandleARB
  procedure glUniform1fx(prog: GLuint; name: AnsiString; value: single );  //GLHandleARB
procedure DisplayGL(var lTex: TTexture);
procedure DisplayGLz(var lTex: TTexture; zoom, zoomOffsetX, zoomOffsetY: integer);
//function DisplayGL(var lTex: TTexture): boolean;
function WarningIfNoveau: boolean;
procedure  InitGL (InitialSetup: boolean);// (var lTex: TTexture);
procedure uniform1f( name: AnsiString; value: single );
procedure uniform1i( name: AnsiString; value: integer);
function  initVertFrag(vert, frag: string): GLuint;
function gpuReport: string;
implementation
uses
  shaderu, mainunit,slices2d;

function gpuReport: string; //warning: must be called while in OpenGL context!
begin
  result := 'Vendor= '+glGetString(GL_VENDOR)+' OpenGL= '+glGetString(GL_VERSION)+'; GLSL='+glGetString(GL_SHADING_LANGUAGE_VERSION);
end;

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

//this GLSL shader will blur data

const kSmoothShaderFrag = 'uniform float coordZ, dX, dY, dZ;'
+#10'uniform sampler3D intensityVol;'
+#10'void main(void) {'
+#10' vec3 vx = vec3(gl_TexCoord[0].xy, coordZ);'
+#10' vec4 samp = texture3D(intensityVol,vx+vec3(+dX,+dY,+dZ));'
+#10' samp += texture3D(intensityVol,vx+vec3(+dX,+dY,-dZ));'
+#10' samp += texture3D(intensityVol,vx+vec3(+dX,-dY,+dZ));'
+#10' samp += texture3D(intensityVol,vx+vec3(+dX,-dY,-dZ));'
+#10' samp += texture3D(intensityVol,vx+vec3(-dX,+dY,+dZ));'
+#10' samp += texture3D(intensityVol,vx+vec3(-dX,+dY,-dZ));'
+#10' samp += texture3D(intensityVol,vx+vec3(-dX,-dY,+dZ));'
+#10' samp += texture3D(intensityVol,vx+vec3(-dX,-dY,-dZ));'
+#10' gl_FragColor = samp*0.125;'
+#10'}';

//this will estimate a Sobel smooth
const kSobelShaderFrag = 'uniform float coordZ, dX, dY, dZ;'
+#10'uniform sampler3D intensityVol;'
+#10'void main(void) {'
+#10'  vec3 vx = vec3(gl_TexCoord[0].xy, coordZ);'
+#10'  float TAR = texture3D(intensityVol,vx+vec3(+dX,+dY,+dZ)).a;'
+#10'  float TAL = texture3D(intensityVol,vx+vec3(+dX,+dY,-dZ)).a;'
+#10'  float TPR = texture3D(intensityVol,vx+vec3(+dX,-dY,+dZ)).a;'
+#10'  float TPL = texture3D(intensityVol,vx+vec3(+dX,-dY,-dZ)).a;'
+#10'  float BAR = texture3D(intensityVol,vx+vec3(-dX,+dY,+dZ)).a;'
+#10'  float BAL = texture3D(intensityVol,vx+vec3(-dX,+dY,-dZ)).a;'
+#10'  float BPR = texture3D(intensityVol,vx+vec3(-dX,-dY,+dZ)).a;'
+#10'  float BPL = texture3D(intensityVol,vx+vec3(-dX,-dY,-dZ)).a;'
+#10'  vec4 gradientSample = vec4 (0.0, 0.0, 0.0, 0.0);'
+#10'  gradientSample.r =   BAR+BAL+BPR+BPL -TAR-TAL-TPR-TPL;'
+#10'  gradientSample.g =  TPR+TPL+BPR+BPL -TAR-TAL-BAR-BAL;'
+#10'  gradientSample.b =  TAL+TPL+BAL+BPL -TAR-TPR-BAR-BPR;'
+#10'  gradientSample.a = (abs(gradientSample.r)+abs(gradientSample.g)+abs(gradientSample.b))*0.29;'
+#10'  gradientSample.rgb = normalize(gradientSample.rgb);'
+#10'  gradientSample.rgb =  (gradientSample.rgb * 0.5)+0.5;'
+#10'  gl_FragColor = gradientSample;'
+#10'}';
//the gradientSample.a coefficient is critical - 0.25 is technically correct, 0.29 better emulates CPU (where we normalize alpha values in the whole volume)

(*const kMinimalShaderFrag = 'uniform float coordZ, dX, dY, dZ;'
+#10'uniform sampler3D intensityVol;'
+#10'void main(void){'
+#10'  gl_FragColor = vec4 (0.3, 0.5, 0.7, 0.2);'
+#10'}';*)

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
  glUseProgram(result);
    GetError(1);
end;


(*function  initVertFrag(vert, frag: string): GLuint;
var
	fr, vt, ProgramID: GLuint;
	status: GLint;
        {$IFDEF UNICODE}
        shader_source: AnsiString;
        {$ELSE}
        shader_source: string;
        {$ENDIF}
begin
    result := 0;
    fr := glCreateShader(GL_FRAGMENT_SHADER);
    if (fr = 0) then
        exit;
    //shader_source:=PAnsiChar(frag+#0);
    shader_source:=PAnsiChar(frag);
    {$IFDEF DGL}
    glShaderSource(fr, 1, PPGLChar(@shader_source), nil);
    {$ELSE}
    glShaderSource(fr, 1, PChar(@shader_source), nil);
    {$ENDIF}
    glCompileShader(fr);
    status := 0;
    glGetShaderiv(fr, GL_COMPILE_STATUS, @status);
    if (status = 0) then begin //report compiling errors.
        ReportErrorsGL(fr);
        glDeleteShader(fr);
        exit;
    end;
    ProgramID := glCreateProgram();
    glAttachShader(ProgramID, fr);
    vt := 0;
    if (length(vert) > 0) then begin
        vt := glCreateShader(GL_VERTEX_SHADER);
        if (vt = 0) then
            exit;
        //shader_source:=PAnsiChar(vert+#0);
        shader_source:=PAnsiChar(vert);
        {$IFDEF DGL}
        glShaderSource(vt, 1, PPGLChar(@shader_source), nil);
        {$ELSE}
        glShaderSource(vt, 1, PChar(@shader_source), nil);
        {$ENDIF}
        glCompileShader(vt);
        glGetShaderiv(vt, GL_COMPILE_STATUS, @status);
        if (status = 0) then begin //report compiling errors.
            ReportErrorsGL(vt);
            glDeleteShader(fr);
            glDeleteShader(vt);
            exit;
        end;
        glAttachShader(ProgramID, vt);
    end;
    glLinkProgram(ProgramID);
    glUseProgram(ProgramID);
    glDetachShader(ProgramID, fr);
    glDeleteShader(fr);
    if (length(vert) > 0) then begin
        glDetachShader(ProgramID, vt);
        glDeleteShader(vt);
    end;
    glUseProgram(0);
    result := ProgramID;
end;   *)

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

procedure performBlurSobel(var lTex: TTexture; lIsOverlay: boolean);
//http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-14-render-to-texture/
//http://www.opengl.org/wiki/Framebuffer_Object_Examples
var
   i: integer;
   coordZ: single; //dx
   fb, tempTex3D: GLuint;
begin
  glGenFramebuffersEXT(1, @fb);
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb);
  //glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,gRayCast.frameBuffer);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);// <- REQUIRED
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
  //glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA8, lTex.FiltDim[1], lTex.FiltDim[2], 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
  glViewport(0, 0, lTex.FiltDim[1], lTex.FiltDim[2]);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho (0, 1,0, 1, -1, 1);  //gluOrtho2D(0, 1, 0, 1);  https://www.opengl.org/sdk/docs/man2/xhtml/gluOrtho2D.xml
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_BLEND);
  //glDisable(GL_TEXTURE_2D);
  //STEP 1: run smooth program gradientTexture -> tempTex3D
  tempTex3D := bindBlankGL(lTex);
  //glUseProgramObjectARB(gRayCast.glslprogramBlur);
  glUseProgram(gRayCast.glslprogramBlur);
  glActiveTexture( GL_TEXTURE1);
  //glBindTexture(GL_TEXTURE_3D, gRayCast.gradientTexture3D);//input texture
  if lIsOverlay then
     glBindTexture(GL_TEXTURE_3D, gRayCast.intensityOverlay3D)//input texture is overlay
  else
      glBindTexture(GL_TEXTURE_3D, gRayCast.intensityTexture3D);//input texture is background
  //glEnable(GL_TEXTURE_2D);
  //glDisable(GL_TEXTURE_2D);
  glUniform1ix(gRayCast.glslprogramBlur, 'intensityVol', 1);
  //glUniform1fx(gRayCast.glslprogramBlur, 'dX', 0.5/lTex.FiltDim[1]); //0.5 for smooth - center contributes
  //glUniform1fx(gRayCast.glslprogramBlur, 'dY', 0.5/lTex.FiltDim[2]);
  //glUniform1fx(gRayCast.glslprogramBlur, 'dZ', 0.5/lTex.FiltDim[3]);
  glUniform1fx(gRayCast.glslprogramBlur, 'dX', 0.7/lTex.FiltDim[1]); //0.5 for smooth - center contributes
  glUniform1fx(gRayCast.glslprogramBlur, 'dY', 0.7/lTex.FiltDim[2]);
  glUniform1fx(gRayCast.glslprogramBlur, 'dZ', 0.7/lTex.FiltDim[3]);
  for i := 0 to (lTex.FiltDim[3]-1) do begin
      coordZ := 1/lTex.FiltDim[3] * (i + 0.5);
      glUniform1fx(gRayCast.glslprogramBlur, 'coordZ', coordZ);
      //glFramebufferTexture3D(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0, GL_TEXTURE_3D, tempTex3D, 0, i);//output texture
      //Ext required: Delphi compile on Winodws 32-bit XP with NVidia 8400M
      glFramebufferTexture3DExt(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0, GL_TEXTURE_3D, tempTex3D, 0, i);//output texture
      glClear(GL_DEPTH_BUFFER_BIT);  // clear depth bit (before render every layer)
      glBegin(GL_QUADS);
      glTexCoord2f(0, 0);
      glVertex2f(0, 0);
      glTexCoord2f(1.0, 0);
      glVertex2f(1.0, 0.0);
      glTexCoord2f(1.0, 1.0);
      glVertex2f(1.0, 1.0);
      glTexCoord2f(0, 1.0);
      glVertex2f(0.0, 1.0);
      glEnd();
  end;
  glUseProgram(0);
  //STEP 2: run sobel program gradientTexture -> tempTex3D
  //glUseProgramObjectARB(gRayCast.glslprogramSobel);
  glUseProgram(gRayCast.glslprogramSobel);
  glActiveTexture(GL_TEXTURE1);
  //x glBindTexture(GL_TEXTURE_3D, gRayCast.intensityTexture3D);//input texture
  glBindTexture(GL_TEXTURE_3D, tempTex3D);//input texture
  //  glEnable(GL_TEXTURE_2D);
  //  glDisable(GL_TEXTURE_2D);
    glUniform1ix(gRayCast.glslprogramSobel, 'intensityVol', 1);
    //glUniform1fx(gRayCast.glslprogramSobel, 'dX', 1.0/lTex.FiltDim[1] ); //1.0 for SOBEL - center excluded
    //glUniform1fx(gRayCast.glslprogramSobel, 'dY', 1.0/lTex.FiltDim[2]);
    //glUniform1fx(gRayCast.glslprogramSobel, 'dZ', 1.0/lTex.FiltDim[3]);
    glUniform1fx(gRayCast.glslprogramSobel, 'dX', 1.2/lTex.FiltDim[1] ); //1.0 for SOBEL - center excluded
    glUniform1fx(gRayCast.glslprogramSobel, 'dY', 1.2/lTex.FiltDim[2]);
    glUniform1fx(gRayCast.glslprogramSobel, 'dZ', 1.2/lTex.FiltDim[3]);
    //for i := 0 to (dim3-1) do begin
    //  glColor4f(0.7,0.3,0.2, 0.7);
    for i := 0 to (lTex.FiltDim[3]-1) do begin
        coordZ := 1/lTex.FiltDim[3] * (i + 0.5);
        glUniform1fx(gRayCast.glslprogramSobel, 'coordZ', coordZ);
        (*Ext required: Delphi compile on Winodws 32-bit XP with NVidia 8400M
        if lIsOverlay then
          glFramebufferTexture3D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_3D, gRayCast.gradientOverlay3D, 0, i)
        else
            glFramebufferTexture3D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_3D, gRayCast.gradientTexture3D, 0, i);*)
        if lIsOverlay then
          glFramebufferTexture3DExt(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_3D, gRayCast.gradientOverlay3D, 0, i)//output is overlay
        else
            glFramebufferTexture3DExt(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_3D, gRayCast.gradientTexture3D, 0, i);//output is background
        glClear(GL_DEPTH_BUFFER_BIT);
        glBegin(GL_QUADS);
        glTexCoord2f(0, 0);
        glVertex2f(0, 0);
        glTexCoord2f(1.0, 0);
        glVertex2f(1.0, 0.0);
        glTexCoord2f(1.0, 1.0);
        glVertex2f(1.0, 1.0);
        glTexCoord2f(0, 1.0);
        glVertex2f(0.0, 1.0);
        glEnd();
    end;
    glUseProgram(0);
     //clean up:
     glDeleteTextures(1,@tempTex3D);
     glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
     glDeleteFramebuffersEXT(1, @fb);
     glActiveTexture( GL_TEXTURE0 );  //required if we will draw 2d slices next
end;

procedure doShaderBlurSobel (var lTex: TTexture);
var
   startTime: DWord;
begin
  if (not lTex.updateBackgroundGradientsGLSL) and (not lTex.updateOverlayGradientsGLSL) then exit;
  //crapGL(lTex); exit;
  if (gRayCast.glslprogramBlur = 0) then
     gRayCast.glslprogramBlur := initVertFrag('',kSmoothShaderFrag); //initFragShader (kSmoothShaderFrag,gRayCast.glslprogramBlur);

  if (gRayCast.glslprogramSobel = 0) then
     gRayCast.glslprogramSobel := initVertFrag('',kSobelShaderFrag);
     //initFragShader (kSobelShaderFrag,gRayCast.glslprogramSobel );
    if (lTex.updateBackgroundGradientsGLSL) then begin
       startTime := gettickcount;
       performBlurSobel(lTex, false);
       lTex.updateBackgroundGradientsGLSL := false;
       if gPrefs.Debug then
          GLForm1.Caption := 'GLSL gradients '+inttostr(gettickcount-startTime)+' ms '+gpuReport;
    end;
    if (lTex.updateOverlayGradientsGLSL) then begin
       performBlurSobel(lTex, true);
       lTex.updateOverlayGradientsGLSL := false;
    end;
end;

procedure  enableRenderbuffers;
begin
     glBindFramebufferEXT (GL_FRAMEBUFFER_EXT, gRayCast.frameBuffer);
     glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, gRayCast.renderBuffer);
end;

procedure disableRenderBuffers;
begin
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
end;

procedure drawVertex(x,y,z: single);
begin
	glColor3f(x,y,z);
	glMultiTexCoord3f(GL_TEXTURE1, x, y, z);
	glVertex3f(x,y,z);
end;

procedure drawQuads(x,y,z: single);
//x,y,z typically 1.
// useful for clipping
// If x=0.5 then only left side of texture drawn
// If y=0.5 then only posterior side of texture drawn
// If z=0.5 then only inferior side of texture drawn
begin
	glBegin(GL_QUADS);
	//* Back side
	glNormal3f(0.0, 0.0, -1.0);
	drawVertex(0.0, 0.0, 0.0);
	drawVertex(0.0, y, 0.0);
	drawVertex(x, y, 0.0);
	drawVertex(x, 0.0, 0.0);
	//* Front side
	glNormal3f(0.0, 0.0, 1.0);
	drawVertex(0.0, 0.0, z);
	drawVertex(x, 0.0, z);
	drawVertex(x, y, z);
	drawVertex(0.0, y, z);
	//* Top side
	glNormal3f(0.0, 1.0, 0.0);
	drawVertex(0.0, y, 0.0);
	drawVertex(0.0, y, z);
    drawVertex(x, y, z);
	drawVertex(x, y, 0.0);
	//* Bottom side
	glNormal3f(0.0, -1.0, 0.0);
	drawVertex(0.0, 0.0, 0.0);
	drawVertex(x, 0.0, 0.0);
	drawVertex(x, 0.0, z);
	drawVertex(0.0, 0.0, z);
	//* Left side
	glNormal3f(-1.0, 0.0, 0.0);
	drawVertex(0.0, 0.0, 0.0);
	drawVertex(0.0, 0.0, z);
	drawVertex(0.0, y, z);
	drawVertex(0.0, y, 0.0);
	//* Right side
	glNormal3f(1.0, 0.0, 0.0);
	drawVertex(x, 0.0, 0.0);
	drawVertex(x, y, 0.0);
	drawVertex(x, y, z);
	drawVertex(x, 0.0, z);
	glEnd();
end;

function LoadStr (lFilename: string): string;
var
  myFile : TextFile;
  text : string;
begin
  result := '';
  if not fileexists(lFilename) then begin
    showDebug('Unable to find '+lFilename);
    //GLForm1.ShowmessageError('Unable to find '+lFilename);
    exit;
  end;
  AssignFile(myFile,lFilename);
  Reset(myFile);
  while not Eof(myFile) do begin
    ReadLn(myFile, text);
    result := result+text+#13#10;
  end;
  CloseFile(myFile);
end;

procedure reshapeOrtho(w,h: integer);
begin
  if (h = 0) then h := 1;
  glViewport(0, 0,w,h);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho (0, 1,0, 1, -1, 1);  //gluOrtho2D(0, 1, 0, 1.0);  https://www.opengl.org/sdk/docs/man2/xhtml/gluOrtho2D.xml
  glMatrixMode(GL_MODELVIEW);//?
end;

procedure resize(w,h, zoom, zoomOffsetX, zoomOffsetY: integer);
var
  whratio,scale: single;
begin
  if (h = 0) then
     h := 1;
  if zoom > 1 then
     glViewport(zoomOffsetX, zoomOffsetY, w*zoom, h*zoom)
  else
      glViewport(0, 0, w, h);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  (*if gPrefs.Perspective then
    gluPerspective(40.0, w/h, 0.01, kMaxDistance{Distance})
  else*) begin
       if gRayCast.Distance = 0 then
          scale := 1
       else
           scale := 1/abs(kDefaultDistance/(gRayCast.Distance+1.0));
       whratio := w/h;
       glOrtho(whratio*-0.5*scale,whratio*0.5*scale,-0.5*scale,0.5*scale, 0.01, kMaxDistance);
  end;
  glMatrixMode(GL_MODELVIEW);//?
end;

procedure  InitGL (InitialSetup: boolean);// (var lTex: TTexture);
begin
  glEnable(GL_CULL_FACE);
  glClearColor(gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255, 0);
  //initShaderWithFile('xrc.vert', 'xrc.frag',gRayCast.glslprogramGradient);
  // Load the vertex and fragment raycasting programs
  //initShaderWithFile('rc.vert', 'rc.frag',gRayCast.glslprogram);
  if (gRayCast.glslprogram <> 0) then begin glDeleteProgram(gRayCast.glslprogram); gRayCast.glslprogram := 0; end;
  gRayCast.glslprogram :=  initVertFrag(gShader.VertexProgram, gShader.FragmentProgram);
  if (gRayCast.glslprogram = 0) then begin //error: load default shader
     gShader := LoadShader('');
     gRayCast.glslprogram :=  initVertFrag(gShader.VertexProgram, gShader.FragmentProgram);
  end;

  // Create the to FBO's one for the backside of the volumecube and one for the finalimage rendering
  if InitialSetup then begin
    glGenFramebuffersEXT(1, @gRayCast.frameBuffer);
    glGenTextures(1, @gRayCast.backFaceBuffer);
    glGenTextures(1, @gRayCast.finalImage);
    glGenRenderbuffersEXT(1, @gRayCast.renderBuffer);
  end;
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,gRayCast.frameBuffer);
  glBindTexture(GL_TEXTURE_2D, gRayCast.backFaceBuffer);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
  glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA16F_ARB, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT, 0, GL_RGBA, GL_FLOAT, nil);
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, gRayCast.backFaceBuffer, 0);
  glBindTexture(GL_TEXTURE_2D, gRayCast.finalImage);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
  glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA16F_ARB, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT, 0, GL_RGBA, GL_FLOAT, nil);
  //These next lines moved to DisplayGZz for VirtualBox compatibility
   glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, gRayCast.renderBuffer);
   glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT);
  glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, gRayCast.renderBuffer);
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
end;

procedure drawUnitQuad;
//stretches image in view space.
begin
	glDisable(GL_DEPTH_TEST);
	glBegin(GL_QUADS);
	glTexCoord2f(0,0);
	glVertex2f(0,0);
	glTexCoord2f(1,0);
	glVertex2f(1,0);
	glTexCoord2f(1, 1);
	glVertex2f(1, 1);
	glTexCoord2f(0, 1);
	glVertex2f(0, 1);
	glEnd();
	glEnable(GL_DEPTH_TEST);
end;

// display the final image on the screen
procedure renderBufferToScreen;
begin
	glClear( GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
	glLoadIdentity();
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D,gRayCast.finalImage);
	//use next line instead of previous to illustrate one-pass rendering
	//glBindTexture(GL_TEXTURE_2D,backFaceBuffer)
	reshapeOrtho(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT);
	drawUnitQuad();
	glDisable(GL_TEXTURE_2D);
end;

// render the backface to the offscreen buffer backFaceBuffer
procedure renderBackFace(var lTex: TTexture);
begin
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, gRayCast.backFaceBuffer, 0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
  glEnable(GL_CULL_FACE);
  glCullFace(GL_FRONT);
  glMatrixMode(GL_MODELVIEW);
  glScalef(lTex.Scale[1],lTex.Scale[2],lTex.Scale[3]);
  drawQuads(1.0,1.0,1.0);
  glDisable(GL_CULL_FACE);
end;

(*procedure  InitGL (InitialSetup: boolean);// (var lTex: TTexture);
begin
  glEnable(GL_CULL_FACE);
  glClearColor(gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255, 0);
  //initShaderWithFile('xrc.vert', 'xrc.frag',gRayCast.glslprogramGradient);
  // Load the vertex and fragment raycasting programs
  //initShaderWithFile('rc.vert', 'rc.frag',gRayCast.glslprogram);
  if (gRayCast.glslprogram <> 0) then begin
    glDeleteProgram(gRayCast.glslprogram);
    gRayCast.glslprogram := 0;
  end;
  gRayCast.glslprogram :=  initVertFrag(gShader.VertexProgram, gShader.FragmentProgram);
  if (gRayCast.glslprogram = 0) then begin //error: load default shader
     gShader := LoadShader('');
     gRayCast.glslprogram :=  initVertFrag(gShader.VertexProgram, gShader.FragmentProgram);
  end;

  // Create the to FBO's one for the backside of the volumecube and one for the finalimage rendering
  if InitialSetup then begin
    glGenFramebuffersEXT(1, @gRayCast.frameBuffer);
    glGenTextures(1, @gRayCast.backFaceBuffer);
    glGenTextures(1, @gRayCast.finalImage);
    glGenRenderbuffersEXT(1, @gRayCast.renderBuffer);
  end;
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,gRayCast.frameBuffer);
  glBindTexture(GL_TEXTURE_2D, gRayCast.backFaceBuffer);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
  glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA16F_ARB, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT, 0, GL_RGBA, GL_FLOAT, nil);
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, gRayCast.backFaceBuffer, 0);
  glBindTexture(GL_TEXTURE_2D, gRayCast.finalImage);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
  glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA16F_ARB, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT, 0, GL_RGBA, GL_FLOAT, nil);
  //These next lines moved to DisplayGZz for VirtualBox compatibility
   glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, gRayCast.renderBuffer);
   glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT);
  glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, gRayCast.renderBuffer);
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
end;

procedure drawUnitQuad;
//stretches image in view space.
begin
	glDisable(GL_DEPTH_TEST);
	glBegin(GL_QUADS);
	glTexCoord2f(0,0);
	glVertex2f(0,0);
	glTexCoord2f(1,0);
	glVertex2f(1,0);
	glTexCoord2f(1, 1);
	glVertex2f(1, 1);
	glTexCoord2f(0, 1);
	glVertex2f(0, 1);
	glEnd();
	glEnable(GL_DEPTH_TEST);
end;

// display the final image on the screen
procedure renderBufferToScreen;
begin
	glClear( GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
	glLoadIdentity();
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D,gRayCast.finalImage);
	//use next line instead of previous to illustrate one-pass rendering
	//glBindTexture(GL_TEXTURE_2D,backFaceBuffer)
	reshapeOrtho(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT);
	drawUnitQuad();
	glDisable(GL_TEXTURE_2D);
end;

// render the backface to the offscreen buffer backFaceBuffer
procedure renderBackFace(var lTex: TTexture);
begin
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, gRayCast.backFaceBuffer, 0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
  glEnable(GL_CULL_FACE);
  glCullFace(GL_FRONT);
  glMatrixMode(GL_MODELVIEW);
  glScalef(lTex.Scale[1],lTex.Scale[2],lTex.Scale[3]);
  drawQuads(1.0,1.0,1.0);
  glDisable(GL_CULL_FACE);
end;    *)

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
  lMgl: array[0..15] of  GLfloat;
begin
  sph2cartDeg90(gRayCast.LightAzimuth,gRayCast.LightElevation,lX,lY,lZ);
  if gPrefs.RayCastViewCenteredLight then begin
    //Could be done in GLSL with following lines of code, but would be computed once per pixel, vs once per volume
	  //vec3 lightPosition =  normalize(gl_ModelViewMatrixInverse * vec4(lightPosition,0.0)).xyz ;
    glGetFloatv(GL_TRANSPOSE_MODELVIEW_MATRIX, @lMgl);
    lA := lY;
    lB := lZ;
    lC := lX;
    lX := defuzz(lA*lMgl[0]+lB*lMgl[4]+lC*lMgl[8]);
    lY := defuzz(lA*lMgl[1]+lB*lMgl[5]+lC*lMgl[9]);
    lZ := defuzz(lA*lMgl[2]+lB*lMgl[6]+lC*lMgl[10]);
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

procedure drawFrame(x,y,z: single);
//x,y,z typically 1.
// useful for clipping
// If x=0.5 then only left side of texture drawn
// If y=0.5 then only posterior side of texture drawn
// If z=0.5 then only inferior side of texture drawn
begin
  glColor4f(1,1,1,1);
	glBegin(GL_LINE_STRIP);
	//* Back side
	//glNormal3f(0.0, 0.0, -1.0);
	drawVertex(0.0, 0.0, 0.0);
	drawVertex(0.0, y, 0.0);
	drawVertex(x, y, 0.0);
	drawVertex(x, 0.0, 0.0);
  glEnd;
	glBegin(GL_LINE_STRIP);
	//* Front side
	//glNormal3f(0.0, 0.0, 1.0);
	drawVertex(0.0, 0.0, z);
	drawVertex(x, 0.0, z);
	drawVertex(x, y, z);
	drawVertex(0.0, y, z);
  glEnd;
	glBegin(GL_LINE_STRIP);
	//* Top side
	//glNormal3f(0.0, 1.0, 0.0);
	drawVertex(0.0, y, 0.0);
	drawVertex(0.0, y, z);
    drawVertex(x, y, z);
	drawVertex(x, y, 0.0);
  glEnd;
    glColor4f(0.2,0.2,0.2,0);
	glBegin(GL_LINE_STRIP);
	//* Bottom side
	//glNormal3f(0.0, -1.0, 0.0);
	drawVertex(0.0, 0.0, 0.0);
	drawVertex(x, 0.0, 0.0);
	drawVertex(x, 0.0, z);
	drawVertex(0.0, 0.0, z);
  glEnd;
  glColor4f(0,1,0,0);
	glBegin(GL_LINE_STRIP);
	//* Left side
	//glNormal3f(-1.0, 0.0, 0.0);
	drawVertex(0.0, 0.0, 0.0);
	drawVertex(0.0, 0.0, z);
	drawVertex(0.0, y, z);
	drawVertex(0.0, y, 0.0);
  glEnd;
  glColor4f(1,0,0,0);
  glBegin(GL_LINE_STRIP);
	//* Right side
	//glNormal3f(1.0, 0.0, 0.0);
	drawVertex(x, 0.0, 0.0);
	drawVertex(x, y, 0.0);
	drawVertex(x, y, z);
	drawVertex(x, 0.0, z);
	glEnd();
end;

procedure rayCasting (var lTex: TTexture);
begin
     //glUseProgram(gRayCast.glslprogramGradient);
     glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, gRayCast.finalImage, 0);
	glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
	//glEnable(GL_TEXTURE_2D);
	glActiveTexture( GL_TEXTURE0 );
	glBindTexture(GL_TEXTURE_2D, gRayCast.backFaceBuffer);
	glActiveTexture( GL_TEXTURE1 );
	glBindTexture(GL_TEXTURE_3D,gRayCast.gradientTexture3D);
{$IFDEF USETRANSFERTEXTURE}
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_1D, gRayCast.TransferTexture1);
{$ENDIF}
        glActiveTexture( GL_TEXTURE3 );
	glBindTexture(GL_TEXTURE_3D,gRayCast.intensityTexture3D);
        if  (gShader.OverlayVolume > 0) then begin
          glActiveTexture(GL_TEXTURE4);
          glBindTexture(GL_TEXTURE_3D,gRayCast.intensityOverlay3D);
          if (gShader.OverlayVolume > 1) then begin
             glActiveTexture(GL_TEXTURE5);
             glBindTexture(GL_TEXTURE_3D,gRayCast.gradientOverlay3D);
          end;
        end;
        glUseProgram(gRayCast.glslprogram);
  uniform1i( 'loops',round(gRayCast.slices*2.2));
  if gRayCast.ScreenCapture then
      uniform1f( 'stepSize', ComputeStepSize(10) )
  else
      uniform1f( 'stepSize', ComputeStepSize(gPrefs.RayCastQuality1to10) );
  uniform1f( 'sliceSize', 1/gRayCast.slices );
  uniform1f( 'viewWidth', gRayCast.WINDOW_WIDTH );
  uniform1f( 'viewHeight', gRayCast.WINDOW_HEIGHT );
  uniform1i( 'backFace', 0 );		// backFaceBuffer -> texture0
  uniform1i( 'gradientVol', 1 );	// gradientTexture -> texture2
  {$IFDEF USETRANSFERTEXTURE}
  uniform1i( 'TransferTexture',2); //used when render volumes are scalar, not RGBA{$ENDIF}
  {$ENDIF}
  uniform1i( 'intensityVol', 3 );
  if (gShader.OverlayVolume > 0) then begin
    uniform1i( 'overlays',gOpenOverlays);
    uniform1i( 'overlayVol', 4 );
    if (gShader.OverlayVolume > 1) then
        uniform1i( 'overlayGradientVol', 5 );
  end;
  if lTex.DataType = GL_RGBA then
    uniform1i( 'useTransferTexture',0)
  else
    uniform1i( 'useTransferTexture',1);
  AdjustShaders(gShader);
  LightUniforms;
  ClipUniforms;
  uniform3fv('clearColor',gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255);
  glEnable(GL_CULL_FACE);
  glCullFace(GL_BACK);
  glMatrixMode(GL_MODELVIEW);
  glScalef(1,1,1);
  drawQuads(1.0,1.0,1.0);
  glDisable(GL_CULL_FACE);
  glUseProgram(0);
  glActiveTexture( GL_TEXTURE0 );
  //glDisable(GL_TEXTURE_2D);
end;

procedure MakeCube(sz: single);
var
  sz2: single;
begin
  sz2 := sz;
  glColor4f(0.1,0.1,0.1,1);
  glBegin(GL_QUADS);
	//* Bottom side
	glVertex3f(-sz, -sz, -sz2);
	glVertex3f(-sz, sz, -sz2);
	glVertex3f(sz, sz, -sz2);
	glVertex3f(sz, -sz, -sz2);
  glEnd;
  glColor4f(0.8,0.8,0.8,1);
  glBegin(GL_QUADS);
	//* Top side
	glVertex3f(-sz, -sz, sz2);
	glVertex3f(sz, -sz, sz2);
	glVertex3f(sz, sz, sz2);
	glVertex3f(-sz, sz, sz2);
  glEnd;
  glColor4f(0,0,0.4,1);
  glBegin(GL_QUADS);
	//* Front side
	glVertex3f(-sz, sz2, -sz);
	glVertex3f(-sz, sz2, sz);
    glVertex3f(sz, sz2, sz);
	glVertex3f(sz, sz2, -sz);
  glEnd;
  glColor4f(0.2,0,0.2,1);
  glBegin(GL_QUADS);
	//* Back side
	glVertex3f(-sz, -sz2, -sz);
	glVertex3f(sz, -sz2, -sz);
	glVertex3f(sz, -sz2, sz);
	glVertex3f(-sz, -sz2, sz);
  glEnd;
  glColor4f(0.6,0,0,1);
  glBegin(GL_QUADS);
	//* Left side
	glVertex3f(-sz2, -sz, -sz);
	glVertex3f(-sz2, -sz, sz);
	glVertex3f(-sz2, sz, sz);
	glVertex3f(-sz2, sz, -sz);
  glEnd;
  glColor4f(0,0.6,0,1);
  glBegin(GL_QUADS);
	//* Right side
	//glNormal3f(1.0, -sz, -sz);
	glVertex3f(sz2, -sz, -sz);
	glVertex3f(sz2, sz, -sz);
	glVertex3f(sz2, sz, sz);
	glVertex3f(sz2, -sz, sz);
	glEnd();
end;

procedure DrawCube (lScrnWid, lScrnHt, zoomOffsetX, zoomOffsetY: integer);
var
  mn: integer;
  sz: single;
begin
  mn := lScrnWid;
  if  mn > lScrnHt then mn := lScrnHt;
  if mn < 10 then exit;
  sz := mn * 0.03;
  // glEnable(GL_CULL_FACE); // <- required for Cocoa
  glDisable(GL_DEPTH_TEST);
  glMatrixMode (GL_PROJECTION);
  glLoadIdentity ();
  glOrtho (0, gRayCast.WINDOW_WIDTH,0, gRayCast.WINDOW_Height,-10*sz,10*sz);
  glEnable(GL_DEPTH_TEST);
  glDisable (GL_LIGHTING);
  glDisable (GL_BLEND);
  glTranslatef(1.8*sz,1.8*sz,0);
  glTranslatef(zoomOffsetX, zoomOffsetY, 0);
  glRotatef(90-gRayCast.Elevation,-1,0,0);
  glRotatef(gRayCast.Azimuth,0,0,1);
  MakeCube(sz);
  //glDisable(GL_DEPTH_TEST);
  //glDisable(GL_CULL_FACE); // <- required for Cocoa
end;

procedure DisplayGLz(var lTex: TTexture; zoom, zoomOffsetX, zoomOffsetY: integer);
begin
  //if (gPrefs.SliceView  = 5) and (length(gRayCast.MosaicString) < 1) then exit; //we need to draw something, otherwise swapbuffer crashes
  if (gPrefs.SliceView  <> 5) then  gRayCast.MosaicString := '';
  doShaderBlurSobel(lTex);
  glClearColor(gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255, 0);
  resize(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT,zoom, zoomOffsetX, zoomOffsetY);
  glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, gRayCast.renderBuffer);
  glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT);  //required by VirtualBox

  {$IFDEF ENABLEMOSAICS}
  if length(gRayCast.MosaicString)> 0 then begin //draw mosaics
     glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
     glDisable(GL_CULL_FACE); //<-this is important, otherwise nodes and quads not filled
     MosaicGL(gRayCast.MosaicString);

  end else {$ENDIF} if gPrefs.SliceView > 0  then begin //draw 2D orthogonal slices
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
    glDisable(GL_CULL_FACE); //<-this is important, otherwise nodes and quads not filled
    DrawOrtho(lTex);
  end else begin //else draw 3D rendering
    enableRenderbuffers();
    glTranslatef(0,0,-gRayCast.Distance);
    glRotatef(90-gRayCast.Elevation,-1,0,0);
    glRotatef(gRayCast.Azimuth,0,0,1);
    glTranslatef(-lTex.Scale[1]/2,-lTex.Scale[2]/2,-lTex.Scale[3]/2);
    renderBackFace(lTex);
    rayCasting(lTex);
    disableRenderBuffers();
    renderBufferToScreen();
    if gPrefs.SliceDetailsCubeAndText then
      drawCube(gRayCast.WINDOW_WIDTH*zoom, gRayCast.WINDOW_HEIGHT*zoom, zoomOffsetX, zoomOffsetY);
    resize(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT,zoom, zoomOffsetX, zoomOffsetY);
  end;
  if gPrefs.ColorEditor then
    DrawNodes(gRayCast.WINDOW_HEIGHT,gRayCast.WINDOW_WIDTH, lTex, gPrefs);
  if gPrefs.Colorbar then
     DrawCLUT( gPrefs.ColorBarPos,0.01, gPrefs);//, gRayCast.WINDOW_WIDTH*zoom, gRayCast.WINDOW_HEIGHT*zoom, zoomOffsetX, zoomOffsetY);

  {$IFDEF ENABLEWATERMARK}
  if gWatermark.filename <> '' then
    LoadWatermark(gWatermark);
  if gWatermark.Ht > 0 then
    DrawWatermark(gWatermark.X,gWatermark.Y,gWatermark.Wid,gWatermark.Ht,gWatermark);
  {$ENDIF}
  glDisable (GL_BLEND); //just in case one of the previous functions forgot...
  glFlush;//<-this would pause until all jobs are SUBMITTED
  //glFinish;//<-this would pause until all jobs finished: generally a bad idea!
  //next, you will need to execute SwapBuffers
end;


(*procedure DisplayGLz(var lTex: TTexture; zoom, zoomOffsetX, zoomOffsetY: integer);
begin
  //if (gPrefs.SliceView  = 5) and (length(gRayCast.MosaicString) < 1) then exit; //we need to draw something, otherwise swapbuffer crashes
  if (gPrefs.SliceView  <> 5) then  gRayCast.MosaicString := '';
  doShaderBlurSobel(lTex);
  glClearColor(gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255, 0);
  resize(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT,zoom, zoomOffsetX, zoomOffsetY);
  glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, gRayCast.renderBuffer);
  glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT);  //required by VirtualBox
  {$IFDEF ENABLEMOSAICS}
  if length(gRayCast.MosaicString)> 0 then begin //draw mosaics
     glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
     glDisable(GL_CULL_FACE); //<-this is important, otherwise nodes and quads not filled
     MosaicGL(gRayCast.MosaicString);

  end else {$ENDIF} if gPrefs.SliceView > 0  then begin //draw 2D orthogonal slices
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
    glDisable(GL_CULL_FACE); //<-this is important, otherwise nodes and quads not filled
    DrawOrtho(lTex);
  end else begin //else draw 3D rendering
    enableRenderbuffers();
    glTranslatef(0,0,-gRayCast.Distance);
    glRotatef(90-gRayCast.Elevation,-1,0,0);
    glRotatef(gRayCast.Azimuth,0,0,1);
    glTranslatef(-lTex.Scale[1]/2,-lTex.Scale[2]/2,-lTex.Scale[3]/2);
    renderBackFace(lTex);
    rayCasting(lTex);
    disableRenderBuffers();
    renderBufferToScreen();
    if gPrefs.SliceDetailsCubeAndText then
      drawCube(gRayCast.WINDOW_WIDTH*zoom, gRayCast.WINDOW_HEIGHT*zoom, zoomOffsetX, zoomOffsetY);
    resize(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT,zoom, zoomOffsetX, zoomOffsetY);
  end;
  if gPrefs.ColorEditor then
    DrawNodes(gRayCast.WINDOW_HEIGHT,gRayCast.WINDOW_WIDTH, lTex, gPrefs);
  if gPrefs.Colorbar then
     DrawCLUT( gPrefs.ColorBarPos,0.01, gPrefs);//, gRayCast.WINDOW_WIDTH*zoom, gRayCast.WINDOW_HEIGHT*zoom, zoomOffsetX, zoomOffsetY);

  {$IFDEF ENABLEWATERMARK}
  if gWatermark.filename <> '' then
    LoadWatermark(gWatermark);
  if gWatermark.Ht > 0 then
    DrawWatermark(gWatermark.X,gWatermark.Y,gWatermark.Wid,gWatermark.Ht,gWatermark);
  {$ENDIF}
  glDisable (GL_BLEND); //just in case one of the previous functions forgot...
  glFlush;//<-this would pause until all jobs are SUBMITTED
  //glFinish;//<-this would pause until all jobs finished: generally a bad idea!
  //next, you will need to execute SwapBuffers
end;*)

procedure DisplayGL(var lTex: TTexture);
begin
  DisplayGLz(lTex,1,0,0);
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
end;//set gRayCast defaults

end.


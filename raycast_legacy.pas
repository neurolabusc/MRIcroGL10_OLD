unit raycast_legacy;
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
{$IFDEF DGL} dglOpenGL, {$ELSE DGL} {$IFDEF COREGL}glcorearb, {$ELSE} gl,glext, {$ENDIF}  {$ENDIF DGL}
 define_types,
    sysutils, histogram2d, math, colorbar2d, raycast_common;

procedure DisplayGL(var lTex: TTexture);
procedure DisplayGLz(var lTex: TTexture; zoom, zoomOffsetX, zoomOffsetY: integer);
procedure  InitGL (InitialSetup: boolean);// (var lTex: TTexture);

implementation
uses
  shaderu, mainunit,slices2d;

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
  {$IFDEF DGL}
  gluOrtho2D(0, 1, 0, 1);
  {$ELSE}
  glOrtho (0, 1,0, 1, -1, 1);  //gluOrtho2D(0, 1, 0, 1);  https://www.opengl.org/sdk/docs/man2/xhtml/gluOrtho2D.xml
  {$ENDIF}
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
          GLForm1.Caption := 'GLSL gradients '+inttostr(gettickcount-startTime)+' ms ';
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

procedure drawQuadX(x,y: single); //NO IDEA WHY THIS IS REQUIRED!
begin
    glBegin(GL_TRIANGLES);
    	glNormal3f(0.0, 0.0, -1.0);
	drawVertex(0.0, 0.0, 0.0);
	drawVertex(0.0, y, 0.0);
	drawVertex(x, y, 0.0);
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
  {$IFDEF DGL}
  gluOrtho2D(0, 1, 0, 1.0);
  {$ELSE}
  glOrtho (0, 1,0, 1, -1, 1);  //https://www.opengl.org/sdk/docs/man2/xhtml/gluOrtho2D.xml
  {$ENDIF}
  glMatrixMode(GL_MODELVIEW);//?
end;

{$IFNDEF DGL}  //gl does not link to the glu functions, so we will write our own
procedure gluPerspective (fovy, aspect, zNear, zFar: single);
//https://www.opengl.org/sdk/docs/man2/xhtml/gluPerspective.xml
var
  i, j : integer;
  f: single;
  m : array [0..3, 0..3] of single;
begin
   for i := 0 to 3 do
       for j := 0 to 3 do
           m[i,j] := 0;
   f :=  cot(degtorad(fovy)/2);
   m[0,0] := f/aspect;
   m[1,1] := f;
   m[2,2] := (zFar+zNear)/(zNear-zFar) ;
   m[3,2] := (2*zFar*zNear)/(zNear-zFar);
   m[2,3] := -1;
   //glLoadMatrixf(@m[0,0]);
   glMultMatrixf(@m[0,0]);
   //raise an exception if zNear = 0??
end;
{$ENDIF}

procedure resizeGL(w,h, zoom, zoomOffsetX, zoomOffsetY: integer);
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
  {$IFDEF DGL}
  if gPrefs.Perspective then
  {$ELSE}
  if false then
  {$ENDIF}
    gluPerspective(40.0, w/h, 0.01, kMaxDistance{Distance})
  else begin
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
     LoadShader('', gShader);
     gRayCast.glslprogram :=  initVertFrag(gShader.VertexProgram, gShader.FragmentProgram);
  end;
  getUniformLocations;
  // Create the to FBO's one for the backside of the volumecube and one for the finalimage rendering
  if InitialSetup then begin
    glGenFramebuffersEXT(1, @gRayCast.frameBuffer);
    glGenTextures(1, @gRayCast.backFaceBuffer);
    glGenTextures(1, @gRayCast.finalImage);
    glGenRenderbuffersEXT(1, @gRayCast.renderBuffer);
    gShader.Vendor:= gpuReport;
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

procedure clipMat;
var
  lMgl: array[0..15] of  GLfloat;
begin
 (* glGetFloatv(GL_TRANSPOSE_MODELVIEW_MATRIX, @lMgl);

     clipboard.AsText:= format('m=[%g %g %g %g; %g %g %g %g; %g %g %g %g; %g %g %g %g]',[
       m[0,0], m[0,1], m[0,2], m[0,3],
       m[1,0], m[1,1], m[1,2], m[1,3],
       m[2,0], m[2,1], m[2,2], m[2,3],
       m[3,0], m[3,1], m[3,2], m[3,3]]
       ); *)
end;

procedure rayCasting (var lTex: TTexture);
begin
          glUseProgram(gRayCast.glslprogram);
     //glUseProgram(gRayCast.glslprogramGradient);
     glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, gRayCast.finalImage, 0);
	glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
	//glEnable(GL_TEXTURE_2D);
        if gShader.SinglePass <> 1 then  begin
           glActiveTexture( GL_TEXTURE0 );
	   glBindTexture(GL_TEXTURE_2D, gRayCast.backFaceBuffer);
           glUniform1i( gRayCast.backFaceLoc, 0 );		// backFaceBuffer -> texture0
        end;

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
        glUniform1i( gRayCast.LoopsLoc,round(gRayCast.slices*2.2));
        if gRayCast.ScreenCapture then
            glUniform1f( gRayCast.stepSizeLoc, ComputeStepSize(10) )
        else
            glUniform1f( gRayCast.stepSizeLoc, ComputeStepSize(gPrefs.RayCastQuality1to10) );
        glUniform1f( gRayCast.sliceSizeLoc, 1/gRayCast.slices );
        glUniform1f( gRayCast.viewWidthLoc, gRayCast.WINDOW_WIDTH );
        glUniform1f( gRayCast.viewHeightLoc, gRayCast.WINDOW_HEIGHT );

        glUniform1i( gRayCast.gradientVolLoc, 1 );	// gradientTexture -> texture2
  {$IFDEF USETRANSFERTEXTURE}
  uniform1i( 'TransferTexture',2); //used when render volumes are scalar, not RGBA{$ENDIF}
  {$ENDIF}
    glUniform1i( gRayCast.intensityVolLoc, 3 );
    glUniform1i( gRayCast.overlayVolLoc, 4 );
    glUniform1i( gRayCast.overlayGradientVolLoc, 5 );
    glUniform1i( gRayCast.overlaysLoc, gOpenOverlays);
  AdjustShaders(gShader);
  LightUniforms;
  ClipUniforms;
  glUniform3f(gRayCast.clearColorLoc,gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255);
  glEnable(GL_CULL_FACE);
  glCullFace(GL_BACK);
  //glMatrixMode(GL_MODELVIEW);
  //glScalef(1,1,1);
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
  resizeGL(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT,zoom, zoomOffsetX, zoomOffsetY);
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
    if gShader.SinglePass <> 1 then
       renderBackFace(lTex)
    else begin
      glMatrixMode(GL_MODELVIEW);
      glScalef(lTex.Scale[1],lTex.Scale[2],lTex.Scale[3]);
      drawQuadX(1.0,1.0); //no idea why this is required!
    end;
    rayCasting(lTex);
    disableRenderBuffers();
    renderBufferToScreen();
    if gPrefs.SliceDetailsCubeAndText then
      drawCube(gRayCast.WINDOW_WIDTH*zoom, gRayCast.WINDOW_HEIGHT*zoom, zoomOffsetX, zoomOffsetY);
    resizeGL(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT,zoom, zoomOffsetX, zoomOffsetY);
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

procedure DisplayGL(var lTex: TTexture);
begin
  DisplayGLz(lTex,1,0,0);
end;


end.


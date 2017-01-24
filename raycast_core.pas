unit raycast_core;
{$include opts.inc}
{$IFDEF DGL}UNABLE TO COMPILE OPENGL CORE WITH DGL - edit opts.inc {$ENDIF}
{$IFDEF LCLCARBON}UNABLE TO COMPILE OPENGL CORE WITH CARBON - set widgetset to Cocoa {$ENDIF}
(*
 This unit enabled OpenGL Core 3.3 support, instead of the legacy OpenGL 2.1 support
 The basic rendering and glsl gradient computation works. No performance benefits observed relative to legacy
CORE still needs a lot of work:
 colorbar
 screenshots
 drawing !!!
*)
interface

uses
	gl, glext, define_types, raycast_common, gl_core_matrix, dialogs,
        texture_3d_unit, SysUtils,DateUtils,gl_2D, histogram2d, colorbar2d;
procedure DrawSliceGL();
procedure  InitGL (InitialSetup: boolean);
procedure DisplayGL(var lTex: TTexture);
//procedure DisplayGLz(var lTex: TTexture; zoom, zoomOffsetX, zoomOffsetY: integer);
procedure DisplayGLz(var lTex: TTexture; framebuffer: TGLuint);

implementation

uses
    shaderu, mainunit, clipbrd, slices2d; //swap

type
TCore = record
  vao, programBackface: GLuint;
  mvpLocBackface, mvpLoc, imvLoc: GLint;

end;

var
  gCore: TCore;
  gInit : boolean = false;

procedure DrawSliceGL();
begin

  glBindVertexArray(gCore.vao);
glDrawElements(GL_TRIANGLES, 2*3, GL_UNSIGNED_INT, nil);
end;

procedure performBlurSobel(var lTex: TTexture; lIsOverlay: boolean);
//http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-14-render-to-texture/
//http://www.opengl.org/wiki/Framebuffer_Object_Examples
var
   i: integer;
   coordZ: single; //dx
   fb, tempTex3D: GLuint;
begin
  glGenFramebuffers(1, @fb);
  glBindFramebuffer(GL_FRAMEBUFFER, fb);
  //glBindFramebufferEXT(GL_FRAMEBUFFER_EXT,gRayCast.frameBuffer);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);// <- REQUIRED
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
  //glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA8, lTex.FiltDim[1], lTex.FiltDim[2], 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
  glViewport(0, 0, lTex.FiltDim[1], lTex.FiltDim[2]);
  (*nglMatrixMode(nGL_PROJECTION);
  nglLoadIdentity();

  //nglOrtho (0, 1,0, 1, -1, 1);  //gluOrtho2D(0, 1, 0, 1);  https://www.opengl.org/sdk/docs/man2/xhtml/gluOrtho2D.xml
  nglMatrixMode(nGL_MODELVIEW);
  nglLoadIdentity(); *)




  glDisable(GL_TEXTURE_2D);
  glDisable(GL_BLEND);
  //glDisable(GL_TEXTURE_2D);
  //STEP 1: run smooth program gradientTexture -> tempTex3D
  //glEnable(GL_TEXTURE_2D); glEnable(GL_BLEND); exit;

  tempTex3D := bindBlankGL(lTex);

  //glUseProgramObjectARB(gRayCast.glslprogramBlur);
  glUseProgram(gRayCast.glslprogramBlur);
  glActiveTexture( GL_TEXTURE1);
  //glBindTexture(GL_TEXTURE_3D, gRayCast.gradientTexture3D);//input texture
  if lIsOverlay then
     glBindTexture(GL_TEXTURE_3D, gRayCast.intensityOverlay3D)//input texture is overlay
  else
      glBindTexture(GL_TEXTURE_3D, gRayCast.intensityTexture3D);//input texture is background
  glUniform1ix(gRayCast.glslprogramBlur, 'intensityVol', 1);
  glUniform1fx(gRayCast.glslprogramBlur, 'dX', 0.7/lTex.FiltDim[1]); //0.5 for smooth - center contributes
  glUniform1fx(gRayCast.glslprogramBlur, 'dY', 0.7/lTex.FiltDim[2]);
  glUniform1fx(gRayCast.glslprogramBlur, 'dZ', 0.7/lTex.FiltDim[3]);
  glBindVertexArray(gCore.vao);
  for i := 0 to (lTex.FiltDim[3]-1) do begin
      coordZ := 1/lTex.FiltDim[3] * (i + 0.5);
      glUniform1fx(gRayCast.glslprogramBlur, 'coordZ', coordZ);
      //glFramebufferTexture3D(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0, GL_TEXTURE_3D, tempTex3D, 0, i);//output texture
      //Ext required: Delphi compile on Winodws 32-bit XP with NVidia 8400M
      glFramebufferTexture3D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_3D, tempTex3D, 0, i);//output texture
      glClear(GL_DEPTH_BUFFER_BIT);  // clear depth bit (before render every layer)
      glDrawElements(GL_TRIANGLES, 2*3, GL_UNSIGNED_INT, nil);
  end;
  glUseProgram(0);
  //STEP 2: run sobel program gradientTexture -> tempTex3D
  //glUseProgramObjectARB(gRayCast.glslprogramSobel);
  glUseProgram(gRayCast.glslprogramSobel);
  glActiveTexture(GL_TEXTURE1);
  //x glBindTexture(GL_TEXTURE_3D, gRayCast.intensityTexture3D);//input texture
  glBindTexture(GL_TEXTURE_3D, tempTex3D);//input texture
    glUniform1ix(gRayCast.glslprogramSobel, 'intensityVol', 1);
    glUniform1fx(gRayCast.glslprogramSobel, 'dX', 1.2/lTex.FiltDim[1] ); //1.0 for SOBEL - center excluded
    glUniform1fx(gRayCast.glslprogramSobel, 'dY', 1.2/lTex.FiltDim[2]);
    glUniform1fx(gRayCast.glslprogramSobel, 'dZ', 1.2/lTex.FiltDim[3]);
    glBindVertexArray(gCore.vao);
    for i := 0 to (lTex.FiltDim[3]-1) do begin
        coordZ := 1/lTex.FiltDim[3] * (i + 0.5);
        glUniform1fx(gRayCast.glslprogramSobel, 'coordZ', coordZ);
        if lIsOverlay then
          glFramebufferTexture3D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_3D, gRayCast.gradientOverlay3D, 0, i)//output is overlay
        else
            glFramebufferTexture3D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_3D, gRayCast.gradientTexture3D, 0, i);//output is background
        glClear(GL_DEPTH_BUFFER_BIT);
        glDrawElements(GL_TRIANGLES, 2*3, GL_UNSIGNED_INT, nil);
    end;
    glUseProgram(0);
     //clean up:
     glDeleteTextures(1,@tempTex3D);
     glBindFramebuffer(GL_FRAMEBUFFER, 0);
     glDeleteFramebuffers(1, @fb);
     glActiveTexture( GL_TEXTURE0 );  //required if we will draw 2d slices next
end;

const kSmoothSobelVert = '#version 330 core'
+#10'layout(location = 0) in vec3 vPos;'
+#10'out vec2 TexCoord;'
+#10'void main() {'
+#10'    TexCoord = vPos.xy;'
+#10'    gl_Position = vec4( (vPos.xy-vec2(0.5,0.5))* 2.0, 0.0, 1.0);'
+#10'//    gl_Position = vec4( (vPos-vec3(0.5,0.5,0.5))* 2.0, 1.0);'
+#10'}';

const kSmoothFrag = '#version 330 core'
+#10'in vec2 TexCoord;'
+#10'out vec4 FragColor;'
+#10'uniform float coordZ, dX, dY, dZ;'
+#10'uniform sampler3D intensityVol;'
+#10'void main(void) {'
+#10' vec3 vx = vec3(TexCoord.xy, coordZ);'
+#10' vec4 samp = texture(intensityVol,vx+vec3(+dX,+dY,+dZ));'
+#10' samp += texture(intensityVol,vx+vec3(+dX,+dY,-dZ));'
+#10' samp += texture(intensityVol,vx+vec3(+dX,-dY,+dZ));'
+#10' samp += texture(intensityVol,vx+vec3(+dX,-dY,-dZ));'
+#10' samp += texture(intensityVol,vx+vec3(-dX,+dY,+dZ));'
+#10' samp += texture(intensityVol,vx+vec3(-dX,+dY,-dZ));'
+#10' samp += texture(intensityVol,vx+vec3(-dX,-dY,+dZ));'
+#10' samp += texture(intensityVol,vx+vec3(-dX,-dY,-dZ));'
+#10' FragColor = samp*0.125;'
+#10'}';

const kSobelFrag = '#version 330 core'
+#10'in vec2 TexCoord;'
+#10'out vec4 FragColor;'
+#10'uniform float coordZ, dX, dY, dZ;'
+#10'uniform sampler3D intensityVol;'
+#10'void main(void) {'
+#10'  vec3 vx = vec3(TexCoord.xy, coordZ);'
+#10'  float TAR = texture(intensityVol,vx+vec3(+dX,+dY,+dZ)).a;'
+#10'  float TAL = texture(intensityVol,vx+vec3(+dX,+dY,-dZ)).a;'
+#10'  float TPR = texture(intensityVol,vx+vec3(+dX,-dY,+dZ)).a;'
+#10'  float TPL = texture(intensityVol,vx+vec3(+dX,-dY,-dZ)).a;'
+#10'  float BAR = texture(intensityVol,vx+vec3(-dX,+dY,+dZ)).a;'
+#10'  float BAL = texture(intensityVol,vx+vec3(-dX,+dY,-dZ)).a;'
+#10'  float BPR = texture(intensityVol,vx+vec3(-dX,-dY,+dZ)).a;'
+#10'  float BPL = texture(intensityVol,vx+vec3(-dX,-dY,-dZ)).a;'
+#10'  vec4 gradientSample = vec4 (0.0, 0.0, 0.0, 0.0);'
+#10'  gradientSample.r =   BAR+BAL+BPR+BPL -TAR-TAL-TPR-TPL;'
+#10'  gradientSample.g =  TPR+TPL+BPR+BPL -TAR-TAL-BAR-BAL;'
+#10'  gradientSample.b =  TAL+TPL+BAL+BPL -TAR-TPR-BAR-BPR;'
+#10'  gradientSample.a = (abs(gradientSample.r)+abs(gradientSample.g)+abs(gradientSample.b))*0.29;'
+#10'  gradientSample.rgb = normalize(gradientSample.rgb);'
+#10'  gradientSample.rgb =  (gradientSample.rgb * 0.5)+0.5;'
+#10'  FragColor = gradientSample;'
+#10'}';


procedure doShaderBlurSobel (var lTex: TTexture);
var
   startTime: TDateTime;
begin
  if (not lTex.updateBackgroundGradientsGLSL) and (not lTex.updateOverlayGradientsGLSL) then exit;
  if (lTex.updateBackgroundGradientsGLSL) then begin
       startTime := Now;
       performBlurSobel(lTex, false);
       lTex.updateBackgroundGradientsGLSL := false;
       if gPrefs.Debug then
          GLForm1.Caption := 'GLSL gradients '+inttostr(MilliSecondsBetween(Now,startTime))+' ms ';
  end;
  if (lTex.updateOverlayGradientsGLSL) then begin
       performBlurSobel(lTex, true);
       lTex.updateOverlayGradientsGLSL := false;
  end;
end;

procedure  FrameBufferGL(InitialSetup: boolean);
begin
  // backFrameBuffer
  if not InitialSetup then begin
     glDeleteTextures(1,@gRaycast.backTexture);
     //glDeleteRenderbuffers(1, @gRayCast.backDepthBuffer);
     glDeleteFramebuffers(1, @gRayCast.backFaceBuffer );
  end;
  //gIsFrameBufferNew := false;
  glGenTextures(1, @gRaycast.backTexture);
  glGenFramebuffers(1, @gRayCast.backFaceBuffer );
  glBindTexture(GL_TEXTURE_2D, gRaycast.backTexture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); //GL_NEAREST
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);//GL_REPEAT
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
  //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT, 0, GL_RGBA, GL_FLOAT, nil);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT, 0, GL_RGBA, GL_FLOAT, nil);
  //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
  glBindFramebuffer(GL_FRAMEBUFFER, gRayCast.backFaceBuffer );
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, gRayCast.backTexture, 0);
  //glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, gRaycast.backDepthBuffer);
  //glEnable(GL_DEPTH_TEST);
end;

procedure LoadBufferData (var vao: gluint);
var
  vtx : packed array[0..23] of GLfloat = (
      0,0,0,
      0,1,0,
      1,1,0,
      1,0,0,
      0,0,1,
      0,1,1,
      1,1,1,
      1,0,1
      ); //vtx = 8 vertex positions (corners) of cube
  idx : packed array[0..35] of GLuint = (
      0,2,1,
      0,3,2,
      4,5,6,
      4,6,7,
      0,1,5,
      0,5,4,
      3,6,2,
      3,7,6,
      1,6,5,
      1,2,6,
      0,4,7,
      0,7,3
      ); //idx = each cube has 6 faces, each composed of two triangles = 12 tri indices
    vbo_point, vbo : gluint;
begin  //vboCube, vaoCube,
  vbo_point := 0;
  vbo := 0;
  vao := 0;
  glGenBuffers(1, @vbo_point);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_point);
  glBufferData(GL_ARRAY_BUFFER, 8*3*sizeof(GLfloat), @vtx[0], GL_STATIC_DRAW); //cube has 8 vertices, each 3 coordinates X,Y,Z
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glGenVertexArrays(1, @vao);
  // vao like a closure binding 3 buffer object: verlocdat vercoldat and veridxdat
  glBindVertexArray(vao);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_point);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), nil);
  glEnableVertexAttribArray(0); // for vertexloc
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), nil);
  glEnableVertexAttribArray(1); // for vertexcol
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glGenBuffers(1, @vbo);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, 36*sizeof(GLuint), @idx[0], GL_STATIC_DRAW); //cube is 6 faces, 2 triangles per face, 3 indices per triangle
  //do not delete the VBOs! http://stackoverflow.com/questions/25167562/how-to-dispose-vbos-stored-in-a-vao
  //glDeleteBuffers(1, @vbo);
  //glDeleteBuffers(1, @vbo_point);
end;

procedure resizeGL(w,h, zoom, zoomOffsetX, zoomOffsetY: integer);
var
   scale, whratio: single;
begin
  if (h = 0) then
     h := 1;
  //if zoom > 1 then
  //   glViewport(zoomOffsetX, zoomOffsetY, w*zoom, h*zoom)
  //else
  //    glViewport(0, 0, w, h);
  glViewport(zoomOffsetX, zoomOffsetY, w,h);
  nglMatrixMode(nGL_PROJECTION);
  nglLoadIdentity();
  if gPrefs.Perspective then
    ngluPerspective(40.0, w/h, 0.01, kMaxDistance{Distance})
  else begin
       if gRayCast.Distance = 0 then
        scale := 1
     else
         scale := 1/abs(kDefaultDistance/(gRayCast.Distance+1.0));
     whratio := w/h;
     nglOrtho(whratio*-0.5*scale,whratio*0.5*scale,-0.5*scale,0.5*scale, 0.01, kMaxDistance);
  end;
  FrameBufferGL(false);
end;

procedure rotateGL(var lTex: TTexture);
begin
  nglMatrixMode(nGL_MODELVIEW);
  nglLoadIdentity();
  nglTranslatef(0,0,-gRayCast.Distance);
  nglRotatef(90-gRayCast.Elevation,-1,0,0);
  nglRotatef(gRayCast.Azimuth,0,0,1);
  nglTranslatef(-lTex.Scale[1]/2,-lTex.Scale[2]/2,-lTex.Scale[3]/2);
  nglScalef(lTex.Scale[1],lTex.Scale[2],lTex.Scale[3]);
end;

procedure drawBox(isFront: boolean);
begin
  glViewport(0, 0, gRayCast.WINDOW_Width, gRayCast.WINDOW_HEIGHT);
  glClearColor(gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255, 0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glEnable(GL_CULL_FACE);
  if isFront then
    glCullFace(GL_FRONT)
  else
     glCullFace(GL_BACK);
  glBindVertexArray(gCore.vao);
  glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, nil);
  glDisable(GL_CULL_FACE);
  //glUseProgram(0);
end;

(*procedure clipMat(m : TnMat44);
begin
     clipboard.AsText:= format('m=[%g %g %g %g; %g %g %g %g; %g %g %g %g; %g %g %g %g]',[
       m[0,0], m[0,1], m[0,2], m[0,3],
       m[1,0], m[1,1], m[1,2], m[1,3],
       m[2,0], m[2,1], m[2,2], m[2,3],
       m[3,0], m[3,1], m[3,2], m[3,3]]
       );
end;*)

//procedure drawRender(var lTex: TTexture; zoom, zoomOffsetX, zoomOffsetY: integer);
procedure drawRender(var lTex: TTexture;  framebuffer : TGLuint);
var
  mat44 : TnMat44;
  i : integer;
begin
    rotateGL(lTex);
    mat44 := ngl_ModelViewProjectionMatrix;
    //glEnable(GL_DEPTH_TEST);
    //1st pass: to texture
    glUseProgram(gCore.programBackface);//mvpLocBackface
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, gRayCast.backFaceBuffer); //draw offscreen
    //glBindFramebuffer(GL_FRAMEBUFFER, 0); //draw to screen
    glUniformMatrix4fv(gCore.mvpLocBackface, 1, GL_FALSE, @mat44[0,0]);
    //glUniform1i(gCore.zoomLocBackface,zoom);
    //glUniform2i(gCore.zoomXYLocBackface, zoomOffsetX, zoomOffsetY);
    //gRayCast.WINDOW_WIDTH*zoom, gRayCast.WINDOW_HEIGHT*zoom, zoomOffsetX, zoomOffsetY
    //draw
    drawBox(false);
    //2nd pass: front
    glUseProgram(gRaycast.glslprogram);
    //XXXXXX
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer); //draw to screen
    //glBindFramebuffer(GL_FRAMEBUFFER, gRayCast.frameBuffer);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, gRayCast.backTexture);
    glUniform1i(gRayCast.backFaceLoc, 1);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_3D, gRayCast.intensityTexture3D);
    glUniform1i(gRayCast.intensityVolLoc, 2);
    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_3D, gRayCast.gradientTexture3D);
    glUniform1i(gRayCast.gradientVolLoc, 3);
    //glUniform1i(gCore.zoomLoc, zoom);
   //glUniform1i(gCore.zoomLoc,zoom);
    //glUniform2i(gCore.zoomXYLoc, zoomOffsetX, zoomOffsetY);
    glUniform1f(gRayCast.viewHeightLoc, gRaycast.WINDOW_HEIGHT);
    glUniform1f(gRayCast.viewWidthLoc, gRaycast.WINDOW_WIDTH);
    //glUniform1f(gRayCast.viewHeightLoc, gRaycast.WINDOW_HEIGHT);
    //glUniform1f(gRayCast.viewWidthLoc, gRaycast.WINDOW_WIDTH);
    //glUniform1f(gRayCast.viewWidthLoc, gRaycast.WINDOW_WIDTH);
    //glUniform1f(gRayCast.viewWidthLoc, gRaycast.WINDOW_WIDTH);
    if gRayCast.ScreenCapture then
       glUniform1f(gRayCast.stepSizeLoc, 10)
    else
        glUniform1f(gRayCast.stepSizeLoc, ComputeStepSize(gPrefs.RayCastQuality1to10)) ;
    glUniform1f(gRayCast.sliceSizeLoc, 1/gRayCast.slices);
    glUniform1i( gRayCast.loopsLoc,round(gRayCast.slices*2.2));
    glUniform3f(gRayCast.lightPositionLoc, 0.0,0.0,1.0);
    //next: overlays
    //uniform1i( 'overlays', gOpenOverlays);
    glUniform1i( gRayCast.overlaysLoc, gOpenOverlays);

    if  (gShader.OverlayVolume > 0) then begin
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_3D,gRayCast.intensityOverlay3D);
        //uniform1i( 'overlayVol', 4 );
        glUniform1i( gRayCast.overlayVolLoc, 4 );
        //GLForm1.caption :=  inttostr(gOpenOverlays)+' -> '+inttostr(gRayCast.intensityOverlay3D);
        if (gShader.OverlayVolume > 1) then begin
           glActiveTexture(GL_TEXTURE5);
           glBindTexture(GL_TEXTURE_3D,gRayCast.gradientOverlay3D);
           //uniform1i( 'overlayGradientVol', 5 );
           glUniform1i( gRayCast.overlayGradientVolLoc, 5 );

        end;
    end;

    LightUniforms;  //TODO: light position not correct : inverseModelView correct?
    ClipUniforms;


    AdjustShaders(gShader);

    glUniform3f(gRayCast.clearColorLoc,gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255);
    glUniformMatrix4fv(gCore.mvpLoc, 1, GL_FALSE, @mat44[0,0]);
    mat44 := inverseMat(ngl_ModelViewMatrix);
    //mat44 := transposeMat(ngl_ModelViewMatrix);
    //mat44 := inverseMat(ngl_ModelViewProjectionMatrix);
    //mat44 := (ngl_ModelViewMatrix);

    //mat44 := transposeMat(mat44);
    //clipMat(mat44);
    glUniformMatrix4fv(gCore.imvLoc, 1, GL_FALSE, @mat44[0,0]);

    i := glGetUniformLocation(gRaycast.glslprogram, pAnsiChar('modelViewMatrix'));
    mat44 := (ngl_ModelViewMatrix);
    glUniformMatrix4fv(i, 1, GL_FALSE, @mat44[0,0]);
    drawBox(true);

    if gPrefs.SliceDetailsCubeAndText then
      drawCube(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT, gRaycast.Azimuth, gRaycast.Elevation);
    glUseProgram(0);
end;

//procedure DisplayGLz(var lTex: TTexture; zoom, zoomOffsetX, zoomOffsetY: integer);
procedure DisplayGLz(var lTex: TTexture;  framebuffer : TGLuint);
begin
  if not gInit then exit;
  if (gPrefs.SliceView  <> 5) then  gRayCast.MosaicString := '';
  doShaderBlurSobel(lTex);
  glClearColor(gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255, 0);
  //resizeGL(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT,zoom, zoomOffsetX, zoomOffsetY);
  resizeGL(gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_HEIGHT,1, 0, 0);
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
  glDisable(GL_CULL_FACE); //<-this is important, otherwise nodes and quads not filled
  if length(gRayCast.MosaicString)> 0 then begin //draw mosaics
     MosaicGL(gRayCast.MosaicString);
  end else if gPrefs.SliceView > 0  then begin //draw 2D orthogonal slices
    DrawOrtho(lTex);
  end else //else draw 3D rendering
      drawRender(lTex, framebuffer);//zoom, zoomOffsetX, zoomOffsetY);
  if gPrefs.ColorEditor then
     DrawNodes(gRayCast.WINDOW_HEIGHT,gRayCast.WINDOW_WIDTH, lTex, gPrefs);
  if gPrefs.Colorbar then
     DrawCLUT( gPrefs.ColorBarPos,0.01, gPrefs);//, gRayCast.WINDOW_WIDTH*zoom, gRayCast.WINDOW_HEIGHT*zoom, zoomOffsetX, zoomOffsetY);

  glFlush;//<-this would pause until all jobs are SUBMITTED
  //
  //GLForm1.GLbox.SwapBuffers;
end;

procedure DisplayGL(var lTex: TTexture);
begin
  DisplayGLz(lTex,0);
  //DisplayGLz(lTex,1,0,0);
  //disableRenderBuffers;
end;

(*const kVertBackface = '#version 330 core'
+#10'layout(location = 0) in vec3 vPos;'
+#10'out vec3 TexCoord1;'
+#10'uniform mat4 modelViewProjectionMatrix;'
+#10'void main() {'
+#10'    TexCoord1 = vPos;'
+#10'    gl_Position = modelViewProjectionMatrix * vec4(vPos, 1.0);'
+#10'}';  *)
         //zoomLoc
const kVert = '#version 330 core'
+#10'layout(location = 0) in vec3 vPos;'
+#10'out vec3 TexCoord1;'
+#10'uniform int zoom = 1;'
+#10'uniform mat4 modelViewProjectionMatrix;'
+#10'void main() {'
+#10'    TexCoord1 = vPos;'
+#10'    gl_Position = modelViewProjectionMatrix * vec4(vPos, 1.0);'
+#10'    gl_Position.xy *= zoom;'
+#10'}';

const kFragBackface = '#version 330 core'
+#10'in vec3 TexCoord1;'
+#10'out vec4 FragColor;'
+#10'void main() {'
+#10'    FragColor = vec4(TexCoord1, 1.0);'
+#10'}';

procedure  InitGL (InitialSetup: boolean);
begin
  if InitialSetup then begin
     if (not  Load_GL_version_3_3_CORE) then begin //requires new glext.pp in path with core supprt
        showmessage('System does not support OpenGL 3.3');
        halt;
     end;
     gCore.vao:= 0;
     LoadBufferData(gCore.vao);
     gShader.Vendor:= gpuReport;
     gShader.vao_point2d := 0;
     gShader.vbo_face2d := 0;

     gShader.program2d:= initVertFrag(kVert2D, kFrag2D)  ;

     gRayCast.glslprogramBlur := initVertFrag(kSmoothSobelVert,kSmoothFrag); //initFragShader (kSmoothShaderFrag,gRayCast.glslprogramBlur);
     gRayCast.glslprogramSobel := initVertFrag(kSmoothSobelVert,kSobelFrag);

     gCore.programBackface :=  initVertFrag(kVert,  kFragBackface);
     gCore.mvpLocBackface := glGetUniformLocation(gCore.programBackface, pAnsiChar('modelViewProjectionMatrix'));
     //gCore.zoomLocBackface := glGetUniformLocation(gCore.programBackface, pAnsiChar('zoom'));
     //gCore.zoomXYLocBackface := glGetUniformLocation(gCore.programBackface, pAnsiChar('zoomXY'));

     //glGenFramebuffers(1, @gRayCast.frameBuffer);
     //glGenRenderbuffers(1, @gRayCast.renderBuffer);
  end;


  //gCore.imvLoc := glGetUniformLocation(gCore.programBackface, pAnsiChar('ModelViewMatrixInverse'));

  //zoomXYLocBackface

  //glUseProgram(0);
  //setup main rendering
  //gRaycast.glslprogram :=  initVertFrag(kVert,  kFrag);
  gRayCast.glslprogram :=  initVertFrag(gShader.VertexProgram, gShader.FragmentProgram);
  if (gRayCast.glslprogram = 0) then begin //error: load default shader
     LoadShader('', gShader);
     gRayCast.glslprogram :=  initVertFrag(gShader.VertexProgram, gShader.FragmentProgram);
  end;
  getUniformLocations;
  gCore.imvLoc := glGetUniformLocation(gRaycast.glslprogram, pAnsiChar('modelViewMatrixInverse'));
  gCore.mvpLoc := glGetUniformLocation(gRaycast.glslprogram, pAnsiChar('modelViewProjectionMatrix'));
  gInit := true;
  //setup cube used for both front and backface
  //setup screen
  //resizeGL(GLBox.ClientWidth, GLBox.ClientHeight);
  //load texture
  //Load3DTextures (FileName : AnsiString; var  gradientVolume, intensityVolume  : GLuint; var isRGBA: integer; var ScaleDim: TScale; loadGradients: boolean): boolean;// Load 3D image                                                                 }
  //Load3DTextures('/Users/rorden/Desktop/aa.nii', gRayCast.gradientTexture3D, gRayCast.intensityTexture3D, isRGBA, gRayCast.ScaleDim, true);
  //Load3DTextures('', gRayCast.gradientTexture3D, gRayCast.intensityTexture3D, isRGBA, gRayCast.ScaleDim, true);

  //gRayCast.slices := 256;//SET!! gRayCast.slices := round(FloatMaxVal(gTexture3D.FiltDim[1], gTexture3D.FiltDim[2],gTexture3D.FiltDim[3]) );
  //FrameBufferGL;

  //rotateGL;
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
  //renderBuffer := 0;
  //frameBuffer := 0;
  backFaceBuffer := 0;
end;//set gRayCast defaults

end.


unit gl_2d;

{$mode objfpc}{$H+}

interface
{$Include opts.inc}
uses
{$IFDEF DGL} dglOpenGL, {$ELSE DGL} {$IFDEF COREGL}gl_core_matrix, glcorearb, {$ELSE} gl, {$ENDIF}  {$ENDIF DGL}
   //colorTable,
    //matmath,
    raycast_common,
    define_types, prefs,
  Classes, SysUtils, math;


{$IFDEF COREGL}
const kVert2D ='#version 330'
+#10'layout(location = 0) in vec3 Vert;'
+#10'layout(location = 3) in vec4 Clr;'
+#10'out vec4 vClr;'
+#10'uniform mat4 ModelViewProjectionMatrix;'
+#10'void main() {'
+#10'    gl_Position = ModelViewProjectionMatrix * vec4(Vert, 1.0);'
+#10'    vClr = Clr;'
+#10'}';
    const kFrag2D = '#version 330'
+#10'in vec4 vClr;'
+#10'out vec4 color;'
+#10'void main() {'
+#10'    color = vClr;'
+#10'}';


 {$ELSE}
    const kVert2D ='varying vec4 vClr;'
    +#10'void main() {'
    +#10'    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;'
    +#10'    vClr = gl_Color;'
    +#10'}';
        const kFrag2D = 'varying vec4 vClr;'
    +#10'void main() {'
    +#10'    gl_FragColor = vClr;'
    +#10'}';

{$ENDIF}
          procedure ReDraw2D; //use pre-calculated drawing
procedure StartDraw2D;
procedure EndDraw2D;
procedure nglBegin(mode: integer);
procedure nglEnd;
procedure nglColor4f(r,g,b,a: single);
procedure nglColor4ub (r,g,b,a: byte);
procedure nglVertex3f(x,y,z: single);
procedure nglVertex2f(x,y: single);

//procedure Set2DDraw (w,h: integer; r,g,b: byte);
//procedure DrawCLUTtrk ( lU: TUnitRect; lBorder, lMin, lMax: single; var lPrefs: TPrefs; LUT: TLUT;window_width, window_height: integer );
procedure TextArrow (X,Y,Sz: single; NumStr: string; orient: integer; FontColor,ArrowColor: TGLRGBQuad);
procedure DrawCube (lScrnWid, lScrnHt, lAzimuth, lElevation: integer);
//procedure DrawCLUT ( lU: TUnitRect; lBorder: single; var lPrefs: TPrefs; lMesh: TMesh; window_width, window_height: integer );
//procedure DrawText (var lPrefs: TPrefs; lScrnWid, lScrnHt: integer);

implementation

uses //{$IFDEF COREGL} raycast_core, {$ENDIF}
    shaderu, mainunit;
const

  kVert : array [1..50] of tpoint = (
   (X:0;Y:0),(X:0;Y:4),(X:0;Y:8),(X:0;Y:12),(X:0;Y:13),
(X:0;Y:14),(X:0;Y:15),(X:0;Y:16),(X:0;Y:17),(X:0;Y:18),
(X:0;Y:22),(X:0;Y:24),(X:0;Y:28),(X:2;Y:14),(X:4;Y:0),
(X:4;Y:4),(X:4;Y:8),(X:4;Y:11),(X:4;Y:12),(X:4;Y:13),
(X:4;Y:15),(X:4;Y:16),(X:4;Y:17),(X:4;Y:22),(X:4;Y:24),
(X:4;Y:28),(X:8;Y:0),(X:8;Y:14),(X:8;Y:18),(X:8;Y:24),
(X:14;Y:0),(X:14;Y:4),(X:14;Y:12),(X:14;Y:13),(X:14;Y:16),
(X:14;Y:17),(X:14;Y:22),(X:14;Y:24),(X:14;Y:28),(X:16;Y:14),
(X:18;Y:0),(X:18;Y:4),(X:18;Y:11),(X:18;Y:12),(X:18;Y:13),
(X:18;Y:15),(X:18;Y:16),(X:18;Y:22),(X:18;Y:24),(X:18;Y:28)
);

 kStripRaw : array [0..11,1..28] of byte = (
    (16, 12, 2, 25, 15, 16, 31, 32, 42, 38, 49, 39, 25, 26, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (15, 25, 27, 30, 26, 25, 13, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (42, 41, 16, 1, 22, 4, 22, 47, 4, 33, 47, 39, 49, 26, 25, 12, 24, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (16, 3, 2, 17, 15, 16, 31, 32, 42, 33, 44, 40, 19, 22, 35, 33, 47, 39, 49, 26, 25, 12, 24, 11, 0, 0, 0, 0 ),
    (13, 26, 7, 21, 18, 46, 43, 50, 41, 39, 31, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (49, 50, 25, 13, 20, 9, 20, 45, 9, 36, 45, 31, 42, 15, 16, 2, 17, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (38, 48, 49, 37, 39, 38, 26, 25, 12, 23, 9, 5, 36, 34, 20, 23, 5, 15, 2, 31, 32, 42, 33, 44, 35, 0, 0, 0 ),
    (11, 13, 24, 25, 13, 50, 25, 49, 38, 27, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (16, 4, 2, 19, 15, 16, 31, 32, 42, 33, 44, 40, 19, 22, 35, 33, 47, 39, 49, 26, 25, 12, 22, 8, 14, 22, 19, 4 ),
    (16, 3, 2, 17, 15, 16, 31, 32, 42, 33, 44, 47, 19, 22, 35, 33, 47, 39, 49, 26, 25, 12, 22, 8, 19, 0, 0, 0 ),
    (1, 15, 2, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (6, 10, 28, 29, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    );
 kStripLocal : array [0..11,1..28] of byte = (
 (1, 2, 3, 4, 5, 1, 6, 7, 8, 9, 10, 11, 4, 12, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
   (1, 2, 3, 4, 5, 2, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (1, 2, 3, 4, 5, 6, 5, 7, 6, 8, 7, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (1, 2, 3, 4, 5, 1, 6, 7, 8, 9, 10, 11, 12, 13, 14, 9, 15, 16, 17, 18, 19, 20, 21, 22, 0, 0, 0, 0 ),
    (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (1, 2, 3, 4, 5, 6, 5, 7, 6, 8, 7, 9, 10, 11, 12, 13, 14, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (1, 2, 3, 4, 5, 1, 6, 7, 8, 9, 10, 11, 12, 13, 14, 9, 11, 15, 16, 17, 18, 19, 20, 21, 22, 0, 0, 0 ),
    (1, 2, 3, 4, 2, 5, 4, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (1, 2, 3, 4, 5, 1, 6, 7, 8, 9, 10, 11, 4, 12, 13, 9, 14, 15, 16, 17, 18, 19, 12, 20, 21, 12, 4, 2 ),
    (1, 2, 3, 4, 5, 1, 6, 7, 8, 9, 10, 11, 12, 13, 14, 9, 11, 15, 16, 17, 18, 19, 13, 20, 12, 0, 0, 0 ),
    (1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ),
    (1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 )
    );
 kStripCount : array [0..11] of byte = (15, 8, 18, 24, 11, 18, 25, 11, 28, 25, 4, 4 );
 kStripWid : array [0..11] of byte = (9, 5, 9, 9, 9, 9, 9, 9, 9, 9, 2, 4 );

  (*procedure Enter2D(lPrefs: TPrefs);
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, lPrefs.window_width, 0, lPrefs.window_height,-1,1);//<- same effect as previous line
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glDisable(GL_DEPTH_TEST);
end;*)
{$IFDEF COREGL}
type

TVtxClr = Packed Record
  vtx   : TPoint3f; //vertex coordinates
  clr : TRGBA;
end;

var
    g2Dvnc: array of TVtxClr;
    g2Drgba : TRGBA;
    g2DNew: boolean;

procedure nglPushMatrix;
begin
 //
end;

procedure nglPopMatrix;
begin
     //
end;

procedure nglColor4f(r,g,b,a: single);
begin
  g2Drgba.R := round(r * 255);
  g2Drgba.G := round(g * 255);
  g2Drgba.B := round(b * 255);
  g2Drgba.A := round(a * 255);
end;

procedure nglColor4ub (r,g,b,a: byte);
begin
  g2Drgba.R := round(r );
  g2Drgba.G := round(g );
  g2Drgba.B := round(b );
  g2Drgba.A := round(a );
end;

procedure nglVertex3f(x,y,z: single);
begin
     setlength(g2Dvnc, length(g2Dvnc)+1);
     g2Dvnc[high(g2Dvnc)].vtx.X := x;
     g2Dvnc[high(g2Dvnc)].vtx.Y := y;
     g2Dvnc[high(g2Dvnc)].vtx.Z := z;
     g2Dvnc[high(g2Dvnc)].clr := g2Drgba;
     if not g2DNew then exit;
     g2DNew := false;
     setlength(g2Dvnc, length(g2Dvnc)+1);
     g2Dvnc[high(g2Dvnc)] := g2Dvnc[high(g2Dvnc)-1];
end;


procedure nglVertex2f(x,y: single);
begin
     nglVertex3f(x,y,0);
end;

procedure nglBegin(mode: integer);
begin
     g2DNew := true;
end;

procedure nglEnd;
begin
     //add tail
     if length(g2Dvnc) < 1 then exit;
     setlength(g2Dvnc, length(g2Dvnc)+1);
     g2Dvnc[high(g2Dvnc)] := g2Dvnc[high(g2Dvnc)-1];
end;

procedure DrawTextCore (lScrnWid, lScrnHt: integer);
begin
  nglMatrixMode(nGL_MODELVIEW);
  nglLoadIdentity;
  nglMatrixMode (nGL_PROJECTION);
  nglLoadIdentity ();
  nglOrtho (0, lScrnWid,0, lScrnHt,-10,10);
end;

procedure ReDraw2D; //use pre-calculated drawing
var
  mv : TnMat44;
  mvpMat: GLint;
begin
  if gShader.nface < 1 then exit;
  glUseProgram(gShader.program2d);
  mv := ngl_ModelViewProjectionMatrix;
  mvpMat := glGetUniformLocation(gShader.program2d, pAnsiChar('ModelViewProjectionMatrix'));
  glUniformMatrix4fv(mvpMat, 1, GL_FALSE, @mv[0,0]);
  glBindVertexArray(gShader.vao_point2d);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,gShader.vbo_face2d);
  glDrawElements(GL_TRIANGLE_STRIP, gShader.nface, GL_UNSIGNED_INT, nil);
  glBindVertexArray(0);
end;

procedure DrawStrips (lScrnWid, lScrnHt: integer);
const
    kATTRIB_VERT = 0;  //vertex XYZ are positions 0,1,2
    kATTRIB_CLR = 3;   //color RGBA are positions 3,4,5,6
var
  i,nface: integer;
  faces: TInts;
   vbo_point : GLuint;
  mv : TnMat44;
  mvpMat: GLint;
begin
  //setup 2D
    if Length(g2Dvnc) < 1 then exit;
  glUseProgram(gShader.program2d);
  if gShader.vao_point2d <> 0 then
     glDeleteVertexArrays(1,@gShader.vao_point2d);
  glGenVertexArrays(1, @gShader.vao_point2d);
  if (gShader.vbo_face2d <> 0) then
     glDeleteBuffers(1, @gShader.vbo_face2d);
  glGenBuffers(1, @gShader.vbo_face2d);
  vbo_point := 0;
  glGenBuffers(1, @vbo_point);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_point);
  glBufferData(GL_ARRAY_BUFFER, Length(g2Dvnc)*SizeOf(TVtxClr), @g2Dvnc[0], GL_STATIC_DRAW);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  // Prepare vertrex array object (VAO)
  glBindVertexArray(gShader.vao_point2d);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_point);
  //Vertices
  glVertexAttribPointer(kATTRIB_VERT, 3, GL_FLOAT, GL_FALSE, sizeof(TVtxClr), PChar(0));
  glEnableVertexAttribArray(kATTRIB_VERT);
  //Color
  glVertexAttribPointer(kATTRIB_CLR, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(TVtxClr), PChar( sizeof(TPoint3f)));
  glEnableVertexAttribArray(kATTRIB_CLR);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
  glDeleteBuffers(1, @vbo_point);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gShader.vbo_face2d);
  nface := Length(g2Dvnc); //each face has 3 vertices
  setlength(faces,nface);
  if nface > 0 then begin
     for i := 0 to (nface-1) do begin
         faces[i] := i;
         glBufferData(GL_ELEMENT_ARRAY_BUFFER, nface*sizeof(uint32), @faces[0], GL_STATIC_DRAW);
     end;
  end;
  mv := ngl_ModelViewProjectionMatrix;
  mvpMat := glGetUniformLocation(gShader.program2d, pAnsiChar('ModelViewProjectionMatrix'));
  glUniformMatrix4fv(mvpMat, 1, GL_FALSE, @mv[0,0]);
  glBindVertexArray(gShader.vao_point2d);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gShader.vbo_face2d);
  glDrawElements(GL_TRIANGLE_STRIP, nface, GL_UNSIGNED_INT, nil); //slow!!! we need to copy VBO with each call
  gShader.nface := nface;
  //GLForm1.ShaderMemo.Lines.Add(inttostr(nface));
end;

procedure Enter2D(w, h: integer);
begin
  glUseProgram(gShader.program2d);
  glDisable(GL_DEPTH_TEST);
end;

procedure Set2DDraw (w,h: integer; r,g,b: byte);
begin
  glDepthMask(GL_TRUE); // enable writes to Z-buffer
  glEnable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE); // glEnable(GL_CULL_FACE); //check on pyramid
  glEnable(GL_BLEND);
  {$IFNDEF COREGL}glEnable(GL_NORMALIZE);{$ENDIF}
  glClearColor(r/255, g/255, b/255, 0.0); //Set background
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
  glViewport( 0, 0, w, h); //required when bitmap zoom <> 1
end;


{$ELSE}

procedure Set2DDraw (w,h: integer; r,g,b: byte);
begin
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
glOrtho (0, 1, 0, 1, -6, 12);
glMatrixMode (GL_MODELVIEW);
glLoadIdentity ();
{$IFDEF DGL}
glDepthMask(BYTEBOOL(1)); // enable writes to Z-buffer
{$ELSE}
glDepthMask(GL_TRUE); // enable writes to Z-buffer
{$ENDIF}

glEnable(GL_DEPTH_TEST);
glDisable(GL_CULL_FACE); // glEnable(GL_CULL_FACE); //check on pyramid
glEnable(GL_BLEND);
glEnable(GL_NORMALIZE);
glClearColor(r/255, g/255, b/255, 0.0); //Set background
glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
glViewport( 0, 0, w, h); //required when bitmap zoom <> 1
end;


procedure Enter2D(w, h: integer);
begin
  glUseProgram(gShader.program2d);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, w, 0, h,-1,1);//<- same effect as previous line
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glDisable(GL_DEPTH_TEST);
end;

procedure nglColor4f(r,g,b,a: single);
begin
  glColor4f(r,g,b,a);
end;

procedure nglColor4ub (r,g,b,a: byte);
begin
  glColor4ub (r,g,b,a);
end;

procedure nglVertex3f(x,y,z: single);
begin
     glVertex3f(x,y,z);
end;

procedure nglVertex2f(x,y: single);
begin
     glVertex2f(x,y);
end;

procedure nglBegin(mode: integer);
begin
     glBegin(mode);
end;

procedure nglEnd;
begin
     glEnd();
end;

{$ENDIF}


function PrintHt (Sz: single): single;
begin
  result := Sz * 14;//14-pixel tall font
end;

function Char2Int (c: char): integer;
begin
    result := ord(c)-48;//ascii '0'..'9' = 48..58
    if result = -3 then result := 11; // '-' minus;
    if (result < 0) or (result > 11) then result := 10; //'.'or''
end;

function PrintWid (Sz: single; NumStr: string): single;
var
  i: integer;
begin
  result := 0;
  if length(NumStr) < 1 then
    exit;
  for i := 1 to length(NUmStr) do begin
    result := result + kStripWid[Char2Int(NumStr[i])  ] + 1;  ;
  end;
  if result < 1 then
    exit;
  result := result -1;//fence post: no gap after last gap between character
  result := result * sz;
end;

procedure MakeCube(sz: single);
//draw a cube of size sz
var
  sz2: single;
begin
  sz2 := sz;
  nglColor4f(0.1,0.1,0.1,1);
  nglBegin(GL_TRIANGLE_STRIP); //* Bottom side
	nglVertex3f(-sz, -sz, -sz2);
	nglVertex3f(-sz, sz, -sz2);
	nglVertex3f(sz, -sz, -sz2);
        nglVertex3f(sz, sz, -sz2);
  nglEnd;
  nglColor4f(0.8,0.8,0.8,1);
  nglBegin(GL_TRIANGLE_STRIP); //* Top side
	nglVertex3f(-sz, -sz, sz2);
	nglVertex3f(sz, -sz, sz2);
        nglVertex3f(-sz, sz, sz2);
        nglVertex3f(sz, sz, sz2);
  nglEnd;
  nglColor4f(0,0,0.5,1);
  nglBegin(GL_TRIANGLE_STRIP); //* Front side
    nglVertex3f(-sz, sz2, -sz);
    nglVertex3f(-sz, sz2, sz);
    nglVertex3f(sz, sz2, -sz);
    nglVertex3f(sz, sz2, sz);
  nglEnd;
  nglColor4f(0.3,0,0.3,1);
  nglBegin(GL_TRIANGLE_STRIP);//* Back side
	nglVertex3f(-sz, -sz2, -sz);
	nglVertex3f(sz, -sz2, -sz);
	nglVertex3f(-sz, -sz2, sz);
	nglVertex3f(sz, -sz2, sz);
  nglEnd;
  nglColor4f(0.6,0,0,1);
  nglBegin(GL_TRIANGLE_STRIP); //* Left side
	nglVertex3f(-sz2, -sz, -sz);
	nglVertex3f(-sz2, -sz, sz);
	nglVertex3f(-sz2, sz, -sz);
	nglVertex3f(-sz2, sz, sz);
  nglEnd;
  nglColor4f(0,0.6,0,1);
  nglBegin(GL_TRIANGLE_STRIP); //* Right side
	//glNormal3f(1.0, -sz, -sz);
	nglVertex3f(sz2, -sz, -sz);
	nglVertex3f(sz2, sz, -sz);
	nglVertex3f(sz2, -sz, sz);
	nglVertex3f(sz2, sz, sz);
  nglEnd();
end; //MakeCube()

procedure DrawCubeCore (lScrnWid, lScrnHt, lAzimuth, lElevation: integer);
var
{$IFDEF COREGL}
  mvp: TnMat44;
{$ENDIF}
  sz: single;
begin

  sz := lScrnWid;
  if  sz > lScrnHt then sz := lScrnHt;
  if sz < 10 then exit;
  sz := sz * 0.03;
  {$IFDEF COREGL}
  glUseProgram(gShader.program2d); //666
  nglMatrixMode(nGL_MODELVIEW);
  nglLoadIdentity;
  //glDisable(GL_DEPTH_TEST);
  nglMatrixMode (nGL_PROJECTION);
  nglLoadIdentity ();
  nglOrtho (0, lScrnWid,0, lScrnHt,-10*sz,10*sz);
  glEnable(GL_DEPTH_TEST);
  //glDisable (GL_LIGHTING);
  //glDisable (GL_BLEND);
  nglTranslatef(0,0,sz*8);
  nglTranslatef(1.8*sz,1.8*sz,0);
  //nglRotatef(90-lElevation,-1,0,0);
  //nglRotatef(-lAzimuth,0,0,1);
  nglRotatef(90-lElevation,-1,0,0);
  //nglRotatef(-lAzimuth,0,0,1);
  nglRotatef(lAzimuth,0,0,1);
  //nglTranslatef(0,0,-30);

  //mvp := ngl_ModelViewProjectionMatrix;
  //glUniformMatrix4fv(glGetUniformLocation(gShader.program2d, pAnsiChar('ModelViewProjectionMatrix')), 1, GL_FALSE, @mvp[0,0]);
  {$ELSE}
  //Enter2D(lScrnWid, lScrnHt);


  glUseProgram(gShader.program2d);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, lScrnWid, 0, lScrnHt,-sz*4,0.01);//<- same effect as previous line
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  (*glUseProgram(gShader.program2d);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  //glDisable(GL_DEPTH_TEST);
  glMatrixMode (GL_PROJECTION);
  glLoadIdentity ();
  glOrtho (0, lScrnWid,0, lScrnHt,-10*sz,10*sz); *)
  glEnable(GL_DEPTH_TEST);
  //glDisable (GL_LIGHTING);
  //glDisable (GL_BLEND);
  glTranslatef(0,0,sz*2);
  //glTranslatef(0,0,0.5);

  glTranslatef(1.8*sz,1.8*sz,0);
  glRotatef(90-lElevation,-1,0,0);
  glRotatef(-lAzimuth,0,0,1);
  {$ENDIF}
  MakeCube(sz);
end;


procedure PrintXY (Xin,Y,Sz: single; NumStr: string;FontColor: TGLRGBQuad);
//draws numerical strong with 18-pixel tall characters. If Sz=2.0 then characters are 36-pixel tall
//Unless you use multisampling, fractional sizes will not look good...
var
  i, j, k: integer;
  X, Sc: single;
begin
  if length(NumStr) < 1 then
    exit;
  Sc := Sz * 0.5;
  X := Xin;
  nglColor4ub (FontColor.rgbRed, FontColor.rgbGreen, FontColor.rgbBlue,FontColor.rgbReserved);
  for i := 1 to length(NUmStr) do begin
    j := Char2Int(NumStr[i]);
    nglBegin(GL_TRIANGLE_STRIP);
    for k := 1 to kStripCount[j] do
        nglVertex2f(Sc*kVert[kStripRaw[j,k]].X + X, Sc*kVert[kStripRaw[j,k]].Y +Y);
    nglEnd;
    X := X + ((kStripWid[j] + 1)* Sz);
  end;
end;

procedure TextArrow (X,Y,Sz: single; NumStr: string; orient: integer; FontColor,ArrowColor: TGLRGBQuad);
//orient code 1=left,2=top,3=right,4=bottom
const
 kZ = -0.1; //put border BEHIND text
var
  lW,lH,lW2,lH2,T: single;
begin
  //glForm1.Caption := format('%g %g %g', [X, Y, Sz]);
  if NumStr = '' then exit;
  //glLoadIdentity();
  lH := PrintHt(Sz);
  lH2 := (lH/2);
  lW := PrintWid(Sz,NumStr);
  lW2 := (lW/2);
  nglColor4ub (ArrowColor.rgbRed, ArrowColor.rgbGreen, ArrowColor.rgbBlue,ArrowColor.rgbReserved);
  case Orient of
    1: begin
      nglBegin(GL_TRIANGLE_STRIP);
        nglVertex3f(X-lH2-lW-3*Sz,Y+LH2+Sz, kZ);
        nglVertex3f(X-lH2-lW-3*Sz,Y-lH2-Sz, kZ);
        nglVertex3f(X-lH2,Y+lH2+Sz, kZ);
        nglVertex3f(X-lH2,Y-lH2-Sz, kZ);
        nglVertex3f(X,Y, kZ);
      nglEnd;
      PrintXY (X-lW-lH2-1.5*Sz,Y-lH2,Sz, NumStr,FontColor);
    end;
    3: begin
      nglBegin(GL_TRIANGLE_STRIP);
        nglVertex3f(X+lH2+lW+2*Sz,Y+LH2+Sz, kZ);
        nglVertex3f(X+lH2+lW+2*Sz,Y-lH2-Sz, kZ);
        nglVertex3f(X+lH2-Sz,Y+lH2+Sz, kZ);
        nglVertex3f(X+lH2-Sz,Y-lH2-Sz, kZ);
        nglVertex3f(X,Y, kZ);
      nglEnd;
      PrintXY (X+lH2,Y-lH2,Sz, NumStr,FontColor);
    end;
    4: begin //bottom
    nglBegin(GL_TRIANGLE_STRIP);
      nglVertex3f(X-lW2-2*Sz,Y-LH-lH2-2*Sz, kZ);//-
      nglVertex3f(X-lW2-2*Sz,Y-lH2, kZ);
      nglVertex3f(X+lW2+Sz,Y-LH-lH2-2*Sz, kZ);//-
      nglVertex3f(X+lW2+Sz,Y-lH2, kZ);
      nglVertex3f(X-lW2-Sz,Y-lH2, kZ);
      nglVertex3f(X,Y, kZ);
    nglEnd;
    PrintXY (X-lW2-Sz,Y-lH-LH2,Sz, NumStr,FontColor);
    end;
    else  begin
      if Orient = 5 then
        T := Y-LH-Sz-lH2
      else
        T := Y;
    nglBegin(GL_TRIANGLE_STRIP);
      nglVertex3f(X-lW2-2*Sz,T+LH+2*Sz+lH2, kZ);
      nglVertex3f(X-lW2-2*Sz,T+lH2, kZ);
      nglVertex3f(X+lW2+Sz,T+LH+2*Sz+lH2, kZ);
      nglVertex3f(X+lW2+Sz,T+lH2, kZ);
      nglVertex3f(X-lW2-Sz,T+lH2, kZ);
      nglVertex3f(X,T, kZ);
    nglEnd;
    PrintXY (X-lW2-Sz,T+lH2+Sz,Sz, NumStr,FontColor);
    end;
  end;//case
end;

procedure SetOrder (l1,l2: single; var lSmall,lLarge: single);
//set lSmall to be the lesser of l1/l2 and lLarge the greater value of L1/L2
begin
  if l1 < l2 then begin
    lSmall := l1;
    lLarge := l2;
  end else begin
    lSmall := l2;
    lLarge := l1;
  end;
end;

procedure DrawCLUTx (var lCLUT: TLUT; lU: TUnitRect; lPrefs: TPrefs);
var
  lL,lT,lR,lB,lN: single;
  lI: integer;
begin
  SetOrder(lU.L,lU.R,lL,lR);
  SetOrder(lU.T,lU.B,lT,lB);
  lL := lL*gRayCast.WINDOW_WIDTH;
  lR := lR*gRayCast.WINDOW_WIDTH;
  lT := lT*gRayCast.WINDOW_HEIGHT;
  lB := lB*gRayCast.WINDOW_HEIGHT;
  if (lR-lL) > (lB-lT) then begin
    lN := lL;
    nglBegin(GL_TRIANGLE_STRIP);
     nglColor4ub (lCLUT[0].rgbRed, lCLUT[0].rgbGreen,lCLUT[0].rgbBlue,255);
     nglVertex2f(lN,lT);
     nglVertex2f(lN,lB);
     for lI := 1 to (255) do begin
        lN := (lI/255 * (lR-lL))+lL;
        nglColor4ub (lCLUT[lI].rgbRed, lCLUT[lI].rgbGreen,lCLUT[lI].rgbBlue,255);
        nglVertex2f(lN,lT);
        nglVertex2f(lN,lB);
     end;
    nglEnd;//GL_TRIANGLE_STRIP
  end else begin //If WIDE, else TALL
    lN := lT;
    nglColor4ub (lCLUT[0].rgbRed, lCLUT[0].rgbGreen,lCLUT[0].rgbBlue,255);
    nglBegin(GL_TRIANGLE_STRIP);
     nglVertex2f(lR, lN);
     nglVertex2f(lL, lN);
     for lI := 1 to (255) do begin
        lN := (lI/255 * (lB-lT))+lT;
        nglColor4ub (lCLUT[lI].rgbRed, lCLUT[lI].rgbGreen,lCLUT[lI].rgbBlue,255);
        nglVertex2f(lR, lN);
        nglVertex2f(lL, lN);
     end;
    nglEnd;//GL_TRIANGLE_STRIP
  end;
end;

procedure DrawBorder (var lU: TUnitRect;lBorder: single; lPrefs: TPrefs);
const
 kZ = -0.1; //put border behind colorbar
var
    lL,lT,lR,lB: single;
begin
  if lBorder <= 0 then
    exit;
  SetOrder(lU.L,lU.R,lL,lR);
  SetOrder(lU.T,lU.B,lT,lB);
  nglColor4ub(lPrefs.GridAndBorder.rgbRed,lPrefs.GridAndBorder.rgbGreen,lPrefs.GridAndBorder.rgbBlue,lPrefs.GridAndBorder.rgbReserved);
  nglBegin(GL_TRIANGLE_STRIP);
      nglVertex3f((lL-lBorder)*gRayCast.WINDOW_WIDTH,(lB+lBorder)*gRayCast.WINDOW_HEIGHT, kZ);
      nglVertex3f((lL-lBorder)*gRayCast.WINDOW_WIDTH,(lT-lBorder)*gRayCast.WINDOW_HEIGHT, kZ);
      nglVertex3f((lR+lBorder)*gRayCast.WINDOW_WIDTH,(lB+lBorder)*gRayCast.WINDOW_HEIGHT, kZ);
      nglVertex3f((lR+lBorder)*gRayCast.WINDOW_WIDTH,(lT-lBorder)*gRayCast.WINDOW_HEIGHT, kZ);
    nglEnd;//GL_TRIANGLE_STRIP
end;

procedure UOffset (var lU: TUnitRect; lX,lY: single);
begin
  lU.L := lU.L+lX;
  lU.T := lU.T+lY;
  lU.R := lU.R+lX;
  lU.B := lU.B+lY;
end;

procedure SetLutFromZero(var lMin,lMax: single);
//if both min and max are positive, returns 0..max
//if both min and max are negative, returns min..0
begin
    SortSingle(lMin,lMax);
    if (lMin > 0) and (lMax > 0) then
      lMin := 0
    else if (lMin < 0) and (lMax < 0) then
      lMax := 0;
end;



const
  kVertTextLeft = 1;
  kHorzTextBottom = 2;
  kVertTextRight = 3;
  kHorzTextTop = 4;

function ColorBarPos(var  lU: TUnitRect): integer;
begin
   SensibleUnitRect(lU);
   if abs(lU.R-lU.L) > abs(lU.B-lU.T) then begin //wide bars
    if (lU.B+lU.T) >1 then
      result := kHorzTextTop
    else
      result := kHorzTextBottom;
   end else begin //high bars
    if (lU.L+lU.R) >1 then
      result := kVertTextLeft
    else
      result := kVertTextRight;
   end;
end;

procedure DrawColorBarText(lMinIn,lMaxIn: single; var lUin: TUnitRect;lBorder: single; var lPrefs: TPrefs);
var
  lS: string;
  lOrient,lDesiredSteps,lPower,	lSteps,lStep,lDecimals,lStepPosScrn, lTextZoom: integer;
  lBarLength,lScrnL,lScrnT,lStepPos,l1stStep,lMin,lMax,lRange,lStepSize: single;
  lU: TUnitRect;
begin
  lU := lUin;
  lOrient := ColorBarPos(lU);
	 lMin := lMinIn;
	 lMax := lMaxIn;
   if (lMinIn < 0) and (lMaxIn <= 0) then begin
	  lMin := abs(lMinIn);
	  lMax := abs(lMaxIn);
   end;
   sortsingle(lMin,lMax);
   //next: compute increment
   lDesiredSteps := 4;
   lRange := abs(lMax - lMin);
   if lRange < 0.000001 then exit;
   lStepSize := lRange / lDesiredSteps;
   lPower := 0;
   while lStepSize >= 10 do begin
      lStepSize := lStepSize/10;
	    inc(lPower);
   end;
   while lStepSize < 1 do begin
	   lStepSize := lStepSize * 10;
	   dec(lPower);
   end;
   lStepSize := round(lStepSize) *Power(10,lPower);
   if lPower < 0 then
	    lDecimals := abs(lPower)
   else
	    lDecimals := 0;
   l1stStep := trunc((lMin)  / lStepSize)*lStepSize;
   lScrnL := lU.L * gRayCast.WINDOW_WIDTH;
   if lOrient =  kVertTextRight then
      lScrnL := lU.R * gRayCast.WINDOW_WIDTH;
   lScrnT := (lU.B) * gRayCast.WINDOW_HEIGHT;
   if lOrient =  kHorzTextTop then
      lScrnT := ((lU.B) * gRayCast.WINDOW_HEIGHT);
   if lOrient =  kHorzTextBottom then
      lScrnT := ((lU.T) * gRayCast.WINDOW_HEIGHT);
   if l1stStep < (lMin) then l1stStep := l1stStep+lStepSize;
    lSteps := trunc( abs((lMax+0.0001)-l1stStep) / lStepSize)+1;
   if (lOrient = kVertTextLeft) or (lOrient = kVertTextRight) then //vertical bars
      lBarLength := gRayCast.WINDOW_HEIGHT * abs(lU.B-lU.T)
   else
      lBarLength := gRayCast.WINDOW_WIDTH * abs(lU.L-lU.R);
   lTextZoom :=  trunc(lBarLength / 1000) + 1;
   for lStep := 1 to lSteps do begin
      lStepPos := l1stStep+((lStep-1)*lStepSize);
      lStepPosScrn := round( abs(lStepPos-lMin)/lRange*lBarLength);
      lS := realtostr(lStepPos,lDecimals);
      if (lMinIn < 0) and (lMaxIn <= 0) then
        lS := '-'+lS;
      if (lOrient = kVertTextLeft) or  (lOrient = kVertTextRight)  then
         TextArrow (lScrnL,lScrnT+ lStepPosScrn,lTextZoom,lS,lOrient,lPrefs.TextColor, lPrefs.TextBorder)
      else
         TextArrow (lScrnL+ lStepPosScrn,lScrnT,lTextZoom,lS,lOrient,lPrefs.TextColor, lPrefs.TextBorder);
		end;
    {$IFNDEF COREGL}glLoadIdentity();{$ENDIF}
end; //DrawColorBarText

type
TColorBar = packed record
   mn, mx: single;
   LUT: TLUT;
 end;
TColorBars = array of TColorBar;

procedure DrawColorBars ( lU: TUnitRect; lBorder: single; var lPrefs: TPrefs; lColorBars: TColorBars; window_width, window_height: integer );
var
      lU2:TUnitRect;
   nLUT, lI: integer;
   lIsHorzTop: boolean;
     lX,lY,lMin,lMax: single;
begin
  nLUT := length(lColorBars);
  if (nLUT < 1) then exit;
  gRayCast.WINDOW_HEIGHT:= window_height;
  gRayCast.WINDOW_WIDTH := window_width;
  lIsHorzTop := false;
  //Enter2D(lPrefs);
  Enter2D(window_width, window_height);

  glEnable (GL_BLEND);//allow border to be translucent
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  if abs(lU.R-lU.L) > abs(lU.B-lU.T) then begin //wide bars
    lX := 0;
    lY := abs(lU.B-lU.T)+lBorder;
    if (lU.B+lU.T) >1 then
      lY := -lY
    else
      lIsHorzTop := true;
  end else begin //high bars
    lX := abs(lU.R-lU.L)+lBorder;
    lY := 0;
    if (lU.L+lU.R) >1 then
      lX := -lX;
  end;
  //next - draw a border - do this once for all overlays, so
  //semi-transparent regions do not display regions of overlay
  SensibleUnitRect(lU);
  lU2 := lU;
  if nLUT > 1 then begin
    for lI := 2 to nLUT do begin
      if lX < 0 then
        lU2.L := lU2.L + lX
      else
        lU2.R := lU2.R + lX;
      if lY < 0 then
        lU2.B := lU2.B + lY
      else
        lU2.T := lU2.T + lY;
    end;
  end;
  DrawBorder(lU2,lBorder,lPrefs);
  lU2 := lU;

  for lI := 0 to (nLUT-1) do begin
    DrawCLUTx(lColorBars[lI].LUT,lU2,lPrefs);
    UOffset(lU2,lX,lY);
  end;
  lU2 := lU;
  for lI := 0 to (nLUT-1) do begin
    lMin := lColorBars[lI].mn;
    lMax := lColorBars[lI].mx;
    SortSingle(lMin,lMax);
    DrawColorBarText(lMin,lMax, lU2,lBorder,lPrefs);
    UOffset(lU2,lX,lY);
  end;
glDisable (GL_BLEND);
end;

{$IFDEF COREGL}
procedure StartDraw2D;
begin
 //Set2DDraw (gRayCast.WINDOW_WIDTH,gRayCast.WINDOW_Height, 48,48,48);
 glDepthMask(GL_TRUE); // enable writes to Z-buffer
 glEnable(GL_DEPTH_TEST);
 glDisable(GL_CULL_FACE); // glEnable(GL_CULL_FACE); //check on pyramid
 glEnable(GL_BLEND);
 {$IFNDEF COREGL}glEnable(GL_NORMALIZE); {$ENDIF}
 glViewport( 0, 0, gRayCast.WINDOW_WIDTH,gRayCast.WINDOW_Height); //required when bitmap zoom <> 1

   nglMatrixMode(nGL_MODELVIEW);
  nglLoadIdentity;
  //glDisable(GL_DEPTH_TEST);
  nglMatrixMode (nGL_PROJECTION);
  nglLoadIdentity ();
  nglOrtho (0, gRayCast.WINDOW_WIDTH,0, gRayCast.WINDOW_Height,-10,10);
  setlength(g2Dvnc, 0);
end;

procedure EndDraw2D;
begin
 DrawStrips (gRayCast.WINDOW_WIDTH, gRayCast.WINDOW_Height);

end;

(*procedure DrawCubeX (lScrnWid, lScrnHt, lAzimuth, lElevation: integer);
begin
 Set2DDraw (lScrnWid,lScrnHt, 48,48,48);
   nglMatrixMode(nGL_MODELVIEW);
  nglLoadIdentity;
  //glDisable(GL_DEPTH_TEST);
  nglMatrixMode (nGL_PROJECTION);
  nglLoadIdentity ();
  nglOrtho (0, lScrnWid,0, lScrnHt,-10,10);

  setlength(g2Dvnc, 0);
  TextArrow (50,50,1, '6666',1, gPrefs.TextColor, gPrefs.TextBorder);
  DrawStrips (lScrnWid, lScrnHt);
end; *)

procedure DrawCube (lScrnWid, lScrnHt, lAzimuth, lElevation: integer);
begin
  setlength(g2Dvnc, 0);
  DrawStrips (lScrnWid, lScrnHt);
  DrawCubeCore (lScrnWid, lScrnHt, lAzimuth, lElevation);
  DrawStrips (lScrnWid, lScrnHt);

end;
{$ELSE}
procedure DrawCube (lScrnWid, lScrnHt, lAzimuth, lElevation: integer);
begin
  DrawCubeCore (lScrnWid, lScrnHt, lAzimuth, lElevation);
end;
{$ENDIF}

(*procedure TestColorBar (var lPrefs: TPrefs; window_width, window_height: integer);
var
  c: TColorBars;
  lU: TUnitRect;
  i : integer = 1;
begin
  lU := CreateUnitRect (0.1,0.1,0.9,0.2);
  setlength(c,2);
  i := 2;
  c[0].LUT := UpdateTransferFunction(i);
  c[0].mn := 2;
  c[0].mx := 10;
  i := 1;
  c[1].LUT := UpdateTransferFunction(i);
  c[1].mn := -2;
  c[1].mx := -10;
  DrawColorBars ( lU, 0.005,  lPrefs, c, window_width, window_height );
end;

procedure DrawCube (lScrnWid, lScrnHt, lAzimuth, lElevation: integer);
begin
  setlength(g2Dvnc, 0);
  DrawCubeCore (lScrnWid, lScrnHt, lAzimuth, lElevation);
  DrawStrips (lScrnWid, lScrnHt);
end;

procedure DrawTextCore (lScrnWid, lScrnHt: integer);
begin
  nglMatrixMode(nGL_MODELVIEW);
  nglLoadIdentity;
  nglMatrixMode (nGL_PROJECTION);
  nglLoadIdentity ();
  nglOrtho (0, lScrnWid,0, lScrnHt,-10,10);
  //clr.r := 22; clr.g := 22; clr.b := 222; clr.a := 255;
  //PrintXY(10,320, 2,'-123.9', clr);
  //clr2.r := 65; clr2.g := 10; clr2.b := 220; clr2.a := 128;
  //TextArrow (60,220, 2, '123.9', 2, clr,clr2);
end;

procedure DrawText (var lPrefs: TPrefs; lScrnWid, lScrnHt: integer);
begin
  setlength(g2Dvnc, 0);
  DrawTextCore(lScrnWid, lScrnHt);
  TestColorBar(lPrefs, lScrnWid, lScrnHt);
  DrawStrips (lScrnWid, lScrnHt);
end;   *)

(*procedure TestColorBar (var lPrefs: TPrefs; window_width, window_height: integer);
var
  c: TColorBars;
  lU: TUnitRect;
  i : integer = 1;
begin
  lU := CreateUnitRect (0.1,0.1,0.9,0.2);
  setlength(c,2);
  i := 2;
  c[0].LUT := UpdateTransferFunction(i);
  c[0].mn := 2;
  c[0].mx := 10;
  i := 1;
  c[1].LUT := UpdateTransferFunction(i);
  c[1].mn := -2;
  c[1].mx := -10;
  DrawColorBars ( lU, 0.005,  lPrefs, c, window_width, window_height );
end;  *)

{$IFDEF COREGL}
procedure DrawText (var lPrefs: TPrefs; lScrnWid, lScrnHt: integer);
begin
 setlength(g2Dvnc, 0);
 DrawTextCore(lScrnWid, lScrnHt);
 //TestColorBar(lPrefs, lScrnWid, lScrnHt);
 DrawStrips (lScrnWid, lScrnHt);
end;
{$ELSE}
procedure DrawText (var lPrefs: TPrefs; lScrnWid, lScrnHt: integer);
begin
 TestColorBar(lPrefs, lScrnWid, lScrnHt);
end;

{$ENDIF}

end.


unit glmtext;
//openGL Text using distance field fonts https://github.com/libgdx/libgdx/wiki/Distance-field-fonts
//traditional signed-distance field fonts use a single channel (alpha), here we use multi-channel (red,green,blue)
//This can preserve sharp corners in fonts
//  https://github.com/Chlumsky/msdfgen
//  https://github.com/Jam3/msdf-bmfont
{$IFDEF FPC}
{$Include opts.inc}
{$mode objfpc}{$H+}
{$ENDIF}
interface

uses
  {$IFDEF FPC}
    {$IFDEF COREGL}glcorearb,  gl_core_matrix, {$ELSE}gl, glext, {$ENDIF} OpenGLContext,LResources,
  {$ELSE}
    dglOpenGL, glpanel, windows,pngimage,
  {$ENDIF}
   raycast_common, Dialogs,Classes, SysUtils, Graphics, strutils, math;

const
    kMaxChar = 2048; //maximum number of characters on screen, if >21845 change TPoint3i to uint32 and set glDrawElements to GL_UNSIGNED_INT
type
    TMetric = Packed Record //each vertex has position and texture coordinates
      x,y,xEnd,yEnd,w,h,xo,yo,xadv   : single; //position coordinates
    end;
    TMetrics = record
      M : array [0..255] of TMetric;
      lineHeight, base, scaleW, scaleH: single;
    end;
    Txyuv = Packed Record //each vertex has position and texture coordinates
      x,y   : single; //position coordinates
      u,v : single; //texture coordinates
    end;
    TRotMat = Packed Record //https://en.wikipedia.org/wiki/Rotation_matrix
            Xx,Xy, Yx,Yy: single;
    end;
    TQuad = array [0..3] of Txyuv; //each character rectangle has 4 vertices
  TGLText = class
  private
         {$IFDEF COREGL}vboVtx, vboIdx, vao,{$ELSE}displayLst,{$ENDIF} tex, shaderProgram: GLuint;
         {$IFDEF COREGL}uniform_mtx, {$ENDIF} uniform_clr, uniform_tex: GLint;
         fCrap, nChar, bmpHt, bmpWid: integer;
         isChanged: boolean;
         quads: array[0..(kMaxChar-1)] of TQuad;
         metrics: TMetrics;
         r,g,b: single;
    {$IFDEF COREGL}procedure LoadBufferData;{$ENDIF}
    function LoadMetrics(fnm : string): boolean;
    function LoadTex(fnm : string): boolean;
    procedure UpdateVbo;
    procedure CharOut(x,y,scale: single; rx: TRotMat; asci: byte);
  public
    property Crap : integer read fCrap;
    procedure ClearText; //remove all previous drawn text
    procedure TextOut(x,y,scale: single; s: string); overload; //add line of text
    procedure TextOut(x,y,scale, angle: single; s: string); overload; //add line of text
    function BaseHeight: single;
    function LineHeight: single;
    function TextWidth(scale: single; s: string): single;
    procedure TextColor(red,green,blue: byte);
    procedure DrawText;
    {$IFDEF FPC}
    procedure ChangeFontName(fntname: string; Ctx: TOpenGLControl);
    constructor Create(fntname : string; out success: boolean; Ctx: TOpenGLControl); //overlod;
    {$ELSE}
    procedure ChangeFontName(fntname: string; Ctx: TGLPanel);
    constructor Create(fntname : string; out success: boolean; Ctx: TGLPanel); //overlod;
    {$ENDIF}
    Destructor  Destroy; override;
  end;
  {$IFNDEF COREGL}var GLErrorStr : string = '';{$ENDIF}

implementation
{$IFNDEF FPC}{$R 'mfnt.res'}{$ENDIF}

const
{$IFDEF COREGL}
    kVert = '#version 330'
+#10'layout(location = 0) in vec2 point;'
+#10'layout(location = 1) in vec2 uvX;'
+#10'uniform mat4 ModelViewProjectionMatrix;'
+#10'out vec2 uv;'
+#10'void main() {'
+#10'    uv = uvX;'
+#10'    vec2 ptx = point;'
+#10'    gl_Position = ModelViewProjectionMatrix * vec4(ptx, -0.5, 1.0);'
+#10'}';

    kFrag = '#version 330'
    +#10'in vec2 uv;'
    +#10'out vec4 color;'
    +#10'uniform sampler2D tex;'
    +#10'uniform vec4 clr;'
    +#10'float median(float r, float g, float b) {'
    +#10'    return max(min(r, g), min(max(r, g), b));'
    +#10'}'
    +#10'void main() {'
    +#10'  vec3 sample = 1.0 - texture(tex, uv).rgb;'
    +#10'  float sigDist = median(sample.r, sample.g, sample.b) - 0.5;'
    +#10'  float opacity = clamp(sigDist/fwidth(sigDist) + 0.5, 0.0, 1.0);'
    +#10'  color = vec4(clr.r,clr.g,clr.b,1.0 - opacity);'
    +#10'}';
{$ELSE} //if core opengl, else legacy shaders
kVert ='varying vec4 vClr;'
+#10'void main() {'
+#10'    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;'
+#10'    vClr = gl_Color;'
+#10'}';

const kFrag = 'varying vec4 vClr;'
+#10'uniform sampler2D tex;'
+#10'uniform vec4 clr;'
+#10'float median(float r, float g, float b) {'
+#10'    return max(min(r, g), min(max(r, g), b));'
+#10'}'
+#10'void main() {'
+#10'  vec3 sample = 1.0 - texture2D(tex,vClr.xy).rgb;'
+#10'  float sigDist = median(sample.r, sample.g, sample.b) - 0.5;'
+#10'  float opacity = clamp(sigDist/fwidth(sigDist) + 0.5, 0.0, 1.0);'
+#10'  gl_FragColor = vec4(clr.rgb, 1.0 - opacity);'
+#10'}';

{$ENDIF}
//{$DEFINE BINARYMETRICS} //binary metrics are faster than reading default metrics created by Hiero
{$IFDEF BINARYMETRICS}
procedure SaveMetricsBinary(fnm: string; fnt: TMetrics);
var
  f : File of TMetrics;
begin
  {$IFDEF ENDIAN_BIG}to do: byte-swap to little-endian  {$ENDIF}
  AssignFile(f, changefileext(fnm,'.fnb'));
  ReWrite(f, 1);
  Write(f, fnt);
  CloseFile(f);
end;

function LoadMetricsBinary(fnm: string; out fnt: TMetrics): boolean;
var
  f : File of TMetrics;
begin
  result := false;
  fnm := changefileext(fnm,'.fnb');
  if not fileexists(fnm) then exit;
  AssignFile(f, fnm);
  Reset(f, 1);
  Read(f, fnt);
  CloseFile(f);
  {$IFDEF ENDIAN_BIG}to do: byte-swap from little-endian  {$ENDIF}
  result := true;
end;
{$ENDIF} // BINARYMETRICS

function LoadMetricsJson(fnm: string; out fnt: TMetrics): boolean;
//load JSON format created by
// https://github.com/Jam3/msdf-bmfont
//Identical attributes to Hiero ASCII FNT format, just saved in JSON
const
  idKey = '"id"';
var
   pages, id, strBlockStart, strBlockEnd: integer;
   str: string;
   f: textfile;
   {$IFDEF FPC}
   r: TLResource;
   {$ELSE}
   r : TResourceStream;
   fLst: TStringList;
   {$ENDIF}
function GetFntVal(key: string): single;
var
   p, pComma: integer;
begin
  result := 0;
  p := PosEx(key,str,strBlockStart);
  if (p < 1) or (p > strBlockEnd) then exit;
  p :=  p + length(key)+1;
  pComma := PosEx(',',str,p);
  if (pComma <= p) or (pComma > strBlockEnd) then exit;
  result := strtofloatdef(copy(str,p, pComma-p), 0);
end; //nested GetFntVal()
begin
  result := false;
  for id := 0 to 255 do begin
      fnt.M[id].x := 0;
      fnt.M[id].y := 0;
      fnt.M[id].xEnd := 0;
      fnt.M[id].yEnd := 0;
      fnt.M[id].w := 0;
      fnt.M[id].h := 0;
      fnt.M[id].xo := 0;
      fnt.M[id].yo := 0;
      fnt.M[id].xadv := 0; //critical to set: fnt format omits non-graphical characters (e.g. DEL): we skip characters whete X-advance = 0
  end;
  if fnm = '' then begin
    {$IFDEF FPC}
    r:=LazarusResources.Find('jsn');
    if r=nil then raise Exception.Create('resource jsn is missing');
    str:=r.Value;
    {$ELSE}
     r := TResourceStream.Create(hInstance,'JSN',RT_RCDATA);
     fLst := TStringList.Create;
     fLst.LoadFromStream(r);
     str := fLst[0];
     fLst.Free;
     r.free;
    {$ENDIF}
  end else begin
    if not fileexists(fnm) then begin
       showmessage('Unable to find '+fnm);
       exit;
    end;
    AssignFile(f, fnm);
    Reset(f);
    ReadLn(f, str);
    CloseFile(f);
  end;
  strBlockStart := PosEx('"common"',str,1);
  strBlockEnd := PosEx('}',str, strBlockStart);
  if (strBlockStart < 1) or (strBlockEnd < 1) then begin
     showmessage('Error: no "common" section');
     exit;
  end;
  fnt.lineHeight := GetFntVal('"lineHeight"');
  fnt.base := GetFntVal('"base"');
  fnt.scaleW := GetFntVal('"scaleW"');
  fnt.scaleH := GetFntVal('"scaleH"');
  pages := round(GetFntVal('"pages"'));
  if (pages <> 1) then begin
     showmessage('Only able to read single page fonts');
     exit;
  end;
  strBlockStart := 1;
  repeat
        strBlockStart := PosEx(idKey,str,strBlockStart);
        if strBlockStart < 1 then continue;
        strBlockEnd := PosEx('}',str, strBlockStart);
        if strBlockEnd < strBlockStart then
           break;
        id := round(GetFntVal(idKey));
        if id = 0 then begin
           strBlockStart := strBlockEnd;
           continue;
        end;
        fnt.M[id].x := GetFntVal('"x"');
        fnt.M[id].y := GetFntVal('"y"');
        fnt.M[id].w := GetFntVal('"width"');
        fnt.M[id].h := GetFntVal('"height"');
        fnt.M[id].xo := GetFntVal('"xoffset"');
        fnt.M[id].yo := GetFntVal('"yoffset"');
        fnt.M[id].xadv := GetFntVal('"xadvance"');
        strBlockStart := strBlockEnd;
  until strBlockStart < 1;
  if (fnt.scaleW < 1) or (fnt.scaleH < 1) then exit;
  for id := 0 to 255 do begin //normalize from pixels to 0..1
      //these next lines seem arbitrary, but they seem to compensate for vertical/horizontal offset vs Hiero
      //fnt.M[id].yo := fnt.base - (fnt.M[id].h + fnt.M[id].yo); //<- Hiero
      fnt.M[id].yo := (0.17*fnt.base)-(fnt.M[id].h + fnt.M[id].yo); //<- msdf-bmfont
      fnt.M[id].xo := fnt.M[id].xo- (0.17*fnt.base);// <-msdf-bmfont
      fnt.M[id].x:=fnt.M[id].x/fnt.scaleW+1/fnt.scaleW ; //+1/scaleW : indexed from 1 not 0?
      fnt.M[id].y:=fnt.M[id].y/fnt.scaleH+1/fnt.scaleH; //+1/scaleH : indexed from 1 not 0?
      fnt.M[id].xEnd := fnt.M[id].x + (fnt.M[id].w/fnt.scaleW)-2/fnt.scaleW;
      fnt.M[id].yEnd := fnt.M[id].y + (fnt.M[id].h/fnt.scaleH)-2/fnt.scaleH;
  end;
  result := true;
end; //LoadMetricsJson()

procedure Rot(xK,yK, x,y: single; r: TRotMat; out Xout, Yout: single);
// rotate points x,y and add to constant offset xK,yK
begin
     Xout := xK + (x * r.Xx) + (y * r.Xy);
     Yout := yK + (x * r.Yx) + (y * r.Yy);
end;

procedure TGLText.CharOut(x,y,scale: single; rx: TRotMat; asci: byte);
var
  q: TQuad;
  x0,x1,y0,y1: single;
begin
  if metrics.M[asci].w = 0 then exit; //nothing to draw, e.g. SPACE character
  if nChar > kMaxChar then nChar := 0; //overflow!
  x0 := (scale * metrics.M[asci].xo);
  x1 := x0 + (scale * metrics.M[asci].w);
  y0 := (scale * metrics.M[asci].yo);
  y1 := y0 + (scale * metrics.M[asci].h);
  Rot(x,y, x0, y0, rx, q[0].x, q[0].y);
  Rot(x,y, x0, y1, rx, q[1].x, q[1].y);
  Rot(x,y, x1, y0, rx, q[2].x, q[2].y);
  Rot(x,y, x1, y1, rx, q[3].x, q[3].y);
  q[0].u := metrics.M[asci].x;
  q[1].u := q[0].u;
  q[2].u := metrics.M[asci].xEnd;
  q[3].u := q[2].u;
  q[0].v := metrics.M[asci].yEnd;
  q[1].v := metrics.M[asci].y;
  q[2].v := q[0].v;
  q[3].v := q[1].v;
  quads[nChar] := q;
  isChanged := true;
  nChar := nChar + 1;
end; //CharOut()

procedure TGLText.TextOut(x,y,scale, angle: single; s: string); //overload
var
  i: integer;
  asci: byte;
  rx: TRotMat;
begin
  angle := DegToRad(angle);
  rx.Xx := cos(angle);
  rx.Xy := -sin(angle);
  rx.Yx := sin(angle);
  rx.Yy := cos(angle);
  if length(s) < 1 then exit;
  for i := 1 to length(s) do begin
      asci := ord(s[i]);
      if metrics.M[asci].xadv = 0 then continue; //not in dataset
      CharOut(x,y,scale,rx,asci);
      Rot(x,y, (scale * metrics.M[asci].xadv),0, rx, x, y);
  end;
end; //TextOut()

procedure TGLText.TextOut(x,y,scale: single; s: string); //overload;
begin
     TextOut(x,y,scale,0,s);
end; //TextOut()

function TGLText.BaseHeight: single;
begin
  result := metrics.base;
end;

function TGLText.LineHeight: single;
begin
     result := metrics.lineHeight;
end;

function TGLText.TextWidth(scale: single; s: string): single;
var
  i: integer;
  asci: byte;
begin
  result := 0;
  if length(s) < 1 then exit;
  for i := 1 to length(s) do begin
      asci := ord(s[i]);
      if metrics.M[asci].xadv = 0 then continue; //not in dataset
      result := result + (scale * metrics.M[asci].xadv);
  end;
end; //TextWidth()

procedure TGLText.TextColor(red,green,blue: byte);
begin
     r := red/255;
     g := green/255;
     b := blue/255;
end;

procedure TGLText.ClearText;
begin
  nChar := 0;
end; //ClearText()

{$IFDEF COREGL}
procedure TGLText.UpdateVbo;
begin
  if (nChar < 1) or (not isChanged) then exit;

  glBindBuffer(GL_ARRAY_BUFFER, vboVtx);
  glBufferSubData(GL_ARRAY_BUFFER,0,nChar * sizeof(TQuad),@quads[0]);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  isChanged := false;
end; //UpdateVbo()
{$ELSE} //not CoreGL
procedure TGLText.UpdateVbo;
var
  z,i: integer;
  q: TQuad;
begin
  if (nChar < 1) or (not isChanged) then exit;
  if displayLst <> 0 then
     glDeleteLists(displayLst, 1);
  displayLst := glGenLists(1);
  glNewList(displayLst, GL_COMPILE);
  z := -1;
  glBegin(GL_TRIANGLES);
  for i := 0 to (nChar-1) do begin
      q := quads[i];
      glColor3f(Q[0].u, Q[0].v, 1.0);
      glVertex3f(Q[0].x, Q[0].y, z);
      glColor3f(Q[1].u, Q[1].v, 1.0);
      glVertex3f(Q[1].x, Q[1].y, z);
      glColor3f(Q[2].u, Q[2].v, 1.0);
      glVertex3f(Q[2].x, Q[2].y, z);
      glColor3f(Q[2].u, Q[2].v, 1.0);
      glVertex3f(Q[2].x, Q[2].y, z);
      glColor3f(Q[1].u, Q[1].v, 1.0);
      glVertex3f(Q[1].x, Q[1].y, z);
      glColor3f(Q[3].u, Q[3].v, 1.0);
      glVertex3f(Q[3].x, Q[3].y, z);
  end;
  glEnd();
  glEndList();
  isChanged := false;
end; //UpdateVbo()
{$ENDIF}

{$IFDEF COREGL}
procedure TGLText.LoadBufferData;
type
    TPoint3i = Packed Record
      x,y,z   : uint16; //vertex indices: for >65535 indices use uint32 and use GL_UNSIGNED_INT for glDrawElements
    end;
const
    kATTRIB_POINT = 0; //XY position on screen
    kATTRIB_UV = 1; //UV coordinates of texture
var
    faces: array of TPoint3i;
    i,j,k: integer;
begin
  uniform_clr := glGetUniformLocation(shaderProgram, pAnsiChar('clr'));
  uniform_tex := glGetUniformLocation(shaderProgram, pAnsiChar('tex'));
  glGenBuffers(1, @vboVtx);
  glBindBuffer(GL_ARRAY_BUFFER, vboVtx);
  glBufferData(GL_ARRAY_BUFFER, kMaxChar * sizeof(TQuad), nil, GL_DYNAMIC_DRAW); //GL_STATIC_DRAW
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glGenVertexArrays(1, @vao);
  glBindVertexArray(vao);
  glBindBuffer(GL_ARRAY_BUFFER, vboVtx);
  glVertexAttribPointer(kATTRIB_POINT, 2, GL_FLOAT, GL_FALSE, sizeof(Txyuv), PChar(0));
  glEnableVertexAttribArray(kATTRIB_POINT);
  glVertexAttribPointer(kATTRIB_UV, 2, GL_FLOAT, GL_FALSE, sizeof(Txyuv), PChar(sizeof(single)*2));
  glEnableVertexAttribArray(kATTRIB_UV);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
  uniform_mtx := glGetUniformLocation(shaderProgram, pAnsiChar('ModelViewProjectionMatrix'));
  glGenBuffers(1, @vboIdx);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboIdx);
  setlength(faces, kMaxChar * 2 ); //each character composed of 2 triangles
  for i := 0 to ((kMaxChar)-1) do begin
      j := i * 2;
      k := i * 4;
      faces[j].x := 0+k;
      faces[j].y := 1+k;
      faces[j].z := 2+k;
      faces[j+1].x := 2+k;
      faces[j+1].y := 1+k;
      faces[j+1].z := 3+k;
  end;
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, Length(faces)*sizeof(TPoint3i), @faces[0], GL_STATIC_DRAW);
  setlength(faces, 0 );
end;
{$ENDIF}

function TGLText.LoadTex(fnm: string): boolean;
var
  {$IFDEF FPC}
  px: TPicture;
  Ptr: PByte;
  {$ELSE}
  ra: array of byte;
  x,y,i: integer;
  PNG: TPNGObject;
  RS : TResourceStream;
  pScanline: pngimage.pByteArray;
  {$ENDIF}
  {$IFDEF TEX8BIT_NOT32} //save 75% of texture size by only saving A not RGBA
  ra: array of byte;
  x,y,i: integer;
  {$ENDIF}
begin
  result := false;
  if (fnm <> '') and (not fileexists(fnm)) then begin
     fnm := changefileext(fnm,'.png');
     if not fileexists(fnm) then
        exit;
  end;
  {$IFDEF FPC}
  px := TPicture.Create;
  try
    if fnm = '' then
       px.LoadFromLazarusResource('png')
    else
        px.LoadFromFile(fnm);
  except
    px.Bitmap.Width:=0;
  end;
  //showmessage(format('bmp %d %d',[px.Bitmap.Width, px.Bitmap.Height]));
  if (px.Bitmap.PixelFormat <> pf32bit ) or (px.Bitmap.Width < 1) or (px.Bitmap.Height < 1) then begin
  {$ELSE}
  PNG := TPNGObject.Create;
  try
    if fnm = '' then begin
      RS := TResourceStream.Create(hInstance,'PNG',RT_RCDATA);
      PNG.LoadFromStream(RS);
      RS.Free;
    end else
      PNG.LoadFromFile(fnm);

  except
    PNG.Transparent:=false;
  end;
  if (not PNG.Transparent) or (PNG.Width < 1) or (PNG.Height < 1) then begin
  {$ENDIF}
     showmessage(format('Error loading 32-bit power-of-two bitmap %s',[fnm]));
     exit;
  end;
  glGenTextures(1, @tex);
  glBindTexture(GL_TEXTURE_2D,  tex);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
{$IFDEF FPC}
  bmpHt := px.Bitmap.Height;
  bmpWid := px.Bitmap.Width;
  {$IFDEF TEX8BIT_NOT32}
  setlength(ra, px.Width * px.Height);
  i := 0;
  for y:= 1 to px.Height do begin
      Ptr := px.Bitmap.RawImage.GetLineStart(y);
      Inc(PByte(Ptr), 3);
      for x := 1 to px.Width do begin
          ra[i] := Ptr^;
          Inc(PByte(Ptr), 4);
          i := i + 1;
      end;
  end;
  glTexImage2D(GL_TEXTURE_2D, 0,GL_RED, px.Width, px.Height, 0, GL_RED, GL_UNSIGNED_BYTE, @ra[0]);
  setlength(ra,0);
  {$ELSE}
  glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA8, px.Width, px.Height, 0, GL_BGRA, GL_UNSIGNED_BYTE, PInteger(px.Bitmap.RawImage.Data));
  {$ENDIF}
  px.Free;
{$ELSE}
  bmpHt := PNG.Height;
  bmpWid := PNG.Width;
  i := 0;
  setlength(ra, bmpHt * bmpWid * 3);
  for y := 0 to bmpHt - 1 do begin
      pScanline := PNG.Scanline[y];
      for x := 0 to (3*PNG.Width) - 1 do begin
        ra[i] :=  pScanline[x];
        i := i + 1;
      end;
  end;
  glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA8, bmpWid, bmpHt, 0, GL_RGB, GL_UNSIGNED_BYTE, @ra[0]);
  setlength(ra,0);
  png.free;
{$ENDIF}
  result := true;
end;

function TGLText.LoadMetrics(fnm : string): boolean;
var
   fntfnm: string;
begin
     {$IFDEF BINARYMETRICS}if LoadMetricsBinary(fnm,metrics) then exit;{$ENDIF}
     if fnm = '' then
        fntfnm := ''
     else
         fntfnm := changefileext(fnm,'.json');
      //result := LoadMetricsAsci(fntfnm,metrics);
      result := LoadMetricsJson(fntfnm,metrics);
     {$IFDEF BINARYMETRICS}SaveMetricsBinary(fntfnm,metrics);{$ENDIF}
end;

{$IFDEF FPC}
constructor TGLText.Create(fntname: string; out success: boolean; Ctx: TOpenGLControl);
{$ELSE}
constructor TGLText.Create(fntname: string; out success: boolean; Ctx: TGLPanel);
{$ENDIF}
begin
  success := true;
  tex := 0;
  shaderProgram := 0;
  {$IFDEF COREGL}
  vboVtx := 0;
  vboIdx := 0;
  vao := 0;
  uniform_mtx := 0;
  {$ELSE}
  displayLst := 0;
  {$ENDIF}
  uniform_clr := 0;
  uniform_tex := 0;
  r := 1;
  g := 1;
  b := 1;
  nChar := 0;
  isChanged := false;
  Ctx.MakeCurrent();
  shaderProgram :=  initVertFrag(kVert, kFrag);
  if shaderProgram = 0 then success := false;
  if not LoadTex(fntname) then success := false;
  if not LoadMetrics(fntname) then success := false;
  uniform_clr := glGetUniformLocation(shaderProgram, pAnsiChar('clr'));
  uniform_tex := glGetUniformLocation(shaderProgram, pAnsiChar('tex'));
  {$IFDEF COREGL}LoadBufferData;{$ENDIF}
  //glFinish;
  Ctx.ReleaseContext;
end;

procedure TGLText.DrawText;
{$IFDEF COREGL}
var
  mvp : TnMat44;
{$ENDIF}
begin
  fCrap:= nChar*10 + random(10);
  if nChar < 1 then exit; //nothing to draw
  glUseProgram(shaderProgram);
  UpdateVbo;
  glUniform4f(uniform_clr, r, g, b, 1.0);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, tex);
  glUniform1i(uniform_tex, 1);
  {$IFDEF COREGL}
  mvp := ngl_ModelViewProjectionMatrix;
  glUniformMatrix4fv(uniform_mtx, 1, GL_FALSE, @mvp[0,0]);
  glBindVertexArray(vao);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,vboIdx);
  glDrawElements(GL_TRIANGLES,  nChar * 2* 3, GL_UNSIGNED_SHORT, nil); //each quad 2 triangles each with 3 indices
  glBindVertexArray(0);
  {$ELSE}
  glCallList(displayLst);
  {$ENDIF}
  glUseProgram(0);
end;

destructor TGLText.Destroy;
begin
  //call the parent destructor:
  inherited;
end;

{$IFDEF FPC}
procedure TGLText.ChangeFontName(fntname: string; Ctx: TOpenGLControl);
{$ELSE}
procedure TGLText.ChangeFontName(fntname: string; Ctx: TGLPanel);
{$ENDIF}
begin
  Ctx.MakeCurrent();
  glDeleteTextures(1, @tex);
   LoadTex(fntname);
   LoadMetrics(fntname);
   Ctx.ReleaseContext;
end;

initialization
{$IFDEF FPC}
 {$I mfnt.lrs}
{$ENDIF}
end.


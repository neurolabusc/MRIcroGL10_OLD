unit histogram2d;
{$IFDEF FPC}{$mode objfpc}{$H+}  {$ENDIF}
{$D-,L-,O+,Q-,R-,Y-,S-}
{$include options.inc}
interface
uses
{$IFNDEF FPC}windows, {$ENDIF}
{$IFDEF USETRANSFERTEXTURE}texture_3d_unita, {$ELSE} texture_3d_unit,{$ENDIF}
 dglOpenGL,  clut, define_types, Forms, Classes, Controls, prefs;

  procedure DrawNodes(WINDOW_HEIGHT,WINDOW_WIDTH: integer; Tex: TTexture; var lPrefs: TPrefs);
  procedure ClutMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  procedure CLUTMouseMove(Shift: TShiftState; X, Y: Integer);
  function AddColorNode (lIntensity: byte) : integer;

implementation

type
  TChart2d = record
    Left,Bottom,Height,Width: single;
    rgba,historgba, backcolor: TGLRGBQuad;
  end;

procedure InterpolateRGBA(var lC1,lC2,lMix: TGLRGBQuad);
begin
  lMix.rgbRed := (lC1.rgbRed + lC2.rgbRed) shr 1;
  lMix.rgbGreen := (lC1.rgbGreen + lC2.rgbGreen) shr 1;
  lMix.rgbBlue := (lC1.rgbBlue + lC2.rgbBlue) shr 1;
end;

procedure DeleteScrnNode (lSelectedNode: integer);
var
  lN: integer;
begin
  if (lSelectedNode = 0) or (lSelectedNode >= (gCLUTrec.numnodes-1)) then
    exit; //out of range or edge node...
  dec(gCLUTrec.numnodes); //if 3 now only 2...
  if lSelectedNode < (gCLUTrec.numnodes) then begin
    for lN := lSelectedNode to (gCLUTrec.numnodes-1) do
      gCLUTrec.nodes[lN] := gCLUTrec.nodes[lN+1];
  end;
end;

function AddColorNode (lIntensity: byte) : integer;
var
  lP,lI,lInten: integer;
begin
  lInten := lIntensity;
  result := -1;//error
  if (lInten <= gCLUTrec.nodes[0].intensity) then
    exit;
  if (lInten >= gCLUTrec.nodes[gCLUTrec.numnodes-1].intensity) then
    exit;
  lP := gCLUTrec.numnodes-1;
  while lInten < gCLUTrec.nodes[lP].intensity do
    dec(lP);
  if  abs(gCLUTrec.nodes[lP].intensity-gCLUTrec.nodes[lP+1].intensity) < 2 then
    exit;
  if lInten = gCLUTrec.nodes[lP].intensity then
    lInten := gCLUTrec.nodes[lP].intensity+1;
  if lInten = gCLUTrec.nodes[lP+1].intensity then
    lInten := gCLUTrec.nodes[lP+1].intensity-1;
  inc(lP);//location of new node
  inc(gCLUTrec.numNodes);
  for lI := (gCLUTrec.numnodes-1) downto (lP+1) do
    gCLUTrec.nodes[lI] := gCLUTrec.nodes[lI-1];
  gCLUTrec.nodes[lP].intensity := lInten;
  result := lP;
end;

procedure AddScrnNode(lPt: TPoint);
var
  lP: integer;
begin
  if gCLUTrec.numnodes < 2 then exit;
  if gCLUTrec.numnodes >= 255 then
    exit;
  //only add node between min and max - not more extreme!
  if (lPt.X <= gCLUTrec.nodes[0].intensity) then
    exit;
  if (lPt.X >= gCLUTrec.nodes[gCLUTrec.numnodes-1].intensity) then
    exit;
  lP := AddColorNode(lPt.X);
  if lP < 0 then
    exit;
  gCLUTrec.nodes[lP].rgba.rgbreserved := lPt.Y;
    InterpolateRGBA(gCLUTrec.nodes[lP-1].rgba,gCLUTrec.nodes[lP+1].rgba,gCLUTrec.nodes[lP].rgba);
end;

procedure CLUTMouseMove(Shift: TShiftState; X, Y: Integer);
var
  lX,lY: integer;
begin
   if not (SSLeft in Shift) then
    exit;
   if (gCLUTrec.numNodes < 1) or (gSelectedNode < 0) or (gCLUTrec.numnodes <= gSelectedNode  ) then
    exit;
   lY := 255-Y;
   if lY < 0 then lY := 0; if lY > 255 then lY := 255;
   gCLUTrec.nodes[gSelectedNode].rgba.rgbReserved := lY;
   if (gSelectedNode > 0) and (gSelectedNode <(gCLUTrec.numnodes-1)) then begin
   lX := X;
   if gSelectedNode > 0 then begin
      if lX <= gCLUTrec.nodes[gSelectedNode-1].intensity then
        lX := gCLUTrec.nodes[gSelectedNode-1].intensity+1;
    end;
    if gSelectedNode < (gCLUTrec.numnodes-1) then begin
      if lX >= gCLUTrec.nodes[gSelectedNode+1].intensity then
        lX := gCLUTrec.nodes[gSelectedNode+1].intensity-1;
    end;
    gCLUTrec.nodes[gSelectedNode].intensity := lX;
   end;//node not first or last (min node must be zero, max node must be 255)
end;
procedure ClutMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  lI,lB: integer;
  lDx,lDx2: single;
  lPt: TPoint;
begin
   gSelectedNode := 0;
   if gCLUTrec.numNodes < 2 then
    exit;
   lPt := Point(X,255-Y);
    if  (SSCtrl in Shift) then begin //remove node
      AddScrnNode(lPt);
      gSelectedNode := -1;
      exit;
   end;
   lB := lPt.X;
   lDx := (lB - gCLUTrec.nodes[0].intensity);
   for lI := 1 to (gCLUTrec.numnodes-1) do begin
    lDx2 := (lB - gCLUTrec.nodes[lI].intensity);
    if abs(lDx2) < abs(lDx) then begin
      gSelectedNode := lI;
      lDx := lDx2;
    end;
   end; //check each node...
   if  (SSShift in Shift) then begin //remove node
      DeleteScrnNode(gSelectedNode);
      gSelectedNode := -1;
   end;
end;

procedure SetColor (rgba: TGLRGBQuad);
begin
  glColor4ub(rgba.rgbRed,rgba.rgbGreen,rgba.rgbBlue,rgba.rgbReserved);
end;

procedure SetColorOpaque (rgba: TGLRGBQuad);
begin
  glColor4ub(rgba.rgbRed,rgba.rgbGreen,rgba.rgbBlue,255);
end;

procedure SetColorA (rgba: TGLRGBQuad; A: byte);
begin
  glColor4ub(rgba.rgbRed,rgba.rgbGreen,rgba.rgbBlue,A);
end;

procedure ShowHistogram (H: HistoRA; C: TChart2d);
var
  ysum : double;
  ny,xprev,x,y,i: integer;
begin
  xprev := -666;
  ny := 0;
  ysum := 0;
  glBegin (GL_TRIANGLE_STRIP);
    for i := 0 to (kHistoBins) do begin
      x := round(i/kHistoBins*C.Width);
      if x > (xprev+1) then begin
        y := round( ((ysum+H[i])/(ny+1)) /kHistoBins*C.Height);

        glVertex3f (x, y, 0);
        glVertex3f (x, 0, 0);
        xprev := x;
        ny := 0;
        ysum := 0;
      end else begin
        ysum := ysum + H[i];
        inc(ny);
      end;
    end;
  glEnd;
  //glEnable(GL_MULTISAMPLE_ARB); //some NVidia cards have problems making consistent transparency when multisampling enabled
end;


procedure ShowNodes (lCLUTrec: TCLUTrec; var C: TChart2d; Tex: TTexture);
const
 kGridThick = 1;
 kThick = 4;
 ngrid = 4;
var
  nsz,nsz2,x,y: single;
  Cx: TChart2d;
  i: integer;
begin

  if lCLUTrec.numnodes < 2 then
    exit;
  glPushMatrix; //?? save pixelspace scale
  glTranslatef(C.Left,C.Bottom,0.0);//pixelspace space
  //glScalef(C.Width,C.Height,0);//scaled...
  glDisable(GL_DEPTH_TEST);


   {$IFNDEF USETRANSFERTEXTURE}
  x := abs(Tex.WindowScaledMax-Tex.WindowScaledMin);//range
  if x = 0 then x := 1; //aoid divide by zero
  nsz := (lCLUTrec.min-Tex.WindowScaledMin)/x*C.Width;
  nsz2 := (lCLUTrec.max-Tex.WindowScaledMin)/x*C.Width;
  SetColor(C.rgba);
  glLineWidth(1);
  glBegin(GL_LINES);
    glVertex3f (0, 0, 0);
    glVertex3f (nsz, -30, 0);
    glVertex3f (256, 0, 0);
    glVertex3f (nsz2, -30, 0);

  glEnd;
  {$ENDIF}
    nsz := kThick+(2*kGridThick);//0.02*C.Width;
  nsz2 := kThick;//0.01 * C.Width;
  //dark background
  SetColor(C.backcolor);//glColor4f(0,0,0,0.2);
  glBegin (GL_QUADS);
        glVertex3f (0, 0, 0);
        glVertex3f (C.Width, 0, 0);
        glVertex3f (C.Width, C.Height, 0);
        glVertex3f (0, C.Height, 0);
  glEnd;

  //draw histogram
  SetColor(C.historgba);
  ShowHistogram(Tex.WindowHisto,C);


  //frame
  //glBlendFunc (GL_SRC_ALPHA, GL_ONE);//additive with colors beneath, does not look good with bright background
  glLineWidth(kGridThick);
  SetColor(C.rgba);
  glBegin (GL_LINE_STRIP);
        //glColor4f (1, 1, 1,1);
        glVertex3f (0, 0, 0);
        glVertex3f (0, C.Height, 0);
        glVertex3f (C.Width, C.Height, 0);
        glVertex3f (C.Width, 0, 0);
        //glVertex3f (0, 0, 0);
  glEnd;
  //grid
  SetColor(C.rgba);
  if ngrid > 0 then begin
    for i := 1 to ngrid do begin
      x := C.Width* i/(ngrid+1);
      glBegin (GL_LINES);
        glVertex3f (x, 0, 0);
        glVertex3f (x, C.Height, 0);
        glVertex3f (0, x, 0);
        glVertex3f (C.Width, x, 0);
      glEnd;
    end;
  end;


  //glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);//if historgram was additive, return to standard mode

  //vertical bar
  glBegin (GL_QUADS);
        SetColorA(C.rgba,0);
        glVertex3f (C.Width, 0, 0);
        glVertex3f (C.Width*1.05, 0, 0);
        SetColorA(C.rgba,255);
        glVertex3f (C.Width*1.05, C.Height, 0);
        glVertex3f (C.Width, C.Height, 0);
  glEnd;
  //horizontal bar
  glBegin (GL_QUADS);
        glColor4f(0,0,0,1);
        glVertex3f (0, 0, 0);
        glVertex3f (0, C.Height*-0.05, 0);
        glColor4f(1,1,1,1);
        glVertex3f (C.Width, C.Height*-0.05, 0);
        glVertex3f (C.Width, 0, 0);
  glEnd;
  //lines between nodes
  SetColor(C.rgba);
  glLineWidth(kThick*2);
  glBegin (GL_LINE_STRIP);
  for i := 0 to (lCLUTrec.numnodes-1) do begin
      x := C.Width*lCLUTrec.nodes[i].intensity/255;
      y  :=  C.Height * lCLUTrec.nodes[i].rgba.rgbReserved/255;
      //glColor4f (x, x, x,0.7);
      glVertex3f (x, y, 0);
    end;
  glEnd;
  //now with node colors... inset
  glLineWidth(kThick);
  glBegin (GL_LINE_STRIP);
  for i := 0 to (lCLUTrec.numnodes-1) do begin
      SetColorOpaque(lCLUTrec.nodes[i].rgba);
      x := C.Width* lCLUTrec.nodes[i].intensity/255;
      y  := C.Height* lCLUTrec.nodes[i].rgba.rgbReserved/255;
      //glColor4f (x, x, x,0.7);
      glVertex3f (x, y, 0);
    end;
  glEnd;
  //nodes
  for i := 0 to (lCLUTrec.numnodes-1) do begin
      x := C.Width*lCLUTrec.nodes[i].intensity/255;
      y  :=  C.Height* lCLUTrec.nodes[i].rgba.rgbReserved/255;
      glBegin (GL_QUADS);
        //node borders
        SetColor(C.rgba);
        glVertex3f (x-nsz, y-nsz, 0);
        glVertex3f (x-nsz, y+nsz, 0);
        glVertex3f (x+nsz, y+nsz, 0);
        glVertex3f (x+nsz, y-nsz, 0);
      glEnd;
      //node centers
      glBegin (GL_QUADS);
        SetColorOpaque(lCLUTrec.nodes[i].rgba);
        glVertex3f (x-nsz2, y-nsz2, 0);
        glVertex3f (x-nsz2, y+nsz2, 0);
        glVertex3f (x+nsz2, y+nsz2, 0);
        glVertex3f (x+nsz2, y-nsz2, 0);
      glEnd;
    end;
    glLineWidth(1);
 {$IFNDEF USETRANSFERTEXTURE}
glTranslatef(0,-100,0.0);
  Cx := C;
  Cx.Height := 70;
  x := abs(Tex.WindowScaledMax-Tex.WindowScaledMin);//range
  if x = 0 then x := 1; //aoid divide by zero
  nsz := (lCLUTrec.min-Tex.WindowScaledMin)/x*Cx.Width;
  nsz2 := (lCLUTrec.max-Tex.WindowScaledMin)/x*Cx.Width;
  SetColor(Cx.rgba);

  glBegin (GL_QUADS);
        glVertex3f (nsz, -2, 0);
        glVertex3f (nsz, Cx.Height, 0);
        glVertex3f (nsz2, Cx.Height, 0);
        glVertex3f (nsz2, -2, 0);
        //glVertex3f (nsz, 0, 0);
  glEnd;
    SetColor(Cx.historgba);
    ShowHistogram(Tex.UnscaledHisto,Cx);
    glPopMatrix;
   {$ENDIF}
end;

procedure DrawNodes(WINDOW_HEIGHT,WINDOW_WIDTH: integer; Tex: TTexture; var lPrefs: TPrefs);
var
  C: TChart2d;
begin
  glMatrixMode (GL_PROJECTION);
  glLoadIdentity ();
  gluOrtho2D (0, WINDOW_WIDTH,0, WINDOW_HEIGHT);
  glEnable (GL_BLEND); //blend transparency bar with background
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  C.rgba := lPrefs.GridAndBorder; //RGBA(96,96,128,196);
  C.historgba := lPrefs.HistogramColor;// RGBA(96,48,96,196);
  C.backcolor := lPrefs.HistogramBack;
  C.Left := 1;
  C.Bottom := WINDOW_HEIGHT-257;
  C.Height := 256;
  C.Width := 256;
  ShowNodes(gCLUTrec,C, Tex);


end;

end.

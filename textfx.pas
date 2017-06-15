unit textfx;
{$include opts.inc}
interface
uses
   {$IFDEF DGL} dglOpenGL, {$ELSE DGL} {$IFDEF COREGL} glcorearb, {$ELSE} gl, {$ENDIF}  {$ENDIF DGL}
	 define_types;
{$IFNDEF COREGL} //coregl uses slices2D
procedure TextArrow (X,Y,Sz: single; NumStr: string; orient: integer;FontColor,ArrowColor: TGLRGBQuad);
procedure StartDraw2D;
procedure EndDraw2D;
{$ENDIF}
procedure Enter2D;

implementation
uses {$IFDEF COREGL} raycast_core, gl_core_matrix, {$ELSE} raycast_legacy, {$ENDIF} raycast_common;
//uses SysUtils,classes, raycastglsl, mainunit;
{$IFNDEF COREGL}
procedure StartDraw2D;
begin
     //core only
end;

procedure EndDraw2D;
begin
  //core only
end;
{$ENDIF}

procedure Enter2D;
begin
  {$IFDEF COREGL}
  nglMatrixMode(nGL_PROJECTION);
  nglLoadIdentity;
  nglOrtho(0, gRayCast.WINDOW_WIDTH, 0, gRayCast.WINDOW_HEIGHT,-1,1);//<- same effect as previous line
  nglMatrixMode(nGL_MODELVIEW);
  nglLoadIdentity;
  {$ELSE}
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, gRayCast.WINDOW_WIDTH, 0, gRayCast.WINDOW_HEIGHT,-1,1);//<- same effect as previous line
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  {$ENDIF}
  glDisable(GL_DEPTH_TEST);
end;

{$IFNDEF COREGL}
procedure Ndec;
begin
  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(0,0);
    glVertex2f(2,0);
    glVertex2f(0,2);
    glVertex2f(2,2);
    glEnd();
end;

procedure N0;
begin
  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(2,2);
    glVertex2f(0,12);
    glVertex2f(0,2);
     glVertex2f(2,12);
    glVertex2f(2,0);
    glVertex2f(2,2);
    glVertex2f(7,0);
    glVertex2f(7,2);
    glVertex2f(9,2);
    glVertex2f(7,12);
    glVertex2f(9,12);
    glVertex2f(7,14);
    glVertex2f(2,12);
    glVertex2f(2,14);
    glVertex2f(0,12);
    glEnd();
end;

procedure N1;
begin
  glBegin(GL_TRIANGLE_STRIP);
  glVertex2f(0,12);
    glVertex2f(2,14);
    glVertex2f(2,12);
    glVertex2f(4,14);
    glVertex2f(2,0);
    glVertex2f(4,0);

    (*glVertex2f(0,11);
      glVertex2f(3,14);
      glVertex2f(3,11);
      glVertex2f(5,14);
      glVertex2f(3,0);
      glVertex2f(5,0);*)
    glEnd();
end;

procedure N2;
begin
  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(9,2);
    glVertex2f(9,0);
    glVertex2f(2,2);
    glVertex2f(0,0);
    glVertex2f(2,8);
    glVertex2f(0,6);
    glVertex2f(2,8);
    glVertex2f(9,8);
    glVertex2f(0,6);
    glVertex2f(7,6);
    glVertex2f(9,8);
    glVertex2f(7,14);
    glVertex2f(9,12);
    glVertex2f(2,14);
    glVertex2f(2,12);
    glVertex2f(0,12);
    glVertex2f(2,11);
    glVertex2f(0,11);
    glEnd();
end;

procedure N3;
begin
  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(2,2);
    glVertex2f(0,4);
    glVertex2f(0,2);
     glVertex2f(2,4);
    glVertex2f(2,0);
    glVertex2f(2,2);
    glVertex2f(7,0);
    glVertex2f(7,2);
    glVertex2f(9,2);
    glVertex2f(7,6);
    glVertex2f(9,6);
    glVertex2f(8,7);
    glVertex2f(2,6);
    glVertex2f(2,8);
    glVertex2f(7,8);
    glVertex2f(7,6);
    glVertex2f(9,8);
    glVertex2f(7,14);
    glVertex2f(9,12);
    glVertex2f(2,14);
    glVertex2f(2,12);
    glVertex2f(0,12);
    glVertex2f(2,11);
    glVertex2f(0,11);
  glEnd();
end;

procedure N4;
begin
  glBegin(GL_TRIANGLE_STRIP);
  glVertex2f(0,14);
  glVertex2f(2,14);
  glVertex2f(0,8);
  glVertex2f(2,8);
  //glVertex2f(2,6);
  glVertex2f(0,6);
  glVertex2f(9,8);
  glVertex2f(9,6);
  glVertex2f(9,14);
  glVertex2f(9,0);
  glVertex2f(7,14);
  glVertex2f(7,0);
  glEnd();
end;

procedure N5;
begin
  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(9,12);
    glVertex2f(9,14);
    glVertex2f(2,12);
    glVertex2f(0,14);
    glVertex2f(2,7);
    glVertex2f(0,9);
    glVertex2f(2,7);
    glVertex2f(9,7);
    glVertex2f(0,9);
    glVertex2f(7,9);
    glVertex2f(9,7);
    glVertex2f(7,0);
    glVertex2f(9,2);
    glVertex2f(2,0);
    glVertex2f(2,2);
    glVertex2f(0,2);
    glVertex2f(2,4);
    glVertex2f(0,4);
    glEnd();
end;

procedure N6;
begin

      glBegin(GL_TRIANGLE_STRIP);
  glVertex2f(7,12);
  glVertex2f(9,11);
  glVertex2f(9,12);
   glVertex2f(7,11);
  glVertex2f(7,14);
  glVertex2f(7,12);
  glVertex2f(2,14);
  glVertex2f(2,12);
  glVertex2f(0,12);
  glVertex2f(2,9);
  glVertex2f(0,9);
  glVertex2f(0,7);
  glVertex2f(7,9);
  glVertex2f(7,7);
  glVertex2f(2,7);
  glVertex2f(2,9);
  glVertex2f(0,7);
  glVertex2f(2,0);
  glVertex2f(0,2);
  glVertex2f(7,0);
  glVertex2f(7,2);
  glVertex2f(9,2);
  glVertex2f(7,7);
  glVertex2f(9,7);
  glVertex2f(7,9);
  glEnd();
end;

procedure N7;
begin
  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(0,11);
    glVertex2f(0,14);
    glVertex2f(2,11);
    glVertex2f(2,12);
    glVertex2f(0,14);
    glVertex2f(9,14);
    glVertex2f(2,12);
    glVertex2f(9,12);
    glVertex2f(7,12);
    glVertex2f(4,0);
    glVertex2f(2,0);
  glEnd();
end;


procedure N8;
begin
  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(2,2);
    glVertex2f(0,6);
    glVertex2f(0,2);
     glVertex2f(2,6);
    glVertex2f(2,0);
    glVertex2f(2,2);
    glVertex2f(7,0);
    glVertex2f(7,2);
    glVertex2f(9,2);
    glVertex2f(7,6);
    glVertex2f(9,6);
    glVertex2f(8,7);
    glVertex2f(2,6);
    glVertex2f(2,8);
    glVertex2f(7,8);
    glVertex2f(7,6);
    glVertex2f(9,8);
    glVertex2f(7,14);
    glVertex2f(9,12);
    glVertex2f(2,14);
    glVertex2f(2,12);
    glVertex2f(0,12);
    glVertex2f(2,8);
    glVertex2f(0,8);
    glVertex2f(1,7);
    glVertex2f(2,8);
    glVertex2f(2,6);
    glVertex2f(0,6);
  glEnd();
end;

procedure Nminus;
begin
  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(0,7);
    glVertex2f(0,9);
    glVertex2f(4,7);
    glVertex2f(4,9);
  glEnd;
end;

procedure N9;
begin
  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(2,2);
    glVertex2f(0,4);
    glVertex2f(0,2);
     glVertex2f(2,4);
    glVertex2f(2,0);
    glVertex2f(2,2);
    glVertex2f(7,0);
    glVertex2f(7,2);
    glVertex2f(9,2);
    glVertex2f(7,6);
    glVertex2f(9,6);
    glVertex2f(9,8);
    glVertex2f(2,6);
    glVertex2f(2,8);
    glVertex2f(7,8);
    glVertex2f(7,6);
    glVertex2f(9,8);
    glVertex2f(7,14);
    glVertex2f(9,12);
    glVertex2f(2,14);
    glVertex2f(2,12);
    glVertex2f(0,12);
    glVertex2f(2,8);
    glVertex2f(0,8);
    glVertex2f(2,6);
  glEnd();
end;

function PrintHt (Sz: single): single;
begin
  result := Sz * 14;//14-pixel tall font
end;

function PrintWid (Sz: single; NumStr: string): single;
var
  i,c: integer;
begin
  result := 0;
  if length(NumStr) < 1 then
    exit;
  for i := 1 to length(NUmStr) do begin
    c := ord(NumStr[i])-48;//ascii '0'..'9' = 48..58
    if (c = -2) or (c = -4) then // '.' or ','
      result := result + 4
    else if c = 1 then   // '1' is not as wide...
      result := result + 6
    else if (c = -3) then  //'-'
      result := result + 6
    else if (c >=0) and (c < 10) then
      result := result + 10;
  end;
  if result < 1 then
    exit;
  result := result -1;//gap between characters
  result := result * sz;
end;

procedure PrintXY (X,Y,Sz: single; NumStr: string;FontColor: TGLRGBQuad);
//draws numerical strong with 18-pixel tall characters. If Sz=2.0 then characters are 36-pixel tall
//Unless you use multisampling, fractional sizes will not look good...
var
  i,c: integer;
begin
  if length(NumStr) < 1 then
    exit;
  x := round(x); y := round(y);
  glLoadIdentity();
  glTranslatef(x,y,0.0); //pixelspace space
  glScalef(Sz ,Sz,0.0);
  glTranslatef(1,0,0.0);//makes a nice border in front, so first and last item effectively have one pixel on outside
  //glColor4f(1,1,1,1);
  glColor4ub (FontColor.rgbRed, FontColor.rgbGreen, FontColor.rgbBlue,FontColor.rgbReserved);
  for i := 1 to length(NUmStr) do begin
    c := ord(NumStr[i])-48;//ascii '0'..'9' = 48..58
    case c of
      -4,-2: Ndec;//'.'or''
      -3: Nminus;
      0: N0;
      1: N1;
      2: N2;
      3: N3;
      4: N4;
      5: N5;
      6: N6;
      7: N7;
      8: N8;
      9: N9;
      else exit;
    end;
    if (c= -4) or (c = -2) then
      glTranslatef(4,0,0.0)
    else if (c = 1)  then
      glTranslatef(6,0,0.0)
    else if  (c = -3) then
      glTranslatef(6,0,0.0)
    else
      glTranslatef(10,0,0.0);
  end;
end;

procedure glVertex2fx (x,y: single);
begin
  glVertex2f(round(x), round(y));
end;

procedure TextArrow (X,Y,Sz: single; NumStr: string; orient: integer; FontColor,ArrowColor: TGLRGBQuad);
//orient code 1=left,2=top,3=right,4=bottom
var
  lW,lH,lW2,lH2,T: single;
begin
  if NumStr = '' then exit;
  glLoadIdentity();
  lH := PrintHt(Sz);
  lH2 := (lH/2);
  lW := PrintWid(Sz,NumStr);
  lW2 := (lW/2);
  glColor4ub (ArrowColor.rgbRed, ArrowColor.rgbGreen, ArrowColor.rgbBlue,ArrowColor.rgbReserved);
  case Orient of
    1: begin
      glBegin(GL_TRIANGLE_STRIP);
        glVertex2fx(X-lH2-lW-2*Sz,Y+LH2+Sz);
        glVertex2fx(X-lH2-lW-2*Sz,Y-lH2-Sz);
        glVertex2fx(X-lH2,Y+lH2+Sz);
        glVertex2fx(X-lH2,Y-lH2-Sz);
        glVertex2fx(X,Y);
      glEnd;
      PrintXY (X-lW-lH2-1.5*Sz,Y-lH2,Sz, NumStr,FontColor);
    end;
    3: begin
      glBegin(GL_TRIANGLE_STRIP);
        glVertex2fx(X+lH2+lW+2*Sz,Y+LH2+Sz);
        glVertex2fx(X+lH2+lW+2*Sz,Y-lH2-Sz);
        glVertex2fx(X+lH2,Y+lH2+Sz);
        glVertex2fx(X+lH2,Y-lH2-Sz);
        glVertex2fx(X,Y);
      glEnd;
      PrintXY (X+lH2,Y-lH2,Sz, NumStr,FontColor);
    end;
    4: begin //bottom
    glBegin(GL_TRIANGLE_STRIP);
      glVertex2fx(X-lW2-Sz,Y-LH-lH2-2*Sz);//-
      glVertex2fx(X-lW2-Sz,Y-lH2);
      glVertex2fx(X+lW2+Sz,Y-LH-lH2-2*Sz);//-
      glVertex2fx(X+lW2+Sz,Y-lH2);
      glVertex2fx(X-lW2-Sz,Y-lH2);
      glVertex2fx(X,Y);
    glEnd;
    PrintXY (X-lW2-Sz,Y-lH-LH2,Sz, NumStr,FontColor);
    end;
    else  begin
      if Orient = 5 then
        T := Y-LH-Sz-lH2
      else
        T := Y;
    glBegin(GL_TRIANGLE_STRIP);
      glVertex2fx(X-lW2-Sz,T+LH+2*Sz+lH2);
      glVertex2fx(X-lW2-Sz,T+lH2);
      glVertex2fx(X+lW2+Sz,T+LH+2*Sz+lH2);
      glVertex2fx(X+lW2+Sz,T+lH2);
      glVertex2fx(X-lW2-Sz,T+lH2);
      glVertex2fx(X,T);
    glEnd;
    PrintXY (X-lW2-Sz,T+lH2+Sz,Sz, NumStr,FontColor);
    end;
  end;//case
      //GLForm1.caption := floattostr(Sz);
end;

{$ENDIF COREGL}

end.

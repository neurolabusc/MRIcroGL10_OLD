unit textfx;
{$include opts.inc}
interface
uses {$IFDEF DGL} dglOpenGL, {$ELSE} gl, glext, {$ENDIF}  define_types;

procedure TextArrow (X,Y,Sz: single; NumStr: string; orient: integer;FontColor,ArrowColor: TGLRGBQuad);
procedure Enter2D;

implementation
uses {$IFDEF COREGL} raycast_core, {$ELSE} raycast_legacy, {$ENDIF} raycast_common;
//uses SysUtils,classes, raycastglsl, mainunit;

procedure Enter2D;
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glOrtho(0, gRayCast.WINDOW_WIDTH, 0, gRayCast.WINDOW_HEIGHT,-1,1);//<- same effect as previous line
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glDisable(GL_DEPTH_TEST);
end;


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
    glVertex2f(2,0);
    glVertex2f(2,12);
    glVertex2f(4,0);
    glVertex2f(4,12);
    glVertex2f(2,14);
    glVertex2f(2,12);
    glVertex2f(0,14);
    glVertex2f(0,12);
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
  glVertex2f(0,7.5);
  glVertex2f(2,7.5);
  glVertex2f(2,5.5);
  glVertex2f(9,7.5);
  glVertex2f(9,5.5);
  glVertex2f(9,14);
  glVertex2f(9,0);
  glVertex2f(7,14);
  glVertex2f(7,0);
  glEnd();
(*  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(0,14);
    glVertex2f(2,14);
    glVertex2f(0,8);
    glVertex2f(2,8);
    glVertex2f(2,6);
    glVertex2f(9,8);
    glVertex2f(9,6);
    glVertex2f(9,14);
    glVertex2f(9,0);
    glVertex2f(7,14);
    glVertex2f(7,0);
  glEnd();*)
end;

procedure N5;
begin
  glBegin(GL_TRIANGLE_STRIP);
    glVertex2f(9,12);
    glVertex2f(9,14);
    glVertex2f(2,12);
    glVertex2f(0,14);
    glVertex2f(2,6.5);
    glVertex2f(0,8.5);
    glVertex2f(2,6.5);
    glVertex2f(9,6.5);
    glVertex2f(0,8.5);
    glVertex2f(7,8.5);
    glVertex2f(9,6.5);
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
    glVertex2f(2,8.5);
    glVertex2f(0,8.5);
    glVertex2f(0,6.5);
    glVertex2f(7,8.5);
    glVertex2f(7,6.5);
    glVertex2f(2,6.5);
    glVertex2f(2,8.5);
    glVertex2f(0,6.5);
    glVertex2f(2,0);
    glVertex2f(0,2);
    glVertex2f(7,0);
    glVertex2f(7,2);
    glVertex2f(9,2);
    glVertex2f(7,6);
    glVertex2f(9,6);
    glVertex2f(7,8);
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
    else if (c = 1) or (c = -3) then
      glTranslatef(6,0,0.0)
    else
      glTranslatef(10,0,0.0);
  end;
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
        glVertex2f(X-lH2-lW-2*Sz,Y+LH2+Sz);
        glVertex2f(X-lH2-lW-2*Sz,Y-lH2-Sz);
        glVertex2f(X-lH2,Y+lH2+Sz);
        glVertex2f(X-lH2,Y-lH2-Sz);
        glVertex2f(X,Y);
      glEnd;
      PrintXY (X-lW-lH2-1.5*Sz,Y-lH2,Sz, NumStr,FontColor);
    end;
    3: begin
      glBegin(GL_TRIANGLE_STRIP);
        glVertex2f(X+lH2+lW+2*Sz,Y+LH2+Sz);
        glVertex2f(X+lH2+lW+2*Sz,Y-lH2-Sz);
        glVertex2f(X+lH2,Y+lH2+Sz);
        glVertex2f(X+lH2,Y-lH2-Sz);
        glVertex2f(X,Y);
      glEnd;
      PrintXY (X+lH2,Y-lH2,Sz, NumStr,FontColor);
    end;
    4: begin //bottom
    glBegin(GL_TRIANGLE_STRIP);
      glVertex2f(X-lW2-Sz,Y-LH-lH2-2*Sz);//-
      glVertex2f(X-lW2-Sz,Y-lH2);
      glVertex2f(X+lW2+Sz,Y-LH-lH2-2*Sz);//-
      glVertex2f(X+lW2+Sz,Y-lH2);
      glVertex2f(X-lW2-Sz,Y-lH2);
      glVertex2f(X,Y);
    glEnd;
    PrintXY (X-lW2-Sz,Y-lH-LH2,Sz, NumStr,FontColor);
    end;
    else  begin
      if Orient = 5 then
        T := Y-LH-Sz-lH2
      else
        T := Y;
    glBegin(GL_TRIANGLE_STRIP);
      glVertex2f(X-lW2-Sz,T+LH+2*Sz+lH2);
      glVertex2f(X-lW2-Sz,T+lH2);
      glVertex2f(X+lW2+Sz,T+LH+2*Sz+lH2);
      glVertex2f(X+lW2+Sz,T+lH2);
      glVertex2f(X-lW2-Sz,T+lH2);
      glVertex2f(X,T);
    glEnd;

    PrintXY (X-lW2-Sz,T+lH2+Sz,Sz, NumStr,FontColor);
    end;
  end;//case
      //GLForm1.caption := floattostr(Sz);
end;

end.

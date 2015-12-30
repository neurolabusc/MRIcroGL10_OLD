unit colorbar2d;
{$D-,L-,O+,Q-,R-,Y-,S-}
interface
{$include options.inc}
uses
{$IFDEF DGL} dglOpenGL, {$ELSE} gl, glext, {$ENDIF}
define_types,  textfx,prefs, clut, math;

procedure DrawCLUT ( lU: TUnitRect;lBorder: single; lPrefs: TPrefs);
function ColorBarPos(var  lU: TUnitRect): integer;

implementation
uses raycastglsl, mainunit,sysutils;

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
    glLoadIdentity();
end; //DrawColorBarText

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

procedure DrawCLUTx (var lCLUT: TCLUTrec; lU: TUnitRect;lPrefs: TPrefs);
var
  lL,lT,lR,lB,lN: single;
  lI: integer;
begin
  if lCLUT.numnodes < 2 then
    exit;
  SetOrder(lU.L,lU.R,lL,lR);
  SetOrder(lU.T,lU.B,lT,lB);
  lL := lL*gRayCast.WINDOW_WIDTH;
  lR := lR*gRayCast.WINDOW_WIDTH;
  lT := lT*gRayCast.WINDOW_HEIGHT;
  lB := lB*gRayCast.WINDOW_HEIGHT;
  if (lR-lL) > (lB-lT) then begin
    lN := (lCLUT.nodes[0].intensity/255 * (lR-lL))+lL;
    glBegin(GL_TRIANGLE_STRIP);
     glColor4ub (lCLUT.nodes[0].rgba.rgbRed, lCLUT.nodes[0].rgba.rgbgreen,lCLUT.nodes[0].rgba.rgbblue,255);
     glVertex2f(lN,lT);
     glVertex2f(lN,lB);
     for lI := 1 to (255) do begin
        lN := (lCLUT.nodes[lI].intensity/255 * (lR-lL))+lL;
        glColor4ub (lCLUT.nodes[lI].rgba.rgbRed, lCLUT.nodes[lI].rgba.rgbgreen,lCLUT.nodes[lI].rgba.rgbblue,255);
        glVertex2f(lN,lT);
        glVertex2f(lN,lB);
     end;
    glEnd;//STRIP
  end else begin //If WIDE, else TALL
    lN := (lCLUT.nodes[0].intensity/255 * (lB-lT))+lT;
    glBegin(GL_TRIANGLE_STRIP);
     glColor4ub (lCLUT.nodes[0].rgba.rgbRed, lCLUT.nodes[0].rgba.rgbgreen,lCLUT.nodes[0].rgba.rgbblue,255);
     glVertex2f(lL, lN);
     glVertex2f(lR, lN);
     for lI := 1 to (255) do begin
        lN := (lCLUT.nodes[lI].intensity/255 * (lB-lT))+lT;
        glColor4ub (lCLUT.nodes[lI].rgba.rgbRed, lCLUT.nodes[lI].rgba.rgbgreen,lCLUT.nodes[lI].rgba.rgbblue,255);
         glVertex2f(lR, lN);
         glVertex2f(lL, lN);
     end;
    glEnd;//STRIP
  end;
end;

procedure DrawBorder (var lU: TUnitRect;lBorder: single; lPrefs: TPrefs);
var
    lL,lT,lR,lB: single;
begin
  if lBorder <= 0 then
    exit;
  SetOrder(lU.L,lU.R,lL,lR);
  SetOrder(lU.T,lU.B,lT,lB);
  glColor4ub(lPrefs.GridAndBorder.rgbRed,lPrefs.GridAndBorder.rgbGreen,lPrefs.GridAndBorder.rgbBlue,lPrefs.GridAndBorder.rgbReserved);
  glBegin(GL_TRIANGLE_STRIP);
      glVertex2f((lL-lBorder)*gRayCast.WINDOW_WIDTH,(lB+lBorder)*gRayCast.WINDOW_HEIGHT);
      glVertex2f((lL-lBorder)*gRayCast.WINDOW_WIDTH,(lT-lBorder)*gRayCast.WINDOW_HEIGHT);
      glVertex2f((lR+lBorder)*gRayCast.WINDOW_WIDTH,(lB+lBorder)*gRayCast.WINDOW_HEIGHT);
      glVertex2f((lR+lBorder)*gRayCast.WINDOW_WIDTH,(lT-lBorder)*gRayCast.WINDOW_HEIGHT);
    glEnd;//In theory, a bit faster than GL_POLYGON
end;

function BarIndex (lBarNumber: integer; IsHorzBottom: boolean): integer;
begin
  {$IFDEF ENABLEOVERLAY}
  if IsHorzBottom then
    result := gOpenOverlays - lBarNumber +1
  else
  {$ENDIF}
    result := lBarNumber;
end;//nested BarIndex

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

procedure DrawCLUT ( lU: TUnitRect;lBorder: single; lPrefs: TPrefs);
var
  lU2:TUnitRect;
  lX,lY,lMin,lMax: single;
  lIsHorzTop: boolean;
  lIx,lI: integer;
begin
  lIsHorzTop := false;
  Enter2D;
  glEnable (GL_BLEND);//allow border to be translucent
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
{$IFDEF ENABLEOVERLAY}
  if gOpenOverlays < 1 then begin
{$ELSE}
  if true then begin
{$ENDIF}
    DrawBorder(lU,lBorder,lPrefs);
    DrawCLUTx(gCLUTrec,lU,lPrefs);
    if lPrefs.ColorbarText then
      DrawColorBarText(gCLUTrec.min,gCLUTrec.max, lU,lBorder,lPrefs);
    glDisable (GL_BLEND);
    exit;
  end;

  {$IFDEF ENABLEOVERLAY}
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
  if gOpenOverlays > 1 then begin
    for lI := 2 to gOpenOverlays do begin
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
  for lI := 1 to gOpenOverlays do begin
    DrawCLUTx(gOverlayCLUTrec[BarIndex(lI,lIsHorzTop)],lU2,lPrefs);
    UOffset(lU2,lX,lY);
  end;
  if not lPrefs.ColorbarText then
    exit;
  lU2 := lU;
  for lIx := 1 to gOpenOverlays do begin
    lI := BarIndex(lIx,lIsHorzTop);
    lMin := gOverlayImg[lI].WindowScaledMin;
    lMax := gOverlayImg[lI].WindowScaledMax;
    SortSingle(lMin,lMax);
    if gOverlayImg[lI].LutFromZero then
      SetLutFromZero(lMin,lMax);
    DrawColorBarText(lMin,lMax, lU2,lBorder,lPrefs);
    UOffset(lU2,lX,lY);
  end;
{$ENDIF}
glDisable (GL_BLEND);
end;

end.
 

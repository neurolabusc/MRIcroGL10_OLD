unit slices2d;
interface
{$include opts.inc}
uses
 {$IFDEF DGL} dglOpenGL, {$ELSE DGL} {$IFDEF COREGL}glcorearb, {$ELSE} gl, glext, {$ENDIF}  {$ENDIF DGL}
{$IFDEF USETRANSFERTEXTURE}texture_3d_unit_transfertexture, {$ELSE} texture_3d_unit,{$ENDIF}
   //types,
   graphics, nii_mat, define_types, coordinates, sysutils, textfx, {$IFDEF COREGL} gl_2d, raycast_core, gl_core_matrix, {$ELSE} raycast_legacy, {$ENDIF} raycast_common, drawu;
const
  kMaxMosaicDim = 12; //e.g. if 12 then only able to draw up to 12x12 mosaics [=144 slices]
  kEmptyOrient = 0;
  kAxialOrient = 1;
  kCoronalOrient = 2;
  kSagRightOrient = 3;
  kSagLeftOrient = 4;
procedure MosaicGL ( lMosaicString: string);

procedure DrawOrtho(var lTex: TTexture);
//procedure SetZooms (var lX,lY,lZ: single);
procedure SetZooms (var lX,lY,lZ: single; lTex: TTexture);
procedure MMToFrac(var X,Y,Z: single);
function SliceMM (lSliceFrac: single; lOrient: integer): single;
function FracToSlice (lFrac: single; lSlices : integer): single;
function FracToVox (Xf,Yf,Zf: single; Xdim, Ydim,Zdim: integer): integer;

implementation

uses mainunit;

  //kFontSize = 24;

type
TPointF = record
     X,Y: single;
end;
  TMosaicSingle = array [1..kMaxMosaicDim, 1..kMaxMosaicDim] of single;
  TMosaicPoint = array [1..kMaxMosaicDim, 1..kMaxMosaicDim] of TPointF;
  TMosaicOrient = array [1..kMaxMosaicDim, 1..kMaxMosaicDim] of byte;
  TMosaicText = array [1..kMaxMosaicDim, 1..kMaxMosaicDim] of boolean;
  TMosaic =record
    Slices: TMosaicSingle;
    Dim,Pos: TMosaicPoint;
    Orient: TMosaicOrient;
    Text: TMosaicText;
    HOverlap,VOverlap,MaxWid,MaxHt: single;
    Rows,Cols: integer;
    isMM: boolean;
  end;

function SliceToFrac (lSlice: single; lSlices : integer): single;
//indexed from 1
begin
    result := 0.5;
    if lSlices < 1 then
      exit;
    //result := round(((lFrac+ (1/lSlices))*lSlices));

    result := (lSlice-1)/lSlices;
    //bound in range 0..1
    if result < 0 then
      result := 0;
    if result > 1 then
      result := 1;
end;

function SliceFracF (lSliceMM: single; lOrient: integer; var lInvMat: TMatrix): single;
var
  X,Y,Z: single;

begin
    X := 0;
    Y := 0;
    Z := 0;
    case lOrient of
      kAxialOrient : Z := lSLiceMM;
      kCoronalOrient : Y := lSliceMM;
      kSagRightOrient : X := lSliceMM;
      kSagLeftOrient : X := lSliceMM;
    end;
    mm2Voxel (X,Y,Z, lInvMat);
    //-1 as the values are indexed from zero...
    //X := SliceToFrac(X-1,gTexture3D.FiltDim[1]);
    //Y := SliceToFrac(Y-1,gTexture3D.FiltDim[2]);
    //Z := SliceToFrac(Z-1,gTexture3D.FiltDim[3]);
    case lOrient of
      kAxialOrient : result := SliceToFrac(Z,gTexture3D.FiltDim[3]);
      kCoronalOrient : result := SliceToFrac(Y,gTexture3D.FiltDim[2]);
      kSagRightOrient,kSagLeftOrient : result := SliceToFrac(X,gTexture3D.FiltDim[1]);
      else result := 0; //should be impossible - prevents compiler warning
    end;
end; //SliceMM

procedure MMToFrac(var X,Y,Z: single);
var
  lOK: boolean;
  lInvMat: TMatrix;
begin
    lInvMat := Hdr2InvMat (gTexture3D.NIftiHdr,lOK);
    mm2Voxel (X,Y,Z, lInvMat);
    SliceToFrac(X,gTexture3D.FiltDim[1]);
    SliceToFrac(Y,gTexture3D.FiltDim[2]);
    SliceToFrac(Z,gTexture3D.FiltDim[3]);
end;

procedure StereoTaxicSpaceToFrac (var lMosaic: TMosaic);
var
  lRow,lCol: integer;
  lFrac: boolean;
  lInvMat: TMatrix;
  lOK: boolean;
begin
  if (lMosaic.Cols < 1) or (lMosaic.Rows < 1)  then
    exit;
  if not lMosaic.isMM then begin
     lFrac := true;
     for lRow := 1 to lMosaic.Rows do
         for lCol := 1 to lMosaic.Cols do
         if (lMosaic.Orient[lCol,lRow] <> kEmptyOrient) and ((lMosaic.Slices[lCol,lRow] < 0) or (lMosaic.Slices[lCol,lRow] > 1)) then
            lFrac := false;
     if lFrac then exit;
  end;
  lMosaic.isMM := true;
  lInvMat := Hdr2InvMat (gTexture3D.NIftiHdr,lOK);
  if not lOK then exit;
  for lRow := 1 to lMosaic.Rows do begin
    for lCol := 1 to lMosaic.Cols do begin
      if lMosaic.Orient[lCol,lRow] <> kEmptyOrient then
        lMosaic.Slices[lCol,lRow] := SliceFracF (lMosaic.Slices[lCol,lRow], lMosaic.Orient[lCol,lRow],lInvMat)
    end;//col
  end;//row
end;

function SliceXY(lOrient: integer): TPointF;
begin
  case lOrient of
    kAxialOrient,kCoronalOrient: result.X :=gTexture3D.FiltDim[1];//screen L/R corresponds to X
    kSagRightOrient,kSagLeftOrient: result.X :=gTexture3D.FiltDim[2];//screen L/R corresponds to Y dimension
    else result.X := 0;
  end;//case
  case lOrient of
    kAxialOrient: result.Y := gTexture3D.FiltDim[2];//screen vert is Y
    kCoronalOrient,kSagRightOrient,kSagLeftOrient: result.Y :=gTexture3D.FiltDim[3];//screen vert is Z dimension
    else result.Y := 0;
  end;//case

end;

procedure MosaicSetXY (var lMosaic: TMosaic);
var
  lRow,lCol: integer;
  lMaxY,lX,Hfrac,Vfrac: single;
begin
  if (lMosaic.Cols < 1) or (lMosaic.Rows < 1)  then
    exit;
  for lRow := 1 to lMosaic.Rows do begin
    for lCol := 1 to lMosaic.Cols do begin
      lMosaic.Dim[lCol,lRow] := SliceXY(lMosaic.Orient[lCol,lRow]);
    end;//col
  end;//row
  lMosaic.MaxWid := 0;
  Hfrac := 1 - abs(lMosaic.HOverlap);
  Vfrac := 1 - abs(lMosaic.VOverlap);

  for lRow := lMosaic.Rows downto 1 do begin
    //find max height for this row
    lMaxY := 0;
    if lRow < lMosaic.Rows then begin
      for lCol := 1 to lMosaic.Cols do
        if lMosaic.Dim[lCol,lRow+1].Y > lMaxY then
          lMaxY := lMosaic.Dim[lCol,lRow+1].Y;
      //if lRow < lMosaic.Rows then
        lMaxY := (lMosaic.Pos[1,lRow+1].Y)+  Vfrac* lMaxY;
    end;
    //now...
    lX := 0;
    for lCol := 1 to lMosaic.Cols do begin
      lMosaic.Pos[lCol,lRow].X := lX;
      lMosaic.Pos[lCol,lRow].Y := lMaxY;
      if lCol < lMosaic.Cols then
        lX := lX +  Hfrac*lMosaic.Dim[lCol,lRow].X
      else
        lX := lX +  lMosaic.Dim[lCol,lRow].X;
    end;//for each column
    if lX > lMosaic.MaxWid then
      lMosaic.MaxWid := lX;

  end;//for each row
  lMosaic.MaxHt := (lMosaic.Pos[1,1].Y+lMosaic.Dim[1,1].Y);
end;

(*procedure ReportMosaic (var lMosaic: TMosaic);
var
  lRow,lCol: integer;
  lMaxY,lX: single;
begin
  if (lMosaic.Cols < 1) or (lMosaic.Rows < 1)  then
    exit;
  for lRow := 1 to lMosaic.Rows do
    for lCol := 1 to lMosaic.Cols do
      fx(lRow,lCol,lMosaic.Dim[lCol,lRow].X,lMosaic.Dim[lCol,lRow].Y);
end;   *)
function Str2Mosaic ( lMosaicString: string): TMosaic;
// '0.2 0.4 0.8; 0.9' has 3 columns and 2 rows
// '0.2 0.4; 0.8 0.9' has 2 columns and 2 rows
// '0.2 0.4; 0.8 s 0.5' has 2 columns and 2 rows, with final item a sagittal slice
//INPUTS
// a c s z   --- orientations (axial,coronal, sagittal,sagittal[mirror]
//  numbers, including decimal separator and E (for scientific notation)
//  ;        ---- next row
// v h     ---- vertical and horizontal overlap, e.g. 0 means none, while 0.2 is 20% range is -1..1
//  note v and h must be followed by a number
function S2F (lStr: String): single;//float to string
begin
  try
    result := StrToFloat(lStr);    // Hexadecimal values are not supported
  except
    //report problem here..
    result := 1;
  end;//try ... except
end; //nested S2F
procedure DummyMosaic;
begin
    result.Rows := 2;
    Result.Cols := 2;
    result.Slices[1,1] := 0.2;
    result.Slices[1,2] := 0.4;
    result.Slices[2,1] := 0.6;
    result.Slices[2,2] := 0.8;
end; //nested proc DummyMosaic
var
  lDone: boolean;
  lCh,lCh2: char;
  lNumStr: string;
  lFloat: single;
  lX,lY,lPos,lLen,lCurrentOrient,lCol : integer;
  lCurrentText : boolean;
begin
  result.isMM := false;
  lCurrentOrient := kAxialOrient;
  lCurrentText := false;
  for lX := 1 to kMaxMosaicDim do begin
    for lY := 1 to kMaxMosaicDim do begin
      result.Orient[lX,lY] := kEmptyOrient;
      result.Text[lX,lY] := lCurrentText;
    end;
  end;
  result.HOverlap := 0;
  result.VOverlap := 0;
  result.Cols := 0;
  result.Rows := 0;
  lLen := length(lMosaicString);
  if lLen < 1 then begin
    DummyMosaic;
    exit;
  end;
  lPos := 1;
  lNumStr := '';
  //lFloat := -1;
  lCol := 0;
  result.Rows := 1;
  result.Cols := 0;
  while lPos <= lLen do begin
    lCh := upcase(lMosaicString[lPos]);
    if lCh in ['0'..'9','-', '+','E',DecimalSeparator] then
      lNumStr := lNumStr + lCh;
    if (lPos = lLen) or (not (lCh in ['0'..'9','-', '+','E',DecimalSeparator])) then begin //not number
      //first, read previous nuber
      if lNumStr <> '' then begin
        lCol := lCol + 1;
        result.Slices[lCol,Result.Rows] := S2F(lNumStr);
        //if lMosaic.Slices[lCol,lRows] < 1 then
        //  fx(lMosaic.Slices[lCol,lRows]);
        //showmessage(floattostr(lMosaic.Slices[lCol,lRows])+'  '+lNumStr);
        result.Orient[lCol,result.Rows] := lCurrentOrient;
        result.Text[lCol,result.Rows] := lCurrentText;
      end;//if lNumStr <> ''
      lNumStr := '';
      //next - see if this is some other command, else whitespace
      if lCh = 'A' then
        lCurrentOrient := kAxialOrient;
      if lCh = 'C' then
        lCurrentOrient := kCoronalOrient;
      if lCh = 'S' then
        lCurrentOrient := kSagRightOrient;
      if lCh = 'Z' then
        lCurrentOrient := kSagLeftOrient;
      if lCh = 'M' then
         result.isMM := true;
      if lCh = 'L' then begin
        lCurrentText := True;

        if (lPos < lLen) and (lMosaicString[lPos+1] = '-') then begin
          lCurrentText := False;
          inc(lPos);
        end else if (lPos < lLen) and (lMosaicString[lPos+1] = '+') then
          inc(lPos);


      end;
      if (lCh = 'V') or (lCh = 'H') then begin
        lDone := false;
        repeat
          lCh2 := upcase(lMosaicString[lPos]);
          if lCh2 in ['0'..'9','-', '+','E',DecimalSeparator] then
            lNumStr := lNumStr + lCh2
          else if lNumStr <> '' then begin
            lDone := true;
            dec(lPos);
          end;
          inc(lPos)
        until (lPos > lLen) or lDone;
        lFloat := S2F(lNumStr);
        if (lFloat > 1) or (lFloat < -1) then
          lFloat := 0;
        if lCh = 'V' then
          result.VOverlap := lFloat
        else
          result.HOverlap := lFloat;
        lNumStr := '';
      end; //V or H ... read overlap
      if lCh = ';' then begin
        result.Rows := result.Rows + 1;
        if lCol > result.Cols then begin
          result.Cols := lCol;
        end;
        lCol := 0;
      end;
    end; //not number
    inc(lPos);//read next character
  end; //for each character in string
  //next - last row may not have a ; so check if final line has most columns...
  if lCol > result.Cols then
    result.Cols := lCol;
  StereoTaxicSpaceToFrac (result);
  MosaicSetXY(result);
  //ReportMosaic(result);
end; //proc ReadMosaicStr

procedure DrawXYTex ( X,Y,W,H: single);
begin
{$IFDEF COREGL}
glUniform4f(glGetUniformLocation(gDraw.glslprogramId, 'XYWH'), X,Y,W,H) ;
DrawSliceGL();

{$ELSE}
glBegin(GL_QUADS);
glTexCoord2f(0, 0);
glVertex2f(X, Y);
glTexCoord2f(1.0, 0);
glVertex2f(X+W, Y);
glTexCoord2f(1.0, 1.0);
glVertex2f(X+W, Y+H);
glTexCoord2f(0, 1.0);
glVertex2f(X, Y+H);
glEnd();
{$ENDIF}
end;

{$IFDEF COREGL}
procedure PrepTexDraw;
var
  mat44: TnMat44;
begin
  //voiOpenGLDraw;
  StartDrawGLSL;
//glDisable (GL_BLEND); //e.g. colorbar can leave blending on
   // glBlendFunc (GL_ONE, GL_ZERO);

  glDisable (GL_BLEND); //e.g. colorbar can leave blending on
  glUniform3f(glGetUniformLocation(gDraw.glslprogramId, pAnsiChar('clearColor')), gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255) ;
  glUniform1ix(gDraw.glslprogramId, 'drawLoaded', gDraw.view3dId );
  mat44 := ngl_ModelViewProjectionMatrix;
  glUniformMatrix4fv(glGetUniformLocation(gDraw.glslprogramId, 'modelViewProjectionMatrix'), 1, GL_FALSE, @mat44[0,0]);
end;

procedure DrawXYCoro ( lX,lY,lW,lH, lSlice: single);
begin
  PrepTexDraw;
  glUniform1ix(gDraw.glslprogramId, 'orientAxCorSag', 2);
  glUniform1fx(gDraw.glslprogramId, 'coordZ', lSlice);
  DrawXYTex(lX,lY,lW,lH);
end;

procedure DrawXYAx ( lX,lY,lW,lH, lSlice: single);
begin
  PrepTexDraw;
  glUniform1ix(gDraw.glslprogramId, 'orientAxCorSag', 1);
  glUniform1fx(gDraw.glslprogramId, 'coordZ', lSlice);
  DrawXYTex(lX,lY,lW,lH);
end;

procedure DrawXYSag ( lX,lY,lW,lH, lSlice: single);
begin
  PrepTexDraw;
  glUniform1ix(gDraw.glslprogramId, 'orientAxCorSag', 3);
  glUniform1fx(gDraw.glslprogramId, 'coordZ', lSlice);
  DrawXYTex(lX,lY,lW,lH);
end;

procedure DrawXYSagMirror ( lX,lY,lW,lH, lSlice: single);
begin
  PrepTexDraw;
  glUniform1ix(gDraw.glslprogramId, 'orientAxCorSag', 4);
  glUniform1fx(gDraw.glslprogramId, 'coordZ', lSlice);
  DrawXYTex(lX,lY,lW,lH);

end;

{$ELSE}
procedure DrawXYCoro ( lX,lY,lW,lH, lSlice: single);
begin
  glBegin(GL_QUADS);
      glTexCoord3d (0, lSlice, 1);
      glVertex2f(lX,lY+lH);
      glTexCoord3d (0,lSlice, 0);
      glVertex2f(lX,lY);
      glTexCoord3d (1,lSlice,0);
      glVertex2f(lX+lW,lY);
      glTexCoord3d (1,lSlice, 1);
      glVertex2f(lX+lW,lY+lH);
  glend;
end;

procedure DrawXYAx ( lX,lY,lW,lH, lSlice: single);
begin
  glBegin(GL_QUADS);
      glTexCoord3d (0, 1, lSlice);
      glVertex2f(lX,lY+lH);
      glTexCoord3d (0,0, lSlice);
      glVertex2f(lX,lY);
      glTexCoord3d (1,0,lSlice);
      glVertex2f(lX+lW,lY);
      glTexCoord3d (1,1, lSlice);
      glVertex2f(lX+LW,lY+lH);
  glend;
end;

procedure DrawXYSag ( lX,lY,lW,lH, lSlice: single);
begin
  glBegin(GL_QUADS);
      glTexCoord3d (lSlice,0,1);
      glVertex2f(lX,lY+lH);
      glTexCoord3d (lSlice,0, 0);
      glVertex2f(lX,lY);
      glTexCoord3d (lSLice, 1, 0);
      glVertex2f(lX+lW,lY);
      glTexCoord3d (lSlice,1, 1);
      glVertex2f(lX+lW,lY+lH);
  glend;
end;

procedure DrawXYSagMirror ( lX,lY,lW,lH, lSlice: single);
begin
  glBegin(GL_QUADS);
      glTexCoord3d (lSlice,0,1);
      glVertex2f(lX+lW,lY+lH);
      glTexCoord3d (lSlice,0, 0);
      glVertex2f(lX+lW,lY);
      glTexCoord3d (lSLice, 1, 0);
      glVertex2f(lX,lY);
      glTexCoord3d (lSlice,1, 1);
      glVertex2f(lX,lY+lH);
  glend;
end;
{$ENDIF}

function FracToVox (Xf,Yf,Zf: single; Xdim, Ydim,Zdim: integer): integer;
var
  X,Y,Z: integer;
begin
     X := round(FracToSlice(Xf,Xdim));
     Y := round(FracToSlice(Yf,Ydim))-1;
     Z := round(FracToSlice(Zf,Zdim))-1;
     //GLForm1.Caption := realtostr(Xf,2)+'x'+ realtostr(Yf,2)+'x'+realtostr(Zf,2)  +'   '+ inttostr(X)+'x'+inttostr(Y+1)+'x'+inttostr(Z+1);
     result := X + (Y * Xdim)  + (Z * Xdim*Ydim);
     if (result > gTexture3D.FiltDim[1]*gTexture3D.FiltDim[2]*gTexture3D.FiltDim[3]) then
        result := 0;
     if result < 1 then
        result := 0;
end;

function FracToSlice (lFrac: single; lSlices : integer): single;
//indexed from 1
begin
    result := round(((lFrac+ (0.5/lSlices))*lSlices)); //e.g. if 6 slices anything greater than 0.167 counted in slice 2
    //result := round(lFrac*lSlices);
    if result > lSLices then //e.g. if lFrac = 1.0, then result is lSlices+1!
      result := lSlices;
    if result < 1 then //This is impossible if lFrac is 0..1, but just in case...
      result := 1;
end;

function SliceMM (lSliceFrac: single; lOrient: integer): single;
var
  X,Y,Z: single;
begin
    X := 0.5;
    Y := 0.5;
    Z := 0.5;
    case lOrient of
      kAxialOrient : Z := lSLiceFrac;
      kCoronalOrient : Y := lSliceFrac;
      kSagRightOrient : X := lSliceFrac;
      kSagLeftOrient : X := lSliceFrac;
    end;
    X := FracToSlice(X,gTexture3D.FiltDim[1]);
    Y := FracToSlice(Y,gTexture3D.FiltDim[2]);
    Z := FracToSlice(Z,gTexture3D.FiltDim[3]);
    Voxel2mm(X,Y,Z,gTexture3D.NIfTIHdr);
    case lOrient of
      kAxialOrient : result := Z;
      kCoronalOrient : result := Y;
      kSagRightOrient,kSagLeftOrient : result := X;
      else result := 0; //should be impossible - prevents compiler warning
    end;
end; //SliceMM

procedure TextLabelXY(X,Y,lSlice: single; lOrient,lDec: integer);
var
  lF: single;
  lS: string;
begin
     lF := SliceMM (lSlice, lOrient);
     if lDec = 0 then
        lF := round(lF);
    lS := realtostr(lF,lDec);
    TextArrow (X,Y,1, lS, 5,gPrefs.TextColor, gPrefs.TextBorder);
end;

function ComputeDecimals(var lMosaic: TMosaic): integer;
var
  lRow,lCol: integer;
  lMin,lMax,lmm: single;
begin
  result := 0;
  if (lMosaic.Rows < 1) or (lMosaic.Cols < 1) or (lMosaic.isMM) then
    exit;
  lMin := MaxInt;
  lMax := -MaxInt;
  for lRow := lMosaic.Rows downto 1 do
      for lCol := 1 to lMosaic.Cols do
        if lMosaic.Text[lCol,lRow] then begin
          lmm := SliceMM(lMosaic.Slices[lCol,lRow],lMosaic.Orient[lCol,lRow]);
          if lmm < lMin then
            lMin := lmm;
          if lmm > lMax then
            lMax := lmm
        end;
 lmm := lMax - lMin;
 if lmm > 10 then
  result := 0
 else if lmm > 1 then
  result := 1
 else
  result := 2;
end;

procedure DrawMosaic(var lMosaic: TMosaic);
var
  lRowInc,lColInc,lRow,lCol,lDec:integer;
  scale:single;
begin
  Enter2D ;//x22;
  glBindTexture(GL_TEXTURE_3D,gRayCast.intensityTexture3D);
  if (lMosaic.MaxWid = 0) or (lMosaic.MaxHt= 0) or (lMosaic.Cols < 1) or (lMosaic.Rows < 1) then
    exit;
  scale := gRayCast.WINDOW_WIDTH/(lMosaic.MaxWid);
  if (gRayCast.WINDOW_HEIGHT/(lMosaic.MaxHt)) < scale then
    scale := gRayCast.WINDOW_HEIGHT/(lMosaic.MaxHt);
  //scale := 2;
  {$IFNDEF COREGL}glPushAttrib (GL_ENABLE_BIT); {$ENDIF}
  glEnable (GL_TEXTURE_3D);
  glDisable (GL_BLEND);
  {$IFNDEF COREGL}
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GEQUAL,1/255);
  {$ENDIF}
  if lMosaic.HOverlap < 0 then
    lColInc := -1
  else
    lColInc := 1;
  if lMosaic.VOverlap < 0 then begin
    lRow := lMosaic.Rows;
    lRowInc := -1;
  end else begin
    lRow := 1;
    lRowInc := 1;
  end;

  while (lRow >= 1) and (lRow <= lMosaic.Rows) do begin
    if lMosaic.HOverlap < 0 then
      lCol := lMosaic.Cols
    else
      lCol := 1;
    while (lCol >= 1) and (lCol <= lMosaic.Cols) do begin
      case lMosaic.Orient[lCol,lRow] of
        kAxialOrient: DrawXYAx (scale*lMosaic.Pos[lCol,lRow].X,scale*lMosaic.Pos[lCol,lRow].Y,scale*lMosaic.dim[lCol,lRow].X,scale*lMosaic.dim[lCol,lRow].Y,lMosaic.Slices[lCol,lRow]{, gTexture3D});
        kCoronalOrient: DrawXYCoro (scale*lMosaic.Pos[lCol,lRow].X,scale*lMosaic.Pos[lCol,lRow].Y,scale*lMosaic.dim[lCol,lRow].X,scale*lMosaic.dim[lCol,lRow].Y,lMosaic.Slices[lCol,lRow]{, gTexture3D});
        kSagRightOrient: DrawXYSag (scale*lMosaic.Pos[lCol,lRow].X,scale*lMosaic.Pos[lCol,lRow].Y,scale*lMosaic.dim[lCol,lRow].X,scale*lMosaic.dim[lCol,lRow].Y,lMosaic.Slices[lCol,lRow]{, gTexture3D});
        kSagLeftOrient: DrawXYSagMirror (scale*lMosaic.Pos[lCol,lRow].X,scale*lMosaic.Pos[lCol,lRow].Y,scale*lMosaic.dim[lCol,lRow].X,scale*lMosaic.dim[lCol,lRow].Y,lMosaic.Slices[lCol,lRow]{, gTexture3D});
      end;//
      lCol := lCol + lColInc;
    end;//col
    lRow := lRow+lRowInc;
  end;//row
  {$IFNDEF COREGL}glPopAttrib; {$ENDIF}
  lDec := ComputeDecimals(lMosaic);
    if lMosaic.VOverlap < 0 then
      lRow := lMosaic.Rows
    else
      lRow := 1;
    Enter2D ;//x22;
    StartDraw2D;
    while (lRow >= 1) and (lRow <= lMosaic.Rows) do begin
      if lMosaic.HOverlap < 0 then
        lCol := lMosaic.Cols
      else
        lCol := 1;
      while (lCol >= 1) and (lCol <= lMosaic.Cols) do begin
        if lMosaic.Text[lCol,lRow] then
          TextLabelXY(scale*(lMosaic.Pos[lCol,lRow].X+(lMosaic.Dim[lCol,lRow].X/2) ),scale*(lMosaic.Pos[lCol,lRow].Y+lMosaic.Dim[lCol,lRow].Y),lMosaic.Slices[lCol,lRow],lMosaic.Orient[lCol,lRow],lDec);
        lCol := lCol + lColInc;
      end;//col
      lRow := lRow+lRowInc;
  end;//row
  {$IFNDEF COREGL}  glLoadIdentity(); {$ENDIF}
  EndDraw2D;
end;

procedure MosaicGL ( lMosaicString: string);
var
  lMosaic: TMosaic;
begin
 lMosaic := Str2Mosaic ( lMosaicString);
 DrawMosaic(lMosaic);
end;

procedure SetZooms (var lX,lY,lZ: single; lTex: TTexture);
var
  lMinS: single;
begin
  lX := 1;
  lY := 1;
  lZ := 1;
  if (not gPrefs.ProportionalStretch) then
    exit;
  //unlike NIFTI header, gTexture.pixmm is absolute - never negative... otherwise we would need abs()
  {$IFDEF USETRANSFERTEXTURE}
  lMinS := 1;
  {$ELSE}
  lMinS := FloatMinVal(gTexture3D.pixmm[1],gTexture3D.pixmm[2],gTexture3D.pixmm[3]);
  if lMinS = 0 then
    exit;
  lX := (lTex.PixMM[1]) / lMinS;
  lY := (lTex.PixMM[2]) / lMinS;
  lZ := (lTex.PixMM[3]) / lMinS;
  {$ENDIF}
end;
(*procedure SetZooms (var lX,lY,lZ: single);
var
  lMinS: single;
begin
  lX := 1;
  lY := 1;
  lZ := 1;
  if (not gPrefs.ProportionalStretch) then
    exit;
  //unlike NIFTI header, gTexture.pixmm is absolute - never negative... otherwise we would need abs()
  {$IFDEF USETRANSFERTEXTURE}
  lMinS := 1;
  {$ELSE}
  lMinS := FloatMinVal(gTexture3D.pixmm[1],gTexture3D.pixmm[2],gTexture3D.pixmm[3]);
  if lMinS = 0 then
    exit;
  lX := (gTexture3D.PixMM[1]) / lMinS;
  lY := (gTexture3D.PixMM[2]) / lMinS;
  lZ := (gTexture3D.PixMM[3]) / lMinS;
  {$ENDIF}
end; *)

procedure ShowOrthoSliceText(Col1L,Col2L,Row1T,Row2T: single);
var
  lS,lC,lA : single;
begin
    Enter2D;
    lS := SliceMM (gRayCast.OrthoX,kSagLeftOrient); //Sag
    if (gPrefs.SliceView = 3) or (gPrefs.SliceView = 4) then
       TextArrow (Col2L,Row1T,1, realtostr(lS,0), 5,gPrefs.TextColor, gPrefs.TextBorder);
    lC := SliceMM (gRayCast.OrthoY,kCoronalOrient); //Coronal
    if (gPrefs.SliceView = 2) or (gPrefs.SliceView = 4) then
       TextArrow (Col1L,Row1T,1, realtostr(lC,0), 5,gPrefs.TextColor, gPrefs.TextBorder);
    lA := SliceMM (gRayCast.OrthoZ,kAxialOrient); //Axial
    if (gPrefs.SliceView = 1) or (gPrefs.SliceView = 4) then
       TextArrow (Col1L,Row2T,1, realtostr(lA,0), 5,gPrefs.TextColor, gPrefs.TextBorder);
    {$IFNDEF COREGL}glLoadIdentity();{$ENDIF}
end;

procedure DrawOrtho(var lTex: TTexture);
var
  scale,X,Y,Z,Yshift, W, H:single;
  drawID : GLuint;
  {$IFDEF COREGL} lineWid: single;
  mat44: TnMat44;{$ENDIF}
begin
  Enter2D;
  SetZooms(X,Y,Z,lTex);
  X := X*abs(lTex.FiltDim[1]);
  Y := Y*abs(lTex.FiltDim[2]);
  Z := Z*abs(lTex.FiltDim[3]);
  if (X = 0) or (Y= 0) or (Z=0) then
    exit;
  case gPrefs.SliceView of
       1: H := Y;//Ax
       2,3: H := Z; //Coro ,Sag
       else H := Z+Y; //MPR
  end;
  case gPrefs.SliceView of
       1,2: W := X;//Ax,Coro
       3: W := Y; //Sag
       else W := X+Y; //MPR
  end;
  scale := gRayCast.WINDOW_HEIGHT/(H);
  if (gRayCast.WINDOW_WIDTH/(W)) < scale then begin
    //size constrained by width, not height
    scale := gRayCast.WINDOW_WIDTH/(W);
    //translate image so aligned with top not bottom of window
    //  glTranslatef(0,gRayCast.WINDOW_HEIGHT-((Y+Z)*scale) ,0);
    Yshift := gRayCast.WINDOW_HEIGHT-((H)*scale);
  end else
      Yshift := 0;

  gRayCast.OrthoZoom := scale;
  X := X * scale;
  Y := Y * scale;
  Z := Z * scale;
  drawID :=  voiOpenGLDraw;
  {$IFDEF COREGL}
  if true then begin
  {$ELSE}
  if (drawID > 0) then begin //display drawing and background image using GLSL
  {$ENDIF}
    glDisable (GL_BLEND); //e.g. colorbar can leave blending on
    glBlendFunc (GL_ONE, GL_ZERO);
    //uniform3fv('clearColor',gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255);
    {$IFDEF COREGL}
    StartDrawGLSL;
    glUniform1ix(gDraw.glslprogramId, 'drawLoaded', gDraw.view3dId );

    //mat44 := ngl_ModelViewProjectionMatrix;
    //gCore.mvpLocBackface := glGetUniformLocation(gCore.programBackface, pAnsiChar('modelViewProjectionMatrix'));
    //glUniformMatrix4fv(glGetUniformLocation(gDraw.glslprogramId, 'modelViewProjectionMatrix'), 1, GL_FALSE, @mat44[0,0]);
    //GLForm1.Caption := format('XY %g %g Screen %d %d ',[X,Y, gRayCast.WINDOW_WIDTH,gRayCast.WINDOW_HEIGHT]  );
    mat44 := ngl_ModelViewProjectionMatrix;
    glUniformMatrix4fv(glGetUniformLocation(gDraw.glslprogramId, 'modelViewProjectionMatrix'), 1, GL_FALSE, @mat44[0,0]);

    {$ENDIF}
    glUniform3f(glGetUniformLocation(gDraw.glslprogramId, pAnsiChar('clearColor')), gPrefs.BackColor.rgbRed/255,gPrefs.BackColor.rgbGreen/255,gPrefs.BackColor.rgbBlue/255) ;
    //draw axial
    if (gPrefs.SliceView = 1) or (gPrefs.SliceView = 4) then begin
       glUniform1ix(gDraw.glslprogramId, 'orientAxCorSag', 1);
       glUniform1fx(gDraw.glslprogramId, 'coordZ', gRayCast.OrthoZ);
       DrawXYTex(0,YShift,X,Y);
    end;
    //draw coronal
    if (gPrefs.SliceView = 2) or (gPrefs.SliceView = 4) then begin
       glUniform1ix(gDraw.glslprogramId, 'orientAxCorSag', 2);
       glUniform1fx(gDraw.glslprogramId, 'coordZ', gRayCast.OrthoY);
       if (gPrefs.SliceView = 4) then
         DrawXYTex(0,Y+YShift,X,Z)
       else
           DrawXYTex(0,YShift,X,Z);
    end;
    //draw sagittal
    if (gPrefs.SliceView > 2) then begin
       glUniform1ix(gDraw.glslprogramId, 'orientAxCorSag', 3);
       glUniform1fx(gDraw.glslprogramId, 'coordZ', gRayCast.OrthoX);
       if (gPrefs.SliceView = 4) then
          DrawXYTex(X,Y+YShift,Y,Z)
       else
           DrawXYTex(0,YShift,Y,Z);
    end;
    glUseProgram(0);
    glActiveTexture( GL_TEXTURE0 );  //required if we will draw 2d slices next
  end else begin  //no drawing: display background image using OpenGL
    glUseProgram(0);
    glActiveTexture( GL_TEXTURE0 );  //required if we will draw 2d slices next
    glBindTexture(GL_TEXTURE_3D,gRayCast.intensityTexture3D);
    {$IFNDEF COREGL}glPushAttrib (GL_ENABLE_BIT); {$ENDIF}
    glEnable (GL_TEXTURE_3D);
    glDisable (GL_BLEND);
    {$IFNDEF COREGL}
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GEQUAL,1/255);// 2015*)
    {$ENDIF}
    //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    case gPrefs.SliceView of
         1 : DrawXYAx  (0, YShift,X,Y, gRayCast.OrthoZ);
         2 : DrawXYCoro(0, YShift,X,Z, gRayCast.OrthoY);
         3 : DrawXYSag (0, YShift,Y,Z, gRayCast.OrthoX);
         else begin
              DrawXYAx  (0,YShift,X,Y, gRayCast.OrthoZ);
              DrawXYCoro(0,Y+YShift,X,Z, gRayCast.OrthoY);
              DrawXYSag (X,Y+YShift,Y,Z, gRayCast.OrthoX);
         end;
    end;
  end;
  StartDraw2D;
  //Enter2D;
  gPrefs.CrosshairThick := 1;
  {$IFNDEF COREGL}glPopAttrib;{$ENDIF}
  if gPrefs.CrosshairThick > 0 then begin
    {$IFDEF COREGL}
    nglColor4f(gPrefs.CrosshairColor.rgbRed/255,gPrefs.CrosshairColor.rgbGreen/255,gPrefs.CrosshairColor.rgbBlue/255,1{gPrefs.CrosshairColor.rgbReserved/255});
    lineWid := gPrefs.CrosshairThick / 2;
    if (gPrefs.SliceView <> 3) then begin //vertical LR line
         nglBegin(GL_TRIANGLE_STRIP); //with OpenGL Core, lines are limited to 1 pixel...
         nglVertex3f(X*gRayCast.OrthoX-lineWid, YShift, 0);
         nglVertex3f(X*gRayCast.OrthoX-lineWid, Y+Z+YShift, 0);
         nglVertex3f(X*gRayCast.OrthoX+lineWid, YShift, 0);
         nglVertex3f(X*gRayCast.OrthoX+lineWid, Y+Z+YShift, 0);
         nglEnd;
    end;
    //vertical line cutting sag
    if (gPrefs.SliceView = 4) then begin //MPR
       nglBegin(GL_TRIANGLE_STRIP);
       nglVertex3f(X+ Y*gRayCast.OrthoY-lineWid, Y+YShift, 0);
       nglVertex3f(X+ Y*gRayCast.OrthoY-lineWid, Y+Z+YShift, 0);
       nglVertex3f(X+ Y*gRayCast.OrthoY+lineWid, Y+YShift, 0);
       nglVertex3f(X+ Y*gRayCast.OrthoY+lineWid, Y+Z+YShift, 0);
       nglEnd;
    //on sag
    end else if (gPrefs.SliceView = 3) then begin
         nglBegin(GL_TRIANGLE_STRIP);
         nglVertex3f(0,Z*gRayCast.OrthoZ+YShift-lineWid, 0);
         nglVertex3f(Y,Z*gRayCast.OrthoZ+YShift-lineWid, 0);
         nglVertex3f(0,Z*gRayCast.OrthoZ+YShift+lineWid, 0);
         nglVertex3f(Y,Z*gRayCast.OrthoZ+YShift+lineWid, 0);
          nglEnd;
    end;
    //horizontal line on AX
    if (gPrefs.SliceView = 1)  or (gPrefs.SliceView = 4) then begin
         nglBegin(GL_TRIANGLE_STRIP); //with OpenGL Core, lines are limited to 1 pixel...
         nglVertex3f(0, Y*gRayCast.OrthoY+YShift-lineWid, 0);
         nglVertex3f(X,Y*gRayCast.OrthoY+YShift-lineWid, 0);
         nglVertex3f(0, Y*gRayCast.OrthoY+YShift+lineWid, 0);
         nglVertex3f(X,Y*gRayCast.OrthoY+YShift+lineWid, 0);
         nglEnd;
    end;
    if (gPrefs.SliceView = 4) then begin //MPR
      nglBegin(GL_TRIANGLE_STRIP); //with OpenGL Core, lines are limited to 1 pixel...
       nglVertex3f(0, Y+Z*gRayCast.OrthoZ+YShift-lineWid, 0);
       nglVertex3f(X+Y,Y+Z*gRayCast.OrthoZ+YShift-lineWid, 0);
       nglVertex3f(0, Y+Z*gRayCast.OrthoZ+YShift+lineWid, 0);
       nglVertex3f(X+Y,Y+Z*gRayCast.OrthoZ+YShift+lineWid, 0);
       nglEnd;
    end else if (gPrefs.SliceView = 2) then begin //cor
      nglBegin(GL_TRIANGLE_STRIP); //with OpenGL Core, lines are limited to 1 pixel...
        nglVertex3f(0, Z*gRayCast.OrthoZ+YShift-lineWid, 0);
        nglVertex3f(X,Z*gRayCast.OrthoZ+YShift-lineWid, 0);
        nglVertex3f(0, Z*gRayCast.OrthoZ+YShift+lineWid, 0);
        nglVertex3f(X,Z*gRayCast.OrthoZ+YShift+lineWid, 0);
        nglEnd;
    end else if (gPrefs.SliceView = 3) then begin  //sag
      nglBegin(GL_TRIANGLE_STRIP);
      nglVertex3f(Y*gRayCast.OrthoY-lineWid, YShift, 0);
      nglVertex3f(Y*gRayCast.OrthoY-lineWid, Z+YShift, 0);
      nglVertex3f(Y*gRayCast.OrthoY+lineWid, YShift, 0);
      nglVertex3f(Y*gRayCast.OrthoY+lineWid, Z+YShift, 0);
      nglEnd;
    end;
    {$ELSE}
    //glColor4f(gPrefs.CrosshairColor.rgbRed/255,gPrefs.CrosshairColor.rgbGreen/255,gPrefs.CrosshairColor.rgbBlue/255,1{gPrefs.CrosshairColor.rgbReserved/255});
    glColor4ub(gPrefs.CrosshairColor.rgbRed,gPrefs.CrosshairColor.rgbGreen,gPrefs.CrosshairColor.rgbBlue,255);

    glLineWidth(gPrefs.CrosshairThick);
    glBegin(GL_LINES);
      //vertical bar cutting ax and cor
      if (gPrefs.SliceView <> 3) then begin
         glVertex3f(X*gRayCast.OrthoX, YShift, 0);
         glVertex3f(X*gRayCast.OrthoX, Y+Z+YShift, 0);
      end;
      //vertical line cutting sag
      if (gPrefs.SliceView = 4) then begin //MPR
         glVertex3f(X+ Y*gRayCast.OrthoY, Y+YShift, 0);
         glVertex3f(X+ Y*gRayCast.OrthoY, Y+Z+YShift, 0);
      end else if (gPrefs.SliceView = 3) then begin
         glVertex3f(Y*gRayCast.OrthoY, YShift, 0);
         glVertex3f(Y*gRayCast.OrthoY, Z+YShift, 0);
      end;
      //horizontal line on ax
      if (gPrefs.SliceView = 1)  or (gPrefs.SliceView = 4) then begin //Ax or MPR
         glVertex3f(0, Y*gRayCast.OrthoY+YShift, 0);
         glVertex3f(X,Y*gRayCast.OrthoY+YShift, 0);
      end;
      //horizontal line on cor sag
      if (gPrefs.SliceView = 4) then begin //MPR
      glVertex3f(0, Y+Z*gRayCast.OrthoZ+YShift, 0);
      glVertex3f(X+Y,Y+Z*gRayCast.OrthoZ+YShift, 0);
      end else if (gPrefs.SliceView = 2) then begin //cor
          glVertex3f(0, Z*gRayCast.OrthoZ+YShift, 0);
          glVertex3f(X,Z*gRayCast.OrthoZ+YShift, 0);
      end else if (gPrefs.SliceView = 3) then begin  //sag
          glVertex3f(0, Z*gRayCast.OrthoZ+YShift, 0);
          glVertex3f(Y,Z*gRayCast.OrthoZ+YShift, 0);
      end;
    glEnd;
    {$ENDIF}
  end; //if CrosshairThick > 0
  if gPrefs.SliceDetailsCubeAndText then begin
     if (gPrefs.SliceView = 2) then Y := 0;
     if (gPrefs.SliceView = 3) then
       ShowOrthoSliceText(X/2,Y/2,Z+YShift,YShift)
    else
        ShowOrthoSliceText(X/2,X+Y/2,Y+Z+YShift,Y+YShift);
  end;
  EndDraw2D;
end;



end.

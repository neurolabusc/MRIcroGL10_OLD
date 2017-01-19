Unit texture_3d_unit;

Interface
{$H+}
{$DEFINE xLOADDUMMY}   //<-use LOADDUMMY to test with dynamically generated volume

{$include opts.inc}
uses
{$DEFINE GZIP}

{$IFNDEF FPC}
  gziod,
{$ELSE}
  gzio2,
{$ENDIF}
//{$IFDEF Unix}LCLIntf, {$ELSE} Windows,{$ENDIF}
  SysUtils,
  Dialogs,clut,
{$IFDEF DGL} dglOpenGL, {$ELSE} gl, glext, {$ENDIF} nii_mat, math,
  ExtCtrls,  nifti_hdr, define_types,nii_label, nifti_types, coordinates;
Type
  TTexture =  RECORD //3D data
    NIFTIhdr,NIFTIhdrRaw: TNIFTIHdr;
    PixMM,Scale: array[1..3] of single;
    FiltDim : array [1..3] of integer;
    DataType,BytesPerVoxel : integer;
    updateBackgroundGradientsGLSL,updateOverlayGradientsGLSL,
    isLabels: boolean; //use maximum intensity projection for angiography....
    WindowScaledMax,WindowScaledMin,MaxThreshScaled,MinThreshScaled: single;
    WindowHisto,UnscaledHisto: HistoRA;
    RawUnscaledImg8,RawUnscaledImgRGBA,
    FiltImg  : bytep0;
    RawUnscaledImg16: SmallIntP0;
    RawUnscaledImg32: SingleP0;
    LabelRA: TStrRA;
  end;
  procedure Float64ToFloat32 (var lHdr: TMRIcroHdr; var lImgBuffer: byteP);
 // procedure ExtractTexture (var lTexture:TTexture; lOtsuLevels: integer; lDilateVox: single; lOneContiguousObject: boolean);
 // procedure Int32ToFloat (var lHdr: TMRIcroHdr; var lImgBuffer: byteP);
function NIFTIhdr_LoadImg (var lFilename: string; var lHdr: TMRIcroHdr; var lImgBuffer: byteP; lVolume: integer): boolean;
Function Load_From_NIfTI (var lTexture: TTexture; Const F_FileName : String; lPowerOfTwo: boolean; lVol: integer) : boolean;
Procedure InitTexture (var lTexture: TTexture);
Procedure SetLengthB (var lPtr: Bytep0;lBytes: integer);
Procedure SetLength32 (var lPtr: SingleP0;lBytes: integer);
procedure SharpenTexture(var lTexture: TTexture);
//function NIFTIvolumes (var lFilename: string): integer;

//procedure EdgeBiasGain (lBiasIn,lGainIn: integer;var  lLUT: TLUTb);
Procedure Calculate_Transfer_Function;

Implementation
uses
{$IFDEF ENABLEEDGE}edgeenhanceu, {$ENDIF}
  texture2raycast, nii_reslice,reorient,histogram, mainunit,{$IFDEF COREGL} raycast_core, {$ELSE} raycast_legacy, {$ENDIF} raycast_common;


(*function AdjustTransparencyRGBA (var lTexture: TTexture): boolean;
//adjust the transpareny of an image that has RGBA as source
//with other image formats, this is done on the UnFiltRGBAImg, because there is a raw image in the native data format
//for RGBA, we need to manipulate the FiltImg
var
  lnVox,lPos,lC: integer;
  lCLUT: TLUT;
begin
  result := false;
  lnVox := lTexture.FiltDim[1]*lTexture.FiltDim[2]*lTexture.FiltDim[3]-1;
  if lnVox < 1 then
    exit;
  if (lTexture.RawUnscaledImg16 <> nil) or  (lTexture.RawUnscaledImg32 <> nil) or (lTexture.RawUnscaledImg8 <> nil) then
    exit;
  Move (gTexture3D.RawUnscaledImgRGBA^,gTexture3D.FiltImg^, lnVox *  gTexture3D.BytesPerVoxel);
  GenerateLUT(gCLUTrec, lCLUT);
  lPos := 0;
  for lC := 1 to lnVox do begin
    gTexture3D.FiltImg^[lPos+3] := lCLUT[gTexture3D.FiltImg^[lPos+1]].rgbReserved;
    lPos := lPos + 4;
  end;
  //ModulateRGBwithEdge (gTexture3D);
  result := true;
end; //proc AdjustTransparency
*)
{$DEFINE MY_GAIN}
function AdjustTransparencyRGBA (var lTexture: TTexture): boolean;
//adjust the transpareny of an image that has RGBA as source
//with other image formats, this is done on the UnFiltRGBAImg, because there is a raw image in the native data format
//for RGBA, we need to manipulate the FiltImg
var
  lnVox,lPos,lC : integer;
  lCLUTalpha: TLUT;
   {$IFDEF MY_GAIN} bias: single; {$ENDIF}
  lLo,lHi,lRng,lV: single;
  LUT : array[0..255] of byte;
begin
  result := false;
  lnVox := lTexture.FiltDim[1]*lTexture.FiltDim[2]*lTexture.FiltDim[3]-1;
  if lnVox < 1 then
    exit;
  if (gTexture3D.RawUnscaledImgRGBA = nil) or (lTexture.RawUnscaledImg16 <> nil) or  (lTexture.RawUnscaledImg32 <> nil) or (lTexture.RawUnscaledImg8 <> nil) then
    exit;
  GenerateLUT(gCLUTrec, lCLUTalpha);
  lLo := gCLutRec.min; lHi := gClutRec.max;
  SortSingle(lLo,lHi);
  lRng := lHi - lLo;
  if lRng <= 0 then begin
     for lC := 0 to 255 do
      LUT[lC] := lC;
  end else begin
   {$IFDEF MY_GAIN}  //Ken Perlin’s bias http://blog.demofox.org/2012/09/24/bias-and-gain-are-your-friend/
   bias := 1.0 - ( 0.5 * (lRng/ 255));
   if (bias <= 0.0) then bias := 0.001;
   if (bias >= 1.0) then bias := 0.999;
   for lC := 0 to 255 do begin
           lV := lC/255.0;
           lV := (lV/ ((((1/bias) - 2)*(1 - lV))+1));
           if (lV > 1.0) then lV := 1.0;
           if (lV < 0.0) then lV := 0.0;
           LUT[lC] := round(255.0 * lV);
    end; //for all indices

    {$ELSE}
   for lC := 0 to 255 do begin
     lV:= ((lC-lLo)/lRng)*255;
     if lV < 0 then lV := 0;
     if lV > 255 then lV := 255;
     LUT[lC] := round(lV);
    end;
   {$ENDIF}
  end;
  lPos := 0;
  for lC := 1 to lnVox do begin
      gTexture3D.FiltImg^[lPos] := LUT[gTexture3D.RawUnscaledImgRGBA^[lPos]];
      gTexture3D.FiltImg^[lPos+1] := LUT[gTexture3D.RawUnscaledImgRGBA^[lPos+1]];
      gTexture3D.FiltImg^[lPos+2] := LUT[gTexture3D.RawUnscaledImgRGBA^[lPos+2]];
      gTexture3D.FiltImg^[lPos+3] := lCLUTalpha[gTexture3D.FiltImg^[lPos+1]].rgbReserved;
    lPos := lPos + 4;
  end;
  result := true;
end; //proc AdjustTransparency

procedure rescaleLabel2RGB (var lTexture: TTexture; lMinScaled,lMaxScaled: single);
//this is for label images that have indexed colors
var
  lVox,lnVox: integer;
  lCLUT8: TLUT;
  lRGBra: GLRGBQuadp0;
begin
  lnVox := lTexture.FiltDim[1]*lTexture.FiltDim[2]*lTexture.FiltDim[3]-1;
  createLutLabel(lCLUT8, abs(lMaxScaled-lMinScaled)/100);
  lCLUT8[0] := gPrefs.BackColor;
  lRGBra:= GLRGBQuadp0(lTexture.FiltImg);
  if lTexture.RawUnscaledImg16 <> nil then begin //16 bit data
      for lVox := 0 to lnVox do
            lRGBra^[lVox] := lCLUT8[((lTexture.RawUnscaledImg16^[lVox]-1) mod 100)+1];
   end else begin
       for lVox := 0 to lnVox do
            lRGBra^[lVox] := lCLUT8[lTexture.RawUnscaledImg8^[lVox]];
   end; //if 16bit else 8bit
end;

procedure rescale2RGB (var lTexture: TTexture; lMinScaled,lMaxScaled: single; var lCLUT: TLUT);
var
  lI,ValueI,lVox,lnVox: integer;
  lMin,lMax,lIntercept,lSlope: single;
  lCLUT8: TLUT;
  lRGBra: GLRGBQuadp0;
begin
  if lTexture.DataType <> GL_RGBA then
    exit;
  lnVox := lTexture.FiltDim[1]*lTexture.FiltDim[2]*lTexture.FiltDim[3]-1;
  if lnVox < 0 then
      exit;
  if lTexture.isLabels then begin
     rescaleLabel2RGB (lTexture, lMinScaled,lMaxScaled);
     exit;
  end;
  lMin := Scaled2Unscaled(lMinScaled,lTexture);
  lMax := Scaled2Unscaled(lMaxScaled,lTexture);
  if lMax = lMin then
    exit;

  if lMax < lMin then begin
      lSlope := lMax;
      lMax := lMin;
      lMin := lSlope;
  end;
  lIntercept := lMin;
  lSlope := 255/(lMax-lMin);
  lI := 0;
  if lTexture.RawUnscaledImg16 <> nil then begin //16
    for lVox := 0 to lnVox do begin
            ValueI := round((lTexture.RawUnscaledImg16^[lVox]-lIntercept)*lSlope);
            if ValueI < 0 then
              ValueI := 0;
            if ValueI > 255 then
              ValueI := 255;
            lTexture.FiltImg^[lI] :=  lCLUT[ValueI].rgbRed;//Luminance
            lTexture.FiltImg^[lI+1] := lCLUT[ValueI].rgbGreen;//Alpha
            lTexture.FiltImg^[lI+2] := lCLUT[ValueI].rgbBlue;//Alpha
            lTexture.FiltImg^[lI+3] := lCLUT[ValueI].rgbReserved;//Alpha
            inc(lI,4);
    end; //for each vox
  end else if lTexture.RawUnscaledImg32 <> nil then begin //32-bit
    for lVox := 0 to lnVox do begin
            ValueI := round((lTexture.RawUnscaledImg32^[lVox]-lIntercept)*lSlope);
            if ValueI < 0 then
              ValueI := 0;
            if ValueI > 255 then
              ValueI := 255;
            lTexture.FiltImg^[lI] :=  lCLUT[ValueI].rgbRed;//Luminance
            lTexture.FiltImg^[lI+1] := lCLUT[ValueI].rgbGreen;//Alpha
            lTexture.FiltImg^[lI+2] := lCLUT[ValueI].rgbBlue;//Alpha
            lTexture.FiltImg^[lI+3] := lCLUT[ValueI].rgbReserved;//Alpha
            inc(lI,4);
    end; //for each vox
  end else if (lTexture.RawUnscaledImg8 <> nil) then begin //8-bit
    //fast method - compute one calculation per index
    for lVox := 0 to 255 do begin
            ValueI := round((lVox-lIntercept)*lSlope);
            if ValueI < 0 then
              ValueI := 0;
            if ValueI > 255 then
              ValueI := 255;
            lCLUT8[lVox] :=  lCLUT[ValueI];//Luminance
    end; //for each vox
    lRGBra:= GLRGBQuadp0(lTexture.FiltImg);
    for lVox := 0 to lnVox do
            lRGBra^[lVox] := lCLUT8[lTexture.RawUnscaledImg8^[lVox]];
{//this works, ~30% slower than method above
  lI := 0;
    for lVox := 0 to lnVox do begin
            ValueI := lTexture.RawUnscaledImg8^[lVox];
            lTexture.FiltImg^[lI] :=  lCLUT8[ValueI].rgbRed;//Luminance
            lTexture.FiltImg^[lI+1] := lCLUT8[ValueI].rgbGreen;//Alpha
            lTexture.FiltImg^[lI+2] := lCLUT8[ValueI].rgbBlue;//Alpha
            lTexture.FiltImg^[lI+3] := lCLUT8[ValueI].rgbReserved;//Alpha
            inc(lI,4);
    end; //for each vox
//slow method - compute one calculation per voxel
    for lVox := 0 to lnVox do begin
            ValueI := round((lTexture.RawUnscaledImg8^[lVox]-lINtercept)*lSlope);
            if ValueI < 0 then
              ValueI := 0;
            if ValueI > 255 then
              ValueI := 255;
            lTexture.FiltImg^[lI] :=  lCLUT[ValueI].rgbRed;//Luminance
            lTexture.FiltImg^[lI+1] := lCLUT[ValueI].rgbGreen;//Alpha
            lTexture.FiltImg^[lI+2] := lCLUT[ValueI].rgbBlue;//Alpha
            lTexture.FiltImg^[lI+3] := lCLUT[ValueI].rgbReserved;//Alpha
            inc(lI,4);
    end; //for each vox}
  end;//8-bit
  {$IFDEF ENABLEEDGE}
  if lTexture.EdgeImg <> nil then
    ModulateRGBwithEdge ( lTexture);
  {$ENDIF}
  //if   (lMin < 0) and (lMax < 0) then
  //  HideTopSlice(lTexture);
end;
//{$ENDIF}
(*procedure EdgeBiasGain (lBiasIn,lGainIn: integer;var  lLUT: TLUTb);
//input values 0..100
{http://dept-info.labri.fr/~schlick/DOC/gem2.html
http://dept-info.labri.fr/~schlick/publi.html
Fast Alternatives to Perlin's Bias and Gain Functions
Christophe Schlick Graphics Gems IV, p379-382, April 1994  }
var
	lIndex: integer;
	lA,lT,lBias,lG,lGain,lResult: single;
begin
  lA := 100-lBiasIn;
	lA := lA/100;
  if lA > 1 then
    lA := 1;
  if lA = 0 then
    lA := 0.000001;
  lG := 100-lGainIn;
	lG := (lG)/100;
        if lG = 0 then
           lG := 0.00001;
        if lG = 1 then
           lG := 0.99999;
	 for lIndex := 0 to (255) do begin
		 lT := lIndex/255;
                 //apply bias
		 lT := (lt/((1/la-2)*(1-lt)+1)) ;
                 //next apply gain
                 if lT < 0.5 then
                      lGain := (lT/((1/lG-2)*(1-2*lT)+1))
                 else
                     lGain := (( (1/lG-2)*(1-2*lT)-lT ) / ( (1/lG-2)*(1-2*lT)-1 ) );
                 lGain := lGain / lT;
                 lResult := (255*lT*lGain);
                 if lResult > 255 then
                    lResult := 255;
                 if lResult < 0 then
                    lResult := 0;
		 lLUT[lIndex] := round(lResult);
		 //lLUT[lIndex] := 255-lLUT[lIndex];

	 end;
end;*)

{$IFDEF ENABLECUTOUT}
function KToVoxel(lK, lRange: integer): integer;
//takes a value 0..1000 representing 0..100%, returns proportion of dimension
begin
  if lK < 0 then
    result := 0
  else
    result := round((lK/1000) * lRange);
  if result >= lRange then
    result := lRange - 1;
end;

Procedure CreateCutout;
//removes a sector from the image to give a cut-away-view
Var
  lTexelBytes,lZi,lYi,lXi,Y,Z,lX,lY,lZ,lX2,lY2,lZ2,lSliceSz, lLineBytes: integer;
begin
  lTexelBytes := gTexture3D.BytesPerVoxel; //e.g. RGBA=4, Luminance+Alpha=2
   lX := GLForm1.XTrackbar.position;
   lY := GLForm1.YTrackbar.position;
   lZ := GLForm1.ZTrackbar.position;
   lX2 := GLForm1.X2Trackbar.position;
   lY2 := GLForm1.Y2Trackbar.position;
   lZ2 := GLForm1.Z2Trackbar.position;
   if (lX=lX2) and (lY=lY2) and (lZ = lZ2) then exit;
   if (lX=0) and (lX2 = 0) then exit;
   if (lY=0) and (lY2 = 0) then exit;
   if (lZ=0) and (lZ2 = 0) then exit;
   //scale units to object
   lX := KToVoxel(lX,gTexture3D.FiltDim[1]);
   lY := KToVoxel(lY,gTexture3D.FiltDim[2]);
   lZ := KToVoxel(lZ,gTexture3D.FiltDim[3]);
   lX2 := KToVoxel(lX2,gTexture3D.FiltDim[1]);
   lY2 := KToVoxel(lY2,gTexture3D.FiltDim[2]);
   lZ2 := KToVoxel(lZ2,gTexture3D.FiltDim[3]);
   SortInt(lX,lX2);
   SortInt(lY,lY2);
   SortInt(lZ,lZ2);
   if ((lX2-lX)<1) or ((lY2-lY)<1) or ((lZ2-lZ)<1) then
    exit;
   lSliceSz := gTexture3D.FiltDim[2] * gTexture3D.FiltDim[1];
   lLineBytes := ((lX2-lX)+1) * lTexelBytes;
   For Z := lZ To lZ2 Do Begin { For Z}
      lZi := Z * lSliceSz* lTexelBytes; //unroll loop - only once per slice
      For Y := lY To lY2 Do Begin { For Y}
        lYi := Y * gTexture3D.FiltDim[1]* lTexelBytes;
        lXi := lZi + lYi + (lX * lTexelBytes);
        FillChar(gTexture3D.FiltImg^[lXi], lLineBytes, 0);
        End; { For Y}
   End; { For Z}
end;//proc CreateCutout
{$ENDIF}//only if ENABLECUTOUT defined

Procedure Calculate_Transfer_Function;
//copies input_texture to output_texture
//adjusts Alpha to account for Invisible Threshold and clipping planes
var
 lCLUT: TLUT;
 //lUnused: GLuint;
begin
  if gTexture3D.FiltImg = nil then
        exit;
  if not AdjustTransparencyRGBA(gTexture3D) then begin
    GenerateLUT(gCLUTrec, lCLUT);
    rescale2RGB (gTexture3D,gCLUTrec.min,gCLUTrec.max,lCLUT); // see CLUT.pas
  end;
GLForm1.BlendOverlaysRGBA(gTexture3D);

{$IFDEF ENABLECUTOUT} CreateCutout; {$ENDIF}
  {$IFDEF USETRANSFERTEXTURE}
  //This will need to be updated....
 LoadTTexture(gTexture3D, gRayCast.gradientTexture3D,gRayCast.intensityTexture3D, gRayCast.transferTexture1, gRayCast.intensityOverlay3D, gRayCast.gradientOverlay3D, gShader.OverlayVolume);
 {$ELSE}
  LoadTTexture(gTexture3D);
 {$ENDIF}
 end; //proc Calculate_Transfer_Function

Procedure SetLengthB (var lPtr: Bytep0;lBytes: integer);
begin
    if lPtr <> nil then
      freemem(lPtr);
    if lBytes < 1 then begin
      lPtr := nil;
      exit;
    end;
    getmem(lPtr,lBytes);
end;

Procedure SetLength16 (var lPtr: SmallIntP0;lBytes: integer);
begin
    if lPtr <> nil then
      freemem(lPtr);
    if lBytes < 1 then begin
      lPtr := nil;
      exit;
    end;
    getmem(lPtr,lBytes);
end;

procedure SmoothVol8 (var rawData: bytep0; lXdim,lYdim,lZdim: integer);
var
  lSmoothImg,lSmoothImg2: SmallIntP0;
  lSliceSz,lnVox,i: integer;
begin
  lSliceSz := lXdim*lYdim;
  lnVox := lSliceSz*lZDim;
  if (lnVox < 0) or (lXDim < 3) or (lYDim < 3) or (lZDim < 3) then exit;
  getmem(lSmoothImg,lnVox * 2);
  getmem(lSmoothImg2,lnVox * 2);
  lSmoothImg[0] := rawData[0];
  lSmoothImg[lnVox-1] := rawData[lnVox-1];
  for i := 1 to (lnVox-2) do
      lSmoothImg[i] := rawData[i-1] + (rawData[i] shl 1) + rawData[i+1];
  for i := lXdim to (lnVox-lXdim-1) do  //output *4 input (10bit->12bit)
      lSmoothImg2[i] := lSmoothImg[i-lXdim] + (lSmoothImg[i] shl 1) + lSmoothImg[i+lXdim];
  for i := lSliceSz to (lnVox-lSliceSz-1) do  // *4 input (12bit->14bit) , >> 6 for 8 bit output
      rawData[i] := (lSmoothImg2[i-lSliceSz] + (lSmoothImg2[i] shl 1) + lSmoothImg2[i+lSliceSz]) shr 6;
  freemem(lSmoothImg);
  freemem(lSmoothImg2);
end;

procedure SmoothVol16 (var rawData: smallintp0; lXdim,lYdim,lZdim: integer);
var
  lSmoothImg,lSmoothImg2: LongIntP0;
  lSliceSz,lnVox,i: integer;
begin
  lSliceSz := lXdim*lYdim;
  lnVox := lSliceSz*lZDim;
  if (lnVox < 0) or (lXDim < 3) or (lYDim < 3) or (lZDim < 3) then exit;
  getmem(lSmoothImg,lnVox * 4);
  getmem(lSmoothImg2,lnVox * 4);
  lSmoothImg[0] := rawData[0];
  lSmoothImg[lnVox-1] := rawData[lnVox-1];
  for i := 1 to (lnVox-2) do
      lSmoothImg[i] := rawData[i-1] + (rawData[i] shl 1) + rawData[i+1];
  for i := lXdim to (lnVox-lXdim-1) do  //output *4 input (10bit->12bit)
      lSmoothImg2[i] := lSmoothImg[i-lXdim] + (lSmoothImg[i] shl 1) + lSmoothImg[i+lXdim];
  for i := lSliceSz to (lnVox-lSliceSz-1) do  // *4 input (12bit->14bit) , >> 6 for 8 bit output
      rawData[i] := (lSmoothImg2[i-lSliceSz] + (lSmoothImg2[i] shl 1) + lSmoothImg2[i+lSliceSz]) shr 6;
  freemem(lSmoothImg);
  freemem(lSmoothImg2);
end;

procedure SharpenTexture8(var lTexture: TTexture);
var
  lFilt: bytep0;
  lnVox, i, v: integer;
begin
   lnVox := lTexture.FiltDim[1] * lTexture.FiltDim[2]  * lTexture.FiltDim[3] ;
   getmem(lFilt,lnVox);
   Move(lTexture.RawUnscaledImg8^, lFilt^, lnVox); //copy edges
   SmoothVol8(lFilt, lTexture.FiltDim[1], lTexture.FiltDim[2], lTexture.FiltDim[3]);
   for i := 0 to (lnVox -1) do begin
       v := lTexture.RawUnscaledImg8^[i] - (lFilt^[i] - lTexture.RawUnscaledImg8^[i]);
       if v < 0 then v := 0;
       if v > 255 then v := 255;
       lTexture.RawUnscaledImg8^[i] := v;
   end;
   freemem(lFilt);
end;

procedure SharpenTexture16(var lTexture: TTexture);
var
  lFilt: smallintp0;
  lnVox, i, v, mx, mn: integer;
begin
   lnVox := lTexture.FiltDim[1] * lTexture.FiltDim[2]  * lTexture.FiltDim[3] ;
   getmem(lFilt,lnVox*2);
   Move(lTexture.RawUnscaledImg16^, lFilt^, lnVox*2); //copy edges
   SmoothVol16(lFilt, lTexture.FiltDim[1], lTexture.FiltDim[2], lTexture.FiltDim[3]);
   mx := lTexture.RawUnscaledImg16^[0];
   mn := mx;
   for i := 0 to (lnVox -1) do begin
       if lTexture.RawUnscaledImg16^[i] > mx then
         mx := lTexture.RawUnscaledImg16^[i];
       if lTexture.RawUnscaledImg16^[i] < mn then
         mn := lTexture.RawUnscaledImg16^[i];
   end;
   for i := 0 to (lnVox -1) do begin
       v := lTexture.RawUnscaledImg16^[i] - (lFilt^[i] - lTexture.RawUnscaledImg16^[i]);
       if v < mn then v := mn;
       if v > mx then v := mx;
       lTexture.RawUnscaledImg16^[i] := v;
   end;
   freemem(lFilt);
end;

procedure SharpenTexture(var lTexture: TTexture);
begin
   if (lTexture.FiltDim[1] < 3) or (lTexture.FiltDim[2] < 3) or (lTexture.FiltDim[3] < 1) then
      exit;
   if (lTexture.RawUnscaledImg8 <> nil) then
      SharpenTexture8(lTexture);
   if (lTexture.RawUnscaledImg16 <> nil) then
      SharpenTexture16(lTexture);

end;

Procedure SetLength32 (var lPtr: SingleP0;lBytes: integer);
begin
    if lPtr <> nil then
      freemem(lPtr);
    if lBytes < 1 then begin
      lPtr := nil;
      exit;
    end;
    getmem(lPtr,lBytes);
end;

Procedure InitTexture (var lTexture: TTexture);
var
  lI: integer;
begin
  with lTexture do begin
    for lI := 1 to 3 do begin
      PixMM[lI] := 0;
      Scale[lI] := 1;
      FiltDim[lI] := 0;
    end;
    updateBackgroundGradientsGLSL := false;
    updateOverlayGradientsGLSL := false;
    NIFTIhdr.scl_slope := 1;
    NIFTIhdr.scl_inter := 0;
    isLabels := false;
    LabelRA := nil; //free memory
    SetLengthB(FiltImg,0);
    SetLengthB(RawUnscaledImgRGBA,0);
    {$IFDEF ENABLERAYCAST}SetLengthB(GradientImgRGBA,0);{$ENDIF}
    SetLengthB(RawUnscaledImg8,0);
    SetLength16(RawUnscaledImg16,0);
    SetLength32(RawUnscaledImg32,0);
    DataType := 0;
    BytesPerVoxel := 0;
  end; //with lTexture
end; //Init

procedure Data_Type_To_Texel_Byte_Size (var lTexture: TTexture);
//determine bytes per voxel
Begin
 with lTexture do begin
  Case lTexture.DataType Of
    GL_COLOR_INDEX : BytesPerVoxel := 1;
    GL_STENCIL_INDEX : BytesPerVoxel := 1;
    GL_DEPTH_COMPONENT :BytesPerVoxel := 1;
    GL_RED : BytesPerVoxel := 1;
    GL_GREEN : BytesPerVoxel := 1;
    GL_BLUE : BytesPerVoxel := 1;
    GL_ALPHA : BytesPerVoxel := 1;
    GL_RGB : BytesPerVoxel := 3;
    GL_RGBA : BytesPerVoxel := 4;
    GL_LUMINANCE : BytesPerVoxel := 1;
    GL_LUMINANCE_ALPHA : BytesPerVoxel := 2;
    Else BytesPerVoxel := 4;
  End; //Case
 end;//with lTexture
End; //Data_Type_To_Texel_Byte_Size

(*procedure ShowType (var lTexture: TTexture);
var
  S: string;
//determine bytes per voxel
Begin
 with lTexture do begin
  Case lTexture.DataType Of
    GL_COLOR_INDEX : S := 'COLOR_INDEX';
    GL_STENCIL_INDEX : S := 'GL_STENCIL_INDEX';
    GL_DEPTH_COMPONENT :S := 'GL_DEPTH_COMPONENT';
    GL_RED : S := 'GL_RED';
    GL_GREEN : S := 'GL_GREEN';
    GL_BLUE : S := 'GL_BLUE';
    GL_ALPHA : S := 'GL_ALPHA';
    GL_RGB : S := 'GL_RGB';
    GL_RGBA : S := 'GL_RGBA';
    GL_LUMINANCE : S := 'GL_LUMINANCE';
    GL_LUMINANCE_ALPHA : S := 'GL_LUMINANCE_ALPHA';
    Else S := '??';;
  End; //Case
 end;//with lTexture
 showmessage('Type '+S);
end; //Data_Type_To_Texel_Byte_Size *)

Procedure NormalizeVector (var lX,lY,lZ: single);
var
  V: single;
begin
  V := Sqrt(sqr(lx)+sqr(ly)+sqr(lZ));
  if V = 0 then
    exit;
  lX := lX/V;
  lY := lY/V;
  lZ := lZ/V;
end;

function IsLabels (var lHdr: TNIfTIHdr): boolean;
//return TRUE for neurolabels
begin
 result :=  (lHdr.intent_code= kNIFTI_INTENT_LABEL) and (lHdr.bitpix <= 16) ;
end;

procedure MakeBorg(Dim: integer; var lImgBuffer: byteP);
const
  Border = 4;//margin so we can calculate gradients at edge
var
  F: array of single;
  mn, mx, scale: single;
  I, X, Y, Z: integer;
begin
  SetLength(F, Dim*Dim*Dim);
  Scale := 0.005;
  I := 0;
  for X := 0 to Dim-1 do
    for Y := 0 to Dim-1 do
      for Z := 0 to Dim-1 do
      begin
        if (X < Border) or (Y < Border) or (Z < Border) or ((Dim-X) < Border) or ((Dim-Y) < Border) or ((Dim-Z) < Border) then
          F[I] := 0
        else
          F[I] := sin(scale *x *y) + sin(scale *y * z) + sin(scale *z * x);
        Inc(I);
      end;
  //next find range...
  mn := F[0];
  for I := 0 to Dim*Dim*Dim-1 do
    if F[I] < mn then
      mn := F[I];
  mx := F[0];
  for I := 0 to Dim*Dim*Dim-1 do
    if F[I] > mx then
      mx := F[I];
  scale := 255/(mx-mn);
  for I := 0 to Dim*Dim*Dim-1 do begin
    if F[I] <= 0 then
      lImgBuffer^[I+1] := 0
    else
      lImgBuffer^[I+1] := Round((F[I]-mn)*scale);
  end;
  F := nil;
end;

procedure MakeL(Dim: integer; var lImgBuffer: byteP);
var
  lX,lY,lZ,lFileBytes,lI: integer;
begin
  lFileBytes := Dim*Dim*Dim;
  for lI := 1 to lFilebytes do
    lImgBuffer^[lI] := 0;
  lI := 0;
  for lZ := 1 to Dim do
    for lY := 1 to Dim do
      for lX := 1 to Dim do begin
        inc(lI);
        if (lZ > 10) and (lZ < 20) then
          lImgBuffer^[lI] := lX;
        if (lY > 10) and (lY < 20) then
          lImgBuffer^[lI] := lX;
      end;//X
end; //proc Make L

//generate volume dynamically instead of loading from disk
function NIFTIhdr_LoadDummyImg (var lHdr: TMRIcroHdr; var lImgBuffer: byteP): boolean;
const
  kSz = 64;
var
  lFileBytes: integer;
begin
  NIFTIhdr_ClearHdr(lHdr);
  with lHdr.NIFTIhdr do begin
    dim[1] := kSz;
    dim[2] := kSz;
    dim[3] := kSz;
    bitpix := 8;//vc16; {8bits per pixel, e.g. unsigned char 136}
    DataType := kDT_UNSIGNED_CHAR;// 2;//vc4;{2=unsigned char, 4=16bit int 136}
  end;
  lFileBytes := kSz * kSz * kSz;
  GetMem(lImgBuffer,lFileBytes);
  MakeBorg(kSz,lImgBuffer);
  result := true;
end;

function NIFTIhdr_LoadImg (var lFilename: string; var lHdr: TMRIcroHdr; var lImgBuffer: byteP; lVolume: integer): boolean;
//loads img to byteP - if this returns successfully you must freemem(lImgBuffer)
var

  lImgName: string;
   lVolOffset,lnVol,lVol,lFileBytes,lImgBytes: integer;
   lBuf: ByteP;
   lInF: File;
begin
    result := false;
    if not NIFTIhdr_LoadHdr (lFilename, lHdr) then
        exit;
   if lHdr.NIFTIhdr.dim[4] < 1 then
    lHdr.NIFTIhdr.dim[4] := 1;
   if lHdr.NIFTIhdr.dim[5] < 1 then
    lHdr.NIFTIhdr.dim[5] := 1;
   lnVol := lHdr.NIFTIhdr.dim[4]*lHdr.NIFTIhdr.dim[5]; //Time+Direction
   lVol := lVolume;
   if (lVol < 1) or (lVol > lnVol) then
    lVol := lnVol;
   if lHdr.NIFTIhdr.datatype = kDT_RGB then begin
      lHdr.NIFTIhdr.bitpix := 24;
      lVol := 1; //read all RGB planes, later on we can separate different planes
   end;
   //GLForm1.Caption := inttostr(lHdr.NIFTIhdr.dim[1])+'x'+inttostr(lHdr.NIFTIhdr.dim[2])+'x'+inttostr(lHdr.NIFTIhdr.dim[3])+ ' '+inttostr(lHdr.NIFTIhdr.bitpix);
   lImgBytes := lHdr.NIFTIhdr.dim[1]*lHdr.NIFTIhdr.dim[2]*lHdr.NIFTIhdr.dim[3]*(lHdr.NIFTIhdr.bitpix div 8);
   if lImgBytes < 1 then begin
    GLForm1.ShowmessageError(format('Image dimensions do not make sense (x*y*z*bpp = %d*%d*%d*%d)',[lHdr.NIFTIhdr.dim[1], lHdr.NIFTIhdr.dim[2], lHdr.NIFTIhdr.dim[3], (lHdr.NIFTIhdr.bitpix div 8)]) );
    exit;

   end;
   lVolOffset := (lVol-1) * lImgBytes;
   lImgName := lHdr.ImgFileName;
   if not fileexists(lImgName) then begin
       GLForm1.ShowmessageError('LoadImg Error: Unable to find '+lImgName);
       exit;
   end;
   if (lHdr.NiftiHdr.vox_offset < 0) then lHdr.NiftiHdr.vox_offset := 0;
   if (lHdr.gzBytes = K_gzBytes_headerAndImageUncompressed) and (FSize (lImgName) < (lHdr.NiftiHdr.vox_offset+ lImgBytes)) then begin
     GLForm1.ShowmessageError(format('LoadImg Error: File smaller (%d) than expected (%d+%d): %s',[FSize (lImgName), round(lHdr.NiftiHdr.vox_offset), lImgBytes,  lImgName]) );
     //GLForm1.ShowmessageError(format('LoadImg Error: File smaller (%d+%d) than expected (%d) : %s',[FSize (lImgName),lHdr.NiftiHdr.vox_offset, lImgBytes,  lImgName]) );
       exit;
   end;
   lFileBytes := lImgBytes;
   GetMem(lImgBuffer,lFileBytes);
   Filemode := 0;  //Read Only - allows us to open images where we do not have permission to modify
   if (lHdr.gzBytes = K_gzBytes_headerAndImageUncompressed) then begin
      AssignFile(lInF, lImgName);
       Reset(lInF,1);
       Seek(lInF,lVolOffset+round(lHdr.NiftiHdr.vox_offset));
       BlockRead(lInF, lImgBuffer^[1],lImgBytes);
       CloseFile(lInF);
   end else begin
       lBuf := @lImgBuffer^[1];
      {$IFDEF GZIP}
      if (lHdr.gzBytes = K_gzBytes_onlyImageCompressed) then
        UnGZip2 (lImgName,lBuf, lVolOffset ,lImgBytes, round(lHdr.NIFtiHdr.vox_offset))
      else
        UnGZip (lImgName,lBuf, lVolOffset+round(lHdr.NIFtiHdr.vox_offset),lImgBytes);
      {$ENDIF}
   end;
   Filemode := 2;  //Read/Write
   result := true;
end;

procedure PowerOfTwo(Var lDim, lPad: integer);
//return 2^n that is equal or larger than the input lDim value
// e.g. if lDim is 129..256 then this procedure will return 256
var
  lResult: integer;
begin
  lResult := 2;
  while (lResult < lDim) do
    lResult := lResult * 2;
  lPad := (lResult - lDim) div 2;
  lDim := lResult;
end;

procedure PadPrime(Var lDim : integer);
//return 2^n that is equal or larger than the input lDim value
// e.g. if lDim is 129..256 then this procedure will return 256
const
  knPrime = 97;
  kPrime : array  [1..knPrime] of integer =
      (5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,
      101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,
      193,197,199,211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,
      293,307,311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,401,
      409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499,503,509,521,523);
var
  lResult,lI: integer;
begin
  lResult := lDim;
  if lDim < 4 then
    lResult := 4
  else begin
    for lI := 1 to knPrime do begin
      if lDim = kPrime[lI] then begin
        lResult := lDim + 1;
      end;
    end;
  end;
  lDim := lResult;
end;

procedure PadThin(Var lDim : integer);
//We will strip the top slice - this is a problem if the image is very thin in the Z dimension
begin
  if lDim < 4 then
    inc(lDim);
end;

procedure ClearSlice (var lTexture: TTexture; lSlice: integer; lVal: single);
var
  lSliceVox, lOffset, lVox,lVali: integer;
begin
  if (lSlice < 1) or (lSlice > lTexture.FiltDim[3]) then
    exit;
  lSliceVox := lTexture.FiltDim[1] * lTexture.FiltDim[2];
  if lSliceVox < 1 then
    exit;
  lOffset := (lSlice-1) * lSliceVox;
  lVali := round(lVal);
  if lTexture.RawUnscaledImg8 <> nil then
     for lVox := 0 to (lSliceVox-1) do //set padded regions to minimum value
        lTexture.RawUnscaledImg8^[lVox+lOffset] := lVali
  else if lTexture.RawUnscaledImg16 <> nil then
     for lVox := 0 to (lSliceVox-1) do //set padded regions to minimum value
        lTexture.RawUnscaledImg16^[lVox+lOffset] := lVali
  else if lTexture.RawUnscaledImg32 <> nil then
     for lVox := 0 to (lSliceVox-1) do //set padded regions to minimum value
        lTexture.RawUnscaledImg32^[lVox+lOffset] := lVal
  else if lTexture.RawUnscaledImgRGBA <> nil then begin
     lOffset := ((lSlice-1) * lSliceVox * 4) +1;//GREEN USED FOR ALPHA
     for lVox := 0 to (lSliceVox-1) do begin //set padded regions to minimum value
        lTexture.RawUnscaledImgRGBA^[lOffset] := 0;  //
        inc(lOffset,4);
     end;
  end;
end;

procedure Float64ToFloat32 (var lHdr: TMRIcroHdr; var lImgBuffer: byteP);
var
  lI,lInVox: integer;
  l64Buf : DoubleP;
  lV: double;
  l32TempBuf,l32Buf : SingleP;
begin
	  if lHdr.NIFTIHdr.datatype <> kDT_DOUBLE then
      exit;
    lInVox :=  lHdr.NIFTIhdr.dim[1] *  lHdr.NIFTIhdr.dim[2] * lHdr.NIFTIhdr.dim[3];
    l64Buf := DoubleP(lImgBuffer );
    GetMem(l32TempBuf ,lInVox*sizeof(single));
    if not lHdr.DiskDataNativeEndian then begin
        for lI := 1 to lInVox do begin
                         try
                            l32TempBuf^[lI] := Swap64r(l64Buf^[lI])
                         except
                            l32TempBuf^[lI] := 0;
                         end; //except
        end; //for
    end else begin  //convert integer to float
			 for lI := 1 to lInVox do begin
                        // try
                        lV := l64Buf^[lI];
                            l32TempBuf^[lI] := lV;//
                       //  except
                       //     l32TempBuf^[lI] := 0;
                       //  end; //except
       end;
    end;
    freemem(lImgBuffer);
    GetMem(lImgBuffer ,lInVox*sizeof(single));
    l32Buf := SingleP(lImgBuffer );
    Move(l32TempBuf^,l32Buf^,lInVox*sizeof(single));
    freemem(l32TempBuf);
    for lI := 1 to lInVox do
			if specialsingle(l32Buf^[lI]) then l32Buf^[lI] := 0.0;
    lHdr.NIFTIHdr.datatype := kDT_FLOAT;
    lHdr.DiskDataNativeEndian := true;
    lHdr.NIFTIhdr.bitpix := 32;
end;//Float64ToFloat32

procedure PadTransform(var lPadX,lPadY,lPadZ: integer; var lHdr : TNIFTIHdr);
var
     lInMat,lTransMat,lResidualMat: TMatrix;
begin
  if (lPadX=0) and (lPadY=0) and (lPadZ = 0) then
    exit;
   lInMat := Matrix3D (
    lHdr.srow_x[0],lHdr.srow_x[1],lHdr.srow_x[2],lHdr.srow_x[3],
    lHdr.srow_y[0],lHdr.srow_y[1],lHdr.srow_y[2],lHdr.srow_y[3],
    lHdr.srow_z[0],lHdr.srow_z[1],lHdr.srow_z[2],lHdr.srow_z[3]);
   lTransMat := Matrix3D (
    1,0,0,-lPadX,
    0,1,0,-lPadY,
    0,0,1,-lPadZ);
  lResidualMat := multiplymatrices(lInMat,lTransMat); //source
  lHdr.srow_x[0] := lResidualMat.Matrix[1,1];
  lHdr.srow_x[1] := lResidualMat.Matrix[1,2];
  lHdr.srow_x[2] := lResidualMat.Matrix[1,3];
  lHdr.srow_y[0] := lResidualMat.Matrix[2,1];
  lHdr.srow_y[1] := lResidualMat.Matrix[2,2];
  lHdr.srow_y[2] := lResidualMat.Matrix[2,3];
  lHdr.srow_z[0] := lResidualMat.Matrix[3,1];
  lHdr.srow_z[1] := lResidualMat.Matrix[3,2];
  lHdr.srow_z[2] := lResidualMat.Matrix[3,3];
  lHdr.srow_x[3] := lResidualMat.Matrix[1,4];
  lHdr.srow_y[3] := lResidualMat.Matrix[2,4];
  lHdr.srow_z[3] := lResidualMat.Matrix[3,4];
end;

function InRange(ImgMin,ImgMax,WinMin,WinMax: single): boolean;
//returns true if window includes some portion of imgmin..imgmax.
begin
  result := true;
  if (WinMin<ImgMin) and (WinMax<ImgMin) and (WinMin<ImgMax) and (WinMax<ImgMax) then
    result := false;
  if (WinMin>ImgMin) and (WinMax>ImgMin) and (WinMin>ImgMax) and (WinMax>ImgMax) then
    result := false;
end;

procedure Uint16ToFloat32 (var lHdr: TMRIcroHdr; var lImgBuffer: byteP);
var
  lI,lInVox: integer;
  l16Buf : WordP;
  lV: double;
  l32TempBuf,l32Buf : SingleP;
begin
  if lHdr.NIFTIHdr.datatype <> kDT_UINT16 then
      exit;
    lInVox :=  lHdr.NIFTIhdr.dim[1] *  lHdr.NIFTIhdr.dim[2] * lHdr.NIFTIhdr.dim[3];
    l16Buf := WordP(lImgBuffer );
    GetMem(l32TempBuf ,lInVox*sizeof(single));
    if not lHdr.DiskDataNativeEndian then begin
        for lI := 1 to lInVox do begin
                         try
                            l32TempBuf^[lI] := Swap(l16Buf^[lI])
                         except
                            l32TempBuf^[lI] := 0;
                         end; //except
        end; //for
    end else begin  //convert integer to float
			 for lI := 1 to lInVox do begin
                        // try
                        lV := l16Buf^[lI];
                            l32TempBuf^[lI] := lV;//
                       //  except
                       //     l32TempBuf^[lI] := 0;
                       //  end; //except
       end;
    end;
    freemem(lImgBuffer);
    GetMem(lImgBuffer ,lInVox*sizeof(single));
    l32Buf := SingleP(lImgBuffer );
    Move(l32TempBuf^,l32Buf^,lInVox*sizeof(single));
    freemem(l32TempBuf);
    for lI := 1 to lInVox do
			if specialsingle(l32Buf^[lI]) then l32Buf^[lI] := 0.0;
    lHdr.NIFTIHdr.datatype := kDT_FLOAT;
    lHdr.DiskDataNativeEndian := true;
    lHdr.NIFTIhdr.bitpix := 32;
end;//Float64ToFloat32

function isPlanarImg(  rawRGB: bytep;  lX, lY, lZ: integer): boolean ;
var
 pos, posEnd, incPlanar, incPacked, byteSlice: integer;
 dxPlanar, dxPacked: double;
begin
  //determine if RGB image is PACKED TRIPLETS (RGBRGBRGB...) or planar (RR..RGG..GBB..B)
  //assumes strong correlation between voxel and neighbor on next line
  result := false;
  if (lY < 2) then exit; //requires at least 2 rows of data
  incPlanar := lX; //increment next row of PLANAR image
  incPacked := lX * 3; //increment next row of PACKED image
  byteSlice := incPacked * lY; //bytes per 3D slice of RGB data
  dxPlanar := 0.0;//difference in PLANAR
  dxPacked := 0.0;//difference in PACKED
  pos := ((lZ div 2) * byteSlice)+1; //offset to middle slice for 3D data
  posEnd := pos + byteSlice - incPacked;
  while (pos <= posEnd) do begin
    dxPlanar := dxPlanar + abs(rawRGB[pos]-rawRGB[pos+incPlanar]);
    dxPacked := dxPacked + abs(rawRGB[pos]-rawRGB[pos+incPacked]);
    pos := pos + 1;
  end;
  result := (dxPlanar < dxPacked);
end;

function RGB2RGBA(var lHdr: TNIFTIhdr; lRGB: bytep; lOutBytes, lTexX, lTexY: integer): bytep0;
//convert RGB to RGBA, optionally convert planar RGB (RRR...RGGG...GBBB...B to RGBARGBARGBA
var             //lBytesRGB,lBytesRGBA, lRGBstart,lRGBAstat
  lOutSliceSz, lInSliceSz, lXYZ, lXY, lX,lY, lZ, lOutPos, lInPos: integer;
  isPlanarRGB: boolean;
  lRGBA: Bytep0;
begin
    result := nil;
    if lHdr.datatype <> kDT_RGB then exit; //not RGB data
    lRGBA := nil;
    SetLengthB(lRGBA,lOutBytes);
    lOutSliceSz := lTexX*lTexY; //may be padded!
    lInSliceSz := lHdr.dim[1]*lHdr.dim[2];
    lOutPos := 0;
    if gPrefs.PlanarRGB = 0 then
       isPlanarRGB := false
    else if gPrefs.PlanarRGB = 1 then
       isPlanarRGB := true
    else
        isPlanarRGB :=  isPlanarImg(lRGB, lHdr.Dim[1], lHdr.Dim[2], lHdr.Dim[3]);
    if not isPlanarRGB then begin   //for data rgbrgbrgb...
      if (lInSliceSz <> lOutSliceSz) then begin //for padded data
        for lZ := 0 to (lOutBytes-1) do
            lRGBA^[lZ] := 0;
        lInPos := 1;
        for lZ := 0 to (lHdr.dim[3]-1) do begin
           for lY := 1 to lHdr.dim[2] do begin
               lOutPos := (lZ * lOutSliceSz * 4)+((lY-1)*  lTexX * 4);
               for lX := 1 to lHdr.dim[1] do begin
                  lRGBA^[lOutPos] := lRGB^[lInPos]; //red
                  inc(lOutPos);  inc(lInPos);
                  lRGBA^[lOutPos] := lRGB^[lInPos+lInSliceSz]; //green
                  inc(lOutPos); inc(lInPos);
                  lRGBA^[lOutPos] := lRGB^[lInPos+lInSliceSz+lInSliceSz]; //blue
                  inc(lOutPos);  inc(lInPos);
                  lRGBA^[lOutPos] := round(1/3 * (lRGBA^[lOutPos-1]+lRGBA^[lOutPos-2]+lRGBA^[lOutpos-3])); //alpha
                  inc(lOutPos);
               end; //for X
           end; //for Y
         end; //for Z
      end else begin //data not padded
       lXYZ := lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3];
       lInPos := 1;
       for lZ := 0 to (lXYZ-1) do begin
           lRGBA^[lOutPos] := lRGB^[lInPos]; //red plane
           inc(lOutPos);  inc(lInPos);
           lRGBA^[lOutPos] := lRGB^[lInPos]; //green plane
           inc(lOutPos);   inc(lInPos);
           lRGBA^[lOutPos] := lRGB^[lInPos]; //blue plane
           inc(lOutPos);   inc(lInPos);
           lRGBA^[lOutPos] := round(1/3 * (lRGBA^[lOutPos-1]+lRGBA^[lOutPos-2]+lRGBA^[lOutpos-3])); //alpha
           inc(lOutPos);
         end;//for each voxel Z
       end; //if not padded
    end else begin  //next for data saved planar
      if (lInSliceSz <> lOutSliceSz) then begin //for padded data
        for lZ := 0 to (lOutBytes-1) do
            lRGBA^[lZ] := 0;
        for lZ := 0 to (lHdr.dim[3]-1) do begin
           lInPos := (lZ * lInSliceSz * 3)+1;
           for lY := 1 to lHdr.dim[2] do begin
               lOutPos := (lZ * lOutSliceSz * 4)+((lY-1)*  lTexX * 4);
               for lX := 1 to lHdr.dim[1] do begin
                lRGBA^[lOutPos] := lRGB^[lInPos]; //red plane
                inc(lOutPos);
                lRGBA^[lOutPos] := lRGB^[lInPos+lInSliceSz]; //green plane
                inc(lOutPos);
                lRGBA^[lOutPos] := lRGB^[lInPos+lInSliceSz+lInSliceSz]; //blue plane
                inc(lOutPos);
                lRGBA^[lOutPos] := round(1/3 * (lRGBA^[lOutPos-1]+lRGBA^[lOutPos-2]+lRGBA^[lOutpos-3])); //alpha
                inc(lOutPos);
                inc(lInPos);
               end; //for X
           end; //for Y
         end; //for Z
      end else begin //data not padded
       for lZ := 0 to (lHdr.dim[3]-1) do begin
           lInPos := (lZ * lInSliceSz * 3)+1;
           for lXY := 1 to lInSliceSz do begin
              lRGBA^[lOutPos] := lRGB^[lInPos]; //red plane
              inc(lOutPos);
              lRGBA^[lOutPos] := lRGB^[lInPos+lInSliceSz]; //green plane
              inc(lOutPos);
              lRGBA^[lOutPos] := lRGB^[lInPos+lInSliceSz+lInSliceSz]; //blue plane
              inc(lOutPos);
              lRGBA^[lOutPos] := round(1/3 * (lRGBA^[lOutPos-1]+lRGBA^[lOutPos-2]+lRGBA^[lOutpos-3])); //alpha
              inc(lOutPos);
              inc(lInPos);
           end;//for XY
         end;//for Z
       end; //if not padded
    end; //if triplet else planar
    result := lRGBA;
end;

procedure SetOriginXYZ (var lTexture3D: TTexture);
var
  lInvMat: TMatrix ;
  lOK: boolean;
  lXmm,lYmm,lZmm: single;
begin
  gRayCast.OrthoX := 0.5;
  gRayCast.OrthoY := 0.5;
  gRayCast.OrthoZ := 0.5;
  if true and  (lTexture3D.FiltDim[1] > 1) or (lTexture3D.FiltDim[2] > 1) or (lTexture3D.FiltDim[3] > 1) then begin
      lInvMat := Hdr2InvMat (lTexture3D.NIftiHdr,lOK);
      if not lOK or isIdentity(lInvMat) then exit;

      lXmm := 0;
      lYmm := 0;
      lZmm := 0;
      mm2Voxel (lXmm,lYmm,lZmm, lInvMat);
      gRayCast.OrthoX := (lXmm-1)/(lTexture3D.FiltDim[1]-1);
      gRayCast.OrthoY := (lYmm-1)/(lTexture3D.FiltDim[2]-1);
      gRayCast.OrthoZ := (lZmm-1)/(lTexture3D.FiltDim[3]-1);
      if (gRayCast.OrthoX < 0.0) or (gRayCast.OrthoX > 1.0) then gRayCast.OrthoX := 0.5;
      if (gRayCast.OrthoY < 0.0) or (gRayCast.OrthoY > 1.0) then gRayCast.OrthoY := 0.5;
      if (gRayCast.OrthoZ < 0.0) or (gRayCast.OrthoZ > 1.0) then gRayCast.OrthoZ := 0.5;
  end;
end;

Function Load_From_NIfTI (var lTexture: TTexture; Const F_FileName : String; lPowerOfTwo: boolean; lVol: integer) : boolean;
var
  CalRange, ImgRange: double;
  lPadX,lPadY,lPadZ,lI,lZ,lY,lX,lSLiceStart,lLineStart,
  lPos,lInVox,lOutVox, lLog10: integer;
  lMinS,lMaxS: single;
  lFilename: string;
  lHdr: TMRIcroHdr;
  lImgBuffer: byteP;
  l16Buf : SmallIntP;
  l32Buf : SingleP;
begin //Proc Load_From_NIfTI
//There are two approaches to spatial coordinates -
//  1.) Multiply NIfTI matrix by OpenGL coordinates: simple
//      but angle of things like clip planes is not intuitive
//  2.) Reorient data to be in closest orthogonal plane to OpenGL space - see reorientcore
//  Here I take the latter approach
    result :=false;
    lFilename := F_Filename;
    //deleteGradients (lTexture);
    InitTexture(lTexture);

    if lFilename = '' then begin
      if not NIFTIhdr_LoadDummyImg (lHdr, lImgBuffer) then
        exit;
    end else
    {$IFDEF LOADDUMMY}
    if not NIFTIhdr_LoadDummyImg (lHdr, lImgBuffer) then
      exit;
    {$ELSE}
    if not NIFTIhdr_LoadImg (lFilename, lHdr, lImgBuffer,lVol) then begin
      //exit;
      if not NIFTIhdr_LoadDummyImg (lHdr, lImgBuffer) then
        exit;
    end;
    {$ENDIF}
    lTexture.NIFTIhdr := lHdr.NIFTIhdr;
    lTexture.NIFTIhdrRaw := lHdr.NIFTIhdr;
    //lTexture.isMRA := IsMRA(lHdr.NIFTIHdr);
    lTexture.isLabels := IsLabels(lHdr.NIFTIHdr);
    if lTexture.isLabels then begin
      if (( lHdr.NIFTIhdr.vox_offset- lHdr.NIFTIhdr.HdrSz) > 128) then
        LoadLabels(lFileName, lTexture.LabelRA, lHdr.NIFTIhdr.HdrSz, round( lHdr.NIFTIhdr.vox_offset))
      else
        LoadLabelsTxt(lFileName, lTexture.LabelRA);
    end else
        lTexture.LabelRA := nil;
    Int32ToFloat(lHdr,lImgBuffer);
    Uint32ToFloat(lHdr,lImgBuffer);
    Uint16ToFloat32(lHdr,lImgBuffer);
    Float64ToFloat32(lHdr,lImgBuffer);
    NIFTIhdr_UnswapImg (lHdr,lImgBuffer); //ensures image data is in native byteorder
    Float32RemoveNAN(lHdr,lImgBuffer);
    NIFTIhdr_MinMaxImg (lHdr,lImgBuffer); //sets global minmax
    if (lHdr.NIFTIhdr.datatype <> kDT_UINT32) and not (lHdr.NIFTIHdr.datatype in [kDT_UNSIGNED_CHAR, kDT_SIGNED_SHORT, kDT_FLOAT,kDT_RGB]) then begin
      freemem(lImgBuffer);
      GLForm1.ShowmessageError('Error: currently only able to read 8, 16, 32-bit integers, 32-bit floats, or 24-bit RGB data.');
      exit;//abort - unsupported format
    end;
    if lHdr.NIFTIHdr.datatype <> kDT_RGB then
    ReorientCore(lHdr.NIFTIHdr, lImgBuffer);   //deal with planar
    ShrinkLarge(lHdr.NIFTIHdr, lImgBuffer, gPrefs.MaxVox);
    //GLForm1.Label4.Caption := inttostr(lHdr.NIFTIhdr.dim[1])+'x'+inttostr(lHdr.NIFTIhdr.dim[2])+'x'+inttostr(lHdr.NIFTIhdr.dim[3]);
    lInVox :=  lHdr.NIFTIhdr.dim[1] *  lHdr.NIFTIhdr.dim[2] * lHdr.NIFTIhdr.dim[3];
    for lI := 1 to 3 do
      lTexture.FiltDim[lI] := lHdr.NIFTIhdr.dim[lI];
    //next get pixel spacing in mm...
    lTexture.PixMM[1] := abs(lHdr.NIFTIhdr.PixDim[1]);//use absolute -some people use negative values for flipped dimensions
    lTexture.PixMM[2] := abs(lHdr.NIFTIhdr.PixDim[2]);
    lTexture.PixMM[3] := abs(lHdr.NIFTIhdr.PixDim[3]);
    if lTexture.PixMM[1] = 0 then
      lTexture.PixMM[1] := 1;
    if lTexture.PixMM[2] = 0 then
      lTexture.PixMM[2] := 1;
    if lTexture.PixMM[3] = 0 then
      lTexture.PixMM[3] := 1;
    //next: as of 2008, OpenGL crashes if slice dimension is a prime number
    //  a quick an dirty solution is to pad images...
    //  this slows down the writing of our output images
    //  Modern NVidia cards do not care if the number of slices [Z-dimension] are even, but ATI X1600 Radeons does
    lPadX := 0;
    lPadY := 0;
    lPadZ := 0;
    //GLForm1.Label4.Caption := inttostr(lTexture.FiltDim[1])+'x'+inttostr(lTexture.FiltDim[2])+'x'+inttostr(lTexture.FiltDim[3]);
    //PadThin(lTexture.FiltDim[3]);

    if (lPowerOfTwo) or (gPrefs.ForcePowerOfTwo) then begin
        PowerOfTwo(lTexture.FiltDim[1],lPadX);
        PowerOfTwo(lTexture.FiltDim[2],lPadY);
        PowerOfTwo(lTexture.FiltDim[3],lPadZ);
        PadTransform(lPadX,lPadY,lPadZ, lHdr.NIFTIHdr);
    {$IFDEF UNIX}
    end else  begin
        //We padded data for the texture-slice based rendering - no longer required!
        //PadPrime(lTexture.FiltDim[1] {,lPadX});
        //PadPrime(lTexture.FiltDim[2]{,lPadY});
    {$ELSE}
    end else begin
      //Windows OpenGL implementation does not require padding data..
    {$ENDIF}
    end;//not power of two
    //Overlays need to be aligned - the next 3 lines adjust the background relative to the overlay
    lTexture.DataType := GL_RGBA ;
    Data_Type_To_Texel_Byte_Size (lTexture);
    lOutVox :=  lTexture.FiltDim[1] * lTexture.FiltDim[2] * lTexture.FiltDim[3];
    if lHdr.NIFTIHdr.datatype = kDT_UNSIGNED_CHAR then begin //Luminance
      SetLengthB(lTexture.RawUnscaledImg8,   lOutVox);
      if lOutVox = lInVox then begin //DEC09... no padding
        Move(lImgBuffer^,lTexture.RawUnscaledImg8^,lInVox);//source/dest
      end else begin
        lI := 0;//lImgBuffer^[1];
        for lZ := 0 to (lOutVox-1) do //set padded regions to minimum value
          lTexture.RawUnscaledImg8^[lZ] := lI;
        lPos := 0;
        for lZ := 0 to (lHdr.NIFTIhdr.dim[3]-1) do begin
          lSliceStart := (lPadZ+lZ) * (lTexture.FiltDim[1]*lTexture.FiltDim[2]);
          for lY := 0 to (lHdr.NIFTIhdr.dim[2]-1) do begin
            lLineStart := lSLiceStart+((lPadY+lY) * lTexture.FiltDim[1]);
            lI := lPadX;
            for lX := 0 to (lHdr.NIFTIhdr.dim[1]-1) do begin
              inc(lPos);
              lTexture.RawUnscaledImg8^[lLineStart+lI ] := lImgBuffer^[lPos];
              inc(lI);
            end;//for X
          end;//for Y
        end;//for Z
      end;//padded
    end; //8bit
    if lHdr.NIFTIHdr.datatype = kDT_SIGNED_SHORT then begin //16-bit
      l16Buf := SmallIntP(lImgBuffer);
      {UnswapImg already computed...
      if not lHdr.DiskDataNativeEndian then
        for lPos := 1 to lInVox do
			    l16Buf^[lPos] := Swap(l16Buf^[lPos]);}
      SetLength16(lTexture.RawUnscaledImg16,   lOutVox* 2);
      if lOutVox = lInVox then begin //no padding
        Move(l16Buf^,lTexture.RawUnscaledImg16^,lOutVox* 2);//source/dest
      end else begin //not padded
        lI := l16Buf^[1];
        for lZ := 0 to (lOutVox-1) do //set padded regions to minimum value
          lTexture.RawUnscaledImg16^[lZ] := lI;
        lPos := 0;
        for lZ := 0 to (lHdr.NIFTIhdr.dim[3]-1) do begin
          lSliceStart := (lPadZ+lZ) * (lTexture.FiltDim[1]*lTexture.FiltDim[2]);
          for lY := 0 to (lHdr.NIFTIhdr.dim[2]-1) do begin
            lLineStart := lSLiceStart+((lPadY+lY) * lTexture.FiltDim[1]);
            lI := lPadX;
            for lX := 0 to (lHdr.NIFTIhdr.dim[1]-1) do begin
              inc(lPos);
              lTexture.RawUnscaledImg16^[lLineStart+lI ] := l16Buf^[lPos];
              inc(lI);
            end;//for X
          end;//for Y
        end;//for Z
      end;//padded
    end; //16-bit integer datatype
    if lHdr.NIFTIHdr.datatype = kDT_FLOAT then begin //32-bit float
      l32Buf := SingleP(lImgBuffer);
      SetLength32(lTexture.RawUnscaledImg32,   lOutVox* 4);
      if lOutVox = lInVox then begin //no padding
        Move(l32Buf^,lTexture.RawUnscaledImg32^,lOutVox* 4);//source/dest
      end else begin //not padded
        lMinS := l32Buf^[1];
        for lZ := 0 to (lOutVox-1) do //set padded regions to minimum value
          lTexture.RawUnscaledImg32^[lZ] := lMinS;
        lPos := 0;
        for lZ := 0 to (lHdr.NIFTIhdr.dim[3]-1) do begin
          lSliceStart := (lPadZ+lZ) * (lTexture.FiltDim[1]*lTexture.FiltDim[2]);
          for lY := 0 to (lHdr.NIFTIhdr.dim[2]-1) do begin
            lLineStart := lSLiceStart+((lPadY+lY) * lTexture.FiltDim[1]);
            lI := lPadX;
            for lX := 0 to (lHdr.NIFTIhdr.dim[1]-1) do begin
              inc(lPos);
              lTexture.RawUnscaledImg32^[lLineStart+lI ] := l32Buf^[lPos];
              inc(lI);
            end;//for X
          end;//for Y
        end;//for Z
      end;//padded
      //ComputeMinMax( lTexture);
    end; //32-bit FLOAT datatype
    if lHdr.NIFTIHdr.datatype = kDT_RGB then begin
      lTexture.RawUnscaledImgRGBA := RGB2RGBA(lHdr.NIFTIHdr, lImgBuffer, lOutVox* lTexture.BytesPerVoxel, lTexture.FiltDim[1], lTexture.FiltDim[2]);

      lHdr.NIFTIHdr.bitpix := 32;
      ReorientCore(lHdr.NIFTIHdr, bytep(lTexture.RawUnscaledImgRGBA));
      end;
       (*
    if lHdr.NIFTIHdr.datatype = kDT_RGB then begin //RGB
        SetLengthB(lTexture.RawUnscaledImgRGBA,   lOutVox* lTexture.BytesPerVoxel);
        fillchar(lTexture.RawUnscaledImgRGBA^,lOutVox* lTexture.BytesPerVoxel,0);
      lInSliceSz := lHdr.NIFTIhdr.dim[1]*lHdr.NIFTIhdr.dim[2];
       for lZ := 0 to (lHdr.NIFTIhdr.dim[3]-1) do begin
        lSliceStart := (lPadZ+lZ) * (lTexture.FiltDim[1]*lTexture.FiltDim[2]*4);
        lPos := lZ * (lHdr.NIFTIhdr.dim[1]*lHdr.NIFTIhdr.dim[2]*3);//input is planar RGB slices
        for lY := 0 to (lHdr.NIFTIhdr.dim[2]-1) do begin
          lIndex := lSLiceStart+( (lY+lPadY) * lTexture.FiltDim[1]*4);
          lIndex := lIndex + (lPadX* 4);
          for lX := 0 to (lHdr.NIFTIhdr.dim[1]-1) do begin
            //output stores data as contiguous bytes RGBARGBARGBA...
            //input is planar RRRRRRGGGGGBBBBB
            inc(lPos);
            lR := lImgBuffer^[lPos]; //red plane
            lG := lImgBuffer^[lPos+lInSliceSz]; //green plane
            lB := lImgBuffer^[lPos+lInSliceSz+lInSliceSz]; //blue plane
            valueB := (lR+lG+lB) div 3;
            lTexture.RawUnscaledImgRGBA^[ lIndex] := lR;//R
            lTexture.RawUnscaledImgRGBA^[ lIndex+1] := lG;//G
            lTexture.RawUnscaledImgRGBA^[ lIndex+2] := lB;//B
            lTexture.RawUnscaledImgRGBA^[ lIndex+3] := valueB;
            inc(lIndex,4);
          end;//for Z
        end;//for Y
       end;//for Z
      //end - extra slice to avoid clip bleeding
    end;     (**)

    //prepare Output data
    freemem(lImgBuffer);
    //next -generate LUT
    SetLengthB(lTexture.FiltImg,   lOutVox* lTexture.BytesPerVoxel);

    lMaxS := FloatMaxVal(lTexture.FiltDim[1]*lTexture.pixmm[1],lTexture.FiltDim[2]*lTexture.pixmm[2],lTexture.FiltDim[3]*lTexture.pixmm[3]);
    if (not gPrefs.ProportionalStretch)  then begin
      lMaxS := FloatMaxVal(lTexture.FiltDim[1],lTexture.FiltDim[2],lTexture.FiltDim[3]);
      lTexture.Scale[1] := lTexture.FiltDim[1] / lMaxS;
      lTexture.Scale[2] := lTexture.FiltDim[2] / lMaxS;
      lTexture.Scale[3] := lTexture.FiltDim[3] / lMaxS;
    end else if (lMaxS = 0) then begin
      lTexture.Scale[1] := 1;
      lTexture.Scale[2] := 1;
      lTexture.Scale[3] := 1;
    end else begin
      lTexture.Scale[1] := (lTexture.FiltDim[1]*lTexture.PixMM[1]) / lMaxS;
      lTexture.Scale[2] := (lTexture.FiltDim[2]*lTexture.PixMM[2]) / lMaxS;
      lTexture.Scale[3] := (lTexture.FiltDim[3]*lTexture.PixMM[3]) / lMaxS;
    end;
    ComputeMinMax(lTexture);
    CalRange :=  lHdr.NIFTIHdr.cal_max - lHdr.NIFTIHdr.cal_min;
    ImgRange := lTexture.WindowScaledMax - lTexture.WindowScaledMin;

    //GLForm1.caption := floattostr(CalRange)+'   '+floattostr(imgrange)+'  '+floattostr(lHdr.WindowScaledMin) +'   '+floattostr(lHdr.WindowScaledMax);
    //ClearSlice (lTexture, lTexture.Dim[3],Scaled2Unscaled(lTexture.WindowScaledMin,lTexture) ); //set all voxels in top slice to zero - prevents clipping artifacts
    //if  (lHdr.NIFTIHdr.cal_min < lHdr.NIFTIHdr.cal_max) then begin
    if (lHdr.NIFTIHdr.datatype = kDT_RGB) then begin
      lTexture.MinThreshScaled := 0;
      lTexture.MaxThreshScaled := 255;
      if ((lHdr.NIFTIHdr.cal_max - lHdr.NIFTIHdr.cal_min) > 1) then begin
        lTexture.MinThreshScaled := lHdr.NIFTIHdr.cal_min;
        lTexture.MaxThreshScaled := lHdr.NIFTIHdr.cal_max;
      end;
    end else if (lTexture.isLabels) then begin
      lTexture.MinThreshScaled := 0;
      lTexture.MaxThreshScaled := 100;
    end else if (CalRange < (1.2 * ImgRange)) and (lHdr.NIFTIHdr.cal_min < lHdr.NIFTIHdr.cal_max) and InRange(lTexture.WindowScaledMin,lTexture.WindowScaledMax,lHdr.NIFTIHdr.cal_min,lHdr.NIFTIHdr.cal_max) then begin
      //need to create histogram so user will see a CLUT in the 'Color&Transparency' window.... 1/2010

      CreateHistoThresh(lTexture, lTexture.WindowScaledMin, lTexture.WindowScaledMax, lTexture.UnscaledHisto, true,0,lTexture.MinThreshScaled,lTexture.MaxThreshScaled);
      lTexture.MinThreshScaled := lHdr.NIFTIHdr.cal_min;
      lTexture.MaxThreshScaled := lHdr.NIFTIHdr.cal_max;

      //fx(lTexture.MinThreshScaled,lTexture.MaxThreshScaled);
    //end else if lTexture.isMRA then begin
    //  CreateHistoThresh(lTexture, lTexture.WindowScaledMin, lTexture.WindowScaledMax, lTexture.UnscaledHisto, true,0,lTexture.MinThreshScaled,lTexture.MaxThreshScaled)
    end else begin
      CreateHistoThresh(lTexture, lTexture.WindowScaledMin, lTexture.WindowScaledMax, lTexture.UnscaledHisto, true, 0.005,lTexture.MinThreshScaled,lTexture.MaxThreshScaled);
      //GlForm1.IntensityBox.caption := format('%g  %g',[lTexture.MinThreshScaled,lTexture.MaxThreshScaled] );
      lLog10 := trunc(log10( lTexture.MaxThreshScaled-lTexture.MinThreshScaled))-2;
      lTexture.MinThreshScaled := lTexture.MinThreshScaled + 0.49999*power(10,lLog10); //round up to get rid of haze
      lTexture.MinThreshScaled := roundto(lTexture.MinThreshScaled,lLog10);
      lTexture.MaxThreshScaled := roundto(lTexture.MaxThreshScaled,lLog10);
    end;
    AutoContrast(gCLUTrec);
    RangeRec(lTexture.MinThreshScaled,lTexture.MaxThreshScaled);
    lTexture.NIFTIhdr := lHdr.NIFTIhdr;
    for lI := 1 to 3 do
      lTexture.NIFTIhdr.dim[lI] := lTexture.FiltDim[lI];
    result :=true;
    SetOriginXYZ(lTexture);

end; //Proc Load_From_NIfTI

end.


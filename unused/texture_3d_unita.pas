unit texture_3d_unita;
//This unit is used when USETRANSFERTEXTURE is defined in options.inc
//  Otherwise  texture_3d_unit is used

interface
{$H+}
{$include options.inc}
{$IFDEF FPC} {$DEFINE GZIP} {$ENDIF}

uses
  {$IFDEF GZIP}zstream, {$ENDIF}define_types, dglOpenGL,sysUtils, dialogs, math, classes,nifti_hdr, clut;

Type
  TTexture =  RECORD //3D data
    DataType: integer;
    Scale: array[1..3] of single;
    FiltDim : array [1..3] of integer;
    FiltImg: bytep0;
    hasGradients: boolean;
    WindowHisto: HistoRA;
    MinThreshScaled,MaxThreshScaled: single;
    NIFTIhdr: TNIFTIHdr;
    WindowScaledMax,WindowScaledMin: single;
    UnscaledHisto: HistoRA;
    RawUnscaledImgRGBA,RawUnscaledImg8: Bytep0;
    RawUnscaledImg16: SmallIntP0;
    RawUnscaledImg32: SingleP0;
end;

Function Load_From_NIfTI (var lTex: TTexture; Const F_FileName : String; lPowerOfTwo: boolean; lVol: integer) : boolean;
Procedure InitTexture (var lTexture: TTexture);
Procedure SetLengthB (var lPtr: Bytep0;lBytes: integer);
Procedure UpdateTransferFunctionX (lNodeRA: TCLUTrec; var TransferTexture : GLuint);

implementation
uses texture2raycast, raycastglsl;

type
  tVolW = array of word;

  Procedure UpdateTransferFunctionX (lNodeRA: TCLUTrec; var TransferTexture : GLuint);
var lCLUT: TLUT;
begin
  GenerateLUT(lNodeRA, lCLUT);
  glBindTexture(GL_TEXTURE_1D, TransferTexture);
  glTexImage1D(GL_TEXTURE_1D, 0, GL_RGBA, 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, @lCLUT[0]);
end;

Procedure InitTexture (var lTexture: TTexture);
begin
  lTexture.FiltImg := nil;
  lTexture.hasGradients := false;
end;

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

function LoadRaw(FileName : AnsiString; var   rawData: bytep0; var lHdr: TNIFTIHdr; lVol: integer): boolean;
//Uncompressed .nii or .hdr/.img pair
var
  Stream : TFileStream;
  lV: integer;
begin
  result := false;
  Stream := TFileStream.Create (FileName, fmOpenRead or fmShareDenyWrite);
  Try
    Stream.ReadBuffer (lHdr, SizeOf (TNIFTIHdr));
    if lHdr.HdrSz <> SizeOf (TNIFTIHdr) then begin
      showDebug('Unable to read image '+Filename+' - this software can only read uncompressed NIfTI files with the same endianess as the host CPU.');
      exit;
    end;
    if (lHdr.bitpix <> 8) and (lHdr.bitpix <> 16) and (lHdr.bitpix <> 24) then begin
      showDebug('Unable to load '+Filename+' - this software can only read 8,16,24-bit NIfTI files.');
      exit;
    end;
    //read the image data
    if extractfileext(Filename) = '.hdr' then begin
      Stream.Free;
      Stream := TFileStream.Create (changefileext(FileName,'.img'), fmOpenRead or fmShareDenyWrite);
    end;
    lV := lHdr.Dim[1]*lHdr.Dim[2]*lHdr.Dim[3]* (lHdr.bitpix div 8);
    Stream.Seek(round(lHdr.vox_offset)+(lV*(lVol-1)),soFromBeginning);
    SetLengthB (rawData, lV);
    Stream.ReadBuffer (rawData^[0], lV);
  Finally
    Stream.Free;
  End; { Try }
  result := true;
end;

function Word2Byte(var   rawData: bytep0; var lHdr: TNIFTIHdr): boolean;// Load 3D data                                                                 }
//convert 16-bit data to 8-bit
var
  i,vx: integer;
  scale: single;
  mn,mx: integer;
  Src,Temp: tVolW;
begin
    vx := (lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]);
	  if (lHdr.bitpix <> 16) or (vx < 1) then
      exit;
    setlength(Src,vx);
    Temp := tVolW(rawData );
    for i := 0 to (vx-1) do
        Src[i] := Temp[i];
    setlengthB(rawData,vx);
    mn := Src[0];
    mx := mn;
    for i := 0 to (vx-1) do begin
        if Src[i] > mx then mx := Src[i];
        if Src[i] < mn then mn := Src[i];
    end;
    if mn>=mx then //avoid divide by zero
      scale := 1
    else
      scale := 255/(mx-mn);
    for i := 0 to (vx-1) do
      rawdata^[i] := round((Src[i]-mn)*Scale);
    Src := nil;//free memory
end;

function RGB2RGBA(var   rawData: bytep0; var lHdr: TNIFTIHdr): boolean;// Load 3D data                                                                 }
//convert 24-bit RGB data to 32-bit
//  warning: NIfTI RGB is planar RRRR GGGG BBBB RRRR ....
//  whereas we need to make quads RGBA RGBA RGBA
var
  alpha,i,rplane,gplane,bplane,z,xy,xysz,vx: integer;
  SrcPlanar: bytep0;
  //OutRGBA: tVolRGBA;
begin
  SrcPlanar := nil;
    vx := (lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]);
	  if (lHdr.bitpix <> 24) or (vx < 1) then
      exit;
    setlengthB(SrcPlanar,vx*3);
    for i := 0 to ((vx*3)-1) do
        SrcPlanar^[i] := rawData^[i];
    setlengthB(rawData,vx*4);
    xysz := lHdr.dim[1]*lHdr.dim[2];
    i := 0;
    for z := 0 to (lHdr.dim[3]-1) do begin
      rplane := z * 3 * xysz;
      gplane := rplane+ xysz;
      bplane := gplane+ xysz;
      for xy := 0 to (xysz-1) do begin
        Alpha := (SrcPlanar^[rplane+xy]+SrcPlanar^[gplane+xy]+SrcPlanar^[bplane+xy]) div 3;
        rawData^[i] := SrcPlanar^[rplane+xy];
        inc(i);
        rawData^[i] := SrcPlanar^[gplane+xy];
        inc(i);
        rawData^[i] := SrcPlanar^[bplane+xy];
        inc(i);
        rawData^[i] := Alpha;
        inc(i);
      end;//for each xy
    end;//for each Z
    SetLengthB(SrcPlanar,0);//free memory
end;

{$IFDEF GZIP}
function LoadGZ(FileName : AnsiString; var   rawData: bytep0; var lHdr: TNIFTIHdr; lVol: integer): boolean;// Load 3D data                                                                 }
//FSL compressed nii.gz file
var
   Stream: TGZFileStream;
   lV: integer;
begin
  result := false;
  Stream := TGZFileStream.Create (FileName, gzopenread);
  Try
    Stream.ReadBuffer (lHdr, SizeOf (TNIFTIHdr));
    if lHdr.HdrSz <> SizeOf (TNIFTIHdr) then begin
      showDebug('Unable to read image '+Filename+' - this software can only read NIfTI files with the same endianess as the host CPU.');
      exit;
    end;
    if (lHdr.bitpix <> 8) and (lHdr.bitpix <> 16) and (lHdr.bitpix <> 24) then begin
      showDebug('Unable to load '+Filename+' - this software can only read 8,16,24-bit NIfTI files.');
      exit;
    end;
    //read the image data
    Stream.Seek(round(lHdr.vox_offset),soFromBeginning);
    SetLengthB (rawData, lHdr.Dim[1]*lHdr.Dim[2]*lHdr.Dim[3] * (lHdr.bitpix div 8));
    for lV := 1 to lVol do
        Stream.ReadBuffer (rawData^[0], lHdr.Dim[1]*lHdr.Dim[2]*lHdr.Dim[3]* (lHdr.bitpix div 8));

  Finally
    Stream.Free;
  End; { Try }
  result := true;
end;
{$ENDIF}

function Load3DNIfTI(FileName : AnsiString; var lTex: TTexture; lVol: integer): boolean;// Load 3D data                                                                 }
Var
  Scale: single;
  Mx,Mn,I: integer;
  F_Filename: AnsiString;
begin
  result := false;
  if Filename = '' then
    exit;
  if uppercase(extractfileext(Filename)) = '.IMG' then begin
      //NIfTI images can be a single .NII file [contains both header and image]
      //or a pair of files named .HDR and .IMG. If the latter, we want to read the header first
      F_Filename := changefileext(FileName,'.hdr');
      {$IFDEF LINUX} //LINUX is case sensitive, OSX is not
      showDebug('Unable to find header (case sensitive!) '+F_Filename);
      {$ELSE}
      showDebug('Unable to find header '+F_Filename);
      {$ENDIF}
  end else
      F_Filename := Filename;
  if not Fileexists(F_FileName) then begin
    showmessage('Unable to find '+F_Filename);
    exit;
  end;
  if uppercase(extractfileext(F_Filename)) = '.GZ' then begin
     {$IFDEF GZIP}
     if not LoadGZ(F_FileName,lTex.FiltImg,lTex.NIFTIhdr,lVol) then
            exit;
     {$ELSE}
     showdebug('Please manually decompress images '+F_Filename);
     exit;                                               options
     {$ENDIF}
  end else begin
     if not LoadRaw(F_FileName,lTex.FiltImg,lTex.NIFTIhdr,lVol) then
        exit;
  end;
  if (lTex.NIFTIhdr.bitpix = 16) then
    Word2Byte(lTex.FiltImg, lTex.NIFTIhdr);
  if (lTex.NIFTIhdr.bitpix = 24) then begin
    RGB2RGBA(lTex.FiltImg, lTex.NIFTIhdr);
    lTex.DataType := GL_RGBA;
  end else
    lTex.DataType := GL_LUMINANCE;
  //Set output values
  lTex.FiltDim[1] := lTex.NIFTIhdr.Dim[1];
  lTex.FiltDim[2] := lTex.NIFTIhdr.Dim[2];
  lTex.FiltDim[3] := lTex.NIFTIhdr.Dim[3];
  //normalize size so there is a proportional bounding box with largest side having length of 1
  Scale := FloatMaxVal(abs(lTex.NIFTIhdr.Dim[1]*lTex.NIFTIhdr.PixDim[1]),abs(lTex.NIFTIhdr.Dim[2]*lTex.NIFTIhdr.pixDim[2]),abs(lTex.NIFTIhdr.Dim[3]*lTex.NIFTIhdr.pixDim[3]));
  if (Scale <> 0) then begin
      lTex.Scale[1] := abs((lTex.NIFTIhdr.Dim[1]*lTex.NIFTIhdr.PixDim[1]) / Scale);
      lTex.Scale[2] := abs((lTex.NIFTIhdr.Dim[2]*lTex.NIFTIhdr.PixDim[2]) / Scale);
      lTex.Scale[3] := abs((lTex.NIFTIhdr.Dim[3]*lTex.NIFTIhdr.PixDim[3]) / Scale);
  end;
  //normalize intensity 0..255
  mx := lTex.FiltImg^[0];
  mn := mx;
  for I := 0 to ((lTex.FiltDim[1]*lTex.FiltDim[2]*lTex.FiltDim[3])-1) do begin
      if lTex.FiltImg^[I] > mx then
        mx := lTex.FiltImg^[I];
      if lTex.FiltImg^[I] < mn then
        mn := lTex.FiltImg^[I];
  end;
  if (mx > mn) and ((mx-mn) < 255) then begin
    Scale := 255/(mx-mn);
    for I := 0 to ((lTex.FiltDim[1]*lTex.FiltDim[2]*lTex.FiltDim[3])-1) do
      lTex.FiltImg^[I] := round(Scale*(lTex.FiltImg^[I]-Mn));
  end;
  result := true;
end;

procedure LoadBorg(Dim: integer; var lTex: TTexture);
const
  Border = 4;//margin so we can calculate gradients at edge
var
  F: array of single;
  mn, mx, scale: single;
  I, X, Y, Z: integer;
begin
  lTex.DataType := GL_LUMINANCE;
  lTex.NIFTIhdr.bitpix := 8;
  lTex.NIFTIhdr.datatype := kDT_UNSIGNED_CHAR ;
  for i := 1 to 3 do begin
    lTex.NIFTIhdr.dim[i] := Dim;
    lTex.FiltDim[I] := Dim;
    lTex.Scale[I] := 1;
  end;
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
  SetLengthB(lTex.FiltImg, Dim*Dim*Dim);
  for I := 0 to Dim*Dim*Dim-1 do begin
    if F[I] <= 0 then
      lTex.FiltImg^[I] := 0
    else
      lTex.FiltImg^[I] := Round((F[I]-mn)*scale);
  end;
  F := nil;
end;

procedure MakeHistogram8x (var rawData: bytep0; Vox: integer; lLogarithm: boolean; var lH: HistoRA);
var
  i,lMax: integer;
  lMaxD: double;
begin
  for i := 0 to kHistobins do
    lH[i] := 0;
  if Vox < 1 then
    exit;
  for i := 0 to (Vox-1) do
    inc(lH[rawData^[i]]);
  lMax := lH[0];
  for i := 0 to kHistobins do
    if lH[i] > lMax then lMax := lH[i];
  if lMax = 0 then
    exit;
  if lLogarithm then begin
    lMaxD := 255/(log2(lMax));
    for i := 0 to kHistoBins do
      lH[i] := round(lMaxD*log2(lH[i]));
  end else
    for i := 0 to kHistobins do
      lH[i] := round(255*lH[i]/lMax);
end;

procedure ClearHistogram8x (var lH: HistoRA);
var
  i: integer;
begin
    for i := 0 to kHistobins do
      lH[i] := 0;
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


Function Load_From_NIfTI (var lTex: TTexture; Const F_FileName : String; lPowerOfTwo: boolean; lVol: integer) : boolean;
begin
  result := true;
  lTex.hasGradients := false;
  NIFTIhdr_ClearHdr(lTex.NIftiHdr);
  if not Load3DNIfTI(F_FileName, lTex,lVol) then
     LoadBorg(64,lTex);
  MakeHistogram8x(lTex.FiltImg,(lTex.FiltDim[1]*lTex.FiltDim[2]*lTex.FiltDim[3]),true,lTex.WindowHisto);
  ClearHistogram8x(lTex.UnscaledHisto);
  LoadTTexture(lTex, gRayCast.gradientTexture3D,gRayCast.intensityTexture3D, gRayCast.transferTexture1D );
end;

end.

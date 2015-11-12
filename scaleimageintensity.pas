unit scaleimageintensity;
interface
{$D-,O+,Q-,R-,S-}
{$IFDEF FPC}
{$mode delphi}
{$ENDIF}
uses
define_types,nifti_hdr;//, nii_reslice, clustering;

procedure RescaleImgIntensity(var lHdr: TMRIcroHdr );
procedure AbsImgIntensity32(var lHdr: TMRIcroHdr );
procedure HideZeros(var lHdr: TMRIcroHdr );
function Scaled2RawIntensity (lHdr: TMRIcroHdr; lScaled: single): single;

implementation

uses sysutils;

function Scaled2RawIntensity (lHdr: TMRIcroHdr; lScaled: single): single;
begin
  if lHdr.NIFTIhdr.scl_slope = 0 then
	result := (lScaled)-lHdr.NIFTIhdr.scl_inter
  else
	result := (lScaled-lHdr.NIFTIhdr.scl_inter) / lHdr.NIFTIhdr.scl_slope;
end;


procedure ReturnMinMax (var lHdr: TMRIcroHdr; var lMin,lMax: single; var lFiltMin8bit, lFiltMax8bit: integer);
var
	lSwap,lMinS,lMaxS : single;
begin
	 lFiltMin8bit := 0;
	 lFiltMax8bit := 255;
	 lMinS := lHdr.WindowScaledMin;
	 lMaxS := lHdr.WindowScaledMax;
	 if lMinS > lMaxS then begin //swap
		lSwap := lMinS;
		lMinS := lMaxS;
		lMaxS := lSwap;
	 end;//swap
	 lMin := (Scaled2RawIntensity(lHdr, lMinS));
	 lMax := (Scaled2RawIntensity(lHdr, lMaxS));
	 //if lMin = lMax then exit;
	 if (lHdr.LutFromZero) then begin
		 if (lMinS > 0) and (lMaxS <> 0)  then begin
				//lMin := Scaled2RawIntensity(lHdr, 0);
				lFiltMin8bit := round(lMinS/lMaxS*255);
				//lMinS := - lHalfBit;//0;
				lHdr.Zero8Bit := 0;
		 end else if (lMaxS < 0) and (lMinS <> 0) then begin
				//lMax := Scaled2RawIntensity(lHdr, -0.000001);
				lFiltMax8bit := 255-round(lMaxS/lMinS*255);
				//lMaxS :=  lHalfBit; //0;
				//lFiltMax8bit := (Scaled2RawIntensity(lHdr, lHdr.WindowScaledMax));
		 end; //> 0
	 end; //LUTfrom Zero
	 lHdr.Zero8Bit := lMinS;
	 lHdr.Slope8bit := (lMaxS-lMinS)/255;
end; //ReturnMinMax

procedure ReturnMinMaxInt (var lHdr: TMRIcroHdr; var lMin,lMax, lFiltMin8bit, lFiltMax8bit: integer);
var
	lMinS,lMaxS: single;
begin
	ReturnMinMax (lHdr, lMinS,lMaxS,lFiltMin8bit, lFiltMax8bit);
	lMin := round(lMinS);
	lMax := round(lMaxS);
end;

procedure HideZeros8(var lHdr: TMRIcroHdr );
var
   lInc: integer;
begin
     if (lHdr.ImgBufferBPP <> 1) or (lHdr.ImgBufferItems < 1) then
        exit;
     for lInc := 1 to lHdr.ScrnBufferItems do
       if lHdr.ImgBuffer^[lInc] = 0 then
		 lHdr.ScrnBuffer^[lInc] := 0;
end;

procedure HideZeros16(var lHdr: TMRIcroHdr );
var
   lInc: integer;
   l16Buf: SmallIntP;
begin
     if (lHdr.ImgBufferBPP <> 2) or (lHdr.ImgBufferItems < 1) then
        exit;
     l16Buf := SmallIntP(lHdr.ImgBuffer );
     for lInc := 1 to lHdr.ScrnBufferItems do
       if l16Buf^[lInc] = 0 then
		 lHdr.ScrnBuffer^[lInc] := 0;

end;

procedure HideZeros32(var lHdr: TMRIcroHdr );
var
   lInc: integer;
   l32Buf : SingleP;
begin
     if (lHdr.ImgBufferBPP <> 4) or (lHdr.ImgBufferItems < 1) then
        exit;
     l32Buf := SingleP(lHdr.ImgBuffer );
     for lInc := 1 to lHdr.ScrnBufferItems do
       if l32Buf^[lInc] = 0 then
		 lHdr.ScrnBuffer^[lInc] := 0;

end;

procedure HideZeros(var lHdr: TMRIcroHdr );
begin
  if (lHdr.ImgBufferBPP  = 4) then
	  HideZeros32(lHdr)
  else if (lHdr.ImgBufferBPP  = 2) then
	  HideZeros16(LHdr)
  else if lHdr.ImgBufferBPP  = 1 then
	  HideZeros8(lHdr);
end;

procedure RescaleImgIntensity8(var lHdr: TMRIcroHdr );
var lRng: single;
	lLUTra: array[0..255] of byte;
	lMax,lMin,lSwap,lMod: single;
	lFiltMin8bit,lFiltMax8bit,lInc: integer;
begin
	 if (lHdr.ImgBufferBPP <> 1) or (lHdr.ImgBufferItems < 2) then
		exit;
	 ReturnMinMax (lHdr, lMin,lMax,lFiltMin8bit,lFiltMax8bit);
	 //ImgForm.Caption := floattostr(lMin);
         //fx(lMin,lMax,lFiltMin8bit,lFiltMax8bit);
	 lRng := (lMax - lMin);
	 if lRng <> 0 then
		lMod := abs({trunc}(((254)/lRng)))
	 else
		 lMod := 0;
	 if lMin > lMax then begin  //maw
		 lSwap := lMin;
		 lMin := lMax;
		 lMax := lSwap;
	 end;
	 for lInc := 0 to 255 do begin
		 if lInc < lMin then
			lLUTra[lInc] := 0
		 else if lInc >= lMax then
			lLUTra[lInc] := 255
		 else
			 lLUTra[lInc] := trunc(((lInc-lMin)*lMod)+1);
	 end; //fill LUT
	 if lRng < 0 then //inverted scale... e.g. negative scale factor
		for lInc := 0 to 255 do
			lLUTra[lInc] := 255-lLUTra[lInc];
	 for lInc := 1 to lHdr.ScrnBufferItems do
		 lHdr.ScrnBuffer^[lInc] := lLUTra[lHdr.ImgBuffer^[lInc]];
end;//proc RescaleImgIntensity8

procedure RescaleImgIntensity16(var lHdr: TMRIcroHdr );
var lRng: single;
	lBuff: bytep0;
	l16Buf : SmallIntP;
	lFiltMin8bit,lFiltMax8bit,lRngi,lMax,lMin,
  lMin16Val,//lMax16Val,
  lSwap,lModShl10,lInc,lInt: integer;
begin
	 if (lHdr.ImgBufferBPP <> 2) or (lHdr.ImgBufferItems < 2) then exit;
	 ReturnMinMaxInt (lHdr, lMin,lMax,lFiltMin8bit,lFiltMax8bit);
	 lRng := lMax - lMin;
	 if lRng <> 0 then
		lModShl10 := abs( trunc(((254)/lRng)* 1024))
	 else
		 lModShl10 := 0;
	 if lMin > lMax then begin
		 lSwap := lMin;
		 lMin := lMax;
		 lMax := lSwap;
	 end;
   //find min/max
   //we can find min max dynamically... useful if software changes values, but slow...
	 (*l16Buf := SmallIntP(lHdr.ImgBuffer );
   lMin16Val := l16Buf^[1];
   lMax16Val := l16Buf^[1];
	 for lInc := 1 to lHdr.ImgBufferItems do begin
      if l16Buf^[lInc] >  lMax16Val then
        lMax16Val := l16Buf^[lInc];
      if l16Buf^[lInc] <  lMin16Val then
        lMin16Val := l16Buf^[lInc];
   end;
   lRngi := 1+ lMax16Val-lMin16Val;
   *)
   //alternatively, we can use static values for Min Max, computed when image is loaded...
	   lMin16Val :=  trunc(lHdr.GlMinUnscaledS);
	   lRngi := (1+ trunc(lHdr.GlMaxUnscaledS))-lMin16Val;
   //next make buffer
	 getmem(lBuff, lRngi+1);  //+1 if the only values are 0,1,2 the range is 2, but there are 3 values!
	 for lInc := 0 to (lRngi) do begin //build lookup table
				   lInt := lInc+lMin16Val;
				   if lInt >= lMax then
					  lBuff^[lInc] := (255)
				   else if lInt < lMin then
						lBuff^[lInc] := 0
				   else
					  lBuff^[lInc] := (((lInt-lMin)*lModShl10) shr 10)+1 ;
					  //lBuff[lInc] := (((lInt-lMin)*lModShl10) shr 10) ;
	 end; //build lookup table
	 if lRng < 0 then //inverted scale... e.g. negative scale factor
		for lInc := 0 to lRngi do
			lBuff^[lInc] := 255-lBuff^[lInc];
	 l16Buf := SmallIntP(lHdr.ImgBuffer );
	 for lInc := 1 to lHdr.ImgBufferItems do
		 lHdr.ScrnBuffer^[lInc] := lBuff^[l16Buf^[lInc]-lMin16Val] ;
	 freemem(lBuff); //release lookup table
end;//proc RescaleImgIntensity16;

procedure RescaleImgIntensity32(var lHdr: TMRIcroHdr );
var lRng: double;
  lMod,lMax,lMin,lSwap: single {was extended};
  lInc,lItems,lFiltMin8bit,lFiltMax8bit: integer;
  l32Buf : SingleP;
begin
	lItems := lHdr.ImgBufferItems ;
	if (lHdr.ImgBufferBPP <> 4) or (lItems< 2) then exit;
	l32Buf := SingleP(lHdr.ImgBuffer );
	ReturnMinMax (lHdr, lMin,lMax,lFiltMin8bit,lFiltMax8bit); //qaz
	 if lMin > lMax then begin
		 lSwap := lMin;
		 lMin := lMax;
		 lMax := lSwap;
	 end;
   lRng := (lMax - lMin);

	if lRng <> 0 then
		lMod := abs(254/lRng)
	 else begin //June 2007
  		for lInc := 1 to lItems do begin
                    if l32Buf^[lInc] >= lMax then
                       lHdr.ScrnBuffer^[lInc] := 255
                    else //if l32Buf[lInc] < lMin then
                         lHdr.ScrnBuffer^[lInc] := 0;
                end;
		 exit;
   end;
	 lMin := lMin - abs(lRng/255);//lMod;
   for lInc := 1 to lItems do begin
		 if l32Buf^[lInc] > lMax then
          			lHdr.ScrnBuffer^[lInc] := 255
		 else if l32Buf^[lInc] < lMin then

					  lHdr.ScrnBuffer^[lInc] := 0  //alfa
		 else begin
			 lHdr.ScrnBuffer^[lInc] :=  round ((l32Buf^[lInc]-lMin)*lMod);

		 end;
     //lHdr.ScrnBuffer^[lInc] := random(255);
		end; //for each voxel

	 //next: prevent rounding errors for images where LUT is from zero
	 //next - flip intensity range OPTIONAL
	 //if lRng < 0 then //inverted scale... e.g. negative scale factor
	 //if (lMin < 0) and (lMax < 0) then //inverted scale... e.g. negative scale factor
	 //	for lInc := 1 to lItems do
	 //		lHdr.ScrnBuffer^[lInc] := 255-lHdr.ScrnBuffer^[lInc];
end; //RescaleImgIntensity32

procedure InvertScrnBuffer(var lHdr: TMRIcroHdr);
var
  lItems,lInc: integer;
begin
    lItems := lHdr.ImgBufferItems ;
		for lInc := 1 to lItems do
			lHdr.ScrnBuffer^[lInc] := 255-lHdr.ScrnBuffer^[lInc];
end;

(*procedure ClusterScrnImgA (var lHdr: TMRIcroHdr);
const
  kUnused = -1;
var
  clusterVol,clusterStart: array of longint;
  pos, j: integer;
  X,Y,XY,Z,XZ,YZ, group, ngroups: integer;
function MaxNeighbor: integer;
begin
     result := clusterVol[pos];
     if (clusterVol[pos+X] > result) then result := clusterVol[pos+X];
     if (clusterVol[pos+Y] > result) then result := clusterVol[pos+Y];
     if (clusterVol[pos+XY] > result) then result := clusterVol[pos+XY];
     if (clusterVol[pos+Z] > result) then result := clusterVol[pos+Z];
     if (clusterVol[pos+XZ] > result) then result := clusterVol[pos+XZ];
     if (clusterVol[pos+YZ] > result) then result := clusterVol[pos+YZ];
end; //nested MaxNeighbor

procedure SetNeighbor (p: integer);
//set voxel to current group
var
  k,oldgroup: integer;
begin
     if (clusterVol[p] <> 0) and (clusterVol[p] <> group) then begin
        if clusterVol[p] > 0 then begin //retire group: consolidate two connected regions
           oldgroup := clusterVol[p];
           for k := clusterStart[oldgroup] to p do begin
             //if clusterVol[k] = oldgroup then
             //   clusterVol[k] := group;
           end;
        end; //retire group
        clusterVol[p] := group;
     end;
end; //nested SetNeighbor
begin
  if (lHdr.ClusterSize  <= 1) then exit;
  if (lHdr.ImgBufferItems <> (lHdr.NIFTIhdr.dim[1]*lHdr.NIFTIhdr.dim[2]*lHdr.NIFTIhdr.dim[3]) ) then exit;
  if (lHdr.ImgBufferItems < 3) then exit;
  //each pixel has 18 neighbars that share an edge
  X := 1; Y := lHdr.NIFTIhdr.dim[1]; XY := X+Y; //future neighbors on same slice, next column (NC), next row (NR) and NC+NR
  Z := lHdr.NIFTIhdr.dim[1]*lHdr.NIFTIhdr.dim[2]; XZ := X+Z; YZ := Y+Z; //neighbors on next slice: NS (next slice), NS+NC, NS+NR

  Setlength (clusterVol,lHdr.ImgBufferItems+1+YZ); //+1 since we will index from 1 not 0!
  Setlength (clusterStart,lHdr.ImgBufferItems);
  for pos := 0 to High(clusterVol) do  clusterVol[pos] := 0; //initialize array
  for pos := 1 to lHdr.ImgBufferItems do begin
      if lHdr.ScrnBuffer^[pos] > 0 then
         clusterVol[pos] := kUnused
  end;
  ngroups := 0;
  j := 0;
  for pos := 1 to (lHdr.ImgBufferItems) do begin
      if clusterVol[pos] <> 0 then begin //this voxel survives threshold
         j := j+1;
         group := MaxNeighbor;
         if group < 1 then begin //new cluster group
            ngroups := ngroups + 1;
            clusterStart[group] := pos;
            group := ngroups;
         end;
         SetNeighbor(pos+YZ);
         SetNeighbor(pos+XZ);
         SetNeighbor(pos+Z);
         SetNeighbor(pos+XY);
         SetNeighbor(pos+Y);
         SetNeighbor(pos+X);
         SetNeighbor(pos);
      end; //voxel suvives threshold
  end; //for each voxel
  clusterVol := nil;
  clusterStart := nil;
end;   *)

procedure FilterScrnImg (var lHdr: TMRIcroHdr);
var
	lInc,lItems,lFiltMin8bit,lFiltMax8bit: integer;
	lMinS,lMaxS,lScale: single;
begin
  ReturnMinMax(lHdr,lMinS,lMaxS,lFiltMin8bit,lFiltMax8bit);
  lItems :=lHdr.ScrnBufferItems;
  if lItems < 1 then exit;
  if lFiltMax8Bit < 255 then begin
	lFiltMin8bit := 255-lFiltMax8bit;
	lFiltMax8Bit := 255;
  end;
  lScale := (lFiltMax8bit-lFiltMin8bit)/255;
  if (lFiltMin8bit > 0) or (lFiltMax8bit < 255) then
	for lInc := 1 to lItems do
		if lHdr.ScrnBuffer^[lInc] <> 0 then
			lHdr.ScrnBuffer^[lInc] := lFiltMin8bit+round(lHdr.ScrnBuffer^[lInc]*lScale);
end; //FilterScrnImg

procedure AbsImgIntensity32(var lHdr: TMRIcroHdr );
var
   l32Buf : SingleP;
   lInc,lImgSamples: integer;
begin
  if (lHdr.ImgBufferItems < 1) and (lHdr.ScrnBufferItems < 1) then
     exit; //1/2008
  lImgSamples := round(ComputeImageDataBytes8bpp(lHdr));
  if lHdr.ImgBufferItems<>lHdr.ScrnBufferItems then
    exit;
  if (lHdr.ImgBufferBPP  <> 4) then
    exit;
	l32Buf := SingleP(lHdr.ImgBuffer );
  for lInc := 1 to lImgSamples do
    l32Buf^[lInc] := abs(l32Buf^[lInc]);
end; //AbsImgIntensity32

procedure RescaleImgIntensity(var lHdr: TMRIcroHdr );
var
   lImgSamples: integer;
begin
  if (lHdr.ImgBufferItems < 1) and (lHdr.ScrnBufferItems < 1) then
     exit; //1/2008
  lImgSamples := round(ComputeImageDataBytes8bpp(lHdr));
  if lHdr.ImgBufferItems<>lHdr.ScrnBufferItems then begin
	  if lHdr.ScrnBufferItems > 0 then
		  freemem(lHdr.ScrnBuffer);
	  lHdr.ScrnBufferItems := lHdr.ImgBufferItems;
	  GetMem(lHdr.ScrnBuffer ,lHdr.ScrnBufferItems);
  end;
  if lHdr.UsesCustomPalette then begin
	  lHdr.WindowScaledMin := 0;
	  lHdr.WindowScaledMax := 255;
  end;
  if lImgSamples < 1 then
	  exit;
  if (lHdr.ImgBufferBPP  = 4) then
	  RescaleImgIntensity32(lHdr)
  else if (lHdr.ImgBufferBPP  = 2) then
	  RescaleImgIntensity16(LHdr)
  else if lHdr.ImgBufferBPP  = 1 then
	  RescaleImgIntensity8(lHdr)
  else if lHdr.ImgBufferBPP  = 3 then
    exit
  else begin
	  msg(lHdr.HdrFileName +' :: Unknown Image Buffer Bytes Per Pixel ');
	  exit;
  end;
  if ((lHdr.WindowScaledMin <= 0) and (lHdr.WindowScaledMax <= 0)) then  //maw
		InvertScrnBuffer(lHdr);
  if lHdr.LUTfromZero then
    FilterScrnImg(lHdr);
end; //RescaleImgIntensity

end.

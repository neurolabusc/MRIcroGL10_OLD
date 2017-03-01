unit histogram;

interface
{$include opts.inc}
{$D-,L-,O+,Q-,R-,Y-,S-}
uses
{$IFDEF USETRANSFERTEXTURE}texture_3d_unit_transfertexture, {$ELSE} texture_3d_unit,{$ENDIF}
define_types, math,nifti_hdr, nifti_types;

procedure ComputeThreshOverlay (var lM: TMRIcroHdr);
procedure CreateHisto (var lHdr: TTexture; lMin, lMax: single; var lHisto: HistoRA; lLogarithm: boolean);
procedure CreateHistoThresh (var lHdr: TTexture; lMin, lMax: single; var lHisto: HistoRA; lLogarithm: boolean; lThreshFrac: single; var lLoPct,lHiPct: single);
procedure ComputeMinMax(var lHdr: TTexture);
function Scaled2Unscaled (lVal: single; var lHdr: TTexture): single;
function Unscaled2Scaled (lVal: single; var lHdr: TTexture): single;

implementation

uses mainunit,dialogs,sysutils;

function Unscaled2Scaled (lVal: single; var lHdr: TTexture): single;
begin
    if lHdr.NIFTIhdr.scl_slope = 0 then
      result := lVal  + lHdr.NIFTIhdr.scl_inter
    else
      result := (lVal * lHdr.NIFTIhdr.scl_slope) + lHdr.NIFTIhdr.scl_inter;
end;

function Scaled2Unscaled (lVal: single; var lHdr: TTexture): single;
begin
  if lHdr.NIFTIhdr.scl_slope = 0 then begin
    result := lVal-lHdr.NIFTIhdr.scl_inter;
    exit;
  end;
  result := (lVal-lHdr.NIFTIhdr.scl_inter) / lHdr.NIFTIhdr.scl_slope ;
end;

function M2T (var lM: TMRIcroHdr; var lT : TTexture): boolean;
var
  i: integer;
begin

  result := false;
  if lM.ImgBuffer = nil then
    exit;
  for i := 1 to 3 do
    lT.FiltDim[i] := lM.NIFTIhdr.Dim[i];
  lT.NIFTIhdr.scl_inter := lM.NIFTIhdr.scl_inter;
  lT.NIFTIhdr.scl_slope := lM.NIFTIhdr.scl_slope;
  lT.RawUnscaledImg8 := nil;
  lT.RawUnscaledImg16 := nil;
  lT.RawUnscaledImg32 := nil;
  case lM.NIFTIhdr.datatype of
       kDT_UNSIGNED_CHAR : lT.RawUnscaledImg8  := @lM.ImgBuffer^;
       kDT_SIGNED_SHORT: lT.RawUnscaledImg16 := SmallIntP0(@lM.ImgBuffer^ );
       kDT_SIGNED_INT: msg('Help: 32bit int not supported');//l32i := LongIntP(@lDestHdr.ImgBuffer^);
       kDT_FLOAT: lT.RawUnscaledImg32 := SingleP0(@lM.ImgBuffer^ );
  end; //case
  result := true;
end;

procedure ComputeThreshOverlay (var lM: TMRIcroHdr);
var
  lT: TTexture;
  lLog10: integer;
  lMinPreRound: single;
begin
  if not M2T (lM,lT) then
    exit;
  ComputeMinMax(lT);
  CreateHistoThresh(lT, lT.WindowScaledMin, lT.WindowScaledMax, lT.UnscaledHisto, true, 0.005,lT.MinThreshScaled,lT.MaxThreshScaled);
  lLog10 := trunc(log10( lT.MaxThreshScaled-lT.MinThreshScaled))-1;
  lMinPreRound := (lM.WindowScaledMin);
  lM.WindowScaledMin := roundto(lT.MinThreshScaled,lLog10);
  if (lMinPreRound > 0) and (lM.WindowScaledMin = 0) then
    lM.WindowScaledMin := power(10,lLog10);
  lM.WindowScaledMax := roundto(lT.MaxThreshScaled,lLog10);
  lM.AutoBalMinUnscaled := lM.WindowScaledMin;
  lM.AutoBalMaxUnscaled := lM.WindowScaledMax;
end;

procedure ComputeMinMax(var lHdr: TTexture);
var
  lMxs,lMns,lVs: single;
  lMxi,lMni,lVi,lC,lImgBufferItems: integer;
begin
   lImgBufferItems := lHdr.FiltDim[1]*lHdr.FiltDim[2]*lHdr.FiltDim[3];
   if lImgBufferItems < 1 then
      exit;
    if (lHdr.RawUnscaledImg8 = nil) and (lHdr.RawUnscaledImg16 =nil) and (lHdr.RawUnscaledImg32 = nil) then begin
      //RGB data
      lHdr.WindowScaledMax := 255;
      lHdr.WindowScaledMin := 0;
      lHdr.WindowScaledMax := Unscaled2Scaled(lHdr.WindowScaledMax,lHdr);
      lHdr.WindowScaledMin := Unscaled2Scaled(lHdr.WindowScaledMin,lHdr);
      exit;
   end;
   if (lHdr.RawUnscaledImg32 <> nil) then begin //32bit
      lMxs := lHdr.RawUnscaledImg32^[0];
      lMns := lHdr.RawUnscaledImg32^[0];
      for lC := 0 to (lImgBufferItems-1) do begin
        lVs := lHdr.RawUnscaledImg32^[lC];
        if lVs < lMns then
          lMns := lVs;
        if lVs > lMxs then
          lMxs := lVs;
      end;
      lHdr.WindowScaledMax := lMxs;
      lHdr.WindowScaledMin := lMns;
   end else begin //8 or 16bit integers
      lMxi := 255; //removes compiler warning...
      lMni := 0; //removes compiler warning...
      if (lHdr.RawUnscaledImg16 <> nil )  then begin //if 16bit ints
        lMxi := lHdr.RawUnscaledImg16^[0];
        lMni := lHdr.RawUnscaledImg16^[0];
        for lC := 0 to (lImgBufferItems-1) do begin
          lVi := lHdr.RawUnscaledImg16^[lC];
          if lVi < lMni then
            lMni := lVi;
          if lVi > lMxi then
            lMxi := lVi;
        end;
      end else if (lHdr.RawUnscaledImg8 <> nil) then begin//else 8 bit data
        lMxi := lHdr.RawUnscaledImg8^[0];
        lMni := lHdr.RawUnscaledImg8^[0];
        for lC := 0 to (lImgBufferItems-1) do begin
          lVi := lHdr.RawUnscaledImg8^[lC];
          if lVi < lMni then
            lMni := lVi;
          if lVi > lMxi then
            lMxi := lVi;
        end;
      end;//8-bit
      lHdr.WindowScaledMax := lMxi;
      lHdr.WindowScaledMin := lMni;

   end; //not 32bit
   lHdr.WindowScaledMax := Unscaled2Scaled(lHdr.WindowScaledMax,lHdr);
   lHdr.WindowScaledMin := Unscaled2Scaled(lHdr.WindowScaledMin,lHdr);

end;
{$define FX9}
procedure CreateHistoThresh (var lHdr: TTexture; lMin, lMax: single; var lHisto: HistoRA; lLogarithm: boolean; lThreshFrac: single; var lLoPct,lHiPct: single);
var
   lModShl10,lMinIx10,lC,lImgBufferItems,lV,lNum: integer;
   lHisto2,lHisto8bit: HistoRA;
   lByte: byte;
   lThreshVox,lMinU,lMaxU,lMod,lRng,lVs: single;
   lRGBdata: boolean;
begin
   lImgBufferItems := lHdr.FiltDim[1]*lHdr.FiltDim[2]*lHdr.FiltDim[3];
   if lImgBufferItems < 1 then
    exit;
   lRGBdata := false;
   if (lHdr.RawUnscaledImg8 = nil) and (lHdr.RawUnscaledImg16 =nil) and (lHdr.RawUnscaledImg32 = nil) and (lHdr.RawUnscaledImgRGBA = nil) then exit;
      for lC := 0 to kHistoBins do
          lHisto[lC] := 0;

   lMinU := Scaled2Unscaled(lMin,lHdr);
   lMaxU := Scaled2Unscaled(lMax,lHdr);
   if lMin > lMax then begin
       lVs := lMaxU;
       lMaxU := lMinU;
       lMinU := lVs;
   end;
   lRng := lMaxU - lMinU;
	 if (lHdr.RawUnscaledImg32 <> nil ) then begin //32bit
		if lRng > 0 then
			lMod := kHistoBins/lRng
		else
			lMod := 0;

		for lC := 0 to (lImgBufferItems-1) do begin
      lVs := lHdr.RawUnscaledImg32^[lC];
      if (lVs >= lMinU) and (lVs <= lMaxU) then begin
			  lByte := round((lVs-lMinU)*lMod);
			  inc(lHisto[lByte]);
      end;
    end;
	 end else begin //not 32-bit : 8, 16, 24 bit data
		   if lRng > 0 then
			  lMod := (kHistoBins)/lRng
			  //lMod := lRng/(kHistoBins)
       else
			   lMod := 0;
		   lModShl10 := trunc(lMod * 1024);
		   lMinIx10 := round(lMinU*lModShl10);
			if (lHdr.RawUnscaledImg16 <> nil )  then begin //if 16bit ints
				for lC := 1 to (lImgBufferItems-1) do begin
          lV := lHdr.RawUnscaledImg16^[lC];
          if (lV >= lMinU) and (lV <= lMaxU) then begin
            lByte := ((lV*lModShl10)-lMinIx10) shr 10;
            inc(lHisto[lByte]);
          end;
        end;
			end else if (lHdr.RawUnscaledImg8 <> nil) then begin//else 8 bit data
{$IFDEF FX9}
        //use lookup table to accelerate...
				for lC := 0 to 255 do begin
          if (lC >= lMinU) and (lC <= lMaxU) then begin
            lByte := ((lC*lModShl10)-lMinIx10) shr 10;
            lHisto8bit[lC] := lByte;
          end else
            lHisto8bit[lC] := kHistoBins;
        end;//for each voxel
      //CLUTform.Caption := floattostr(lMinU)+'  '+floattostr(lmaxU)+'  1 = '+inttostr(lMinIx10);
				for lC := 1 to (lImgBufferItems-1) do
            inc(lHisto[lHisto8Bit[lHdr.RawUnscaledImg8^[lC]]]);
        lHisto[kHistoBins] := 0;
{$ELSE}
				for lC := 1 to (lImgBufferItems-1) do begin
          lV := lHdr.RawUnscaledImg8^[lC];
          if (lV >= lMinU) and (lV <= lMaxU) then begin
            lByte := ((lC*lModShl10)-lMinIx10) shr 10;
            inc(lHisto[lByte]);
          end;
        end;//for each voxel
{$ENDIF}
    end else if (lHdr.RawUnscaledImgRGBA<> nil) then begin//else rgba
        lRGBdata := true;
        lNum := 1; //read green
				for lC := 1 to (lImgBufferItems-1) do begin
          lV := lHdr.RawUnscaledImgRGBA^[lNum];
          lNum := lNum + 3;
          if (lV >= lMinU) and (lV <= lMaxU) then begin
            lByte := ((lV*lModShl10)-lMinIx10 )shr 10;
            inc(lHisto[lByte]);
          end;
        end;//for each voxel
      end;//24-bit
	 end; //not 32bit
   //next compute thresholds...
   lThreshVox := lImgBufferItems * lThreshFrac;
   lLoPct := 0;
   lHiPct := 255;
   if (lThreshVox > 0) and (lThreshVox < lImgBufferItems) and (not lRGBdata) then begin
      //count down

      lNum := 0;
      lC := kHistoBins;
      repeat
		   lNum := lNum + lHisto[lC];
		   dec(lC);
      until (lC = 0) or (lNum >= lThreshVox);
      if lC = 0 then
        lC := 128;
      lHiPct := ((lC/kHistoBins*(lMaxU-lMinU))+lMinU);
      //count up
      lNum := 0;
      lC := 0;
      repeat
		    lNum := lNum + lHisto[lC];
		    inc(lC);
      until (lC >= kHistoBins) or (lNum >= lThreshVox);
      lLoPct := ((lC/kHistoBIns*(lMaxU-lMinU))+lMinU);

   end; //if threshvox > 0 --- compute thresholded range
   lLoPct := Unscaled2Scaled(lLoPct,lHdr);
   lHiPct := Unscaled2Scaled(lHiPct,lHdr);

   //next smooth
   if true then begin
    for lC := 1 to (kHistoBins-1) do
      lHisto2[lC]:= (lHisto[lC-1]+lHisto[lC]+lHisto[lC+1]) div 3;
    for lC := 1 to (kHistoBins-1) do
      lHisto[lC]:= lHisto2[lC];
   end;
   if lLogarithm then
    for lC := 0 to kHistoBins do
      lHisto[lC] := round(10*log2(lHisto[lC]));
end; //CreateHistoThresh

procedure CreateHisto (var lHdr: TTexture; lMin, lMax: single; var lHisto: HistoRA; lLogarithm: boolean);
var
  l1,l2: single;
begin
   CreateHistoThresh (lHdr,lMin, lMax, lHisto, lLogarithm, 0, l1,l2);
end;


end.


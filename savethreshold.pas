unit savethreshold;
{$IFDEF FPC}{$mode delphi}    {$ENDIF}
 {$H+}


interface

uses
  Classes, SysUtils, Dialogs, define_types, nifti_hdr, scaleimageintensity, clustering, nifti_types;


//function SaveImg (lOutname: string; var lHdrx: TMRIcroHdr): boolean;
function SaveImg (lOutname: string; var lHdr: TNIFTIhdr; lImg: Bytep): boolean;
function SaveImgScaled (lOutname: string; lFilter: integer; lScale: single): boolean;
//function SaveImgIso (lOutname: string; lFilter: integer): boolean;
function SaveThresholdedUI(lThresh, lClusterMM3: single; lSaveToDisk: boolean): boolean;
function SaveThresholded(lInname: string; lThresh, lClusterMM3: single; lSaveToDisk: boolean): integer;


implementation

uses
  {$IFNDEF FPC}
    gziod,
  {$ELSE}
    gzio2,
  {$ENDIF}
  reorient, mainunit;

  procedure ThreshImgIntensity8(var lHdr: TMRIcroHdr; lThresh: single);
var
  lInc,lItems: integer;
  l8Buf : ByteP;
    lThreshSI: smallint;
  lThreshSS: single;
begin
     lItems := lHdr.ImgBufferItems ;
     if (lHdr.ImgBufferBPP <> 2) or (lItems < 2) then exit;
     l8Buf := ByteP(lHdr.ImgBuffer );
     lThreshSS := Scaled2RawIntensity (lHdr, lThresh);
     if lThreshSS < 0 then lThreshSS := 0;
     if lThreshSS > 255 then lThreshSS := 255;
     lThreshSI := round(lThreshSS);
     if lThresh < 0 then begin
        for lInc := 1 to lItems do
            if l8Buf^[lInc] > lThreshSI then
               l8Buf^[lInc] := 0;
     end else begin
       for lInc := 1 to lItems do
           if l8Buf^[lInc] < lThreshSI then
              l8Buf^[lInc] := 0;
     end
end;

procedure ThreshImgIntensity16(var lHdr: TMRIcroHdr; lThresh: single);
var
  lInc,lItems: integer;
  l16Buf : SmallIntP;
    lThreshSI: smallint;
  lThreshSS: single;
begin
     lItems := lHdr.ImgBufferItems ;
     if (lHdr.ImgBufferBPP <> 2) or (lItems < 2) then exit;
     l16Buf := SmallIntP(lHdr.ImgBuffer );
     lThreshSS := Scaled2RawIntensity (lHdr, lThresh);
     if lThreshSS < -32768 then lThreshSS := -32768;
     if lThreshSS > 32767 then lThreshSS := 32767;
     lThreshSI := round(lThreshSS);
     if lThresh < 0 then begin
        for lInc := 1 to lItems do
            if l16Buf^[lInc] > lThreshSI then
               l16Buf^[lInc] := 0;
     end else begin
       for lInc := 1 to lItems do
           if l16Buf^[lInc] < lThreshSI then
              l16Buf^[lInc] := 0;
     end
end;

procedure ThreshImgIntensity32(var lHdr: TMRIcroHdr; lThresh: single);
var
  lInc,lItems: integer;
  l32Buf : SingleP;
begin
     lItems := lHdr.ImgBufferItems ;
     if (lHdr.ImgBufferBPP <> 4) or (lItems< 2) then exit;
     l32Buf := SingleP(lHdr.ImgBuffer );
     if lThresh < 0 then begin
        for lInc := 1 to lItems do
            if l32Buf^[lInc] > lThresh then
               l32Buf^[lInc] := 0;
     end else begin
       for lInc := 1 to lItems do
           if l32Buf^[lInc] < lThresh then
              l32Buf^[lInc] := 0;
     end
end;

procedure ApplyClustering(var lHdr: TMRIcroHdr; lClusterVoxels: integer);
var
  i, lVolVox: integer;
  l8Buf : ByteP;
  l16Buf : SmallIntP;
  l32Buf : SingleP;

begin
     lVolVox := lHdr.ImgBufferItems;
     if (lVolVox < 1) or (lClusterVoxels < 2) then exit;
     for i := 1 to lVolVox do
         lHdr.ScrnBuffer^[i] := 0;
     if (lHdr.ImgBufferBPP  = 4) then begin
        l32Buf := SingleP(lHdr.ImgBuffer );
        for i := 1 to lVolVox do
            if l32Buf[i] <> 0 then
               lHdr.ScrnBuffer^[i] := 1;
        ClusterScrnImg (lHdr, lClusterVoxels);
        for i := 1 to lVolVox do
            if lHdr.ScrnBuffer^[i] = 0 then
              l32Buf[i] := 0;
     end else if (lHdr.ImgBufferBPP  = 2) then begin
        l16Buf := SmallIntP(lHdr.ImgBuffer );
        for i := 1 to lVolVox do
            if l16Buf[i] <> 0 then
               lHdr.ScrnBuffer^[i] := 1;
        ClusterScrnImg (lHdr, lClusterVoxels);
        for i := 1 to lVolVox do
            if lHdr.ScrnBuffer^[i] = 0 then
              l16Buf[i] := 0;
     end else if lHdr.ImgBufferBPP  = 1 then begin
        l8Buf := ByteP(lHdr.ImgBuffer );
        for i := 1 to lVolVox do
            if l8Buf[i] <> 0 then
               lHdr.ScrnBuffer^[i] := 1;
        ClusterScrnImg (lHdr, lClusterVoxels);
        for i := 1 to lVolVox do
            if lHdr.ScrnBuffer^[i] = 0 then
              l8Buf[i] := 0;
     end else
          exit;
end;

function SaveImg (lOutname: string; var lHdr: TNIFTIhdr; lImg: Bytep): boolean;
var
  i : integer;
  outbytes : int64;
//lOutname,
  lOutnameGz : string;
lF: File;
    h: TNIFTIHdr;
    doGz: boolean;
begin
     doGz := ExtGZ(lOutname);
     result := false;
     //lOutname := ChangeFilePrefixExt (lInName,'r','.nii');
     if fileexists(lOutname) then begin
        showmessage('Error: file already exists '+lOutname);
        exit;
     end;
     //loutnameGz := lOutname +'.gz';
     if doGz then begin
       lOutnameGz := lOutname;
       lOutname := ChangeFileExtX(lOutname,'.tmp');
       if fileexists(lOutname) then begin
           showmessage('Error: file already exists '+lOutname);
           exit;
        end;
     end;
     h := lHdr;
     outbytes := 1;
     for i := 1 to 7 do
         if h.dim[i] > 0 then
            outbytes := outbytes * h.dim[i];
     if (outbytes < 2) then exit;
     h.magic := kNIFTI_MAGIC_EMBEDDED_HDR; //save as .nii not hdr/img
     h.vox_offset:= 352;
     outbytes := outbytes * (h.bitpix div 8);// lHdrx.ImgBufferBPP;
 	Filemode := 1;
	AssignFile(lF, lOutname);
	Rewrite(lF,1);
        BlockWrite(lF,h,sizeof(TNIFTIHdr) );
      i := 0;
      BlockWrite(lF,i, 4 ); //NIFTI .nii requires 4 byte pad 348->352
      BlockWrite(lF,lImg^, outbytes); //lHdrx.ImgBuffer^,outbytes);
      CloseFile(lF);
      Filemode := 2;
      if doGz then GZipFile(lOutname, lOutnameGz, true);
      //showmessage(lOutname +' -> '+lOutnameGz);
     result := true;
end;
//function SaveImg (lOutname: string; var lHdrx: TMRIcroHdr): boolean;
(*function SaveImg (lOutname: string; var lHdr: TNIFTIhdr; lImg: Bytep): boolean; overload;
begin
     SaveImg (lOutname, lHdr, lImg, 1, 1.0);

end;*)

function numVox(h: TNIFTIHdr): int64;
var
    outbytes: int64;
    i: integer;
begin
     outbytes := 1;
     for i := 1 to 7 do
         if h.dim[i] > 0 then
            outbytes := outbytes * h.dim[i];
     result := outbytes;
end;

function SaveImgScaled (lOutname: string; lFilter: integer; lScale: single): boolean;
var
  i, bpp, nVox : int64;
  lOutnameGz : string;
  lImg, lImgX: byteP;
  lF: File;
  h: TNIFTIHdr;
  doGz: boolean;
begin
     result := false;
     //lOutname := ChangeFilePrefixExt (lInName,'r','.nii');
     if fileexists(lOutname) then begin
        showmessage('Error: file already exists '+lOutname);
        exit;
     end;
     nVox := numVox(gTexture3D.NIFTIhdr);
     h := gTexture3D.NIFTIhdr;
     if (lScale <= 0) and (h.pixdim[1] = h.pixdim[2]) and  (h.pixdim[1] = h.pixdim[3]) then
        exit; //already isotropic
     if  gTexture3D.RawUnscaledImg32 <> nil then begin
       lImg := bytep(gTexture3D.RawUnscaledImg32);
       h.datatype:= kDT_FLOAT;
       h.bitpix:= 32;
       bpp := 4
     end else if gTexture3D.RawUnscaledImg16 <> nil then begin
       lImg := bytep(gTexture3D.RawUnscaledImg16);
       h.datatype:= kDT_INT16;
       h.bitpix:= 16;
       bpp := 2
     end else if gTexture3D.RawUnscaledImg8 <> nil then begin
       lImg := bytep(gTexture3D.RawUnscaledImg8);
       h.datatype:= kDT_UINT8;
       h.bitpix:= 8;
       bpp := 1
     end else  begin
        showmessage('Unsupported format');
        exit;
     end;

     doGz := ExtGZ(lOutname);
     //loutnameGz := lOutname +'.gz';
     if doGz then begin
       lOutnameGz := lOutname;
       lOutname := ChangeFileExtX(lOutname,'.tmp');
       if fileexists(lOutname) then begin
           showmessage('Error: file already exists '+lOutname);
           exit;
        end;
     end;
     h.magic := kNIFTI_MAGIC_EMBEDDED_HDR; //save as .nii not hdr/img

     h.vox_offset:= 352;
     //outbytes := nVox * bpp;// lHdrx.ImgBufferBPP;
     Filemode := 1;
     AssignFile(lF, lOutname);
     Rewrite(lF,1);
     GetMem(lImgX,nVox * bpp);
     System.Move(lImg^,lImgX^,nVox * bpp);
     if lScale <= 0 then
         EnlargeIsotropic(h, lImgX, lFilter)
     else
         ShrinkOrEnlarge(h, lImgX, lFilter, lScale);
     nVox := numVox(h);
     //outbytes := nVox * bpp;
      BlockWrite(lF,h,sizeof(TNIFTIHdr) );
      i := 0;
      BlockWrite(lF,i, 4 ); //NIFTI .nii requires 4 byte pad 348->352
      BlockWrite(lF,lImgX^, nVox * bpp);
      FreeMem(lImgX);
        CloseFile(lF);
      Filemode := 2;
      if doGz then GZipFile(lOutname, lOutnameGz, true);
      //showmessage(lOutname +' -> '+lOutnameGz);
     result := true;
end;

(*function SaveImgIso (lOutname: string; lFilter: integer): boolean;
begin
     result := SaveImgScaled (lOutname, lFilter, 0);
end;*)

function SaveThresholded(lInname: string; lThresh, lClusterMM3: single; lSaveToDisk: boolean): integer;
var
  i,  lClusterVox: integer;
  loutmm3: single;
    lOpt : TOpenOptions;
  lInterp: boolean;
begin
     result := -1; //assume failure
     loutmm3 := abs(gTexture3D.NIFTIhdr.pixdim[1]*gTexture3D.NIFTIhdr.pixdim[2]*gTexture3D.NIFTIhdr.pixdim[3]);
     if (loutmm3 = 0 ) then
        lClusterVox := 0
     else
         lClusterVox := round (abs(lClusterMM3)/ loutmm3);
     lOpt := GLForm1.OpenDialog1.Options;
     lInterp := gPrefs.InterpolateOverlays;
     gPrefs.InterpolateOverlays := true;
     i := GLForm1.AddOverlay(lInname,1);
          GLForm1.OpenDialog1.Options := lOpt;
     gPrefs.InterpolateOverlays := lInterp;
     if (i < 1) then
        exit;
     if (gOverlayImg[i].ImgBufferBPP  = 4) then
	  ThreshImgIntensity32(gOverlayImg[i], lThresh)
     else if (gOverlayImg[i].ImgBufferBPP  = 2) then
	  ThreshImgIntensity16(gOverlayImg[i], lThresh)
     else if gOverlayImg[i].ImgBufferBPP  = 1 then
	  ThreshImgIntensity8(gOverlayImg[i], lThresh)
     else
          exit;
     ApplyClustering (gOverlayImg[i], lClusterVox);
     if lSaveToDisk then
        //SaveImg (ChangeFilePrefixExt (lInName,'r','.nii.gz'), gOverlayImg[i]);
        SaveImg (ChangeFilePrefixExt (lInName,'r','.nii.gz'), gOverlayImg[i].NIFTIhdr, gOverlayImg[i].ImgBuffer);
     result := i;
     GLForm1.UpdateImageIntensityMinMax (i, lThresh, lThresh);
end;

function SaveThresholdedUI (lThresh, lClusterMM3: single; lSaveToDisk: boolean): boolean;
var

  lF, lIndex: integer;
begin
     result := false;
     lIndex := 0;
     if (gTexture3D.FiltDim[1] < 1) or (gTexture3D.FiltDim[2] < 1) or (gTexture3D.FiltDim[3] < 1) then begin
       showmessage('Please load a background image before loading an overlay.');
       exit;
     end;
     GLForm1.OpenDialog1.Options := [ofAllowMultiSelect,ofFileMustExist];
     if (not GLForm1.OpenDialog1.Execute) or (GLForm1.OpenDialog1.Files.Count < 1) then
        exit;
     for lF := 0 to (GLForm1.OpenDialog1.Files.Count-1) do begin
            GLForm1.Closeoverlays1Click(nil);
            lIndex := SaveThresholded(GLForm1.OpenDialog1.Files[lF], lThresh, lClusterMM3, lSaveToDisk);
     end;
     result := lIndex > 0;
end;


end.


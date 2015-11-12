unit drawu;

{$IFDEF FPC}{$mode delphi}{$ENDIF}

interface
//{$IFDEF USETRANSFERTEXTURE}texture_3d_unita, {$ELSE} texture_3d_unit,{$ENDIF}

uses                                
  {$IFNDEF FPC} Windows, {$ENDIF}  //raycastglsl,
  shaderu, clut,dglOpenGL,dialogs,Classes,define_types, sysUtils;

type
 TDraw = packed record //Next: analyze Format Header structure
   dim3d: array [0..3] of integer; //unused,X,Y,Z voxels in volume space
   dim2d: array [0..3] of integer; //orient,X,Y,Slice in slice space
   clickStartX, clickStartY,clickPrevX,clickPrevY: integer; //location of previous mouse buttons
   colorLut: array [0..255] of TGLRGBQuad;
   glslprogramId,view3dId, colorLutId: GLuint;
   penColor : byte;
   view3d, view2d, undo2d, modified2d: bytep0;
   //lut: array of TGLRGBQuad;
   start2dXY, prev2dXY : array [0..2] of integer; //unused,X,Y for pixel coordinates
   doRedraw,doAlpha, isMouseDown, isModified, isForceCreate: boolean;
 end;

// var gDraw: TDraw;
function voiInit: TDraw;
procedure voiFree(var gDraw: TDraw);
procedure voiUndo (var gDraw: TDraw);
procedure voiMouseUp (var gDraw: TDraw; autoClose, overwriteColors: boolean);
function voiMouseMove (var gDraw: TDraw; Xfrac, Yfrac, Zfrac:  single): boolean;
procedure voiMouseDown(var gDraw: TDraw; Color, Orient: integer; Xfrac, Yfrac, Zfrac:  single);
procedure voiMouseFloodFill(var gDraw: TDraw; Color, Orient: integer; Xfrac, Yfrac, Zfrac:  single);
function voiOpenGLDraw(var gDraw: TDraw): GLuint; //must be called from OpenGL
procedure voiChangeAlpha (var gDraw: TDraw; a: byte);
procedure voiCreate(var gDraw: TDraw; X,Y,Z: integer; ptr: byteP0);
procedure voiClose(var gDraw: TDraw);
function voiGetVolume (var gDraw: TDraw): byteP0;
function voiActiveOrient(var gDraw: TDraw): integer;
function voiIsModified(var gDraw: TDraw): boolean;
function voiIsEmpty (var gDraw: TDraw): boolean;
function voiActiveX (var gDraw: TDraw): boolean;
function voiIsOpen (var gDraw: TDraw): boolean;
procedure voiPasteSlice(var gDraw: TDraw; Xfrac, Yfrac, Zfrac:  single);
procedure voiColor (var gDraw: TDraw; idx, r, g, b: byte);
procedure voiDefaultLUT(var gDraw: TDraw);
procedure voiSmoothIntensity (var gDraw: TDraw; RGBAimg: bytep0);
procedure voiSetModified(var gDraw: TDraw; b: boolean);

implementation

uses
  texture2raycast, mainunit, raycastglsl; //checkTextureMemory

procedure voiSetModified(var gDraw: TDraw; b: boolean);
begin
       gDraw.isModified := b;  //2015
end;

function numThresh (v: singlep0; lStart,lEnd: integer; thresh: single): integer; //how many members of the array are >= thresh?
var
  i: integer;
begin
     result := 0;
     for i := lStart to lEnd do
         if v[i] >= thresh then inc(result);
end;

function maxVol (v: singlep0; lStart,lEnd: integer): single; //brightest and darkest
var
  i: integer;
begin
     result := v[0];
     for i := lStart to lEnd do
         if v[i] >= result then result := v[i];
end;

procedure meanStdInMask(mask, v: singlep0; lStart,lEnd: integer) ;
//modulate mask based on variance - in v
const
  kFrac = 0.7; //0..1 what proportion of signal modulatated by intensity
var
  mx: single;
  mean, stdev, delta,m2: double;
  i,n: integer;
begin
     //1.) determine max intensity in mask, e.g. if a binary 0/1 mask this will be 1
     mx := maxVol(mask,lStart,lEnd);
     if mx = 0 then exit;
     mx := 0.75 * mx;
     //calculate stdev and mean with Welford on pass methodhttp://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
     n := 0;
     mean := 0.0;
     m2 := 0.0;
     for i := lStart to lEnd do begin
         if (mask[i] >= mx) then begin
            n := n + 1;
            delta := v[i] - mean;
            mean := mean + (delta/n);
            m2 := m2 + (delta * (v[i] -mean)  );
         end;
     end;
     if (n < 2) then exit;
     stdev := sqrt(m2/(n-1)); //convert to standard deviation
     //GLForm1.Caption := inttostr(n)+' '+ floattostr(mean)+'  '+floattostr(stdev);
     for i := lStart to lEnd do begin
         delta := (v[i] - mean)/stdev; //z-score
         delta := abs(delta)/3; //e.g. Z= -1.5 -> 0.5
         if delta > kFrac then delta := kFrac;  //delta is clipped to 0..kFrac
         delta := 1-delta;
         //if (mask[i] > 0) then   mask[i] := 243 * delta; //purely drive by intensity
         mask[i] := mask[i] * (delta  + (1-kFrac) );
     end;
end;

procedure SmoothImg(vol: singlep0; X,Y,Z: integer);
var
   vol2: singlep0;
   i, nPix, dimOff: integer;
begin
     if (X < 5) or (Y < 5) or (Z < 5) then exit;
     nPix := X * Y * Z;
     getmem(vol2, nPix * sizeof(single));
     Move(vol^, vol2^,nPix * sizeof(single));//source/dest -> only for edges
     for i := 2 to (nPix-1-2) do //smooth in X direction
         vol[i] := vol2[i-2] + 2*vol2[i-1] + 3* vol2[i] + 2* vol2[i+1] + vol2[i+2]; //x9 of original value
     dimOff := X;
     for i := 2*dimOff to (nPix-1-(2*dimOff)) do //smooth in Y direction
         vol2[i] := vol[i-2*dimOff] + 2*vol[i-dimOff] + 3* vol[i] + 2* vol[i+dimOff] + vol[i+2*dimOff]; //x9 of original value
     dimOff := X * Y;
     for i := 2*dimOff to (nPix-1-(2*dimOff)) do //smooth in Z direction
         vol[i] := vol2[i-2*dimOff] + 2*vol2[i-dimOff] + 3* vol2[i] + 2* vol2[i+dimOff] + vol2[i+2*dimOff]; //x9 of original value
      freemem(vol2);
end;

procedure SmoothVol(var gDraw: TDraw; lColor: integer; intenVol: singlep0);
label
  666;
var
  vol: singlep0;
  nPix,i,  origVol : integer;
  tLo,tMid,tHi, nMid : integer;
  t1stVox, tLastVox: integer;
begin
     //volume dimensions must be at least 5x5x5 voxels for smooth
     nPix := gDraw.dim3d[1] * gDraw.dim3d[2]*gDraw.dim3d[3];
     getmem(vol, nPix * sizeof(single));
     origVol := 0;
     for i := 0 to (nPix-1) do
         if (gDraw.view2d[i] = lColor) then begin
            vol[i] := 1;
            inc(origVol);
         end else
             vol[i] := 0;
     if (origVol < 1) then goto 666;
     SmoothImg(vol, gDraw.dim3d[1], gDraw.dim3d[2], gDraw.dim3d[3]);
     t1stVox := -1;
     tLastVox := -1;
     for i := 0 to (nPix-1) do begin
         vol[i] := vol[i] * (1/3); //normalize from 0..729 to 0..243
         if vol[i] = 0.0 then begin
            tLastVox := i;
            if (t1stVox < 0) then t1stVox := i;
         end;
     end;
     if (intenVol <> nil) then
        meanStdInMask(vol, intenVol,  t1stVox,tLastVox) ;
     //find threshold that maintains overall volume
     tLo := 1;
     tMid := 121;
     tHi := 243;
     nMid := numThresh (vol, t1stVox,tLastVox , tMid);
     while (tHi-tLo) > 3 do begin
           if (nMid > origVol) then
              tLo := tMid
           else
               tHi := tMid;
           tMid := ((tHi-tLo) div 2) + tLo;
           nMid := numThresh (vol, t1stVox,tLastVox , tMid);
     end;
     for i := 0 to (nPix-1) do
         if (vol[i] >= tMid) then
                gDraw.view2d[i] := lColor
         else
             gDraw.view2d[i] := 0;
666:
     freemem(vol);
end;

procedure UpdateView3d (var gDraw: TDraw);
var
  volOffset, i,j,k, nPix: integer;
begin
     if (gDraw.undo2d = nil) or (gDraw.view3d = nil) then exit;
     if (gDraw.dim2d[0] = 0) then begin //3D volume
        nPix := gDraw.dim3d[1]* gDraw.dim3d[2] * gDraw.dim3d[3];
        if nPix < 1 then exit;
        Move(gDraw.view2d^, gDraw.view3d^,nPix);//source/dest
        exit;
     end;
     nPix := gDraw.dim2d[1] * gDraw.dim2d[2]; //dim[3] = number of pixels
     if (nPix < 1) then exit;

     if (gDraw.dim2d[0] = 3) then begin//Sag
        volOffset := gDraw.dim2d[3]; //sag slices are in X direction
        i := 0; //sag is Y*Z
        for j := 0 to (gDraw.dim3d[3]-1) do begin //read each slice (Z)
            for  k := 0 to (gDraw.dim3d[2]-1) do begin //read Y direction
                 gDraw.view3d[(k*gDraw.dim3d[1]) +volOffset] := gDraw.view2d[i];
                 i := i + 1;
            end;
            volOffset := volOffset + (gDraw.dim3d[1]*gDraw.dim3d[2]); //next Z slice
        end;
     end else if (gDraw.dim2d[0] = 2) then begin//Coro
         volOffset := gDraw.dim2d[3]*gDraw.dim3d[1]; //coro slices are in Y direction
         i := 0;  //coro is X*Z
         for j := 0 to (gDraw.dim3d[3]-1) do begin //read each slice (Z)
             for  k := 0 to (gDraw.dim3d[1]-1) do begin //read X direction
                  gDraw.view3d[k+volOffset] := gDraw.view2d[i];
                  i := i + 1;
             end;
             volOffset := volOffset + (gDraw.dim3d[1]*gDraw.dim3d[2]); //next Z slice
         end;
     end else begin //Axial
           volOffset := gDraw.dim2d[3]*gDraw.dim3d[1]*gDraw.dim3d[2]; //axial slices are in Z direction, each X*Y pixels
           Move(gDraw.view2d^, gDraw.view3d^[volOffset],nPix);//source/dest
           //for i := 0 to (nPix -1) do //data contiguous - we replaced for loop with single move operation
           //    gDraw.view3d[i+volOffset] := gDraw.view2d[i];
     end;
end;

procedure voiSmoothIntensity (var gDraw: TDraw; RGBAimg: bytep0);
var
  nPix, dark, bright, i, alpha: integer;
  intenVol: singlep0;
begin
     if (gDraw.view3d = nil) then exit;
     if (gDraw.dim3d[1] < 5) or (gDraw.dim3d[1] < 5) or (gDraw.dim3d[1] < 5) then exit;
     nPix := gDraw.dim3d[1] * gDraw.dim3d[2]*gDraw.dim3d[3];
     dark := 256;
     bright := 0;
     for i := 0 to (nPix -1) do begin
         if (gDraw.view3d[i] < dark) then dark := gDraw.view3d[i];
         if (gDraw.view3d[i] > bright) then bright := gDraw.view3d[i];
     end;
     if (bright = dark) then exit; //no variability
     gDraw.dim2d[0] := 0; //dim[0] = slice orientation 0 = 3d volume
     getmem(gDraw.view2d, nPix);
     getmem(gDraw.undo2d, nPix);
     Move(gDraw.view3d^, gDraw.undo2d^,nPix);//source/dest
     Move(gDraw.undo2d^,gDraw.view2d^,nPix);//source/dest
     if (RGBAimg <> nil) then begin
        getmem(intenVol, nPix * sizeof(single));
        alpha := 3; //array is red/green/blue/aplha 0=R,1=G,2=B,3=A
        for i := 0 to nPix do begin
            intenVol^[i] := RGBAimg[alpha];//Alpha
            inc(alpha,4);
        end; //for each vox
        SmoothImg(intenVol, gDraw.dim3d[1], gDraw.dim3d[2], gDraw.dim3d[3]);
     end else
         intenVol := nil;
     if (dark = 0) then dark := 1;
     for i := dark to bright do
       SmoothVol(gTexture3D.Draw, i, intenVol);
     if (RGBAimg <> nil) then
        freemem(intenVol);
  gDraw.doRedraw := true;
  UpdateView3d(gTexture3D.Draw);
  gDraw.isModified := true;  //2015
end;

procedure voiColor (var gDraw: TDraw; idx, r, g, b: byte);
begin
     gDraw.doAlpha := true;
     gDraw.colorLut[idx].rgbRed := r;
     gDraw.colorLut[idx].rgbGreen := g;
     gDraw.colorLut[idx].rgbBlue := b;
end;

function voiIsOpen (var gDraw: TDraw): boolean;
begin
  result := (gDraw.view3d <> nil);
end;

function voiIsModified(var gDraw: TDraw): boolean;
begin
     result := gDraw.isModified;
end;

function voiIsEmpty (var gDraw: TDraw): boolean;
var
  i,vx: integer;
begin
     result := true;
     vx := gDraw.dim3d[1] * gDraw.dim3d[2]*gDraw.dim3d[3];
     if (vx < 0) or (gDraw.view3d = nil)  then exit;
     i := 0;
     while (i < vx) and (gDraw.view3d[i] = 0) do
       inc(i);
     if (i < vx) then
        result := false;
end;

function frac2pix (frac: single; dimPix: integer): integer;
begin
  //result := round(((frac- (0.5/dimPix))*dimPix))-1; //e.g. if 6 slices anything greater than 0.167 counted in slice 2
  //result := round(frac * dimPix);
  result := round((frac * dimPix)-0.5);
  if (result < 0) then result := 0;
  if (result >= dimPix) then result := dimPix - 1;
end;

procedure click2pix (var gDraw: TDraw; var Xpix, Ypix: integer; Xfrac, Yfrac, Zfrac:  single);
begin
  if (gDraw.dim2d[0] = 3) then begin //Sag
     Xpix := frac2pix(Yfrac, gDraw.dim2d[1]); //Sag is Y*Z
     Ypix := frac2pix(Zfrac, gDraw.dim2d[2]); //Sag is Y*Z
  end else if (gDraw.dim2d[0] = 2) then begin //Coro
     Xpix := frac2pix(Xfrac, gDraw.dim2d[1]); //Coro X*Z
     Ypix := frac2pix(Zfrac, gDraw.dim2d[2]); //Coro is X*Z
  end else begin  //Axial
      Xpix := frac2pix(Xfrac, gDraw.dim2d[1]); //Axial X*Y
      //GLForm1.Caption := floattostr(Xfrac)+' fcx  '+inttostr(gDraw.dim2d[1])+'  '+inttostr(Xpix);
      Ypix := frac2pix(Yfrac, gDraw.dim2d[2]); //Axial X*Y
  end;
end;

function voiActiveX (var gDraw: TDraw): boolean;
begin
     if (gDraw.view3d = nil) then
        result := false
     else
       result := true;
end;

function voiActiveOrient (var gDraw: TDraw): integer;
begin
     if (gDraw.view3d <> nil) and  (gDraw.isMouseDown) then
        result := gDraw.dim2d[0] //return Axial(1), Coronal(2) or Sagittal(3)
     else
       result := -1;
end;

procedure closeSlice (var gDraw: TDraw);
begin
  if (gDraw.view2d <> nil) then freemem(gDraw.view2d);
  if (gDraw.undo2d <> nil) then freemem(gDraw.undo2d);
  if (gDraw.modified2d <> nil) then freemem(gDraw.modified2d);
  gDraw.view2d := nil;
  gDraw.undo2d := nil;
  gDraw.modified2d := nil;
end;

procedure voiMouseDown(var gDraw: TDraw; Color, Orient: integer; Xfrac, Yfrac, Zfrac:  single);
//Orient: Ax(1), Cor(2), Sag(3)
var
  nPix, nSlices, volOffset,i,j, k: integer;
begin
     if (gDraw.view3d = nil) then exit;
     if ((gDraw.dim3d[1] * gDraw.dim3d[2]*gDraw.dim3d[3]) < 1) then exit;
     if (Color < 0) or (Color > 255) or (Xfrac < 0.0) or (Yfrac < 0.0) or (Zfrac < 0.0) or (Xfrac > 1.0) or (Yfrac > 1.0) or (Zfrac > 1.0) then exit;
     if (Orient < 1) or (Orient > 3) then exit; //accept Axial, Sag, Coro
     closeSlice(gTexture3D.Draw);
     gDraw.penColor := Color;
     gDraw.dim2d[0] := Orient; //dim[0] = slice orient
     if (Orient = 3) then begin
        gDraw.dim2d[1] := gDraw.dim3d[2]; //Sag is Y*Z
        gDraw.dim2d[2] := gDraw.dim3d[3]; //Sag is Y*Z
        nSlices := gDraw.dim3d[1]; //Sag slices in X direction
        //gDraw.dim2d[3] := round(Xfrac * gDraw.dim3d[1]) //sag slices select Left-Right slices
        gDraw.dim2d[3] := frac2pix(Xfrac, gDraw.dim3d[1]); //sag slices select Left-Right slices
     end else if (Orient = 2) then begin
        gDraw.dim2d[1] := gDraw.dim3d[1]; //Coro X*Z
        gDraw.dim2d[2] := gDraw.dim3d[3]; //Coro is X*Z
        nSlices := gDraw.dim3d[2]; //Axial slices in Y direction
        //gDraw.dim2d[3] := round(Yfrac * gDraw.dim3d[2]) //coro slices select Anterio-Posterior slices
        gDraw.dim2d[3] := frac2pix(Yfrac, gDraw.dim3d[2]); //coro slices select Anterio-Posterior slices
     end else begin  //Axial
         gDraw.dim2d[1] := gDraw.dim3d[1]; //Axial X*Y
         gDraw.dim2d[2] := gDraw.dim3d[2]; //Axial X*Y
         nSlices := gDraw.dim3d[3]; //Axial slices in Z direction
         //gDraw.dim2d[3] := round(Zfrac * gDraw.dim3d[3]); //axial influences head-foot
         gDraw.dim2d[3] := frac2pix(Zfrac, gDraw.dim3d[3]); //axial influences head-foot
     end;
     nPix := gDraw.dim2d[1] * gDraw.dim2d[2]; //dim[3] = number of pixels
     if (nPix < 1) then exit;
     //gDraw.dim2d[3] is the active slice we will be manipulating
     if (gDraw.dim2d[3] < 0) or (gDraw.dim2d[3] >= nSlices) then exit;
     //create slices holding initial pixel values
     getmem(gDraw.view2d, nPix);
     getmem(gDraw.undo2d, nPix);
     getmem(gDraw.modified2d, nPix);
     FillChar(gDraw.modified2d^,nPix,0); //set all to zero: nothing drawn yet
     //
     if (Orient = 3) then begin//Sag
        volOffset := gDraw.dim2d[3]; //sag slices are in X direction
        i := 0; //sag is Y*Z
        for j := 0 to (gDraw.dim3d[3]-1) do begin //read each slice (Z)
            for  k := 0 to (gDraw.dim3d[2]-1) do begin //read Y direction
                 gDraw.undo2d[i] := gDraw.view3d[(k*gDraw.dim3d[1]) +volOffset];
                 i := i + 1;
            end;
            volOffset := volOffset + (gDraw.dim3d[1]*gDraw.dim3d[2]); //next Z slice
        end;
     end else if (Orient = 2) then begin//Coro
         volOffset := gDraw.dim2d[3]*gDraw.dim3d[1]; //coro slices are in Y direction
         i := 0;  //coro is X*Z
         for j := 0 to (gDraw.dim3d[3]-1) do begin //read each slice (Z)
             for  k := 0 to (gDraw.dim3d[1]-1) do begin //read X direction
                  gDraw.undo2d[i] := gDraw.view3d[k+volOffset];
                  i := i + 1;
             end;
             volOffset := volOffset + (gDraw.dim3d[1]*gDraw.dim3d[2]); //next Z slice
         end;
     end else begin //Axial
           volOffset := gDraw.dim2d[3]*gDraw.dim3d[1]*gDraw.dim3d[2]; //axial slices are in Z direction, each X*Y pixels
           Move(gDraw.view3d^[volOffset], gDraw.undo2d^,nPix);//source/dest
           //for i := 0 to (nPix -1) do //data contiguous - we can replace for loop with move
           //    gDraw.undo2d[i] := gDraw.view3d[i+volOffset];
     end;
     Move(gDraw.undo2d^,gDraw.view2d^,nPix);//source/dest
     //for i := 0 to (nPix div 4) do
     //    gDraw.view2d[i] := i mod 2;
     //record mouse
     click2pix (gTexture3D.Draw, gDraw.clickStartX, gDraw.clickStartY, Xfrac, Yfrac, Zfrac);
     gDraw.clickPrevX := gDraw.clickStartX;
     gDraw.clickPrevY := gDraw.clickStartY;
     gDraw.isMouseDown := true;
     gDraw.isModified := true;
end;

const
  kFillNewColor = 255;//255;
  kIgnoreColor = 253;//253;
  kFillOldColor = 0;

procedure borderPixel (var gDraw: TDraw; x,y: integer);
var
  px : integer;
begin
     px := x + y* gDraw.dim2d[1];
     if gDraw.modified2d[px] = kFillOldColor then
        gDraw.modified2d[px] := kFillNewColor;
end;

procedure fillPixel (var gDraw: TDraw; x,y: integer);
var
   px : integer;
begin
       px := x + y* gDraw.dim2d[1];
       if gDraw.modified2d[px] <> kFillOldColor then exit;
       gDraw.modified2d[px] := kFillNewColor;
       fillPixel (gDraw, x-1,y);
       fillPixel (gDraw, x+1,y);
       fillPixel (gDraw, x,y-1);
       fillPixel (gDraw, x,y+1);
end;

procedure fillPixelBound (var gDraw: TDraw; x,y: integer);
//fill pixel with range checking
var
   px : integer;
begin
       px := x + y* gDraw.dim2d[1];
       if gDraw.modified2d[px] <> kFillOldColor then exit;
       gDraw.modified2d[px] := kFillNewColor;
       if (x > 0) then fillPixelBound (gDraw, x-1,y);
       if (x < (gDraw.dim2d[1]-1)) then fillPixelBound (gDraw, x+1,y);
       if (y > 0) then fillPixelBound (gDraw, x,y-1);
       if (y < (gDraw.dim2d[2]-1)) then fillPixelBound (gDraw, x,y+1);
end;

function isFillNewColor (var gDraw: TDraw; x,y: integer): boolean;
begin
       result := (gDraw.modified2d[x + y* gDraw.dim2d[1] ] = kFillNewColor);
end;

procedure setColor (var gDraw: TDraw; x,y: integer; clr: byte);
begin
       gDraw.modified2d[x + y* gDraw.dim2d[1]] := clr;
end;

procedure fillBubbles (var gDraw: TDraw);
//from borders identifies all connected voxels of kFillOldColor and makes them kFillNewColor
var
  i: integer;
begin
     if (gDraw.view2d = nil) or (gDraw.modified2d = nil) then exit;
     if (gDraw.dim2d[1] < 3) or (gDraw.dim2d[2] < 3) then exit;
     //blank left and right sides to prevent overflow errors
     for i := 0 to (gDraw.dim2d[2]-1) do begin
         borderPixel(gDraw, 0,i);
         borderPixel(gDraw, gDraw.dim2d[1]-1,i);
     end;
     //blank top and bottom sides to prevent overflow errors
     for i := 0 to (gDraw.dim2d[1]-1) do begin
         borderPixel(gDraw, i,0);
         borderPixel(gDraw, i,gDraw.dim2d[2]-1);
     end;
     //seed left and right edges
    for i := 1 to (gDraw.dim2d[2]-2) do begin
         if isFillNewColor(gDraw, 0,i) then fillPixel(gDraw, 1,i);
         if isFillNewColor(gDraw, gDraw.dim2d[1]-1,i) then fillPixel(gDraw, gDraw.dim2d[1]-2,i);
     end;
     //seed top and bottom edges
     for i := 1 to (gDraw.dim2d[1]-2) do begin
         if isFillNewColor(gDraw, i, 0) then fillPixel(gDraw, i,1);
         if isFillNewColor(gDraw, i, gDraw.dim2d[2]-1) then fillPixel(gDraw, i,gDraw.dim2d[2]-2);
     end;
end;

procedure fillRegion (var gDraw: TDraw);
var
  i: integer;
begin
     if (gDraw.view2d = nil) or (gDraw.modified2d = nil) then exit;
     if (gDraw.dim2d[1] < 3) or (gDraw.dim2d[2] < 3) then exit;
     fillBubbles(gDraw);
     for i := 0 to ((gDraw.dim2d[1]*gDraw.dim2d[2])-1) do
         if (gDraw.modified2d[i] = kFillOldColor) then
            gDraw.view2d[i] := gDraw.penColor;
end;

procedure doFloodFill(var gDraw: TDraw; x,y: integer; newColor, oldColor: byte);
//set all voxels connected to location x,y of oldColor to have newColor
var
   nPix, i: integer;
begin
     nPix := gDraw.dim2d[1]*gDraw.dim2d[2];
     for i := 0 to (nPix-1) do begin
         if gDraw.view2d[i] = oldColor then
            gDraw.modified2d[i] := kFillOldColor
         else
            gDraw.modified2d[i] := kIgnoreColor;
     end;
     fillPixelBound (gDraw, x,y);
     if newColor = oldColor then begin
        for i := 0 to (nPix-1) do begin
         if gDraw.modified2d[i] = kFillNewColor then
            gDraw.modified2d[i] := kIgnoreColor
         else
           gDraw.modified2d[i] := kFillOldColor;
        end;
        fillBubbles(gDraw); //any oldcolor connected to the border set to newcolor
        for i := 0 to (nPix-1) do begin
         if gDraw.modified2d[i] = kFillOldColor then
           gDraw.modified2d[i] := kFillNewColor  //fill pockets
        else
          gDraw.modified2d[i] := kIgnoreColor;
         end;
     end;
     for i := 0 to (nPix-1) do
         if gDraw.modified2d[i] = kFillNewColor then
            gDraw.view2d[i] := newColor;
end;

procedure voiMouseFloodFill(var gDraw: TDraw; Color, Orient: integer; Xfrac, Yfrac, Zfrac:  single);
var
   x,y: integer;
   oldColor: byte;
begin
     voiMouseDown(gDraw, Color, Orient, Xfrac, Yfrac, Zfrac);
     gDraw.isMouseDown := false;
     if (gDraw.view2d = nil) or (gDraw.modified2d = nil) then exit;
     if (gDraw.dim2d[1] < 3) or (gDraw.dim2d[2] < 3) then exit;
     click2pix (gDraw, x,  y, Xfrac, Yfrac, Zfrac);
     oldColor := gDraw.view2d[x + y* gDraw.dim2d[1]];
     //GLForm1.caption :=inttostr(oldColor)  +'->'+ inttostr(Color)+'xxxx'+inttostr(random(888));
     doFloodFill(gDraw, x,y, Color, oldColor);
     gDraw.doRedraw := true;
     UpdateView3d(gDraw);
end;

procedure drawPixel (var gDraw: TDraw; x,y: integer);
var
  px : integer;
begin
     px := x + y* gDraw.dim2d[1];
     gDraw.modified2d[px] := kIgnoreColor;//1;
     gDraw.view2d[px] := gDraw.penColor;
end;

procedure DrawLine (var gDraw:TDraw; x,y, x2, y2:  integer);
//http://www.edepot.com/lineb.html
var
  yLonger: boolean;
  i,incrementVal, shortLen, longLen, swap: integer;
  multDiff: double;
begin
     //drawPixel(x,y);
     drawPixel(gDraw, x2,y2);

     yLonger:=false;
     shortLen:=y2-y;
     longLen:=x2-x;
     if (abs(shortLen)>abs(longLen)) then begin
	swap:=shortLen;
	shortLen:=longLen;
	longLen:=swap;
	yLonger:=true;
     end;
     if (longLen<0) then
        incrementVal:=-1
     else
        incrementVal:=1;
     if (longLen=0.0) then
        multDiff:=shortLen
     else
       multDiff:=shortLen/longLen;
     i := 0;
     if (yLonger) then begin
        while (i <> longLen) do begin
            drawPixel(gDraw, round(x+(i*multDiff)),y+i);
            i := i +incrementVal;
        end;
     end else begin
         while (i <> longLen) do begin
	     drawPixel(gDraw, x+i,round(y+(i*multDiff)));
             i := i +incrementVal;
        end;
     end;
end; //DrawX

function voiMouseMove (var gDraw: TDraw; Xfrac, Yfrac, Zfrac:  single): boolean;
var
  clickX, clickY: integer;
begin
  result := false;
  if not gDraw.isMouseDown then exit;
  click2pix (gDraw, clickX, clickY, Xfrac, Yfrac, Zfrac);
  if (clickX = gDraw.clickPrevX) and (clickY = gDraw.clickPrevY) then exit;
  DrawLine (gDraw, gDraw.clickPrevX, gDraw.clickPrevY, clickX, clickY);
  gDraw.clickPrevX := clickX;
  gDraw.clickPrevY := clickY;
  gDraw.doRedraw := true;
  result := true;
end;

procedure preserveColors (var gDraw: TDraw);
var
  i: integer;
begin
       for i := 0 to ((gDraw.dim2d[1]*gDraw.dim2d[2])-1) do
         if (gDraw.undo2d[i] <> 0) then
            gDraw.view2d[i] := gDraw.undo2d[i];
end;

procedure voiMouseUp (var gDraw: TDraw; autoClose, overwriteColors: boolean);
begin
  if (autoClose) then begin
     DrawLine (gDraw, gDraw.clickPrevX, gDraw.clickPrevY, gDraw.clickStartX, gDraw.clickStartY);
     fillRegion(gDraw);
  end;
  if not overwriteColors then
     preserveColors(gDraw);
  gDraw.doRedraw := true;
  UpdateView3d(gDraw);
  gDraw.isMouseDown := false;
end;

procedure voiUndo (var gDraw: TDraw);
var
  temp: bytep0;
  nPix: integer;
begin

     if (gDraw.view3dId = 0) or ( gDraw.view2d = nil) or ( gDraw.undo2d = nil) then exit;
     if (gDraw.dim2d[0] = 0) then  //3D volume
        nPix := gDraw.dim3d[1]* gDraw.dim3d[2] * gDraw.dim3d[3]
     else
          nPix := gDraw.dim2d[1] * gDraw.dim2d[2]; //dim[3] = number of pixels
     if (nPix < 1) then exit;
     //swap active and undo images, so multiple calls to 'Undo' will undo/redo last drawing...
     getmem(temp, nPix);
     Move(gDraw.undo2d^,temp^,nPix);//source/dest
     Move(gDraw.view2d^,gDraw.undo2d^,nPix);//source/dest
     Move(temp^,gDraw.view2d^,nPix);//source/dest
     freemem(temp);
     gDraw.doRedraw := true;
     UpdateView3d(gDraw);
end;

procedure voiPasteSlice(var gDraw: TDraw; Xfrac, Yfrac, Zfrac:  single);
begin
     if (gDraw.view3dId = 0) or ( gDraw.view2d = nil) then exit;
     if (gDraw.dim2d[0] = 3) then begin
        gDraw.dim2d[3] := round(Xfrac * gDraw.dim3d[1]) //sag slices select Left-Right slices
     end else if (gDraw.dim2d[0] = 2) then begin
        gDraw.dim2d[3] := round(Yfrac * gDraw.dim3d[2]) //coro slices select Anterio-Posterior slices
     end else begin  //Axial
         gDraw.dim2d[3] := round(Zfrac * gDraw.dim3d[3]); //axial influences head-foot
     end;
     gDraw.doRedraw := true;
     UpdateView3d(gDraw);
end;

procedure Redraw (var gDraw: TDraw);
begin
     if (gDraw.view3dId = 0) or ( gDraw.view2d = nil) then exit;
     glBindTexture(GL_TEXTURE_3D, gDraw.view3dId);
     if (gDraw.dim2d[0] = 0) then begin //insert 3D volume
        glTexSubImage3D(GL_TEXTURE_3D,0,
          0, 0,0,
         gDraw.dim3d[1], gDraw.dim3d[2], gDraw.dim3d[3],
         GL_ALPHA, GL_UNSIGNED_BYTE,@gDraw.view2d[0]);
     end else if (gDraw.dim2d[0] = 3) then begin//Sag  - insert slice in X dimension
        glTexSubImage3D(GL_TEXTURE_3D,0,
         gDraw.dim2d[3], 0,0,
         1, gDraw.dim2d[1],gDraw.dim2d[2],
         GL_ALPHA, GL_UNSIGNED_BYTE,@gDraw.view2d[0]);
     end else if (gDraw.dim2d[0] = 2) then begin//Coro  - insert slice in Y dimension
        glTexSubImage3D(GL_TEXTURE_3D,0,
         0,gDraw.dim2d[3], 0,
         gDraw.dim2d[1],1, gDraw.dim2d[2],
         GL_ALPHA, GL_UNSIGNED_BYTE,@gDraw.view2d[0]);
     end else  begin//Axial - insert slice in Z dimension
       glTexSubImage3D(GL_TEXTURE_3D,0,
         0, 0,gDraw.dim2d[3],
        gDraw.dim2d[1],gDraw.dim2d[2],1,
        GL_ALPHA, GL_UNSIGNED_BYTE,@gDraw.view2d[0]);
     end;
end;

procedure voiChangeAlpha (var gDraw: TDraw; a: byte);
var
  i: integer;
begin
      //gDraw.alpha := a;
      gDraw.doAlpha := true;
      gDraw.colorLut[0].rgbReserved := 0;
      for i := 1 to 255 do
        gDraw.colorLut[i].rgbReserved := a;
end;

function voiGetVolume (var gDraw: TDraw): byteP0;
begin
     result := gDraw.view3d;
end;

function makeRGB(r,g,b: byte): TGLRGBQuad;
begin
    result.rgbRed := r;
    result.rgbGreen := g;
    result.rgbBlue := b;
end;

procedure voiDefaultLUT;
var
  i:integer;
begin
     with gDraw do begin
    colorLut[0] := makeRGB(0,0,0);
    colorLut[1] := makeRGB(255,0,0);//red
    colorLut[2] := makeRGB(0,128,0);//green
    colorLut[3] := makeRGB(0,0,255);//blue
    colorLut[4] := makeRGB(255,128,0);//orange
    colorLut[5] := makeRGB(128,0,255);//purple
    colorLut[6] := makeRGB(0,200,200);//cyan
    colorLut[7] := makeRGB(160,48,48);//brick
    colorLut[8] := makeRGB(32,255,32);//lime
    colorLut[9] := makeRGB(128,160,230);//lightblue
    for i := 10 to 255 do
        colorLut[i] := colorLut[((i-1) mod 9)+1];
  end;
end;

procedure CreateColorTable (gDraw: TDraw);// Load image data
begin
  if (gDraw.colorLutId <> 0) then glDeleteTextures(1,@gDraw.colorLutId);
  glGenTextures(1, @gDraw.colorLutId);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glBindTexture(GL_TEXTURE_1D, gDraw.colorLutId);
  glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_CLAMP);
  glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexImage1D(GL_TEXTURE_1D, 0, GL_RGBA, 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, @gDraw.colorLut[0]);
end;

procedure voiClose (var gDraw: TDraw);
begin
  if (gDraw.view3d <> nil) then freemem(gDraw.view3d);
  gDraw.view3d := nil;
  gDraw.isMouseDown:= false;
  closeSlice (gDraw);
end;

procedure voiCloseGL (var gDraw: TDraw);
begin
  if (gDraw.view3dId <> 0) then glDeleteTextures(1,@gDraw.view3dId);
  if (gDraw.colorLutId <> 0) then glDeleteTextures(1,@gDraw.colorLutId);
  if (gDraw.glslprogramId <> 0) then glDeleteProgram(gDraw.glslprogramId);
  gDraw.view3dId := 0;
  gDraw.colorLutId := 0;
  gDraw.glslprogramId := 0;
end;

procedure voiCreate(var gDraw: TDraw; X,Y,Z: integer; Ptr: ByteP0);
var
  vx: integer;
begin
  gDraw.isModified := false;
  gDraw.dim3d[1] := X;
  gDraw.dim3d[2] := Y;
  gDraw.dim3d[3] := Z;
  closeSlice(gDraw);
  if (gDraw.view3d <> nil) then freemem(gDraw.view3d);
  vx :=  gDraw.dim3d[1] * gDraw.dim3d[2] * gDraw.dim3d[3];
  if (vx <1) or (gDraw.dim3d[1] < 1) or (gDraw.dim3d[2] < 1) or (gDraw.dim3d[3] < 1) then begin
     gDraw.view3d := nil;
     exit;
  end;
  gDraw.isForceCreate := true;
  getmem(gDraw.view3d, vx);
  if (Ptr <> nil) then
     Move(Ptr^,gDraw.view3d^,vx)//source/dest
  else begin
     FillChar(gDraw.view3d^,vx,0); //set all to zero
  end;
end;

procedure voiCreateGL (var gDraw: TDraw);
//portion of voiCreate that requires OpenGL context

begin
     gDraw.isForceCreate := false;
     if (gDraw.view3dId <> 0) then glDeleteTextures(1,@gDraw.view3dId);
     if (gDraw.colorLutId <> 0) then  glDeleteTextures(1,@gDraw.colorLutId);
      gDraw.view3dId := 0;
      gDraw.colorLutId := 0;
      if (gDraw.dim3d[1] < 1) or (gDraw.dim3d[2] < 1) or (gDraw.dim3d[3] < 1) then begin
         gDraw.dim3d[1] := 0; gDraw.dim3d[2] := 0; gDraw.dim3d[3] := 0;
         exit;
      end;
      CreateColorTable(gDraw);
      glPixelStorei(GL_UNPACK_ALIGNMENT,1);
      glGenTextures(1, @gDraw.view3dId);
      glBindTexture(GL_TEXTURE_3D, gDraw.view3dId);
      glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
      glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
      glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
      glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_BORDER);
      glTexImage3D(GL_TEXTURE_3D, 0, GL_ALPHA8, gDraw.dim3d[1], gDraw.dim3d[2], gDraw.dim3d[3], 0, GL_ALPHA, GL_UNSIGNED_BYTE,@gDraw.view3d[0]);
end;

const kMinimalShaderFrag = 'uniform float coordZ;'
+#10'uniform int orientAxCorSag;'
+#10'uniform sampler3D drawVol, intensityVol;'
+#10'uniform sampler1D drawLUT;'
+#10'uniform vec3 clearColor;'
+#10'void main(void){'
+#10'vec3 vox;'
+#10'if (orientAxCorSag == 2) vox = vec3(gl_TexCoord[0].x, coordZ, gl_TexCoord[0].y);'
+#10'else if (orientAxCorSag == 3) vox = vec3( coordZ, gl_TexCoord[0].x, gl_TexCoord[0].y);'
+#10'else vox = vec3(gl_TexCoord[0].xy, coordZ);'
+#10'vec4 bg = texture3D(intensityVol, vox);'
+#10'if (bg.a < 0.01) bg.rgb = clearColor;'
+#10'vec4 dr = texture1D(drawLUT, texture3D(drawVol, vox).a).rgba;'
+#10'gl_FragColor.rgb = mix(bg.rgb,dr.rgb,dr.a);'
+#10'}';

procedure StartGLSL (var gDraw: TDraw);
begin
    if (gDraw.glslprogramId = 0) then gDraw.glslprogramId := initVertFrag('',kMinimalShaderFrag);
    glUseProgram(gDraw.glslprogramId);
    glEnable(GL_BLEND);
    glActiveTexture( GL_TEXTURE0 );  //required if we will draw 2d slices next
    glBindTexture(GL_TEXTURE_3D,gRayCast.intensityTexture3D);
    glUniform1ix(gDraw.glslprogramId, 'intensityVol', 0);
    glActiveTexture( GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_1D, gDraw.colorLutId);
    glUniform1ix(gDraw.glslprogramId, 'drawLUT', 2);
    glActiveTexture( GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_3D, gDraw.view3dId);
    glUniform1ix(gDraw.glslprogramId, 'drawVol', 1);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_BORDER);
end;

function voiOpenGLDraw(var gDraw: TDraw): GLuint;
begin
     result := 0;
     if (gDraw.view3d = nil) and (gDraw.view3dId <> 0) then voiCloseGL(gDraw);
     if (gDraw.view3d <> nil) and ((gDraw.view3dId = 0) or (gDraw.isForceCreate)) then  voiCreateGL(gDraw);
     if gDraw.view3dId = 0 then exit;
     if gDraw.doAlpha then begin
        CreateColorTable(gDraw);
        gDraw.doAlpha := false;
     end;
     if gDraw.doRedraw then begin
        Redraw(gDraw);
        gDraw.doRedraw := false;
     end;
     StartGLSL(gDraw);
     result := gDraw.glslprogramId;
end;

function voiInit: TDraw;
begin
 result.doRedraw := false;
 result.doAlpha:= false;
 result.glslprogramId := 0;
 result.colorLutId := 0;
 result.view3dId := 0;
 voiDefaultLUT(result);
 voiChangeAlpha(result, 128);
 result.doAlpha := false;
 result.isModified := false;
 result.view2d := nil;
 result.undo2d := nil;
 result.modified2d := nil;
 result.view3d := nil;
 result.isForceCreate := false;
 result.isMouseDown:= false;
end;

procedure voiFree(var gDraw: TDraw);
begin
    voiClose(gDraw);
end;

(*initialization
 gDraw.doRedraw := false;
 gDraw.doAlpha:= false;
 gDraw.glslprogramId := 0;
 gDraw.colorLutId := 0;
 gDraw.view3dId := 0;
 voiDefaultLUT;
 voiChangeAlpha(128);
 gDraw.doAlpha := false;
 gDraw.isModified := false;
 gDraw.view2d := nil;
 gDraw.undo2d := nil;
 gDraw.modified2d := nil;
 gDraw.view3d := nil;
 gDraw.isForceCreate := false;
 gDraw.isMouseDown:= false;
finalization
  voiClose;
end.*)
end.



unit reorient;
{$D-,O+,Q-,R-,S-}  //Delphi L- Y-
interface

uses
  SysUtils,define_types,nii_mat,nifti_hdr,dialogs, nifti_types, clipbrd, math;

//function ReorientNIfTI(lFilename: string; lPrefs: TPrefs): string; //returns output filename if successful
function ReorientCore(var lHdr: TNIFTIhdr; lBufferIn: bytep): boolean;
procedure ShrinkLarge(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
implementation
  uses mainunit;

function NIfTIAlignedM (var lM: TMatrix): boolean;
//check that diagonals are positive and all other cells are zero
//negative diagonals suggests flipping...
//non-negative other cells suggests the image is not pure axial
var
   lr,lc: integer;
begin
    result := false;
    for lr := 1 to 3 do
        for lc := 1 to 3 do begin
            if (lr = lc) and (lM.matrix[lr,lc] <= 0) then
               exit;
            if (lr <> lc) and (lM.matrix[lr,lc] <> 0) then
               exit;
        end;
    result := true;
end;


function NIfTIAligned (var lHdr: TNIFTIhdr): boolean;
//check that diagonals are positive and all other cells are zero
//negative diagonals suggests flipping...
//non-negative other cells suggests the image is not pure axial
var
   lM: TMatrix;
begin
    lM := Matrix3D (
    lHdr.srow_x[0],lHdr.srow_x[1],lHdr.srow_x[2],lHdr.srow_x[3],
    lHdr.srow_y[0],lHdr.srow_y[1],lHdr.srow_y[2],lHdr.srow_y[3],
    lHdr.srow_z[0],lHdr.srow_z[1],lHdr.srow_z[2],lHdr.srow_z[3]);
    result := NIfTIAlignedM(lM);
end;

procedure FromMatrix (M: TMatrix; var  m11,m12,m13, m21,m22,m23,
						   m31,m32,m33:  DOUBLE)  ;
  BEGIN

   m11 := M.Matrix[1,1];
   m12 := M.Matrix[1,2];
   m13 := M.Matrix[1,3];
   m21 := M.Matrix[2,1];
   m22 := M.Matrix[2,2];
   m23 := M.Matrix[2,3];
   m31 := M.Matrix[3,1];
   m32 := M.Matrix[3,2];
   m33 := M.Matrix[3,3];
END {FromMatrix3D};

function nifti_mat44_orthogx( lR :TMatrix): TMatrix;
//returns rotation matrix required to orient image so it is aligned nearest to the identity matrix =
// 1 0 0 0
// 0 1 0 0
// 0 0 1 0
// 0 0 0 1
//Therefore, image is approximately oriented in space
var
   lrow,lcol,lMaxRow,lMaxCol,l2ndMaxRow,l2ndMaxCol,l3rdMaxRow,l3rdMaxCol: integer;
   r11,r12,r13 , r21,r22,r23 , r31,r32,r33, val,lAbsmax,lAbs: double;
   Q: TMatrix;  //3x3
begin
   // load 3x3 matrix into local variables
   FromMatrix(lR,r11,r12,r13,r21,r22,r23,r31,r32,r33);
   Q := Matrix2D( r11,r12,r13,r21,r22,r23,r31,r32,r33);
   // normalize row 1
   val := Q.matrix[1,1]*Q.matrix[1,1] + Q.matrix[1,2]*Q.matrix[1,2] + Q.matrix[1,3]*Q.matrix[1,3] ;
   if( val > 0.0 )then begin
     val := 1.0 / sqrt(val) ;
     Q.matrix[1,1] := Q.matrix[1,1]*val ;
     Q.matrix[1,2] := Q.matrix[1,2]*val ;
     Q.matrix[1,3] := Q.matrix[1,3]*val ;
   end else begin
     Q.matrix[1,1] := 1.0 ; Q.matrix[1,2] := 0.0; Q.matrix[1,3] := 0.0 ;
   end;
   // normalize row 2
   val := Q.matrix[2,1]*Q.matrix[2,1] + Q.matrix[2,2]*Q.matrix[2,2] + Q.matrix[2,3]*Q.matrix[2,3] ;
   if( val > 0.0 ) then begin
     val := 1.0 / sqrt(val) ;
     Q.matrix[2,1] := Q.matrix[2,1]* val ;
     Q.matrix[2,2] := Q.matrix[2,2] * val ;
     Q.matrix[2,3] := Q.matrix[2,3] * val ;
   end else begin
     Q.matrix[2,1] := 0.0 ; Q.matrix[2,2] := 1.0 ; Q.matrix[2,3] := 0.0 ;
   end;
   // normalize row 3
   val := Q.matrix[3,1]*Q.matrix[3,1] + Q.matrix[3,2]*Q.matrix[3,2] + Q.matrix[3,3]*Q.matrix[3,3] ;
   if( val > 0.0 ) then begin
     val := 1.0 / sqrt(val) ;
     Q.matrix[3,1] := Q.matrix[3,1] *val ;
      Q.matrix[3,2] := Q.matrix[3,2] *val ;
      Q.matrix[3,3] := Q.matrix[3,3] *val ;
   end else begin
     Q.matrix[3,1] := Q.matrix[1,2]*Q.matrix[2,3] - Q.matrix[1,3]*Q.matrix[2,2] ;  //* cross */
     Q.matrix[3,2] := Q.matrix[1,3]*Q.matrix[2,1] - Q.matrix[1,1]*Q.matrix[2,3] ;  //* product */
     Q.matrix[3,3] := Q.matrix[1,1]*Q.matrix[2,2] - Q.matrix[1,2]*Q.matrix[2,1] ;
   end;
   //next - find closest orthogonal coordinates - each matrix cell must be 0,-1 or 1
   //First: find axis most aligned to a principal axis
   lAbsmax := 0;
   lMaxRow := 1;
   lMaxCol := 1;
   for lrow := 1 to 3 do begin
       for lcol := 1 to 3 do begin
           lAbs := abs(Q.matrix[lrow,lcol]);
           if lAbs > lAbsMax then begin
              lAbsmax := lAbs;
              lMaxRow := lRow;
              lMaxCol := lCol;
           end;
       end; //for rows
   end; //for columns
   //Second - find find axis that is 2nd closest to principal axis
   lAbsmax := 0;
   l2ndMaxRow := 2;
   l2ndMaxCol := 2;
   for lrow := 1 to 3 do begin
       for lcol := 1 to 3 do begin
           if (lrow <> lMaxRow) and (lCol <> lMaxCol) then begin
              lAbs := abs(Q.matrix[lrow,lcol]);
              if lAbs > lAbsMax then begin
                 lAbsmax := lAbs;
                 l2ndMaxRow := lRow;
                 l2ndMaxCol := lCol;
              end; //new max
           end; //do not check MaxRow/MaxCol
       end; //for rows
   end; //for columns
   //next - no degrees of freedom left: third prinicple axis is the remaining axis
   if ((lMaxRow = 1) or (l2ndMaxRow = 1)) and ((lMaxRow = 2) or (l2ndMaxRow = 2)) then
      l3rdMaxRow := 3
   else if ((lMaxRow = 1) or (l2ndMaxRow = 1)) and ((lMaxRow = 3) or (l2ndMaxRow = 3)) then
        l3rdMaxRow := 2
   else
       l3rdMaxRow := 1;
   if ((lMaxCol = 1) or (l2ndMaxCol = 1)) and ((lMaxCol = 2) or (l2ndMaxCol = 2)) then
      l3rdMaxCol := 3
   else if ((lMaxCol = 1) or (l2ndMaxCol = 1)) and ((lMaxCol = 3) or (l2ndMaxCol = 3)) then
        l3rdMaxCol := 2
   else
       l3rdMaxCol := 1;
   //finally, fill in our rotation matrix
   //cells in the canonical rotation transform can only have values 0,1,-1
   result := Matrix3D( 0,0,0,0, 0,0,0,0, 0,0,0,0);
   if Q.matrix[lMaxRow,lMaxCol] < 0 then
      result.matrix[lMaxRow,lMaxCol] := -1
   else
       result.matrix[lMaxRow,lMaxCol] := 1;

   if Q.matrix[l2ndMaxRow,l2ndMaxCol] < 0 then
      result.matrix[l2ndMaxRow,l2ndMaxCol] := -1
   else
       result.matrix[l2ndMaxRow,l2ndMaxCol] := 1;

   if Q.matrix[l3rdMaxRow,l3rdMaxCol] < 0 then
      result.matrix[l3rdMaxRow,l3rdMaxCol] := -1
   else
       result.matrix[l3rdMaxRow,l3rdMaxCol] := 1;
end;


procedure FindMatrixPt (lX,lY,lZ: single; var lXout,lYOut,lZOut: single; var lMatrix: TMatrix);
begin
	lXOut := (lX*lMatrix.matrix[1,1])+(lY*lMatrix.matrix[1,2])+(lZ*lMatrix.matrix[1,3])+lMatrix.matrix[1,4];
	lYOut := (lX*lMatrix.matrix[2,1])+(lY*lMatrix.matrix[2,2])+(lZ*lMatrix.matrix[2,3])+lMatrix.matrix[2,4];
	lZOut := (lX*lMatrix.matrix[3,1])+(lY*lMatrix.matrix[3,2])+(lZ*lMatrix.matrix[3,3])+lMatrix.matrix[3,4];
end;

procedure CheckMin(var lX,lY,lZ,lXMin,lYMin,lZMin: single);
begin
	if lX < lXMin then lXMin := lX;
	if lY < lYMin then lYMin := lY;
	if lZ < lZMin then lZMin := lZ;
end;

procedure Mins (var lMatrix: TMatrix; var lHdr: TNIFTIhdr; var lXMin,lYMin,lZMin: single);
var
   lPos,lXc,lYc,lZc: integer;
   lx,ly,lz: single;
begin
  FindMatrixPt(0,0,0,lX,lY,lZ,lMatrix);
  lXMin := lX;
  lYMin := lY;
  lZMin := lZ;
  for lPos := 1 to 7 do begin
	if odd(lPos) then
		lXc := lHdr.Dim[1]-1
	else
		lXc := 0;
	if odd(lPos shr 1) then
		lYc := lHdr.Dim[2]-1
	else
		lYc := 0;
	if odd(lPos shr 2) then
		lZc := lHdr.Dim[3]-1
	else
		lZc := 0;
	FindMatrixPt(lXc,lYc,lZc,lX,lY,lZ,lMatrix);
	CheckMin(lX,lY,lZ,lXMin,lYMin,lZMin);
  end;
end;

procedure Zoom(var lHdr: TNIFTIhdr; lScale: single);
//if we have a 256x256x256 pixel image with scale of 0.5, output is 128x128x128
//if we have a 1x1x1mm pixel image with a scale of 2.0, output is 2x2x2mm
var
   i: integer;
begin
     for i := 1 to 3 do begin
         lHdr.dim[i] := round(lHdr.dim[i] * lScale);
         lHdr.pixdim[i] := lHdr.pixdim[i] / lScale;
         //fx(lHdr.srow_x[i] ,lHdr.srow_y[i] ,lHdr.srow_z[i] );
     end;
     for i :=0 to 2 do begin

         lHdr.srow_x[i] := lHdr.srow_x[i]/ lScale;
         lHdr.srow_y[i] := lHdr.srow_y[i]/ lScale;
         lHdr.srow_z[i] := lHdr.srow_z[i]/ lScale;
     end;
end;

// Extends image shrink code by Anders Melander, anders@melander.dk
// Here's some additional copyrights for you:
//
// The algorithms and methods used in this library are based on the article
// "General Filtered Image Rescaling" by Dale Schumacher which appeared in the
// book Graphics Gems III, published by Academic Press, Inc.
// From filter.c:
// The authors and the publisher hold no copyright restrictions
// on any of these files; this source code is public domain, and
// is freely available to the entire computer graphics community
// for study, use, and modification.  We do request that the
// comment at the top of each file, identifying the original
// author and its original publication in the book Graphics
// Gems, be retained in all programs that use these files.

function HermiteFilter(Value: Single): Single;
begin
  // f(t) = 2|t|^3 - 3|t|^2 + 1, -1 <= t <= 1
  if (Value < 0.0) then
    Value := -Value;
  if (Value < 1.0) then
    Result := (2.0 * Value - 3.0) * Sqr(Value) + 1.0
  else
    Result := 0.0;
end;

// Box filter
// a.k.a. "Nearest Neighbour" filter
// anme: I have not been able to get acceptable
//       results with this filter for subsampling.

function BoxFilter(Value: Single): Single;
begin
  if (Value > -0.5) and (Value <= 0.5) then
    Result := 1.0
  else
    Result := 0.0;
end;

// Triangle filter
// a.k.a. "Linear" or "Bilinear" filter

function TriangleFilter(Value: Single): Single;
begin
  if (Value < 0.0) then
    Value := -Value;
  if (Value < 1.0) then
    Result := 1.0 - Value
  else
    Result := 0.0;
end;

// Bell filter

function BellFilter(Value: Single): Single;
begin
  if (Value < 0.0) then
    Value := -Value;
  if (Value < 0.5) then
    Result := 0.75 - Sqr(Value)
  else if (Value < 1.5) then
  begin
    Value := Value - 1.5;
    Result := 0.5 * Sqr(Value);
  end
  else
    Result := 0.0;
end;

// B-spline filter

function SplineFilter(Value: Single): Single;
var
  tt: single;
begin
  if (Value < 0.0) then
    Value := -Value;
  if (Value < 1.0) then
  begin
    tt := Sqr(Value);
    Result := 0.5 * tt * Value - tt + 2.0 / 3.0;
  end
  else if (Value < 2.0) then
  begin
    Value := 2.0 - Value;
    Result := 1.0 / 6.0 * Sqr(Value) * Value;
  end
  else
    Result := 0.0;
end;

// Lanczos3 filter

function Lanczos3Filter(Value: Single): Single;

function SinC(Value: Single): Single;
  begin
    if (Value <> 0.0) then
    begin
      Value := Value * Pi;
      Result := sin(Value) / Value
    end
    else
      Result := 1.0;
  end;
begin
  if (Value < 0.0) then
    Value := -Value;
  if (Value < 3.0) then
    Result := SinC(Value) * SinC(Value / 3.0)
  else
    Result := 0.0;
end;

function MitchellFilter(Value: Single): Single;
const
  B = (1.0 / 3.0);
  C = (1.0 / 3.0);
var
  tt: single;
begin
  if (Value < 0.0) then
    Value := -Value;
  tt := Sqr(Value);
  if (Value < 1.0) then
  begin
    Value := (((12.0 - 9.0 * B - 6.0 * C) * (Value * tt))
      + ((-18.0 + 12.0 * B + 6.0 * C) * tt)
      + (6.0 - 2 * B));
    Result := Value / 6.0;
  end
  else if (Value < 2.0) then
  begin
    Value := (((-1.0 * B - 6.0 * C) * (Value * tt))
      + ((6.0 * B + 30.0 * C) * tt)
      + ((-12.0 * B - 48.0 * C) * Value)
      + (8.0 * B + 24 * C));
    Result := Value / 6.0;
  end
  else
    Result := 0.0;
end;

type
  // Contributor for a pixel
  TFilterProc = function(Value: Single): Single;
  TContributor = record
    pixel: integer; // Source pixel
    weight: single; // Pixel weight
  end;
  TContributorList = array[0..0] of TContributor;
  PContributorList = ^TContributorList;
  // List of source pixels contributing to a destination pixel
  TCList = record
    n: integer;
    p: PContributorList;
  end;
  TCListList = array[0..0] of TCList;
  PCListList = ^TCListList;

procedure SetContrib(out contrib: PCListList; SrcPix, DstPix, Delta: integer; xscale, fwidth: single; filter: TFilterProc);
var
  i,j,k: integer;
  width, fscale: single;
  sum, center, weight: single; // Filter calculation variables
  left, right: integer; // Filter calculation variables
begin
  if (DstPix < 1) or (xscale > 1) or (xscale < 0) then exit;
  width := fwidth / xscale;
  fscale := 1.0 / xscale;
  GetMem(contrib, DstPix * sizeof(TCList));
  for i := 0 to DstPix - 1 do begin
      contrib^[i].n := 0;
      GetMem(contrib^[i].p, trunc(width * 2.0 + 1) * sizeof(TContributor));
      center := i / xscale;
      left := floor(center - width);
      left := max(left,0);
      right := ceil(center + width);
      right := min(right, SrcPix - 1);
      sum := 0.0;
      for j := left to right do begin
        weight := filter((center - j) / fscale) / fscale;
        if (weight = 0.0) then
          continue;
        sum := sum + weight;
        k := contrib^[i].n;
        contrib^[i].n := contrib^[i].n + 1;
        contrib^[i].p^[k].pixel := j * Delta;
        contrib^[i].p^[k].weight := weight;
      end;
      for k := 0 to contrib^[i].n - 1 do
          contrib^[i].p^[k].weight := contrib^[i].p^[k].weight/sum;
      (*showmessage(format('n=%d l=%d r=%d c=%g sum=%g',[contrib^[i].n, left, right, center, sum]));
      for k := 0 to contrib^[i].n - 1 do
          showmessage(format('%d %g',[contrib^[i].p^[k].pixel, contrib^[i].p^[k].weight])); *)
    end;
end;

procedure ShrinkLarge8(var lHdr: TNIFTIhdr; var lBuffer: bytep; xscale, fwidth: single; filter: TFilterProc);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
label
  666;
var
  sum, mx, mn: single;
  lineStart, x,y,z, lXo,lYo,lZo,lXi,lYi,lZi, outBytes, i,j: integer;
  contrib: PCListList;
  finalImg, tempImgX, tempImgY, tempImgZ: Singlep;
begin
  lXi := lHdr.dim[1]; //input X
  lYi := lHdr.dim[2]; //input Y
  lZi := lHdr.dim[3]; //input Z
  lXo := lXi; lYo := lYi; lZo := lZi; //output initially same as input
  //inBytes := lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]*bytesPerVox;
  //find min/max values
  mn := lBuffer^[1];
  mx := mn;
  for i := 1 to (lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]) do begin
      if lBuffer^[i] < mn then mn := lBuffer^[i];
      if lBuffer^[i] > mx then mx := lBuffer^[i];
  end;
  Zoom(lHdr,xscale);
  //shrink in 1st dimension : do X as these are contiguous = faster, compute slower dimensions at reduced resolution
  lXo := lHdr.dim[1]; //input X
  GetMem( tempImgX,lXo*lYi*lZi*sizeof(single)); //8
  SetContrib(contrib, lXi, lXo, 1, xscale, fwidth, filter);
  i := 1;
  for z := 0 to (lZi - 1) do begin
    for y := 0 to (lYi-1) do begin
        lineStart := 1+ (lXi * y)+((lXi*lYi) * z);
        for x := 0 to (lXo - 1) do begin
            sum := 0.0;
            for j := 0 to contrib^[x].n - 1 do begin
              sum := sum + (contrib^[x].p^[j].weight * lBuffer^[lineStart +contrib^[x].p^[j].pixel]);
            end;
            tempImgX^[i] := sum;
            i := i + 1;
        end; //for X
    end; //for Y
  end; //for Z
  for i := 0 to lXo - 1 do
     FreeMem(contrib^[i].p);
  FreeMem(contrib);
  Freemem( lBuffer);
  //{$DEFINE XONLY}
  {$IFDEF XONLY}
  finalImg := tempImgX;
  goto 666;
  {$ENDIF}
  if ((lYi = lHdr.dim[2]) and (lZi = lHdr.dim[3])) then goto 666; //e.g. 1D image
  //shrink in 2nd dimension
  lYo := lHdr.dim[2]; //reduce Y output
  GetMem( tempImgY,lXo*lYo*lZi*sizeof(single)); //8
  SetContrib(contrib, lYi, lYo, lXo, xscale, fwidth, filter);
  i := 1;
  for z := 0 to (lZi - 1) do begin
      for y := 0 to (lYo - 1) do begin
          for x := 0 to (lXo-1) do begin
            lineStart :=  1+x+((lXo*lYi) * z);
            sum := 0.0;
            for j := 0 to contrib^[y].n - 1 do begin
              //sum := sum + (contrib^[y].p^[j].weight * sourceLine^[contrib^[y].p^[j].pixel]);
              sum := sum + (contrib^[y].p^[j].weight * tempImgX^[lineStart +contrib^[y].p^[j].pixel] );
            end;
            tempImgY^[i] := sum;
            i := i + 1;
        end; //for X
    end; //for Y
  end; //for Z
  for i := 0 to lYo - 1 do
     FreeMem(contrib^[i].p);
  FreeMem(contrib);
  Freemem( tempImgX);
  //{$DEFINE YONLY}
  {$IFDEF YONLY}
    finalImg := tempImgY;
    goto 666;
  {$ENDIF}
  if (lZi = lHdr.dim[3]) then goto 666; //e.g. 2D image
  //shrink the 3rd dimension
  lZo := lHdr.dim[3]; //reduce Z output
  GetMem( tempImgZ,lXo*lYo*lZo*sizeof(single)); //8
  SetContrib(contrib, lZi, lZo, (lXo*lYo), xscale, fwidth, filter);
  i := 1;
  for z := 0 to (lZo - 1) do begin
      for y := 0 to (lYo - 1) do begin
          for x := 0 to (lXo-1) do begin
            lineStart :=  1+x+(lXo * y);
            sum := 0.0;
            for j := 0 to contrib^[z].n - 1 do begin
              sum := sum + (contrib^[z].p^[j].weight * tempImgY^[lineStart +contrib^[z].p^[j].pixel] );
            end;
            tempImgZ^[i] := sum;
            i := i + 1;
        end; //for X
    end; //for Y
  end; //for Z
  for i := 0 to lZo - 1 do
     FreeMem(contrib^[i].p);
  FreeMem(contrib);
  Freemem( tempImgY);
  finalImg := tempImgZ;
666:
  lHdr.dim[1] := lXo;
  lHdr.dim[2] := lYo;
  lHdr.dim[3] := lZo;
  outBytes := lHdr.dim[1] * lHdr.dim[2] * lHdr.dim[3]*sizeof(byte);
  GetMem( lBuffer,outBytes); //8
  for i := 1 to ((lXo*lYo*lZo)-1) do begin
      //check image range - some interpolation can cause ringing
      // e.g. if input range 0..1000 do not create negative values!
      if finalImg^[i] > mx then finalImg^[i] := mx;
      if finalImg^[i] < mn then finalImg^[i] := mn;
      lBuffer^[i] := round(finalImg^[i]);
  end;
  Freemem( finalImg);
end; //ShrinkLarge8()

procedure ShrinkLarge16(var lHdr: TNIFTIhdr; var lBuffer: bytep; xscale, fwidth: single; filter: TFilterProc);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
label
  666;
var
  sum, mx, mn: single;
  lineStart, x,y,z,  lXo,lYo,lZo,lXi,lYi,lZi, outBytes, i,j: integer;
  contrib: PCListList;
  lImg16: SmallIntP;
  finalImg, tempImgX, tempImgY, tempImgZ: Singlep;
begin
  lXi := lHdr.dim[1]; //input X
  lYi := lHdr.dim[2]; //input Y
  lZi := lHdr.dim[3]; //input Z
  lXo := lXi; lYo := lYi; lZo := lZi; //output initially same as input
  //inBytes := lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]*bytesPerVox;
  //find min/max values
  lImg16 := SmallIntP(lBuffer);
  mn := lImg16^[1];
  mx := mn;
  for i := 1 to (lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]) do begin
      if lImg16^[i] < mn then mn := lImg16^[i];
      if lImg16^[i] > mx then mx := lImg16^[i];
  end;
  Zoom(lHdr,xscale);
  //shrink in 1st dimension : do X as these are contiguous = faster, compute slower dimensions at reduced resolution
  lXo := lHdr.dim[1]; //input X
  GetMem( tempImgX,lXo*lYi*lZi*sizeof(single)); //8
  SetContrib(contrib, lXi, lXo, 1, xscale, fwidth, filter);
  i := 1;
  for z := 0 to (lZi - 1) do begin
    for y := 0 to (lYi-1) do begin
        lineStart := 1+ (lXi * y)+((lXi*lYi) * z);
        for x := 0 to (lXo - 1) do begin
            sum := 0.0;
            for j := 0 to contrib^[x].n - 1 do begin
              sum := sum + (contrib^[x].p^[j].weight * lImg16^[lineStart +contrib^[x].p^[j].pixel]);
            end;
            tempImgX^[i] := sum;
            i := i + 1;
        end; //for X
    end; //for Y
  end; //for Z
  for i := 0 to lXo - 1 do
     FreeMem(contrib^[i].p);
  FreeMem(contrib);
  Freemem( lBuffer);
  //{$DEFINE XONLY}
  {$IFDEF XONLY}
  finalImg := tempImgX;
  goto 666;
  {$ENDIF}
  if ((lYi = lHdr.dim[2]) and (lZi = lHdr.dim[3])) then goto 666; //e.g. 1D image
  //shrink in 2nd dimension
  lYo := lHdr.dim[2]; //reduce Y output
  GetMem( tempImgY,lXo*lYo*lZi*sizeof(single)); //8
  SetContrib(contrib, lYi, lYo, lXo, xscale, fwidth, filter);
  i := 1;
  for z := 0 to (lZi - 1) do begin
      for y := 0 to (lYo - 1) do begin
          for x := 0 to (lXo-1) do begin
            lineStart :=  1+x+((lXo*lYi) * z);
            sum := 0.0;
            for j := 0 to contrib^[y].n - 1 do begin
              //sum := sum + (contrib^[y].p^[j].weight * sourceLine^[contrib^[y].p^[j].pixel]);
              sum := sum + (contrib^[y].p^[j].weight * tempImgX^[lineStart +contrib^[y].p^[j].pixel] );
            end;
            tempImgY^[i] := sum;
            i := i + 1;
        end; //for X
    end; //for Y
  end; //for Z
  for i := 0 to lYo - 1 do
     FreeMem(contrib^[i].p);
  FreeMem(contrib);
  Freemem( tempImgX);
  //{$DEFINE YONLY}
  {$IFDEF YONLY}
    finalImg := tempImgY;
    goto 666;
  {$ENDIF}
  if (lZi = lHdr.dim[3]) then goto 666; //e.g. 2D image
  //shrink the 3rd dimension
  lZo := lHdr.dim[3]; //reduce Z output
  GetMem( tempImgZ,lXo*lYo*lZo*sizeof(single)); //8
  SetContrib(contrib, lZi, lZo, (lXo*lYo), xscale, fwidth, filter);
  i := 1;
  for z := 0 to (lZo - 1) do begin
      for y := 0 to (lYo - 1) do begin
          for x := 0 to (lXo-1) do begin
            lineStart :=  1+x+(lXo * y);
            sum := 0.0;
            for j := 0 to contrib^[z].n - 1 do begin
              sum := sum + (contrib^[z].p^[j].weight * tempImgY^[lineStart +contrib^[z].p^[j].pixel] );
            end;
            tempImgZ^[i] := sum;
            i := i + 1;
        end; //for X
    end; //for Y
  end; //for Z
  for i := 0 to lZo - 1 do
     FreeMem(contrib^[i].p);
  FreeMem(contrib);
  Freemem( tempImgY);
  finalImg := tempImgZ;
666:
  lHdr.dim[1] := lXo;
  lHdr.dim[2] := lYo;
  lHdr.dim[3] := lZo;
  outBytes := lHdr.dim[1] * lHdr.dim[2] * lHdr.dim[3]*sizeof(SmallInt);
  GetMem( lBuffer,outBytes);
  lImg16 := SmallIntP(lBuffer);
  for i := 1 to ((lXo*lYo*lZo)-1) do begin
      //check image range - some interpolation can cause ringing
      // e.g. if input range 0..1000 do not create negative values!
      if finalImg^[i] > mx then finalImg^[i] := mx;
      if finalImg^[i] < mn then finalImg^[i] := mn;
      lImg16^[i] := round(finalImg^[i]);
  end;
  Freemem( finalImg);
end; //ShrinkLarge16()

procedure ShrinkLarge24(var lHdr: TNIFTIhdr; var lBuffer: bytep; xscale, fwidth: single; filter: TFilterProc);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
//this is done as three passes: once for red, green and blue
// it might be a little faster to compute as one pass.
// however, shrinklarge is designed for huge images (~2Gb) that will overwhelm graphics cards
// since we use 32-bit floats, computing 3 passes requires less RAM
var
   iHdr: TNIFTIhdr;
   lXi, lYi, lZi, nVxi, nVxo, i, j, k: integer;
  imgo, img1: bytep;
begin
  lXi := lHdr.dim[1]; //input X
  lYi := lHdr.dim[2]; //input Y
  lZi := lHdr.dim[3]; //input Z
  nVxi := lXi * lYi * lZi;
  iHdr := lHdr;
  for k := 1 to 3 do begin
    GetMem( img1,nVxi);
    j := k;
    for i := 1 to nVxi do begin
        img1[i] := lBuffer[j];
        j := j + 3;
    end;
    lHdr := iHdr;
    ShrinkLarge8(lHdr, img1, xscale, fwidth, filter);
    if (k = 1) then begin
       nVxo := lHdr.dim[1] * lHdr.dim[2] * lHdr.dim[3];
       getmem(imgo,nVxo * 3);
    end;
    j := k;
    for i := 1 to nVxo do begin
        imgo[j] := img1[i];
        j := j + 3;
    end;
    FreeMem( img1);
  end;
  freemem(lBuffer);
  lBuffer := imgo;
end; //ShrinkLarge24()

procedure ShrinkLarge32(var lHdr: TNIFTIhdr; var lBuffer: bytep; xscale, fwidth: single; filter: TFilterProc);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
label
  666;
var
  sum, mx, mn: single;
  lineStart, x,y,z, lXo,lYo,lZo,lXi,lYi,lZi, i,j: integer;
  contrib: PCListList;
  lImg32: SingleP;
  finalImg, tempImgX, tempImgY, tempImgZ: Singlep;
begin
  //bytesPerVox := 4;
  lXi := lHdr.dim[1]; //input X
  lYi := lHdr.dim[2]; //input Y
  lZi := lHdr.dim[3]; //input Z
  lXo := lXi; lYo := lYi; lZo := lZi; //output initially same as input
  //inBytes := lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]*bytesPerVox;
  //find min/max values
  lImg32 := SingleP(lBuffer);
  mn := lImg32^[1];
  mx := mn;
  for i := 1 to (lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]) do begin
      if lImg32^[i] < mn then mn := lImg32^[i];
      if lImg32^[i] > mx then mx := lImg32^[i];
  end;
  Zoom(lHdr,xscale);
  //shrink in 1st dimension : do X as these are contiguous = faster, compute slower dimensions at reduced resolution
  lXo := lHdr.dim[1]; //input X
  GetMem( tempImgX,lXo*lYi*lZi*sizeof(single));
  SetContrib(contrib, lXi, lXo, 1, xscale, fwidth, filter);
  i := 1;
  for z := 0 to (lZi - 1) do begin
    for y := 0 to (lYi-1) do begin
        lineStart := 1+ (lXi * y)+((lXi*lYi) * z);
        for x := 0 to (lXo - 1) do begin
            sum := 0.0;
            for j := 0 to contrib^[x].n - 1 do begin
              sum := sum + (contrib^[x].p^[j].weight * lImg32^[lineStart +contrib^[x].p^[j].pixel]);
            end;
            tempImgX^[i] := sum;
            i := i + 1;
        end; //for X
    end; //for Y
  end; //for Z
  for i := 0 to lXo - 1 do
     FreeMem(contrib^[i].p);
  FreeMem(contrib);
  Freemem( lBuffer);
  //{$DEFINE XONLY}
  {$IFDEF XONLY}
  finalImg := tempImgX;
  goto 666;
  {$ENDIF}
  if ((lYi = lHdr.dim[2]) and (lZi = lHdr.dim[3])) then goto 666; //e.g. 1D image
  //shrink in 2nd dimension
  lYo := lHdr.dim[2]; //reduce Y output
  GetMem( tempImgY,lXo*lYo*lZi*sizeof(single)); //8
  SetContrib(contrib, lYi, lYo, lXo, xscale, fwidth, filter);
  i := 1;
  for z := 0 to (lZi - 1) do begin
      for y := 0 to (lYo - 1) do begin
          for x := 0 to (lXo-1) do begin
            lineStart :=  1+x+((lXo*lYi) * z);
            sum := 0.0;
            for j := 0 to contrib^[y].n - 1 do begin
              //sum := sum + (contrib^[y].p^[j].weight * sourceLine^[contrib^[y].p^[j].pixel]);
              sum := sum + (contrib^[y].p^[j].weight * tempImgX^[lineStart +contrib^[y].p^[j].pixel] );
            end;
            tempImgY^[i] := sum;
            i := i + 1;
        end; //for X
    end; //for Y
  end; //for Z
  for i := 0 to lYo - 1 do
     FreeMem(contrib^[i].p);
  FreeMem(contrib);
  Freemem( tempImgX);
  //{$DEFINE YONLY}
  {$IFDEF YONLY}
    finalImg := tempImgY;
    goto 666;
  {$ENDIF}
  if (lZi = lHdr.dim[3]) then goto 666; //e.g. 2D image
  //shrink the 3rd dimension
  lZo := lHdr.dim[3]; //reduce Z output
  GetMem( tempImgZ,lXo*lYo*lZo*sizeof(single)); //8
  SetContrib(contrib, lZi, lZo, (lXo*lYo), xscale, fwidth, filter);
  i := 1;
  for z := 0 to (lZo - 1) do begin
      for y := 0 to (lYo - 1) do begin
          for x := 0 to (lXo-1) do begin
            lineStart :=  1+x+(lXo * y);
            sum := 0.0;
            for j := 0 to contrib^[z].n - 1 do begin
              sum := sum + (contrib^[z].p^[j].weight * tempImgY^[lineStart +contrib^[z].p^[j].pixel] );
            end;
            tempImgZ^[i] := sum;
            i := i + 1;
        end; //for X
    end; //for Y
  end; //for Z
  for i := 0 to lZo - 1 do
     FreeMem(contrib^[i].p);
  FreeMem(contrib);
  Freemem( tempImgY);
  finalImg := tempImgZ;
666:
  lHdr.dim[1] := lXo;
  lHdr.dim[2] := lYo;
  lHdr.dim[3] := lZo;
  for i := 1 to ((lXo*lYo*lZo)-1) do begin
      //check image range - some interpolation can cause ringing
      // e.g. if input range 0..1000 do not create negative values!
      if finalImg^[i] > mx then finalImg^[i] := mx;
      if finalImg^[i] < mn then finalImg^[i] := mn;
  end;
  lBuffer := bytep(finalImg);
end; //ShrinkLarge32()


(*procedure ShrinkLarge8(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
var
   lBase,lO,lX,lY,lZ,lMax,lXYi,lXi,lYi,lZi,lZt,lYt,lXt,lOffset: int64;
   lScale,lZf, lYf,lXf,lXl,lYl,lZl : single;
   lIn: bytep;
begin
  if lHdr.datatype <> kDT_UNSIGNED_CHAR then
    exit;
  if (lHdr.dim[1] > lHdr.dim[2]) and  (lHdr.dim[1] > lHdr.dim[3]) then
   lMax := lHdr.dim[1]
  else if (lHdr.dim[2] > lHdr.dim[3])  then
     lMax := lHdr.dim[2]
  else
    lMax := lHdr.dim[3];
  if (lMax <= lMaxDim) or (lMax < 3) then begin
     {$IFDEF UNIX}
     writeln(format('Loading image at full size: maximum image dimension (%d) is less than "MaxVox" (%d). Edit "MaxVox" preference to downsample.',[lMax, lMaxDim]));
     {$ENDIF}
     exit; //not a large image or not a 3D image
  end;
  {$IFDEF UNIX}
  writeln(format('Downsampling image: maximum image dimension (%d) is greater than "MaxVox" (%d). Edit "MaxVox" preference to load at full resolution.',[lMax, lMaxDim]));
  {$ENDIF}
  lScale := lMaxDim/lMax;// from source to target: 256->128 = 0.5
  lXYi := lHdr.dim[1]*lHdr.dim[2]; //input XY
  lXi := lHdr.dim[1]; //input X
  lYi := lHdr.dim[2]; //input Y
  lZi := lHdr.dim[3]; //input Z
  lOffset := lXYi* lHdr.dim[3];//8 bytes
  Getmem(lIn,lOffset);
  Move(lBuffer^,lIn^,lOffset);
  Zoom(lHdr,lScale);
  Freemem( lBuffer);
  GetMem( lBuffer,lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3] ); //8
  lScale := lMax/lMaxDim;// from target to source: 128->256 = 2.0
  lO := 0; //output voxel
  for lZ := 0 to (lHdr.dim[3]-1) do begin
      lZf := lZ * lScale;
      lZt := trunc(lZf);
      if lZt >= (lZi-1) then begin
         lZt := lZi-2;
         lZf := 1;
      end else
          lZf := lZf-lZt;//frac(lZf)
      lZl := 1-lZf;
      for lY := 0 to (lHdr.dim[2]-1) do begin
          lYf := lY * lScale;
          lYt := trunc(lYf);
          if lYt >= (lYi-1) then begin
             lYt := lYi-2;
             lYf := 1;
          end else
              lYf := lYf-lYt;
          lYl := 1 - lYf;
          lOffset := (lZt*lXYi)+ (lYt*lXi);
          for lX := 1 to lHdr.dim[1] do begin
              inc(lO);
              lXf := lX * lScale;
              lXt := trunc(lXf);
              if lXt >= lXi then begin
                 lXt := lXi-1;
                 lXf := 1;
              end else
                  lXf := lXf-lXt;
              lXl := 1-lXf;
              if lXt < 1 then
                 lXt := 1; //indexed from 1...
              lBase := lOffset + lXt;
              //lBuffer^[lO] :=  lIn^[lBase]; //<- nearest neighbor
              lBuffer^[lO] :=
                                         round (
		 	   {all min} ( (lXl*lYl*lZl)*lIn^[lBase])
			   {x+1}+((lXf*lYl*lZl)*lIn^[lBase]+1)
			   {y+1}+((lXl*lYf*lZl)*lIn^[lBase+lXi])
			   {z+1}+((lXl*lYl*lZf)*lIn^[lBase+lXYi])
			   {x+1,y+1}+((lXf*lYf*lZl)*lIn^[lBase+1+lXi])
			   {x+1,z+1}+((lXf*lYl*lZf)*lIn^[lBase+1+lXYi])
			   {y+1,z+1}+((lXl*lYf*lZf)*lIn^[lBase+lXi+lXYi])
			   {x+1,y+1,z+1}+((lXf*lYf*lZf)*lIn^[lBase+1+lXi+lXYi]) );
          end; //lX
      end; //lY
  end; //Z
  Freemem(lIn);
end; //ShrinkLarge8

procedure ShrinkLarge16(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
var
   lBase,lO,lX,lY,lZ,lMax,lXYi,lXi,lYi,lZi,lZt,lYt,lXt,lOffset: int64;
   lScale,lZf, lYf,lXf,lXl,lYl,lZl : single;
   lIn,lOut: SmallIntP; //16
begin
  if lHdr.datatype <> kDT_SIGNED_SHORT then //16
     exit;
  if (lHdr.dim[1] > lHdr.dim[2]) and  (lHdr.dim[1] > lHdr.dim[3]) then
     lMax := lHdr.dim[1]
  else if (lHdr.dim[2] > lHdr.dim[3])  then
       lMax := lHdr.dim[2]
  else
      lMax := lHdr.dim[3];
  if (lMax <= lMaxDim) or (lMax < 3) then begin
     {$IFDEF UNIX}
     writeln(format('Loading image at full size: maximum image dimension (%d) is less than "MaxVox" (%d). Edit "MaxVox" preference to downsample.',[lMax, lMaxDim]));
     {$ENDIF}
     exit; //not a large image or not a 3D image
  end;
  {$IFDEF UNIX}
  writeln(format('Downsampling image: maximum image dimension (%d) is greater than "MaxVox" (%d). Edit "MaxVox" preference to load at full resolution.',[lMax, lMaxDim]));
  {$ENDIF}
  lScale := lMaxDim/lMax;// from source to target: 256->128 = 0.5
  lXYi := lHdr.dim[1]*lHdr.dim[2]; //input XY
  lXi := lHdr.dim[1]; //input X
  lYi := lHdr.dim[2]; //input Y
  lZi := lHdr.dim[3]; //input Z
  lOffset := lXYi* lHdr.dim[3]*sizeof(smallint);//16 bytes
  Getmem(lIn,lOffset);
  lOut := SmallIntP(lBuffer);
  Move(lOut^,lIn^,lOffset);
  Zoom(lHdr,lScale);
  Freemem( lBuffer);
  GetMem( lBuffer,lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]*sizeof(smallint) ); //16
  lOut := SmallIntP(lBuffer);
  lScale := lMax/lMaxDim;// from target to source: 128->256 = 2.0
  lO := 0; //output voxel
  for lZ := 0 to (lHdr.dim[3]-1) do begin
      lZf := lZ * lScale;
      lZt := trunc(lZf);
      if lZt >= (lZi-1) then begin
         lZt := lZi-2;
         lZf := 1;
      end else
          lZf := lZf-lZt;//frac(lZf)
      lZl := 1-lZf;
      for lY := 0 to (lHdr.dim[2]-1) do begin
          lYf := lY * lScale;
          lYt := trunc(lYf);
          if lYt >= (lYi-1) then begin
             lYt := lYi-2;
             lYf := 1;
          end else
              lYf := lYf-lYt;
          lYl := 1 - lYf;
          lOffset := (lZt*lXYi)+ (lYt*lXi);
          for lX := 1 to lHdr.dim[1] do begin
              inc(lO);
              lXf := lX * lScale;
              lXt := trunc(lXf);
              if lXt >= lXi then begin
                 lXt := lXi-1;
                 lXf := 1;
              end else
                  lXf := lXf-lXt;
              lXl := 1-lXf;
              if lXt < 1 then
                 lXt := 1; //indexed from 1...
              lBase := lOffset + lXt;
              //lBuffer^[lO] :=  lIn^[lBase]; //<- nearest neighbor
              lOut^[lO] :=
                                         round (
		 	   {all min} ( (lXl*lYl*lZl)*lIn^[lBase])
			   {x+1}+((lXf*lYl*lZl)*lIn^[lBase]+1)
			   {y+1}+((lXl*lYf*lZl)*lIn^[lBase+lXi])
			   {z+1}+((lXl*lYl*lZf)*lIn^[lBase+lXYi])
			   {x+1,y+1}+((lXf*lYf*lZl)*lIn^[lBase+1+lXi])
			   {x+1,z+1}+((lXf*lYl*lZf)*lIn^[lBase+1+lXYi])
			   {y+1,z+1}+((lXl*lYf*lZf)*lIn^[lBase+lXi+lXYi])
			   {x+1,y+1,z+1}+((lXf*lYf*lZf)*lIn^[lBase+1+lXi+lXYi]) );

          end; //lX

      end; //lY
  end; //Z
  Freemem(lIn);
end;  //ShrinkLarge16 *)

(*procedure ShrinkLarge24(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
//WARNING: this code is for 24-bit RGB format, which is planar RRRRRRGGGGGBBBBB!!!!
var
   lBase,lO,lX,lY,lZ,lMax,lXYo,lXYi24,lXi,lYi,lZi,lZt,lYt,lXt,lOffset: int64;
   lScale,lZf, lYf,lXf,lXl,lYl,lZl : single;
   lIn: bytep;
begin
  if lHdr.datatype <> kDT_RGB then
     exit;
  if (lHdr.dim[1] > lHdr.dim[2]) and  (lHdr.dim[1] > lHdr.dim[3]) then
     lMax := lHdr.dim[1]
  else if (lHdr.dim[2] > lHdr.dim[3])  then
       lMax := lHdr.dim[2]
  else
      lMax := lHdr.dim[3];
  if (lMax <= lMaxDim) or (lMax < 3) then begin
     {$IFDEF UNIX}
     writeln(format('Loading image at full size: maximum image dimension (%d) is less than "MaxVox" (%d). Edit "MaxVox" preference to downsample.',[lMax, lMaxDim]));
     {$ENDIF}
     exit; //not a large image or not a 3D image
  end;
  {$IFDEF UNIX}
  writeln(format('Downsampling image: maximum image dimension (%d) is greater than "MaxVox" (%d). Edit "MaxVox" preference to load at full resolution.',[lMax, lMaxDim]));
  {$ENDIF}
  lScale := lMaxDim/lMax;// from source to target: 256->128 = 0.5
  lXYi24 := lHdr.dim[1]*lHdr.dim[2]*3; //slice size in bytes * 3 since  RGB planes
  lXi := lHdr.dim[1]; //input X
  lYi := lHdr.dim[2]; //input Y
  lZi := lHdr.dim[3]; //input Z
  lOffset := lXYi24* lHdr.dim[3];//*3 = 24-bit
  Getmem(lIn,lOffset);
  Move(lBuffer^,lIn^,lOffset);
  Zoom(lHdr,lScale);
  Freemem( lBuffer);
  lXYo := lHdr.dim[1]*lHdr.dim[2];///output
  GetMem( lBuffer,lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]*3 ); //*3= 24-bit
  lScale := lMax/lMaxDim;// from target to source: 128->256 = 2.0
  for lZ := 0 to (lHdr.dim[3]-1) do begin
      lZf := lZ * lScale;
      lZt := trunc(lZf);
      if lZt >= (lZi-1) then begin
         lZt := lZi-2;
         lZf := 1;
      end else
          lZf := lZf-lZt;//frac(lZf)
      lZl := 1-lZf;
      lO := lZ * lHdr.dim[1]*lHdr.dim[2]*3; //offset for slice triplet: *3 as RGB planes
      for lY := 0 to (lHdr.dim[2]-1) do begin
          lYf := lY * lScale;
          lYt := trunc(lYf);
          if lYt >= (lYi-1) then begin
             lYt := lYi-2;
             lYf := 1;
          end else
              lYf := lYf-lYt;
          lYl := 1 - lYf;
          lOffset := (lZt*lXYi24)+ (lYt*lXi);
          for lX := 1 to lHdr.dim[1] do begin

              lXf := lX * lScale;
              lXt := trunc(lXf);
              if lXt >= lXi then begin
                 lXt := lXi-1;
                 lXf := 1;
              end else
                  lXf := lXf-lXt;
              lXl := 1-lXf;
              if lXt < 1 then
                 lXt := 1; //indexed from 1...
              lBase := lOffset + lXt;
              //RED SLICE
              inc(lO);
              //lBuffer^[lO] :=lIn^[lBase];
              lBuffer^[lO] :=  round (
		 	   {all min} ( (lXl*lYl*lZl)*lIn^[lBase])
			   {x+1}+((lXf*lYl*lZl)*lIn^[lBase]+1)
			   {y+1}+((lXl*lYf*lZl)*lIn^[lBase+lXi])
			   {z+1}+((lXl*lYl*lZf)*lIn^[lBase+lXYi24])
			   {x+1,y+1}+((lXf*lYf*lZl)*lIn^[lBase+1+lXi])
			   {x+1,z+1}+((lXf*lYl*lZf)*lIn^[lBase+1+lXYi24])
			   {y+1,z+1}+((lXl*lYf*lZf)*lIn^[lBase+lXi+lXYi24])
			   {x+1,y+1,z+1}+((lXf*lYf*lZf)*lIn^[lBase+1+lXi+lXYi24]) );
              //GREEN SLICE
              lBase := lBase+(lXi*lYi);
              //lBuffer^[lO+lXYo] :=lIn^[lBase];
              lBuffer^[lO+lXYo] :=  round (
		 	   {all min} ( (lXl*lYl*lZl)*lIn^[lBase])
			   {x+1}+((lXf*lYl*lZl)*lIn^[lBase]+1)
			   {y+1}+((lXl*lYf*lZl)*lIn^[lBase+lXi])
			   {z+1}+((lXl*lYl*lZf)*lIn^[lBase+lXYi24])
			   {x+1,y+1}+((lXf*lYf*lZl)*lIn^[lBase+1+lXi])
			   {x+1,z+1}+((lXf*lYl*lZf)*lIn^[lBase+1+lXYi24])
			   {y+1,z+1}+((lXl*lYf*lZf)*lIn^[lBase+lXi+lXYi24])
			   {x+1,y+1,z+1}+((lXf*lYf*lZf)*lIn^[lBase+1+lXi+lXYi24]) );
              //BLUE SLICE
              lBase := lBase+(lXi*lYi);
              //lBuffer^[lO+lXYo] :=lIn^[lBase];
              lBuffer^[lO+lXYo+lXYo] :=  round (
		 	   {all min} ( (lXl*lYl*lZl)*lIn^[lBase])
			   {x+1}+((lXf*lYl*lZl)*lIn^[lBase]+1)
			   {y+1}+((lXl*lYf*lZl)*lIn^[lBase+lXi])
			   {z+1}+((lXl*lYl*lZf)*lIn^[lBase+lXYi24])
			   {x+1,y+1}+((lXf*lYf*lZl)*lIn^[lBase+1+lXi])
			   {x+1,z+1}+((lXf*lYl*lZf)*lIn^[lBase+1+lXYi24])
			   {y+1,z+1}+((lXl*lYf*lZf)*lIn^[lBase+lXi+lXYi24])
			   {x+1,y+1,z+1}+((lXf*lYf*lZf)*lIn^[lBase+1+lXi+lXYi24]) );
          end; //lX
      end; //lY
  end; //Z
  Freemem(lIn);
end; //ShrinkLarge24
  *)
(*procedure ShrinkLarge32(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
var
   lBase,lO,lX,lY,lZ,lMax,lXYi,lXi,lYi,lZi,lZt,lYt,lXt,lOffset: int64;
   lScale,lZf, lYf,lXf,lXl,lYl,lZl : single;
   lIn,lOut: SingleP; //32
begin
  if lHdr.datatype <> kDT_FLOAT then //32
     exit;
  if (lHdr.dim[1] > lHdr.dim[2]) and  (lHdr.dim[1] > lHdr.dim[3]) then
     lMax := lHdr.dim[1]
  else if (lHdr.dim[2] > lHdr.dim[3])  then
       lMax := lHdr.dim[2]
  else
      lMax := lHdr.dim[3];
  if (lMax <= lMaxDim) or (lMax < 3) then begin
     {$IFDEF UNIX}
     writeln(format('Loading image at full size: maximum image dimension (%d) is less than "MaxVox" (%d). Edit "MaxVox" preference to downsample.',[lMax, lMaxDim]));
     {$ENDIF}
     exit; //not a large image or not a 3D image
  end;
  {$IFDEF UNIX}
  writeln(format('Downsampling image: maximum image dimension (%d) is greater than "MaxVox" (%d). Edit "MaxVox" preference to load at full resolution.',[lMax, lMaxDim]));
  {$ENDIF}
  lScale := lMaxDim/lMax;// from source to target: 256->128 = 0.5
  lXYi := lHdr.dim[1]*lHdr.dim[2]; //input XY
  lXi := lHdr.dim[1]; //input X
  lYi := lHdr.dim[2]; //input Y
  lZi := lHdr.dim[3]; //input Z
  lOffset := lXYi* lHdr.dim[3]*sizeof(single);//32 bytes
  Getmem(lIn,lOffset);
  lOut := SingleP(lBuffer);
  Move(lOut^,lIn^,lOffset);
  Zoom(lHdr,lScale);
  Freemem( lBuffer);
  GetMem( lBuffer,lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]*sizeof(single) ); //32
  lOut := SingleP(lBuffer);
  lScale := lMax/lMaxDim;// from target to source: 128->256 = 2.0
  lO := 0; //output voxel
  for lZ := 0 to (lHdr.dim[3]-1) do begin
      lZf := lZ * lScale;
      lZt := trunc(lZf);
      if lZt >= (lZi-1) then begin
         lZt := lZi-2;
         lZf := 1;
      end else
          lZf := lZf-lZt;//frac(lZf)
      lZl := 1-lZf;
      for lY := 0 to (lHdr.dim[2]-1) do begin
          lYf := lY * lScale;
          lYt := trunc(lYf);
          if lYt >= (lYi-1) then begin
             lYt := lYi-2;
             lYf := 1;
          end else
              lYf := lYf-lYt;
          lYl := 1 - lYf;
          lOffset := (lZt*lXYi)+ (lYt*lXi);
          for lX := 1 to lHdr.dim[1] do begin
              inc(lO);
              lXf := lX * lScale;
              lXt := trunc(lXf);
              if lXt >= lXi then begin
                 lXt := lXi-1;
                 lXf := 1;
              end else
                  lXf := lXf-lXt;
              lXl := 1-lXf;
              if lXt < 1 then
                 lXt := 1; //indexed from 1...
              lBase := lOffset + lXt;
              //lBuffer^[lO] :=  lIn^[lBase]; //<- nearest neighbor
              lOut^[lO] :=
                                         (
		 	   {all min} ( (lXl*lYl*lZl)*lIn^[lBase])
			   {x+1}+((lXf*lYl*lZl)*lIn^[lBase]+1)
			   {y+1}+((lXl*lYf*lZl)*lIn^[lBase+lXi])
			   {z+1}+((lXl*lYl*lZf)*lIn^[lBase+lXYi])
			   {x+1,y+1}+((lXf*lYf*lZl)*lIn^[lBase+1+lXi])
			   {x+1,z+1}+((lXf*lYl*lZf)*lIn^[lBase+1+lXYi])
			   {y+1,z+1}+((lXl*lYf*lZf)*lIn^[lBase+lXi+lXYi])
			   {x+1,y+1,z+1}+((lXf*lYf*lZf)*lIn^[lBase+1+lXi+lXYi]) );

          end; //lX

      end; //lY
  end; //Z
  Freemem(lIn);
end;  //ShrinkLarge32  *)

procedure ShrinkLarge(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
var
   imx: integer;
   xscale, fwidth: single;
   filter: TFilterProc;
begin
  imx := max(max(lHdr.dim[1], lHdr.dim[2]), lHdr.dim[3]);
  if (imx <= lMaxDim) or (lMaxDim < 1) then exit;
  xscale := lMaxDim/imx; //always less than 1!
  //filter := @BoxFilter; fwidth := 0.5;
  //filter := @TriangleFilter; fwidth := 1;
  //filter := @Hermite; fwidth := 1;
  //filter := @BellFilter; fwidth := 1.5;
  //filter := @SplineFilter; fwidth := 2;
  filter := @Lanczos3Filter; fwidth := 3;
  //filter := @MitchellFilter; fwidth := 2;
  if lHdr.datatype = kDT_UNSIGNED_CHAR then
     ShrinkLarge8(lHdr, lBuffer, xscale, fwidth, @filter)
  else if lHdr.datatype = kDT_SIGNED_SHORT then
     ShrinkLarge16(lHdr, lBuffer, xscale, fwidth, @filter)
  else if lHdr.datatype = kDT_FLOAT then
     ShrinkLarge32(lHdr, lBuffer, xscale, fwidth, @filter)
  else if lHdr.datatype = kDT_RGB then
     ShrinkLarge24(lHdr, lBuffer, xscale, fwidth, @filter);
end;

(*procedure ShrinkLarge(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
//fwidth: single; filter: TFilterProc);
begin
  //filter := @TriangleFilter; fwidth := 1;
  //filter := @Hermite; fwidth := 1;
  //filter := @BellFilter; fwidth := 1.5;
  //filter := @SplineFilter; fwidth := 2;
  //filter := @Lanczos3Filter; fwidth := 3;
  //filter := @MitchellFilter; fwidth := 2;
  if lHdr.datatype = kDT_UNSIGNED_CHAR then
     ShrinkLarge8(lHdr, lBuffer, lMaxDim, 2, @MitchellFilter)
  else if lHdr.datatype = kDT_SIGNED_SHORT then
     ShrinkLarge16(lHdr, lBuffer, lMaxDim, 2, @MitchellFilter)
  else if lHdr.datatype = kDT_FLOAT then
     ShrinkLarge32(lHdr, lBuffer, lMaxDim, 2, @MitchellFilter)
  else if lHdr.datatype = kDT_RGB then
     ShrinkLarge24(lHdr, lBuffer, lMaxDim, 2, @MitchellFilter);
end;*)

(*procedure showmat(lMat: TMatrix);
begin
 clipboard.AsText:= format('o=[%g %g %g %g; %g %g %g %g; %g %g %g %g; 0 0 0 1]',[
      lMat.matrix[1,1], lMat.matrix[1,2], lMat.matrix[1,3], lMat.matrix[1,4],
      lMat.matrix[2,1], lMat.matrix[2,2], lMat.matrix[2,3], lMat.matrix[2,4],
      lMat.matrix[3,1], lMat.matrix[3,2], lMat.matrix[3,3], lMat.matrix[3,4]
      ]);
end;  *)

function ReorientCore(var lHdr: TNIFTIhdr; lBufferIn: bytep): boolean;
var
   lOutHdr: TNIFTIhdr;
   lResidualMat: TMatrix;
   lInMinX,lInMinY,lInMinZ,lOutMinX,lOutMinY,lOutMinZ,
   dx, dy, dz: single;
   lStartX,
   lZ,lY,lX,lB,
   lOutZ,lOutY,
   lXInc, lYInc, lZInc,lBPP: int64;
   lInPos,lVolBytes,lOutPos: int64;
   lBufferOut: bytep;
   lFlipX,lFlipY,lFlipZ: boolean;
   lInMat,lRotMat: TMatrix;
begin
   result := false;
   if {(lHdr.dim[4] > 1) or} (lHdr.dim[3] < 2) then begin
      //Msg('Can only orient 3D images '+inttostr(lHdr.dim[3])+' '+inttostr(lHdr.dim[4]));
      exit;
   end;
   //Msg(lHdrName);
   //ShowHdr(lHdr);
   lInMat := Matrix3D (
    lHdr.srow_x[0],lHdr.srow_x[1],lHdr.srow_x[2],lHdr.srow_x[3],
    lHdr.srow_y[0],lHdr.srow_y[1],lHdr.srow_y[2],lHdr.srow_y[3],
    lHdr.srow_z[0],lHdr.srow_z[1],lHdr.srow_z[2],lHdr.srow_z[3]);
   //ShowMat(lInMat);
   if (NIfTIAlignedM (lInMat)) then begin
     //Msg('According to header, image is canonically oriented');
     exit;
   end;
   lRotMat := nifti_mat44_orthogx( lInMat);
   //ShowMat(lInMat);
   //ShowMat(lRotMat);
   if NIfTIAlignedM (lRotMat) then begin
     //Msg('According to header, image is already approximately canonically oriented');
     exit; //already as close as possible
   end;
   lOutHdr := lHdr;

   //Some software uses negative pixdims to represent a spatial flip - now that the image is canonical, all dimensions are positive
   lOutHdr.pixdim[1] := abs(lHdr.pixdim[1]);
   lOutHdr.pixdim[2] := abs(lHdr.pixdim[2]);
   lOutHdr.pixdim[3] := abs(lHdr.pixdim[3]);
   //sort out dim1
   lFlipX := false;
   if lRotMat.Matrix[1,2] <> 0 then begin
       lXinc := lHdr.dim[1];
       lOutHdr.dim[1] := lHdr.dim[2];
       lOutHdr.pixdim[1] := abs(lHdr.pixdim[2]);
       if lRotMat.Matrix[1,2] < 0 then lFlipX := true
   end else if lRotMat.Matrix[1,3] <> 0 then begin
       lXinc := lHdr.dim[1]*lHdr.dim[2];
       lOutHdr.dim[1] := lHdr.dim[3];
       lOutHdr.pixdim[1] := abs(lHdr.pixdim[3]);
       if lRotMat.Matrix[1,3] < 0 then lFlipX := true
   end else begin
       lXinc := 1;
       if lRotMat.Matrix[1,1] < 0 then lFlipX := true
   end;
   //sort out dim2
   lFlipY := false;
   if lRotMat.Matrix[2,2] <> 0 then begin
       lYinc := lHdr.dim[1];
       //lOutHdr.dim[2] := lHdr.dim[2];
       //lOutHdr.pixdim[2] := lHdr.pixdim[2];
       if lRotMat.Matrix[2,2] < 0 then lFlipY := true
   end else if lRotMat.Matrix[2,3] <> 0 then begin
       lYinc := lHdr.dim[1]*lHdr.dim[2];
       lOutHdr.dim[2] := lHdr.dim[3];
       lOutHdr.pixdim[2] := abs(lHdr.pixdim[3]);
       if lRotMat.Matrix[2,3] < 0 then lFlipY := true
   end else begin
       lYinc := 1;
       lOutHdr.dim[2] := lHdr.dim[1];
       lOutHdr.pixdim[2] := abs(lHdr.pixdim[1]);
       if lRotMat.Matrix[2,1] < 0 then lFlipY := true
   end;
   //sort out dim3
   lFlipZ := false;
   if lRotMat.Matrix[3,2] <> 0 then begin
       lZinc := lHdr.dim[1];
       lOutHdr.dim[3] := lHdr.dim[2];
       lOutHdr.pixdim[3] := lHdr.pixdim[2];
       if lRotMat.Matrix[3,2] < 0 then lFlipZ := true;
   end else if lRotMat.Matrix[3,3] <> 0 then begin
       lZinc := lHdr.dim[1]*lHdr.dim[2];
       //lOutHdr.dim[3] := lHdr.dim[3];
       //lOutHdr.pixdim[3] := lHdr.pixdim[3];
       if lRotMat.Matrix[3,3] < 0 then lFlipZ := true;
   end else begin
       lZinc := 1;
       lOutHdr.dim[3] := lHdr.dim[1];
       lOutHdr.pixdim[3] := lHdr.pixdim[1];
       if lRotMat.Matrix[3,1] < 0 then lFlipZ := true;
   end;
   //details for writing...
   lBPP := (lHdr.bitpix div 8); //bytes per pixel
   lXinc := lXinc * lBPP;
   lYinc := lYinc * lBPP;
   lZinc := lZinc * lBPP;
   lVolBytes := lHdr.dim[1]*lHdr.dim[2]*lHdr.dim[3]*lBPP;
   //now write header...
   //create Matrix of residual orientation...
  lResidualMat := invertMatrixF(lRotMat);
  //the next steps are inelegant - the translation values are computed by brute force
  //at the moment, our lResidualMat looks like this
  //lResidualMat  =  [ 0  -1  0  0; 0  0 1 0; 1  0 0  0; 0 0 0 1];
  //however, it should specify the dimensions in mm of the dimensions that are flipped
  //However, note that whenever you reverse the direction of
  //voxel coordinates, you need to include the appropriate offset
  //in the 'a' matrix.  That is:
  //lResidualMat = [0 0 1 0; -1 0 0 Nx-1; 0 1 0 0; 0 0 0 1]
  //where Nx is the number of voxels in the x direction.
  //So, if you took Nx=256, then for your values before, you'd get:
  //TransRot  =  [ 0  -1  0  255; 0  0 1 0; 1  0 0  0; 0 0 0 1];
  //Because we do not do this, we use the function mins to compute the translations...
  //I have not implemented refined version yet - require sample volumes to check
  //Ensure Nx is voxels not mm, etc....
  //start of kludge
  lResidualMat := multiplymatrices(lInMat,lResidualMat); //source
  lResidualMat.Matrix[1,4] := 0;
  lResidualMat.Matrix[2,4] := 0;
  lResidualMat.Matrix[3,4] := 0;
  Mins (lInMat, lHdr,lInMinX,lInMinY,lInMinZ);
  Mins (lResidualMat, lOutHdr,lOutMinX,lOutMinY,lOutMinZ);
  lResidualMat.Matrix[1,4] :=  lInMinX-lOutMinX;
  lResidualMat.Matrix[2,4]  := lInMinY-lOutMinY;
  lResidualMat.Matrix[3,4] := lInMinZ-lOutMinZ;
  //End of kuldge
  (*mx(lInMat);
  mx(lRotMat);
  mx(lResidualMat);*)
  lOutHdr.srow_x[0] := lResidualMat.Matrix[1,1];
  lOutHdr.srow_x[1] := lResidualMat.Matrix[1,2];
  lOutHdr.srow_x[2] := lResidualMat.Matrix[1,3];
  lOutHdr.srow_y[0] := lResidualMat.Matrix[2,1];
  lOutHdr.srow_y[1] := lResidualMat.Matrix[2,2];
  lOutHdr.srow_y[2] := lResidualMat.Matrix[2,3];
  lOutHdr.srow_z[0] := lResidualMat.Matrix[3,1];
  lOutHdr.srow_z[1] := lResidualMat.Matrix[3,2];
  lOutHdr.srow_z[2] := lResidualMat.Matrix[3,3];
  lOutHdr.srow_x[3] := lResidualMat.Matrix[1,4];
  lOutHdr.srow_y[3] := lResidualMat.Matrix[2,4];
  lOutHdr.srow_z[3] := lResidualMat.Matrix[3,4];
  nifti_mat44_to_quatern( lResidualMat,
   lOutHdr.quatern_b,lOutHdr.quatern_c,lOutHdr.quatern_d,
   lOutHdr.qoffset_x,lOutHdr.qoffset_y,lOutHdr.qoffset_z,
                             dx, dy, dz, lOutHdr.pixdim[0]); //qfac is stored in the otherwise unused pixdim[0]
   GetMem(lBufferOut,lVolBytes);
   lOutPos := 0;
   //convert
   if lFlipX then begin
      lStartX := (lOutHdr.dim[1]-1)*lXInc;
      lXInc := -lXInc;
   end else
       lStartX := 0;
   if lFlipY then begin
      lStartX := lStartX + (lOutHdr.dim[2]-1)*lYInc;
      lYInc := -lYInc;
   end;
   if lFlipZ then begin
      lStartX := lStartX + (lOutHdr.dim[3]-1)*lZInc;
      lZInc := -lZInc;
   end;
   for lZ := 1 to lOutHdr.dim[3] do begin
       lOutZ := lStartX + (lZ-1) * lZInc;
       for lY := 1 to lOutHdr.dim[2] do begin
           lOutY := ((lY-1) * lYInc) + lOutZ;
           for lX := 1 to lOutHdr.dim[1] do begin
               for lB := 1 to (lBPP) do begin
                   inc(lOutPos);
                   lInPos := ((lX-1) * lXInc) + lOutY + lB;
                   lBufferOut^[lOutPos] := lBufferIn^[lInPos];
               end;
           end;
       end; //for Y
   end; //for Z
   Move(lBufferOut^,lBufferIn^,lVolBytes);
   Freemem(lBufferOut);
   lHdr := lOutHdr;
end;//ReorientCore

end.

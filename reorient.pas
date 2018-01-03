unit reorient;
{$D-,O+,Q-,R-,S-}  //Delphi L- Y-
interface

uses
  SysUtils,define_types,nii_mat,nifti_hdr,dialogs, nifti_types, clipbrd;

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

procedure ShrinkLarge8(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
var
   lBase,lO,lX,lY,lZ,lMax,lXYi,lXi,lYi,lZi,lZt,lYt,lXt,lOffset: integer;
   lScale,lZf, lYf,lXf,lXl,lYl,lZl : single;
   lIn: bytep;
begin
  if (lHdr.dim[1] > lHdr.dim[2]) and  (lHdr.dim[1] > lHdr.dim[3]) then
     lMax := lHdr.dim[1]
  else if (lHdr.dim[2] > lHdr.dim[3])  then
       lMax := lHdr.dim[2]
  else
      lMax := lHdr.dim[3];
  if (lMax <= lMaxDim) or (lMax < 3) then
     exit; //not a large image or not a 3D image
  if lHdr.datatype <> kDT_UNSIGNED_CHAR then
     exit;
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
   lBase,lO,lX,lY,lZ,lMax,lXYi,lXi,lYi,lZi,lZt,lYt,lXt,lOffset: integer;
   lScale,lZf, lYf,lXf,lXl,lYl,lZl : single;
   lIn,lOut: SmallIntP; //16
begin
  if (lHdr.dim[1] > lHdr.dim[2]) and  (lHdr.dim[1] > lHdr.dim[3]) then
     lMax := lHdr.dim[1]
  else if (lHdr.dim[2] > lHdr.dim[3])  then
       lMax := lHdr.dim[2]
  else
      lMax := lHdr.dim[3];
  if (lMax <= lMaxDim) or (lMax < 3) then
     exit; //not a large image or not a 3D image
  if lHdr.datatype <> kDT_SIGNED_SHORT then //16
     exit;
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
end;  //ShrinkLarge16

procedure ShrinkLarge24(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
//WARNING: this code is for 24-bit RGB format, which is planar RRRRRRGGGGGBBBBB!!!!
var
   lBase,lO,lX,lY,lZ,lMax,lXYo,lXYi24,lXi,lYi,lZi,lZt,lYt,lXt,lOffset: integer;
   lScale,lZf, lYf,lXf,lXl,lYl,lZl : single;
   lIn: bytep;
begin
  if (lHdr.dim[1] > lHdr.dim[2]) and  (lHdr.dim[1] > lHdr.dim[3]) then
     lMax := lHdr.dim[1]
  else if (lHdr.dim[2] > lHdr.dim[3])  then
       lMax := lHdr.dim[2]
  else
      lMax := lHdr.dim[3];
  if (lMax <= lMaxDim) or (lMax < 3) then
     exit; //not a large image or not a 3D image
  if lHdr.datatype <> kDT_RGB then
     exit;
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

procedure ShrinkLarge32(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
var
   lBase,lO,lX,lY,lZ,lMax,lXYi,lXi,lYi,lZi,lZt,lYt,lXt,lOffset: integer;
   lScale,lZf, lYf,lXf,lXl,lYl,lZl : single;
   lIn,lOut: SingleP; //32
begin
  if (lHdr.dim[1] > lHdr.dim[2]) and  (lHdr.dim[1] > lHdr.dim[3]) then
     lMax := lHdr.dim[1]
  else if (lHdr.dim[2] > lHdr.dim[3])  then
       lMax := lHdr.dim[2]
  else
      lMax := lHdr.dim[3];
  if (lMax <= lMaxDim) or (lMax < 3) then
     exit; //not a large image or not a 3D image
  if lHdr.datatype <> kDT_FLOAT then //32
     exit;
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
end;  //ShrinkLarge32


procedure ShrinkLarge(var lHdr: TNIFTIhdr; var lBuffer: bytep; lMaxDim: integer);
//rescales images with any dimension larger than lMaxDim to have a maximum dimension of maxdim...
begin
  if lHdr.datatype = kDT_UNSIGNED_CHAR then
     ShrinkLarge8(lHdr, lBuffer, lMaxDim)
  else if lHdr.datatype = kDT_SIGNED_SHORT then
     ShrinkLarge16(lHdr, lBuffer, lMaxDim)
  else if lHdr.datatype = kDT_FLOAT then
     ShrinkLarge32(lHdr, lBuffer, lMaxDim)
  else if lHdr.datatype = kDT_RGB then
     ShrinkLarge24(lHdr, lBuffer, lMaxDim);
end;

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
   lXInc, lYInc, lZInc,lBPP: integer;
   lInPos,lVolBytes,lOutPos: integer;
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

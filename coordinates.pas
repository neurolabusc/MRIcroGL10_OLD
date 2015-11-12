unit coordinates;
{$D-,L-,O+,Q-,R-,Y-,S-}
interface
uses
  SysUtils,define_types,nii_mat,nifti_hdr,dialogs, nifti_types;

procedure Voxel2mm(var X,Y,Z: single; var lHdr: TNIfTIHdr);
procedure mm2Voxel (var X,Y,Z: single; var lInvMat: TMatrix);
function Hdr2Mat (lHdr:  TNIFTIhdr): TMatrix;
function Hdr2InvMat (lHdr: TNiftiHdr; var lOK: boolean): TMatrix;
implementation

function Hdr2InvMat (lHdr: TNiftiHdr; var lOK: boolean): TMatrix;
var
  lSrcMat: TMatrix;
begin
  lSrcMat := Hdr2Mat( lHdr);
  result := lSrcMat;
  invertMatrix(result);
  lOK :=  (result.matrix[4,4] <> 0);
end;

procedure  Coord(var lV: TVector; var lMat: TMatrix);
//transform X Y Z by matrix
var
  lXi,lYi,lZi: single;
begin
  lXi := lV.vector[1]; lYi := lV.vector[2]; lZi := lV.vector[3];
  lV.vector[1] := (lXi*lMat.matrix[1][1]+lYi*lMat.matrix[1][2]+lZi*lMat.matrix[1][3]+lMat.matrix[1][4]);
  lV.vector[2] := (lXi*lMat.matrix[2][1]+lYi*lMat.matrix[2][2]+lZi*lMat.matrix[2][3]+lMat.matrix[2][4]);
  lV.vector[3] := (lXi*lMat.matrix[3][1]+lYi*lMat.matrix[3][2]+lZi*lMat.matrix[3][3]+lMat.matrix[3][4]);
end;

procedure mm2Voxel (var X,Y,Z: single; var lInvMat: TMatrix);
//returns voxels indexed from 1 not 0!
var
   lV: TVector;
begin
     lV := Vector3D (X,Y,Z);
     Coord (lV,lInvMat);
     X := lV.vector[1]+1;
     Y := lV.vector[2]+1;
     Z := lV.vector[3]+1;
end;

function Hdr2Mat (lHdr:  TNIFTIhdr): TMatrix;
begin
  Result := Matrix3D (
  lHdr.srow_x[0],lHdr.srow_x[1],lHdr.srow_x[2],lHdr.srow_x[3],
  lHdr.srow_y[0],lHdr.srow_y[1],lHdr.srow_y[2],lHdr.srow_y[3],
  lHdr.srow_z[0],lHdr.srow_z[1],lHdr.srow_z[2],lHdr.srow_z[3]);
end;

procedure Voxel2mm(var X,Y,Z: single; var lHdr: TNIfTIHdr);
var
   lV: TVector;
   lMat: TMatrix;
begin
     //lV := Vector3D (X-1,Y-1,Z-1);
     lV := Vector3D (X-1,Y-1,Z-1);
     lMat := Hdr2Mat(lHdr);
     Coord(lV,lMat);
     X := lV.vector[1];
     Y := lV.vector[2];
     Z := lV.vector[3];
end;

end.
 

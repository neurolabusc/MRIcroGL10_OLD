unit nii_mat;
//basic Matrix and Vector Types and Transforms
interface

uses dialogs;

type
  TMatrix = record
      matrix: array [1..4, 1..4] of single;
  end;

  TVector = record
      vector: array [1..4] of single;
  end;

  function eye3D: TMatrix; //identity matrix
  procedure invertMatrix(VAR a: TMatrix);
  function invertMatrixF(VAR a: TMatrix): TMatrix;
  function matrix2D(a,b,c, d,e,f, g,h,i: single): TMatrix;
  function matrix3D(a,b,c,d, e,f,g,h, i,j,k,l: single): TMatrix;
  function multiplymatrices(a, b: TMatrix): TMatrix;
  function sameVec (a,b: TVector): boolean;
  function transform(v: TVector; m: TMatrix): TVector;
  procedure  transposeMatrix(var lMat: TMatrix);
  function vector3D  (x, y, z:  single):  TVector;

implementation

function eye3D: TMatrix; //identity matrix
begin
     result := Matrix3D(1,0,0,0,  0,1,0,0,  0,0,1,0);
end;

function invertMatrixF(VAR a: TMatrix): TMatrix;
//Translated by Chris Rorden, from C function "nifti_mat44_inverse"
// Authors: Bob Cox, revised by Mark Jenkinson and Rick Reynolds
// License: public domain
// http://niftilib.sourceforge.net
//Note : For higher performance we could assume the matrix is orthonormal and simply Transpose
//Note : We could also compute Gauss-Jordan here
var
	r11,r12,r13,r21,r22,r23,r31,r32,r33,v1,v2,v3 , deti : double;
begin
   r11 := a.matrix[1,1]; r12 := a.matrix[1,2]; r13 := a.matrix[1,3];  //* [ r11 r12 r13 v1 ] */
   r21 := a.matrix[2,1]; r22 := a.matrix[2,2]; r23 := a.matrix[2,3];  //* [ r21 r22 r23 v2 ] */
   r31 := a.matrix[3,1]; r32 := a.matrix[3,2]; r33 := a.matrix[3,3];  //* [ r31 r32 r33 v3 ] */
   v1  := a.matrix[1,4]; v2  := a.matrix[2,4]; v3  := a.matrix[3,4];  //* [  0   0   0   1 ] */
   deti := r11*r22*r33-r11*r32*r23-r21*r12*r33
		 +r21*r32*r13+r31*r12*r23-r31*r22*r13 ;
   if( deti <> 0.0 ) then
	deti := 1.0 / deti ;
   result.matrix[1,1] := deti*( r22*r33-r32*r23) ;
   result.matrix[1,2] := deti*(-r12*r33+r32*r13) ;
   result.matrix[1,3] := deti*( r12*r23-r22*r13) ;
   result.matrix[1,4] := deti*(-r12*r23*v3+r12*v2*r33+r22*r13*v3
                      -r22*v1*r33-r32*r13*v2+r32*v1*r23) ;
   result.matrix[2,1] := deti*(-r21*r33+r31*r23) ;
   result.matrix[2,2] := deti*( r11*r33-r31*r13) ;
   result.matrix[2,3] := deti*(-r11*r23+r21*r13) ;
   result.matrix[2,4] := deti*( r11*r23*v3-r11*v2*r33-r21*r13*v3
                      +r21*v1*r33+r31*r13*v2-r31*v1*r23) ;
   result.matrix[3,1] := deti*( r21*r32-r31*r22) ;
   result.matrix[3,2] := deti*(-r11*r32+r31*r12) ;
   result.matrix[3,3] := deti*( r11*r22-r21*r12) ;
   result.matrix[3,4] := deti*(-r11*r22*v3+r11*r32*v2+r21*r12*v3
                      -r21*r32*v1-r31*r12*v2+r31*r22*v1) ;
   result.matrix[4,1] := 0; result.matrix[4,2] := 0; result.matrix[4,3] := 0.0 ;
   if (deti = 0.0) then
        result.matrix[4,4] := 0
   else
       result.matrix[4,4] := 1;//  failure flag if deti == 0
end;

procedure invertMatrix(VAR a: TMatrix);
begin
  a :=  invertMatrixF(a);
end;

function matrix2D(a,b,c, d,e,f, g,h,i: single): TMatrix;
begin
     result := matrix3D(a,b,c,0.0, d,e,f,0.0, g,h,i,0.0 );
end; //matrix2D()

function matrix3D(a,b,c,d, e,f,g,h, i,j,k,l: single): TMatrix;
begin
     result.matrix[1,1] := a;
     result.matrix[1,2] := b;
     result.matrix[1,3] := c;
     result.matrix[1,4] := d;
     result.matrix[2,1] := e;
     result.matrix[2,2] := f;
     result.matrix[2,3] := g;
     result.matrix[2,4] := h;
     result.matrix[3,1] := i;
     result.matrix[3,2] := j;
     result.matrix[3,3] := k;
     result.matrix[3,4] := l;
     result.matrix[4,1] := 0.0;
     result.matrix[4,2] := 0.0;
     result.matrix[4,3] := 0.0;
     result.matrix[4,4] := 1.0;
end;  //matrix3D()

function multiplymatrices(a, b: TMatrix): TMatrix;
var i,j: integer;
begin
   result := Eye3D;
   for i := 1 to 4 do begin
       for j := 1 to 4 do begin
           result.matrix[i, j] := A.matrix[i, 1] * B.matrix[1,j]
           + A.matrix[i, 2] * B.matrix[2, j]
           + A.matrix[i, 3] * B.matrix[3, j]
           + A.matrix[i, 4] * B.matrix[4, j];
       end;  //for j
   end; //for i
end; //multiplymatrices()

function sameVec (a,b: TVector): boolean;
begin
   result := ( (a.vector[1]=b.vector[1]) and (a.vector[2]=b.vector[2]) and (a.vector[3]=b.vector[3]));
end; //sameVec()

function transform(v: TVector; m: TMatrix): TVector;
//vec4 nifti_vect44mat44_mul(vec4 v, mat44 m ) //multiply vector * 4x4matrix
var
   i, j: integer;
begin
    for i := 1 to 3 do begin//multiply Pcrs * m
        result.vector[i] := 0.0;
        for j := 1 to 4 do
            result.vector[i] := result.vector[i] + m.matrix[j,i]*v.vector[j];
    end;
    result.vector[4] := 1.0;
end; //transform()

procedure  transposeMatrix(var lMat: TMatrix);
var
  lTemp: TMatrix;
  i,j: integer;
begin
  lTemp := lMat;
  for i := 1 to 4 do
    for j := 1 to 4 do
      lMat.matrix[i,j] := lTemp.matrix[j,i];
end; //transposeMatrix()

function vector3D  (x, y, z:  single):  TVector;
begin
	result.vector[1] := x;
	result.vector[2] := y;
	result.vector[3] := z;
	result.vector[4] := 1.0;
end; //vector3D()

end. //unit nii_mat

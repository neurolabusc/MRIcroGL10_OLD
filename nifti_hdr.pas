unit nifti_hdr;
{$include opts.inc}
{$D-,O+,Q-,R-,S-}
interface
uses
{$H+}
{$Include isgui.inc}
{$IFNDEF FPC}
  gziod,
{$ELSE}
  gzio2,
{$ENDIF}
{$IFNDEF FPC} Windows, {$ENDIF}
{$IFDEF DGL} dglOpenGL, {$ELSE} gl,  {$ENDIF}
 nifti_types,
define_types,SysUtils,nii_mat,nifti_foreign, //GLMisc, //GLTexture, GLContext,
{$IFDEF GUI}dialogs;{$ELSE} dialogsx;{$ENDIF}
type
 TMRIcroHdr =  record //Next: analyze Format Header structure
   NIFTIhdr : TNIFTIhdr;
   AutoBalMinUnscaled,AutoBalMaxUnscaled
   ,WindowScaledMin,WindowScaledMax
   ,GlMinUnscaledS,GlMaxUnscaledS,Zero8Bit,Slope8bit: double; //brightness and contrast
   NIfTItransform,DiskDataNativeEndian,UsesCustomPalette,RGB,LutFromZero,LutVisible: boolean;
   HdrFileName,ImgFileName: string;
   gzBytes: Int64;
   //ClusterSize,
   LUTindex,ScrnBufferItems,ImgBufferItems,RenderBufferItems,ImgBufferBPP,RenderDim: longint;
   ImgBufferUnaligned: Pointer; //raw address of Image Buffer: address may not be aligned
   ScrnBuffer,ImgBuffer: Bytep;
   LUT: TLUT;
   Mat: TMatrix;
 end; //TNIFTIhdr Header Structure

function NIFTIvolumes (var lFilename: string): integer;
function FixDataType (var lHdr: TNIFTIhdr): boolean;  overload;
function FixDataType (var lHdr: TMRIcroHdr): boolean; overload;
 function ComputeImageDataBytes (var lHdr: TMRIcroHdr): longint; //size of image data in bytes
 function ComputeImageDataBytes8bpp (var lHdr: TMRIcroHdr): longint; //size of image as 32-bit per voxel data in bytes
 function ComputeImageDataBytes32bpp (var lHdr: TMRIcroHdr): longint; //size of image as 32-bit per voxel data in bytes
 procedure NIFTIhdr_SwapBytes (var lAHdr: TNIFTIhdr); //Swap Byte order for the Analyze type
 //procedure NIFTIhdr_ClearHdr (var lHdr: TNIfTIHdr); overload; //set all values of header to something reasonable
 procedure NIFTIhdr_ClearHdr (var lHdr: TMRIcroHdr); overload;//set all values of header to something reasonable
 function NIFTIhdr_LoadHdr (var lFilename: string; var lHdr: TMRIcroHdr): boolean;
 function NIFTIhdr_SaveHdr (var lFilename: string; var lHdr: TMRIcroHdr; lAllowOverwrite: boolean): boolean; overload;
 function NIFTIhdr_SaveHdr (var lFilename: string; var lHdr: TNIFTIHdr; lAllowOverwrite,lSPM2: boolean): boolean; overload;
 //procedure NIFTIhdr_SetIdentityMatrix (var lHdr: TMRIcroHdr); //create neutral rotation matrix
 function CopyNiftiHdr (var lInHdr,lOutHdr: TNIFTIhdr): boolean;
 function IsNIfTIHdrExt (var lFName: string):boolean; //1494
 function IsNifTiMagic (var lHdr: TNIFTIhdr): boolean;
 procedure WriteNiftiMatrix (var lHdr: TNIFTIhdr;
	m11,m12,m13,m14,
	m21,m22,m23,m24,
	m31,m32,m33,m34:  Single);
function niftiflip (var lHdr: TMRIcrohdr): boolean;
procedure nifti_mat44_to_quatern( lR :TMatrix;
                             var qb, qc, qd,
                             qx, qy, qz,
                             dx, dy, dz, qfac : single);
function IsVOIROIExt (var lFName: string):boolean;

implementation

uses mainunit;

function NIFTIvolumes (var lFilename: string): integer;
var lHdr: TMRIcroHdr;
begin
  result := -1;
    if not NIFTIhdr_LoadHdr (lFilename, lHdr) then
      exit;
  result := lHdr.NIFTIhdr.dim[4];
  if (result < 1) then result := 1;
end;

function NIFTIhdr_SaveHdr (var lFilename: string; var lHdr: TNIFTIHdr; lAllowOverwrite,lSPM2: boolean): boolean; overload;
var lOutHdr: TNIFTIhdr;
	lExt: string;
    lF: File;
    lOverwrite: boolean;
begin
     lOverwrite := false; //will we overwrite existing file?
     result := false; //assume failure
	 if lHdr.magic = kNIFTI_MAGIC_EMBEDDED_HDR then begin
		 lExt := UpCaseExt(lFileName);
		 if (lExt = '.GZ') or (lExt = '.NII.GZ') then begin
			showmessage('Unable to save .nii.gz headers (first ungzip your image if you wish to edit the header)');
			exit;
		 end;
		 lFilename := changefileext(lFilename,'.nii')
	 end else
         lFilename := changefileext(lFilename,'.hdr');
     if ((sizeof(TNIFTIhdr))> DiskFreeEx(lFileName)) then begin
        ShowMessage('There is not enough free space on the destination disk to save the header. '+kCR+
        lFileName+ kCR+' Bytes Required: '+inttostr(sizeof(TNIFTIhdr)) );
        exit;
     end;
     if Fileexists(lFileName) then begin
         if lAllowOverwrite then begin
            case MessageDlg('Do you wish to modify the existing file '+lFilename+'?', mtConfirmation,[mbYes, mbNo], 0) of	{ produce the message dialog box }
             6: lOverwrite := true; //6= mrYes, 7=mrNo... not sure what this is for Linux. Hardcoded as we do not include Form values
        end;//case
         end else
             showmessage('Error: the file '+lFileName+' already exists.');
         if not lOverwrite then Exit;
	 end;
	 if lHdr.magic = kNIFTI_MAGIC_EMBEDDED_HDR then
		if lHdr.vox_offset < sizeof(TNIFTIHdr) then
		   lHdr.vox_offset := sizeof(TNIFTIHdr); //embedded images MUST start after header
	 if lHdr.magic = kNIFTI_MAGIC_SEPARATE_HDR then
		   lHdr.vox_offset := 0; //embedded images MUST start after header

                if lSPM2 then begin //SPM2 does not recognize NIfTI - origin values will be wrong
                   lHdr.magic := 0;
                end;
     result := true;
     move(lHdr, lOutHdr, sizeof(lOutHdr));
     Filemode := 1;
     AssignFile(lF, lFileName); {WIN}
     if lOverwrite then //this allows us to modify just the 348byte header of an existing NII header without touching image data
         Reset(lF,sizeof(TNIFTIhdr))
     else
         Rewrite(lF,sizeof(TNIFTIhdr));
     BlockWrite(lF,lOutHdr, 1  {, NumWritten});
     CloseFile(lF);
     Filemode := 2;
end; //func NIFTIhdr_SaveHdr

function CopyNiftiHdr (var lInHdr,lOutHdr: TNIFTIhdr): boolean;
begin
     move(lInHdr,lOutHdr,sizeof(TNIFTIhdr));
    result := true;
end;

function IsVOIROIExt (var lFName: string):boolean;
var
	lExt: string;
begin
	lExt := UpCaseExt(lFName);
	if (lExt = '.VOI') or (lExt = '.ROI') then
		result := true
	else
		result := false;
end;

procedure WriteNiftiMatrix (var lHdr: TNIFTIhdr;
	m11,m12,m13,m14,
	m21,m22,m23,m24,
	m31,m32,m33,m34:  Single);
begin
 with lHdr do begin
	srow_x[0] := m11;
	srow_x[1] := m12;
	srow_x[2] := m13;
	srow_x[3] := m14;
	srow_y[0] := m21;
	srow_y[1] := m22;
	srow_y[2] := m23;
	srow_y[3] := m24;
	srow_z[0] := m31;
	srow_z[1] := m32;
	srow_z[2] := m33;
	srow_z[3] := m34;
 end; //with lHdr
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

procedure WriteNiftiMatrix2 (var lHdr: TNIFTIhdr;
	M: TMatrix);
begin
 with lHdr do begin
	srow_x[0] := M.Matrix[1,1];
	srow_x[1] := M.Matrix[1,2];
	srow_x[2] := M.Matrix[1,3];
	srow_x[3] := M.Matrix[1,4];
	srow_y[0] := M.Matrix[2,1];
	srow_y[1] := M.Matrix[2,2];
	srow_y[2] := M.Matrix[2,3];
	srow_y[3] := M.Matrix[2,4];
	srow_z[0] := M.Matrix[3,1];
	srow_z[1] := M.Matrix[3,2];
	srow_z[2] := M.Matrix[3,3];
	srow_z[3] := M.Matrix[3,4];
 end; //with lHdr
end;

function niftiflip (var lHdr: TMRIcrohdr): boolean;
var
  lR,lF,lO: TMatrix;
begin
  result := false;
  if (lHdr.NIFTIhdr.srow_x[0]+lHdr.NIFTIhdr.srow_y[0]+lHdr.NIFTIhdr.srow_z[0]) > 0 then
    exit;
  result := true;
  lR := Matrix3D (
  lHdr.NIFTIhdr.srow_x[0],lHdr.NIFTIhdr.srow_x[1],lHdr.NIFTIhdr.srow_x[2],lHdr.NIFTIhdr.srow_x[3],
  lHdr.NIFTIhdr.srow_y[0],lHdr.NIFTIhdr.srow_y[1],lHdr.NIFTIhdr.srow_y[2],lHdr.NIFTIhdr.srow_y[3],
  lHdr.NIFTIhdr.srow_z[0],lHdr.NIFTIhdr.srow_z[1],lHdr.NIFTIhdr.srow_z[2],lHdr.NIFTIhdr.srow_z[3]);
  lF := Matrix3D (-1,0,0,0,  0,1,0,0,  0,0,1,0 );
  lO := MultiplyMatrices(lR,lF);
  WriteNiftiMatrix2(lHdr.NIFTIhdr,lO);
end;

function IsNifTiMagic (var lHdr: TNIFTIhdr): boolean;
begin
	if (lHdr.magic =kNIFTI_MAGIC_SEPARATE_HDR) or (lHdr.Magic = kNIFTI_MAGIC_EMBEDDED_HDR ) then
		result := true
	else
		result :=false; //analyze
end;

function IsNIfTIHdrExt (var lFName: string):boolean;
var
	lExt: string;
begin
	lExt := UpCaseExt(lFName);
	if (lExt='.NII') or (lExt = '.HDR') or (lExt = '.NII.GZ') or (lExt = '.VOI') then
		result := true
	else
		result := false;
end;

function ComputeImageDataBytes32bpp (var lHdr: TMRIcroHdr): integer;
var
   lDim, lBytes : integer;
begin
     //result := 0;
     with lHdr.NIFTIhdr do begin
          if Dim[0] < 1 then begin
             showmessage('NIFTI format error: datasets must have at least one dimension (dim[0] < 1).');
             Dim[0] := 3;
             //exit;
          end;
          lBytes := 4; //bits per voxel
          for lDim := 1 to 3 {Dim[0]}  do
              lBytes := lBytes * Dim[lDim];
     end; //with niftihdr
     result := lBytes; //+7 to ensure binary data not clipped
end; //func ComputeImageDataBytes32bpp

function ComputeImageDataBytes8bpp (var lHdr: TMRIcroHdr): integer;
var
   lDim, lBytes : integer;
begin
     result := 0;
     with lHdr.NIFTIhdr do begin
          if Dim[0] < 1 then begin
             showmessage('NIFTI format error: datasets must have at least one dimension (dim[0] < 1).');
             exit;
          end;
          lBytes := 1; //bits per voxel
		  for lDim := 1 to 3 {Dim[0]}  do
              lBytes := lBytes * Dim[lDim];
     end; //with niftihdr
     result := lBytes;
end; //func ComputeImageDataBytes8bpp

function ComputeImageDataBytes (var lHdr: TMRIcroHdr): integer;
var
   lDim : integer;
   lSzInBits : Int64;
begin
     result := 0;
     with lHdr.NIFTIhdr do begin
          if Dim[0] < 1 then begin
             showmessage('NIFTI format error: datasets must have at least one dimension (dim[0] < 1).');
             exit;
          end;
		  lSzInBits := bitpix; //bits per voxel
		  //showmessage(inttostr(Dim[0]));
		  for lDim := 1 to 3 {Dim[0]} do
			  lSzInBits := lSzInBits * Dim[lDim];
	 end; //with niftihdr
	 result := (lSzInBits + 7) div 8; //+7 to ensure binary data not clipped
end; //func ComputeImageDataBytes

function orthogonalMatrix(var lHdr: TMRIcroHdr): boolean;
var
 lM: TMatrix;
 lRow,lCol,lN0: integer;
begin
  result := false;
  lM := Matrix3D (
  lHdr.NIFTIhdr.srow_x[0],lHdr.NIFTIhdr.srow_x[1],lHdr.NIFTIhdr.srow_x[2],lHdr.NIFTIhdr.srow_x[3],
  lHdr.NIFTIhdr.srow_y[0],lHdr.NIFTIhdr.srow_y[1],lHdr.NIFTIhdr.srow_y[2],lHdr.NIFTIhdr.srow_y[3],
  lHdr.NIFTIhdr.srow_z[0],lHdr.NIFTIhdr.srow_z[1],lHdr.NIFTIhdr.srow_z[2],lHdr.NIFTIhdr.srow_z[3]);
  for lRow := 1 to 3 do begin
	  lN0 := 0;
	  for lCol := 1 to 3 do
		if lM.matrix[lRow,lCol] = 0 then
			inc(lN0);
	  if lN0 <> 2 then exit; //exactly two values are zero
  end;
  for lCol := 1 to 3 do begin
	  lN0 := 0;
	  for lRow := 1 to 3 do
		if lM.matrix[lRow,lCol] = 0 then
			inc(lN0);
	  if lN0 <> 2 then exit; //exactly two values are zero
  end;
  result := true;
end;

function EmptyMatrix(var lHdr: TMRIcroHdr): boolean;
var
 lM: TMatrix;
 lRow,lCol: integer;
begin
  result := false;
  lM := Matrix3D (
  lHdr.NIFTIhdr.srow_x[0],lHdr.NIFTIhdr.srow_x[1],lHdr.NIFTIhdr.srow_x[2],lHdr.NIFTIhdr.srow_x[3],
  lHdr.NIFTIhdr.srow_y[0],lHdr.NIFTIhdr.srow_y[1],lHdr.NIFTIhdr.srow_y[2],lHdr.NIFTIhdr.srow_y[3],
  lHdr.NIFTIhdr.srow_z[0],lHdr.NIFTIhdr.srow_z[1],lHdr.NIFTIhdr.srow_z[2],lHdr.NIFTIhdr.srow_z[3]);
  for lRow := 1 to 3 do begin {3/2008}
	  for lCol := 1 to 4 do begin
              if (lRow = lCol) then begin
		if lM.matrix[lRow,lCol] <> 1 then
			exit;
              end else begin
		if lM.matrix[lRow,lCol] <> 0 then
			exit;
              end// unity matrix does not count - mriconvert creates bogus [1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 0]
          end; //each col
  end;//each row
(*  for lRow := 1 to 3 do
	  for lCol := 1 to 4 do
		if lM.matrix[lRow,lCol] <> 0 then
  			exit;*)
  result := true;
end;

procedure nifti_quatern_to_mat44( var lR :TMatrix;
                             var qb, qc, qd,
                             qx, qy, qz,
                             dx, dy, dz, qfac : single);
var
   a,b,c,d,xd,yd,zd: double;
begin
   //a := qb;
   b := qb;
   c := qc;
   d := qd;
   //* last row is always [ 0 0 0 1 ] */
   lR.matrix[4,1] := 0;
   lR.matrix[4,2] := 0;
   lR.matrix[4,3] := 0;
   lR.matrix[4,4] := 1;
   //* compute a parameter from b,c,d */
   a := 1.0 - (b*b + c*c + d*d) ;
   if( a < 1.e-7 ) then begin//* special case */
     a := 1.0 / sqrt(b*b+c*c+d*d) ;
     b := b*a ; c := c*a ; d := d*a ;//* normalize (b,c,d) vector */
     a := 0.0 ;//* a = 0 ==> 180 degree rotation */
   end else begin
     a := sqrt(a) ; //* angle = 2*arccos(a) */
   end;
   //* load rotation matrix, including scaling factors for voxel sizes */
   if dx > 0 then
      xd := dx
   else
       xd := 1;
   if dy > 0 then
      yd := dy
   else
       yd := 1;
   if dz > 0 then
      zd := dz
   else
       zd := 1;
   if( qfac < 0.0 ) then zd := -zd ;//* left handedness? */
   lR.matrix[1,1]:=        (a*a+b*b-c*c-d*d) * xd ;
   lR.matrix[1,2]:= 2.0 * (b*c-a*d        ) * yd ;
   lR.matrix[1,3]:= 2.0 * (b*d+a*c        ) * zd ;
   lR.matrix[2,1]:=  2.0 * (b*c+a*d        ) * xd ;
   lR.matrix[2,2]:=        (a*a+c*c-b*b-d*d) * yd ;
   lR.matrix[2,3]:=  2.0 * (c*d-a*b        ) * zd ;
   lR.matrix[3,1]:= 2.0 * (b*d-a*c        ) * xd ;
   lR.matrix[3,2]:=  2.0 * (c*d+a*b        ) * yd ;
   lR.matrix[3,3]:=         (a*a+d*d-c*c-b*b) * zd ;
   //* load offsets */
   lR.matrix[1,4]:= qx ;
   lR.matrix[2,4]:= qy ;
   lR.matrix[3,4]:= qz ;
end;

function HasQuat( var lHdr: TNIfTIHdr ): boolean;
//var lR :TMatrix;
begin
    result := false;
    if (lHdr.qform_code <= kNIFTI_XFORM_UNKNOWN) or (lHdr.qform_code > kNIFTI_XFORM_MNI_152) then
       exit;
    result := true;
end;

function Quat2Mat( var lHdr: TNIfTIHdr ): boolean;
var lR :TMatrix;
begin
    result := false;
    if (lHdr.qform_code <= kNIFTI_XFORM_UNKNOWN) or (lHdr.qform_code > kNIFTI_XFORM_MNI_152) then
       exit;
    result := true;
    nifti_quatern_to_mat44(lR,lHdr.quatern_b,lHdr.quatern_c,lHdr.quatern_d,
   lHdr.qoffset_x,lHdr.qoffset_y,lHdr.qoffset_z,
   lHdr.pixdim[1],lHdr.pixdim[2],lHdr.pixdim[3],
   lHdr.pixdim[0]);
   lHdr.srow_x[0] := lR.matrix[1,1];
   lHdr.srow_x[1] := lR.matrix[1,2];
   lHdr.srow_x[2] := lR.matrix[1,3];
   lHdr.srow_x[3] := lR.matrix[1,4];
   lHdr.srow_y[0] := lR.matrix[2,1];
   lHdr.srow_y[1] := lR.matrix[2,2];
   lHdr.srow_y[2] := lR.matrix[2,3];
   lHdr.srow_y[3] := lR.matrix[2,4];
   lHdr.srow_z[0] := lR.matrix[3,1];
   lHdr.srow_z[1] := lR.matrix[3,2];
   lHdr.srow_z[2] := lR.matrix[3,3];
   lHdr.srow_z[3] := lR.matrix[3,4];
		lHdr.sform_code := 1;   
end;


function nifti_mat33_determ( R: TMatrix ):double;   //* determinant of 3x3 matrix */
begin
   result := r.matrix[1,1]*r.matrix[2,2]*r.matrix[3,3]
          -r.matrix[1,1]*r.matrix[3,2]*r.matrix[2,3]
          -r.matrix[2,1]*r.matrix[1,2]*r.matrix[3,3]
         +r.matrix[2,1]*r.matrix[3,2]*r.matrix[1,3]
         +r.matrix[3,1]*r.matrix[1,2]*r.matrix[2,3]
         -r.matrix[3,1]*r.matrix[2,2]*r.matrix[1,3] ;
end;

function nifti_mat33_rownorm( A: TMatrix ): single;  //* max row norm of 3x3 matrix */
var
   r1,r2,r3: single ;
begin
   r1 := abs(A.matrix[1,1])+abs(A.matrix[1,2])+abs(A.matrix[1,3]) ;
   r2 := abs(A.matrix[2,1])+abs(A.matrix[2,2])+abs(A.matrix[2,3]) ;
   r3 := abs(A.matrix[3,1])+abs(A.matrix[3,2])+abs(A.matrix[3,3]) ;
   if( r1 < r2 ) then r1 := r2 ;
   if( r1 < r3 ) then r1 := r3 ;
   result := r1 ;
end;

function nifti_mat33_colnorm( A: TMatrix ): single;  //* max column norm of 3x3 matrix */
var
   r1,r2,r3: single ;
begin
   r1 := abs(A.matrix[1,1])+abs(A.matrix[2,1])+abs(A.matrix[3,1]) ;
   r2 := abs(A.matrix[1,2])+abs(A.matrix[2,2])+abs(A.matrix[3,2]) ;
   r3 := abs(A.matrix[1,3])+abs(A.matrix[2,3])+abs(A.matrix[3,3]) ;
   if( r1 < r2 ) then r1 := r2 ;
   if( r1 < r3 ) then r1 := r3 ;
   result := r1 ;
end;

function nifti_mat33_inverse( R: TMatrix ): TMatrix;   //* inverse of 3x3 matrix */
var
   r11,r12,r13,r21,r22,r23,r31,r32,r33 , deti: double ;
   Q: TMatrix ;
begin
   FromMatrix(R,r11,r12,r13,r21,r22,r23,r31,r32,r33);
   deti := r11*r22*r33-r11*r32*r23-r21*r12*r33
         +r21*r32*r13+r31*r12*r23-r31*r22*r13 ;

   if( deti <> 0.0 ) then deti := 1.0 / deti ;

   Q.matrix[1,1] := deti*( r22*r33-r32*r23) ;
   Q.matrix[1,2] := deti*(-r12*r33+r32*r13) ;
   Q.matrix[1,3] := deti*( r12*r23-r22*r13) ;

   Q.matrix[2,1] := deti*(-r21*r33+r31*r23) ;
   Q.matrix[2,2] := deti*( r11*r33-r31*r13) ;
   Q.matrix[2,3] := deti*(-r11*r23+r21*r13) ;

   Q.matrix[3,1] := deti*( r21*r32-r31*r22) ;
   Q.matrix[3,2] := deti*(-r11*r32+r31*r12) ;
   Q.matrix[3,3] := deti*( r11*r22-r21*r12) ;
   result := Q;
end;

function nifti_mat33_polar( A: TMatrix ): TMatrix;
var
    dif: single;
   k: integer;
   X , Y , Z: TMatrix ;
   alp,bet,gam,gmi : single;
begin
    dif:=1.0 ;
   k:=0 ;
   X := A ;
   // force matrix to be nonsingular
   //reportmatrix('x',X);
   gam := nifti_mat33_determ(X) ;
   while( gam = 0.0 )do begin        //perturb matrix
     gam := 0.00001 * ( 0.001 + nifti_mat33_rownorm(X) ) ;
     X.matrix[1,1] := X.matrix[1,1]+gam ;
     X.matrix[2,2] := X.matrix[2,2]+gam ;
     X.matrix[3,3] := X.matrix[3,3] +gam ;
     gam := nifti_mat33_determ(X) ;
   end;
   while true do begin
     Y := nifti_mat33_inverse(X) ;
     if( dif > 0.3 )then begin     // far from convergence
       alp := sqrt( nifti_mat33_rownorm(X) * nifti_mat33_colnorm(X) ) ;
       bet := sqrt( nifti_mat33_rownorm(Y) * nifti_mat33_colnorm(Y) ) ;
       gam := sqrt( bet / alp ) ;
       gmi := 1.0 / gam ;
     end else begin
       gam := 1.0;
       gmi := 1.0 ;  //close to convergence
     end;
     Z.matrix[1,1] := 0.5 * ( gam*X.matrix[1,1] + gmi*Y.matrix[1,1] ) ;
     Z.matrix[1,2] := 0.5 * ( gam*X.matrix[1,2] + gmi*Y.matrix[2,1] ) ;
     Z.matrix[1,3] := 0.5 * ( gam*X.matrix[1,3] + gmi*Y.matrix[3,1] ) ;
     Z.matrix[2,1] := 0.5 * ( gam*X.matrix[2,1] + gmi*Y.matrix[1,2] ) ;
     Z.matrix[2,2] := 0.5 * ( gam*X.matrix[2,2] + gmi*Y.matrix[2,2] ) ;
     Z.matrix[2,3] := 0.5 * ( gam*X.matrix[2,3] + gmi*Y.matrix[3,2] ) ;
     Z.matrix[3,1] := 0.5 * ( gam*X.matrix[3,1] + gmi*Y.matrix[1,3] ) ;
     Z.matrix[3,2] := 0.5 * ( gam*X.matrix[3,2] + gmi*Y.matrix[2,3] ) ;
     Z.matrix[3,3] := 0.5 * ( gam*X.matrix[3,3] + gmi*Y.matrix[3,3] ) ;
     dif := abs(Z.matrix[1,1]-X.matrix[1,1])+abs(Z.matrix[1,2]-X.matrix[1,2])
          +abs(Z.matrix[1,3]-X.matrix[1,3])+abs(Z.matrix[2,1]-X.matrix[2,1])
          +abs(Z.matrix[2,2]-X.matrix[2,2])+abs(Z.matrix[2,3]-X.matrix[2,3])
          +abs(Z.matrix[3,1]-X.matrix[3,1])+abs(Z.matrix[3,2]-X.matrix[3,2])
          +abs(Z.matrix[3,3]-X.matrix[3,3])                          ;
     k := k+1 ;
     if( k > 100) or (dif < 3.e-6 ) then begin
         result := Z;
         break ; //convergence or exhaustion
     end;
     X := Z ;
   end;
   result := Z ;
end;

procedure nifti_mat44_to_quatern( lR :TMatrix;
                             var qb, qc, qd,
                             qx, qy, qz,
                             dx, dy, dz, qfac : single);
var
   r11,r12,r13 , r21,r22,r23 , r31,r32,r33, xd,yd,zd , a,b,c,d : double;
   P,Q: TMatrix;  //3x3
begin
   (* offset outputs are read write out of input matrix  *)
   qx := lR.matrix[1,4];
   qy := lR.matrix[2,4];
   qz := lR.matrix[3,4];
   (* load 3x3 matrix into local variables *)
   FromMatrix(lR,r11,r12,r13,r21,r22,r23,r31,r32,r33);
   (* compute lengths of each column; these determine grid spacings  *)
   xd := sqrt( r11*r11 + r21*r21 + r31*r31 ) ;
   yd := sqrt( r12*r12 + r22*r22 + r32*r32 ) ;
   zd := sqrt( r13*r13 + r23*r23 + r33*r33 ) ;
   (* if a column length is zero, patch the trouble *)
   if( xd = 0.0 )then begin r11 := 1.0 ; r21 := 0; r31 := 0.0 ; xd := 1.0 ; end;
   if( yd = 0.0 )then begin r22 := 1.0 ; r12 := 0; r32 := 0.0 ; yd := 1.0 ; end;
   if( zd = 0.0 )then begin r33 := 1.0 ; r13 := 0; r23 := 0.0 ; zd := 1.0 ; end;
   (* assign the output lengths *)
   dx := xd;
   dy := yd;
   dz := zd;
   (* normalize the columns *)
   r11 := r11/xd ; r21 := r21/xd ; r31 := r31/xd ;
   r12 := r12/yd ; r22 := r22/yd ; r32 := r32/yd ;
   r13 := r13/zd ; r23 := r23/zd ; r33 := r33/zd ;
   (* At this point, the matrix has normal columns, but we have to allow
      for the fact that the hideous user may not have given us a matrix
      with orthogonal columns.
      So, now find the orthogonal matrix closest to the current matrix.
      One reason for using the polar decomposition to get this
      orthogonal matrix, rather than just directly orthogonalizing
      the columns, is so that inputting the inverse matrix to R
      will result in the inverse orthogonal matrix at this point.
      If we just orthogonalized the columns, this wouldn't necessarily hold. *)
   Q :=  Matrix2D (r11,r12,r13,          // 2D "graphics" matrix
                           r21,r22,r23,
                           r31,r32,r33);
   P := nifti_mat33_polar(Q) ;  (* P is orthog matrix closest to Q *)
   FromMatrix(P,r11,r12,r13,r21,r22,r23,r31,r32,r33);
   (*                            [ r11 r12 r13 ]               *)
   (* at this point, the matrix  [ r21 r22 r23 ] is orthogonal *)
   (*                            [ r31 r32 r33 ]               *)
   (* compute the determinant to determine if it is proper *)
   zd := r11*r22*r33-r11*r32*r23-r21*r12*r33
       +r21*r32*r13+r31*r12*r23-r31*r22*r13 ;  (* should be -1 or 1 *)
   if( zd > 0 )then begin             (* proper *)
     qfac  := 1.0 ;
   end else begin                  (* improper ==> flip 3rd column *)
     qfac := -1.0 ;
     r13 := -r13 ; r23 := -r23 ; r33 := -r33 ;
   end;
   (* now, compute quaternion parameters *)
   a := r11 + r22 + r33 + 1.0;
   if( a > 0.5 ) then begin                (* simplest case *)
     a := 0.5 * sqrt(a) ;
     b := 0.25 * (r32-r23) / a ;
     c := 0.25 * (r13-r31) / a ;
     d := 0.25 * (r21-r12) / a ;
   end else begin                       (* trickier case *)
     xd := 1.0 + r11 - (r22+r33) ;  (* 4*b*b *)
     yd := 1.0 + r22 - (r11+r33) ;  (* 4*c*c *)
     zd := 1.0 + r33 - (r11+r22) ;  (* 4*d*d *)
     if( xd > 1.0 ) then begin
       b := 0.5 * sqrt(xd) ;
       c := 0.25* (r12+r21) / b ;
       d := 0.25* (r13+r31) / b ;
       a := 0.25* (r32-r23) / b ;
     end else if( yd > 1.0 ) then begin
       c := 0.5 * sqrt(yd) ;
       b := 0.25* (r12+r21) / c ;
       d := 0.25* (r23+r32) / c ;
       a := 0.25* (r13-r31) / c ;
     end else begin
       d := 0.5 * sqrt(zd) ;
       b := 0.25* (r13+r31) / d ;
       c := 0.25* (r23+r32) / d ;
       a := 0.25* (r21-r12) / d ;
     end;
     if( a < 0.0 )then begin b:=-b ; c:=-c ; d:=-d; {a:=-a; not used} end;
   end;

   qb := b ;
   qc := c ;
   qd := d ;
end;

procedure FixCrapMat(var lMat: TMatrix);
var
 lVec000,lVec100,lVec010,lVec001: TVector;
begin
 lVec000 := Vec3D  (0, 0, 0);
 lVec100 := Vec3D  (1, 0, 0);
 lVec010 := Vec3D  (0, 1, 0);
 lVec001 := Vec3D  (0, 0, 1);
 lVec000 := Transform3D (lVec000, lMat);
 lVec100 := Transform3D (lVec100, lMat);
 lVec010 := Transform3D (lVec010, lMat);
 lVec001 := Transform3D (lVec001, lMat);
 if SameVec(lVec000,lVec100) or
    SameVec(lVec000,lVec010) or
    SameVec(lVec000,lVec001) then begin
    lMat := eye3D;
    showmessage('Warning: the transformation matrix is corrupt [some dimensions have zero size]');
 end;
end;

function FixDataType (var lHdr: TNIFTIhdr): boolean;  overload;
label
  191;
var
  ldatatypebpp,lbitpix: integer;
begin
  result := true;
  lbitpix := lHdr.bitpix;
  case lHdr.datatype of
    kDT_BINARY : ldatatypebpp := 1;
    kDT_UNSIGNED_CHAR  : ldatatypebpp := 8;     // unsigned char (8 bits/voxel)
    kDT_SIGNED_SHORT  : ldatatypebpp := 16;      // signed short (16 bits/voxel)
    kDT_SIGNED_INT : ldatatypebpp := 32;      // signed int (32 bits/voxel)
    kDT_FLOAT : ldatatypebpp := 32;      // float (32 bits/voxel)
    kDT_COMPLEX : ldatatypebpp := 64;      // complex (64 bits/voxel)
    kDT_DOUBLE  : ldatatypebpp := 64;      // double (64 bits/voxel)
    kDT_RGB : ldatatypebpp := 24;      // RGB triple (24 bits/voxel)
    kDT_INT8 : ldatatypebpp := 8;     // signed char (8 bits)
    kDT_UINT16 : ldatatypebpp := 16;      // unsigned short (16 bits)
    kDT_UINT32 : ldatatypebpp := 32;     // unsigned int (32 bits)
    kDT_INT64 : ldatatypebpp := 64;     // long long (64 bits)
    kDT_UINT64 : ldatatypebpp := 64;     // unsigned long long (64 bits)
    kDT_FLOAT128 : ldatatypebpp := 128;     // long double (128 bits)
    kDT_COMPLEX128 : ldatatypebpp := 128;   // double pair (128 bits)
    kDT_COMPLEX256 : ldatatypebpp := 256;     // long double pair (256 bits)
    else
      ldatatypebpp := 0;
  end;
  if (ldatatypebpp = lHdr.bitpix) and (ldatatypebpp <> 0) then
    exit;
  //showmessage(inttostr(ldatatypebpp));
  if (ldatatypebpp <> 0) then begin
    //use bitpix from datatype...
    lHdr.bitpix := ldatatypebpp;
    exit;
  end;
  if (lbitpix <> 0) and (ldatatypebpp = 0) then begin
    //assume bitpix is correct....
    //note that several datatypes correspond to each bitpix, so assume most popular...
    case lbitpix of
      1: lHdr.datatype := kDT_BINARY;
      8: lHdr.datatype :=  kDT_UNSIGNED_CHAR;
      16: lHdr.datatype := kDT_SIGNED_SHORT;
      24: lHdr.datatype :=     kDT_RGB;
      32: lHdr.datatype :=     kDT_FLOAT;
      64: lHdr.datatype := kDT_DOUBLE;
      else goto 191; //impossible bitpix
    end;
    exit;
  end;
191:
  //Both bitpix and datatype are wrong... assume most popular format
  result := false;
  lHdr.bitpix := 16;
  lHdr.datatype := kDT_SIGNED_SHORT;
end;

function FixDataType (var lHdr: TMRIcroHdr): boolean;  overload;
begin
  result := FixDataType(lHdr.NIFTIhdr);

end;

(*function cleanstr(str: string): string;
const
  //kBad = [#0..#9,#11,#12,#14..#31,#127, #255];
  kBad = [#0..#255];
var
  i: integer;
begin
  result := str;
  if length(str) < 1 then exit;
  result := 'x';
  for i := 1 to length(str) do
        if str[i] in kBad then
          result := result+ chr(0);
  GLForm1.ShowmessageError(result);
end; *)

function NIFTIhdr_LoadHdr (var lFilename: string; var lHdr: TMRIcroHdr): boolean;
var
  lHdrFile: file;
  lOri: array [1..3] of single;
  lBuff: Bytep;
  lAHdr: TAnalyzeHdrSection;
  lReportedSz, lSwappedReportedSz,lHdrSz,lFileSz: Longint;
  lExt: string; //1494
  swapEndian, isDimPermute2341: boolean;
begin
  Result := false; //assume error
  isDimPermute2341 := false;
  NIFTIhdr_ClearHdr(lHdr);
  if lFilename = '' then exit;
  lExt := UpCaseExt(lFilename);
  lHdr.ImgFileName:= lFilename;
  if (lExt = '.HDR')  then
     lHdr.ImgFileName:= changefileext(lFilename,'.img');
  if lExt = '.IMG' then begin
      lHdr.ImgFileName := lFilename;
     lFilename := changeFileExt(lFilename,'.hdr');
  end;
  if (lExt = '.BRIK') or (lExt='.BRIK.GZ') then
	  lFilename := changeFileExtX(lFilename,'.head');
  if not FileExistsEX(lFilename) then exit;
  lHdr.HdrFileName:= lFilename;
  if (lExt <> '.IMG') and (lExt <> '.NII') and (lExt <> '.VOI') and  (lExt <> '.HDR') and (lExt <> '.NII.GZ') then begin
     result := readForeignHeader (lFilename, lHdr.NIFTIhdr,  lHdr.gzBytes, swapEndian, isDimPermute2341);
    lHdr.ImgFileName := lfilename;
    lfilename :=  lHdr.HdrFileName; //expects filename to be header not image!
    lHdr.DiskDataNativeEndian := not  swapEndian;
    exit;
  end else if (lExt = '.NII.GZ') or (lExt = '.VOI') then
     lHdr.gzBytes := K_gzBytes_headerAndImageCompressed;
  lHdrSz := sizeof(TniftiHdr);
  lFileSz := FSize (lFilename);
  if lFileSz = 0 then begin
	  ShowMessage('Unable to find NIFTI header named '+lFilename);
	  exit;
  end;
  if (lFileSz < lHdrSz) and (lHdr.gzBytes = K_gzBytes_headerAndImageUncompressed) then begin
	  ShowMessage('Error in reading NIFTI header: NIfTI headers need to be at least '+inttostr(lHdrSz)+ ' bytes: '+lFilename);
	  exit;
  end;
  FileMode := 0;  { Set file access to read only }
  if (lHdr.gzBytes <> K_gzBytes_headerAndImageUncompressed) then begin//1388
	  lBuff := @lHdr;
	  UnGZip(lFileName,lBuff,0,lHdrSz);
   end else begin //if gzip
	   {$I-}
	   AssignFile(lHdrFile, lFileName);
	   FileMode := 0;  { Set file access to read only }
	   Reset(lHdrFile, 1);
	   {$I+}
	   if ioresult <> 0 then begin
		  ShowMessage('Error in reading NIFTI header.'+inttostr(IOResult));
		  FileMode := 2;
		  exit;
	   end;
	   BlockRead(lHdrFile, lHdr, lHdrSz);
	   CloseFile(lHdrFile);
   end;
  FileMode := 2;
  if (IOResult <> 0) then exit;

  lReportedSz := lHdr.niftiHdr.HdrSz;
  lSwappedReportedSz := lReportedSz;
  swap4(lSwappedReportedSz);
  if lReportedSz = lHdrSz then begin
	 lHdr.DiskDataNativeEndian := true;
  end else if lSwappedReportedSz = lHdrSz then begin
	  lHdr.DiskDataNativeEndian := false;
	  NIFTIhdr_SwapBytes (lHdr.niftiHdr);
  end else begin
          //result := NIFTIhdr_LoadDCM (lFilename,lHdr); //2/2008
          //if not result then
	     ShowMessage('Warning: the header file is not in NIfTi format [the first 4 bytes do not have the value 348]. Assuming big-endian data.');
	  exit;
  end;
  if (lHdr.NIFTIhdr.dim[0] > 7) or (lHdr.NIFTIhdr.dim[0] < 1) then begin //only 1..7 dims, so this
	  Showmessage('Illegal NIfTI Format Header: this header does not specify 1..7 dimensions.');
	  exit;
  end;
  FixDataType(lHdr);
  result := true;
  if  IsNifTiMagic(lHdr.niftiHdr) then begin  //must match MAGMA in nifti_img
    lOri[1] := (lHdr.NIFTIhdr.dim[1]+1) div 2;
    lOri[2] := (lHdr.NIFTIhdr.dim[2]+1) div 2;
    lOri[3] := (lHdr.NIFTIhdr.dim[3]+1) div 2;
	  if  (not HasQuat(lHdr.NiftiHdr)) {3/2008} and (lHdr.NIFTIhdr.sform_code = 0) and (orthogonalMatrix(lHdr)) then
		  lHdr.NIFTIhdr.sform_code := 1;
    //ShowHdr(lHdr.NIFTIHdr,3);
    if emptymatrix(lHdr) then begin

      if Quat2Mat(lHdr.NiftiHdr) then
                     //HasQuat will specify
      else begin
        lHdr.NIFTIhdr.srow_x[0] := lHdr.NIFTIhdr.pixdim[1];
        lHdr.NIFTIhdr.srow_y[1] := lHdr.NIFTIhdr.pixdim[2];
        lHdr.NIFTIhdr.srow_z[2] := lHdr.NIFTIhdr.pixdim[3];
			  lHdr.NIFTIhdr.srow_x[3] := -lHdr.NIFTIhdr.srow_x[3];
			  lHdr.NIFTIhdr.srow_y[3] := -lHdr.NIFTIhdr.srow_y[3];
			  lHdr.NIFTIhdr.srow_z[3] := -lHdr.NIFTIhdr.srow_z[3];
        lHdr.NIFTIhdr.sform_code := 1;
      end;

    end;
    if (lHdr.NIFTIhdr.srow_x[0] > 0) and (lHdr.NIFTIhdr.srow_y[1] > 0) and (lHdr.NIFTIhdr.srow_z[2] > 0) and
		  (lHdr.NIFTIhdr.srow_x[3] > 0) and (lHdr.NIFTIhdr.srow_y[3] > 0) and (lHdr.NIFTIhdr.srow_z[3] > 0) then begin
      lHdr.NIFTIhdr.srow_x[3] := -lHdr.NIFTIhdr.srow_x[3];
			lHdr.NIFTIhdr.srow_y[3] := -lHdr.NIFTIhdr.srow_y[3];
			lHdr.NIFTIhdr.srow_z[3] := -lHdr.NIFTIhdr.srow_z[3];
		  lHdr.NIFTIhdr.sform_code := 1;
	  end; //added 4Mar2006 -> corrects for improperly signed offset values...
  end else begin //not NIFT: Analyze
    lHdr.NIfTItransform := false;
    if not lHdr.DiskDataNativeEndian then begin
		  NIFTIhdr_SwapBytes (lHdr.niftiHdr);
		  move(lHdr.niftiHdr,lAHdr,sizeof(lAHdr));
		  NIFTIhdr_SwapBytes (lHdr.niftiHdr);
		  lAHdr.Originator[1] := swap(lAHdr.Originator[1]);
		  lAHdr.Originator[2] := swap(lAHdr.Originator[2]);
		  lAHdr.Originator[3] := swap(lAHdr.Originator[3]);
    end else
      move(lHdr.niftiHdr,lAHdr,sizeof(lAHdr));
    lOri[1] :=lAHdr.Originator[1];
	  lOri[2] := lAHdr.Originator[2];
	  lOri[3] := lAHdr.Originator[3];
    if ((lOri[1]<1) or (lOri[1]> lHdr.NIFTIhdr.dim[1])) and
            ((lOri[2]<1) or (lOri[2]> lHdr.NIFTIhdr.dim[2])) and
            ((lOri[3]<1) or (lOri[3]> lHdr.NIFTIhdr.dim[3])) then begin
      lOri[1] := (lHdr.NIFTIhdr.dim[1]+1) div 2;
      lOri[2] := (lHdr.NIFTIhdr.dim[2]+1) div 2;
      lOri[3] := (lHdr.NIFTIhdr.dim[3]+1) div 2;
    end;
	  //showmessage(inttostr(sizeof(lAHdr))+'  '+realtostr(lHdr.Ori[1],1)+' '+ realtostr(lHdr.Ori[2],1)+' '+realtostr(lHdr.Ori[3],1) );
	  //DANGER: This header was from ANALYZE format, not NIFTI: make sure the rotation matrix is switched off
	  //NIFTIhdr_SetIdentityMatrix(lHdr);
    NII_SetIdentityMatrix (lHdr.NIFTIhdr);
	  lHdr.NIFTIhdr.qform_code := kNIFTI_XFORM_UNKNOWN;
	  lHdr.NIFTIhdr.sform_code := kNIFTI_XFORM_UNKNOWN;
          //test - input estimated orientation matrix
    lHdr.NIFTIhdr.sform_code := kNIFTI_XFORM_SCANNER_ANAT ;
    lHdr.NIFTIhdr.srow_x[0] := lHdr.NIFTIhdr.pixdim[1];
    lHdr.NIFTIhdr.srow_y[1] := lHdr.NIFTIhdr.pixdim[2];
    lHdr.NIFTIhdr.srow_z[2] := lHdr.NIFTIhdr.pixdim[3];
    lHdr.NIFTIhdr.srow_x[3] := (lOri[1]-1)*-lHdr.NIFTIhdr.pixdim[1];
    lHdr.NIFTIhdr.srow_y[3] := (lOri[2]-1)*-lHdr.NIFTIhdr.pixdim[2];
    lHdr.NIFTIhdr.srow_z[3] := (lOri[3]-1)*-lHdr.NIFTIhdr.pixdim[3];
	  //Warning: some of the NIFTI float values that do exist as integer values in Analyze may have bizarre values like +INF, -INF, NaN
	  lHdr.NIFTIhdr.toffset := 0;
	  lHdr.NIFTIhdr.intent_code := kNIFTI_INTENT_NONE;
	  lHdr.NIFTIhdr.dim_info := kNIFTI_SLICE_SEQ_UNKNOWN + (kNIFTI_SLICE_SEQ_UNKNOWN shl 2) + (kNIFTI_SLICE_SEQ_UNKNOWN shl 4); //Freq, Phase and Slie all unknown
	  lHdr.NIFTIhdr.xyzt_units := kNIFTI_UNITS_UNKNOWN;
	  lHdr.NIFTIhdr.slice_duration := 0; //avoid +inf/-inf, NaN
	  lHdr.NIFTIhdr.intent_p1 := 0;  //avoid +inf/-inf, NaN
	  lHdr.NIFTIhdr.intent_p2 := 0;  //avoid +inf/-inf, NaN
	  lHdr.NIFTIhdr.intent_p3 := 0;  //avoid +inf/-inf, NaN
	  lHdr.NIFTIhdr.pixdim[0] := 1; //QFactor should be 1 or -1
  end;
  if (lHdr.NIFTIhdr.sform_code > kNIFTI_XFORM_UNKNOWN) and (lHdr.NIFTIhdr.sform_code <= kNIFTI_XFORM_MNI_152) then begin //DEC06

	lHdr.Mat:= Matrix3D(
		lHdr.NIFTIhdr.srow_x[0],lHdr.NIFTIhdr.srow_x[1],lHdr.NIFTIhdr.srow_x[2],lHdr.NIFTIhdr.srow_x[3],
		lHdr.NIFTIhdr.srow_y[0],lHdr.NIFTIhdr.srow_y[1],lHdr.NIFTIhdr.srow_y[2],lHdr.NIFTIhdr.srow_y[3],
		lHdr.NIFTIhdr.srow_z[0],lHdr.NIFTIhdr.srow_z[1],lHdr.NIFTIhdr.srow_z[2],lHdr.NIFTIhdr.srow_z[3]);
         //ReportMatrix(lHdr.Mat);
  end else begin
	lHdr.Mat:= Matrix3D(
		lHdr.NIFTIhdr.pixdim[1],0,0,(lOri[1]-1)*-lHdr.NIFTIhdr.pixdim[1],
		0,lHdr.NIFTIhdr.pixdim[2],0,(lOri[2]-1)*-lHdr.NIFTIhdr.pixdim[2],
		0,0,lHdr.NIFTIhdr.pixdim[3],(lOri[3]-1)*-lHdr.NIFTIhdr.pixdim[3]);
  end;
    FixCrapMat(lHdr.Mat);
    //lHdr.NIFTIhdr.descrip := cleanstr(lHdr.NIFTIhdr.descrip);
end; //func NIFTIhdr_LoadHdr

procedure NIFTIhdr_SetIdentityMatrix (var lHdr: TMRIcroHdr); //create neutral rotation matrix
var lInc: integer;
begin
	with lHdr.NIFTIhdr do begin
		 for lInc := 0 to 3 do
			 srow_x[lInc] := 0;
		 for lInc := 0 to 3 do
             srow_y[lInc] := 0;
         for lInc := 0 to 3 do
             srow_z[lInc] := 0;
         for lInc := 1 to 16 do
             intent_name[lInc] := chr(0);
         //next: create identity matrix: if code is switched on there will not be a problem
		 srow_x[0] := 1;
         srow_y[1] := 1;
         srow_z[2] := 1;
    end;
end; //proc NIFTIhdr_IdentityMatrix

(*procedure NIFTIhdr_ClearHdr (var lHdr: TNIfTIHdr); overload;//put sensible default values into header
var lInc: byte;
begin
    with lHdr do begin
         {set to 0}
         HdrSz := sizeof(TNIFTIhdr);
         for lInc := 1 to 10 do
             Data_Type[lInc] := chr(0);
         for lInc := 1 to 18 do
             db_name[lInc] := chr(0);
         extents:=0;
         session_error:= 0;
         regular:='r'{chr(0)};
		 dim_info:=(0);
         dim[0] := 4;
         for lInc := 1 to 7 do
             dim[lInc] := 0;
         intent_p1 := 0;
         intent_p2 := 0;
         intent_p3 := 0;
         intent_code:=0;
         datatype:=0 ;
         bitpix:=0;
         slice_start:=0;
         for lInc := 1 to 7 do
             pixdim[linc]:= 1.0;
         vox_offset:= 0.0;
         scl_slope := 1.0;
         scl_inter:= 0.0;
         slice_end:= 0;
         slice_code := 0;
         xyzt_units := 10;
         cal_max:= 0.0;
         cal_min:= 0.0;
         slice_duration:=0;
         toffset:= 0;
         glmax:= 0;
         glmin:= 0;
         for lInc := 1 to 80 do
             descrip[lInc] := chr(0);{80 spaces}
         for lInc := 1 to 24 do
             aux_file[lInc] := chr(0);{80 spaces}
         {below are standard settings which are not 0}
         bitpix := 16;//vc16; {8bits per pixel, e.g. unsigned char 136}
         DataType := 4;//vc4;{2=unsigned char, 4=16bit int 136}
         Dim[0] := 3;
         Dim[1] := 256;
         Dim[2] := 256;
         Dim[3] := 128;
         Dim[4] := 1; {n vols}
         Dim[5] := 1;
         Dim[6] := 1;
         Dim[7] := 1;
         glMin := 0;
         glMax := 255;
         qform_code := kNIFTI_XFORM_UNKNOWN;
         sform_code:= kNIFTI_XFORM_UNKNOWN;
         quatern_b := 0;
         quatern_c := 0;
         quatern_d := 0;
         qoffset_x := 0;
         qoffset_y := 0;
         qoffset_z := 0;
         magic := kNIFTI_MAGIC_SEPARATE_HDR;
    end; //with the NIfTI header...
end; //proc NIFTIhdr_ClearHdr  *)

procedure NIFTIhdr_ClearHdr (var lHdr: TMRIcroHdr); overload;//put sensible default values into header
begin
    lHdr.UsesCustomPalette := false;
    lHdr.RGB := false;
    //lHdr.NativeMM3:= 0;
	lHdr.DiskDataNativeEndian:= true;
 lHdr.NIfTItransform := true;
 lHdr.LutVisible := true;
	lHdr.LutFromZero := false;
  NII_Clear(lHdr.NIFTIHdr); //NIFTIhdr_ClearHdr(lHdr.NIFTIHdr);
  lHdr.gzBytes := K_gzBytes_headerAndImageuncompressed;
         NIFTIhdr_SetIdentityMatrix(lHdr);
    with lHdr do begin
	 ScrnBufferItems := 0;
	 ImgBufferItems := 0;
	 ImgBufferBPP := 0;
	 RenderBufferItems := 0;
	 ScrnBuffer:= nil;
	 ImgBuffer := nil;
    end;
end; //proc NIFTIhdr_ClearHdr

function NIFTIhdr_SaveHdr (var lFilename: string; var lHdr: TMRIcroHdr; lAllowOverwrite: boolean): boolean; overload;
var lOutHdr: TNIFTIhdr;
	lExt: string;
    lF: File;
    lOverwrite: boolean;
begin
     lOverwrite := false; //will we overwrite existing file?
     result := false; //assume failure
	 if lHdr.NIFTIhdr.magic = kNIFTI_MAGIC_EMBEDDED_HDR then begin
		 lExt := UpCaseExt(lFileName);
		 if (lExt = '.GZ') or (lExt = '.NII.GZ') then begin
			showmessage('Unable to save .nii.gz headers (first ungzip your image if you wish to edit the header)');
			exit;
		 end;
		 lFilename := changefileext(lFilename,'.nii')
	 end else
         lFilename := changefileext(lFilename,'.hdr');
     if ((sizeof(TNIFTIhdr))> DiskFreeEx(lFileName)) then begin
        ShowMessage('There is not enough free space on the destination disk to save the header. '+kCR+
        lFileName+ kCR+' Bytes Required: '+inttostr(sizeof(TNIFTIhdr)) );
        exit;
     end;
     if Fileexists(lFileName) then begin
         if lAllowOverwrite then begin
            case MessageDlg('Do you wish to modify the existing file '+lFilename+'?', mtConfirmation,[mbYes, mbNo], 0) of	{ produce the message dialog box }
             6: lOverwrite := true; //6= mrYes, 7=mrNo... not sure what this is for unix. Hardcoded as we do not include Form values
        end;//case
         end else
             showmessage('Error: the file '+lFileName+' already exists.');
         if not lOverwrite then Exit;
	 end;
     if lHdr.NIFTIhdr.magic = kNIFTI_MAGIC_EMBEDDED_HDR then
        if lHdr.NIFTIhdr.vox_offset < sizeof(TNIFTIHdr) then
           lHdr.NIFTIhdr.vox_offset := sizeof(TNIFTIHdr); //embedded images MUST start after header
     if lHdr.NIFTIhdr.magic = kNIFTI_MAGIC_SEPARATE_HDR then
           lHdr.NIFTIhdr.vox_offset := 0; //embedded images MUST start after header
     result := true;
     move(lHdr.NIFTIhdr, lOutHdr, sizeof(lOutHdr));
     if lHdr.DiskDataNativeEndian= false then
        NIFTIhdr_SwapBytes (lOutHdr);{swap to big-endianformat}
     Filemode := 1;
     AssignFile(lF, lFileName); {WIN}
     if lOverwrite then //this allows us to modify just the 348byte header of an existing NII header without touching image data
         Reset(lF,sizeof(TNIFTIhdr))
     else
         Rewrite(lF,sizeof(TNIFTIhdr));
     BlockWrite(lF,lOutHdr, 1  {, NumWritten});
     CloseFile(lF);
     Filemode := 2;
end; //func NIFTIhdr_SaveHdr

procedure NIFTIhdr_SwapBytes (var lAHdr: TNIFTIhdr); //Swap Byte order for the Analyze type
var
   lInc: integer;
begin
    with lAHdr do begin
         swap4(hdrsz);
         swap4(extents);
         session_error := swap2(session_error);
         for lInc := 0 to 7 do
             dim[lInc] := swap2(dim[lInc]);//666
         Xswap4r(intent_p1);
         Xswap4r(intent_p2);
         Xswap4r(intent_p3);
         intent_code:= swap2(intent_code);
         datatype:= swap2(datatype);
         bitpix := swap2(bitpix);
         slice_start:= swap2(slice_start);
         for lInc := 0 to 7 do
             Xswap4r(pixdim[linc]);
         Xswap4r(vox_offset);
{roi scale = 1}
         Xswap4r(scl_slope);
         Xswap4r(scl_inter);
         slice_end := swap2(slice_end);
         Xswap4r(cal_max);
         Xswap4r(cal_min);
         Xswap4r(slice_duration);
         Xswap4r(toffset);
         swap4(glmax);
         swap4(glmin);
         qform_code := swap2(qform_code);
         sform_code:= swap2(sform_code);
         Xswap4r(quatern_b);
         Xswap4r(quatern_c);
         Xswap4r(quatern_d);
         Xswap4r(qoffset_x);
         Xswap4r(qoffset_y);
         Xswap4r(qoffset_z);
		 for lInc := 0 to 3 do //alpha
			 Xswap4r(srow_x[lInc]);
		 for lInc := 0 to 3 do //alpha
			 Xswap4r(srow_y[lInc]);
		 for lInc := 0 to 3 do //alpha
             Xswap4r(srow_z[lInc]);
    end; //with NIFTIhdr
end; //proc NIFTIhdr_SwapBytes

end.
 

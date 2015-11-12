unit lut;

interface
uses define_types, sysutils, dialogs, clut;
{$D-,L-,O+,Q-,R-,Y-,S-}
const
 knAutoLUT = 7;
procedure LUTdropLoad( lLUTindex: integer; var lLUT: TLUT; lLUTname: string; var lCLUTrec: TCLUTrec);
//procedure LoadColorScheme(lStr: string; var lLUT: TLUT);

implementation

function SetAlpha(lIndex: byte): byte;
begin
  result := lindex shr 4;
end;

procedure LinearMinMaxCLUTrec(lMin,lMax: TGLRGBQuad; var lNodeRA: TCLUTrec);
//creates linear RGBA values from minimum to maximum
begin
  lNodeRA.nodes[0].intensity := 0;
  lNodeRA.nodes[0].rgba := lMin;
  lNodeRA.nodes[1].intensity := 255;
  lNodeRA.nodes[1].rgba := lMax;
  lNodeRA.numnodes := 2;
end;

procedure  LoadMonochromeLUT (var lLUTindex: integer; var lLUT: TLUT; var lCLUTrec: TCLUTrec); //lLUT: 0=gray,1=red,2=green,3=blue
var
   //lR,lG,lB,
   lInc: integer;
begin
	case lLUTindex of
		1:
		for lInc := 0 to 255 do begin
		 lLUT[lInc].rgbRed := lInc;
		 lLUT[lInc].rgbGreen := 0;
		 lLUT[lInc].rgbBlue := 0;
		 lLUT[lInc].rgbReserved := SetAlpha(lInc);
		end;//red
		2:
		for lInc := 0 to 255 do begin
		 lLUT[lInc].rgbRed := 0;
		 lLUT[lInc].rgbGreen := lInc;
		 lLUT[lInc].rgbBlue := 0;
		 lLUT[lInc].rgbReserved := SetAlpha(lInc);
		end;//green
		3:
		for lInc := 0 to 255 do begin
		 lLUT[lInc].rgbRed := 0;
		 lLUT[lInc].rgbGreen := 0;
		 lLUT[lInc].rgbBlue := lInc;
		 lLUT[lInc].rgbReserved := SetAlpha(lInc);
		end;//blue
    		4:
		for lInc := 0 to 255 do begin
		 lLUT[lInc].rgbRed := lInc;
		 lLUT[lInc].rgbGreen := 0;
		 lLUT[lInc].rgbBlue := lInc;
		 lLUT[lInc].rgbReserved := SetAlpha(lInc);
		end;//r+b=violet
		5:
		for lInc := 0 to 255 do begin
		 lLUT[lInc].rgbRed := lInc;
		 lLUT[lInc].rgbGreen := lInc;
		 lLUT[lInc].rgbBlue := 0;
		 lLUT[lInc].rgbReserved := SetAlpha(lInc);
		end;//red + green = yellow
		6:
		for lInc := 0 to 255 do begin
		 lLUT[lInc].rgbRed := 0;
		 lLUT[lInc].rgbGreen := lInc;
		 lLUT[lInc].rgbBlue := lINc;
		 lLUT[lInc].rgbReserved := SetAlpha(lInc);
		end;//green+blue = cyan

		else begin
			for lInc := 0 to 255 do begin
				lLUT[lInc].rgbRed := lInc;
				lLUT[lInc].rgbGreen := lInc;
				lLUT[lInc].rgbBlue := lInc;
				lLUT[lInc].rgbReserved := SetAlpha(lInc);
			end;//for gray
		end//else... gray
	end;
  LinearMinMaxCLUTrec(lLUT[0],lLUT[255],lCLUTrec);
end;


procedure LUTdropLoad(lLUTindex: integer; var lLUT: TLUT; lLUTname: string; var lCLUTrec: TCLUTrec);
var
   lStr: string;
begin
     if lLUTindex < knAutoLUT then begin
        LoadMonochromeLUT(lLUTindex,lLUT,lCLUTrec);
        exit;
     end;
     lStr := ClutDir+pathdelim+lLUTname+'.clut';
     if not FileExistsEX(lStr) then  begin
        showmessage('Can not find '+lStr);
        exit;
     end;
     CLUT2TLUT(lStr,lLUT,lCLUTrec);
	 (*lStr := ClutDir+pathdelim+lLUTname+'.lut';
	 if not FileExistsEX(lStr) then  begin
		showmessage('Can not find '+lStr);
    exit;
   end;
	 LoadColorScheme(lStr, lLUT); *)
end;
(*begin
	 if lLUTindex < knAutoLUT then begin
    LoadMonochromeLUT(lLUTindex,lLUT,lCLUTrec);
		exit;
	 end; //if B&W lut
end; *)

end.

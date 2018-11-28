unit clut;
{$D-,L-,O+,Q-,R-,Y-,S-}
{$IFDEF FPC} {$mode delphi}{$H+} {$ENDIF}
//color lookup tables
interface
uses
//{$IFNDEF UNIX}Windows,{$ENDIF}
dialogs,Classes,define_types, IniFiles, SysUtils,prefs,Menus, StdCtrls, userdir;
type
  TCLUTnode =record
    intensity: byte;
    rgba: TGLRGBQuad;
  end;
  TCLUTnodeRA = array [0..255] of TCLUTnode;
  TCLUTrec =record
    numnodes: integer;
    min,max: single;
    nodes: TCLUTnodeRA;
  end;
var
  gCLUTrec: TCLUTrec;
  gSelectedNode: integer = -1;
  function Node(lIntensity,lR,lG,lB,lA: byte): TCLUTnode;
  procedure RangeRec (lMin,lMax: single);
  procedure AutoContrast (var lCLUTrec: TCLUTrec);
  procedure GenerateLUT(lNodeRA: TCLUTrec; var lCLUT: TLUT);
  procedure LoadColorSchemes;
  procedure LUTChange(Sender: TObject);
  procedure SetItemNameX (lStr: string; var LUTdrop: TComboBox); overload;
  procedure SetItemNameX (lStr: string; var LUTdrop: TMenuItem); overload;
  procedure UpdateColorSchemes (var LUTdrop: TComboBox);
  procedure CLUT2TLUT(lFilename: string; var lLUT: TLUT; var lCLUTrec: TCLUTrec);
  //procedure LinearMinMaxCLUT(lMin,lMax: TGLRGBQuad; var lCLUT: TLUT);
  function CLUTDir: string;
implementation
uses mainunit;

function StripAmpersand(lS: string): string;
var i: integer;

begin
     result := '';
     if length(lS) < 1 then
        exit;
     for i := 1 to length(lS) do
         if lS[i] <> '&' then
            result := result+ lS[i];
end;

procedure SetItemNameX (lStr: string; var LUTdrop: TMenuItem); overload;
var
  i: integer;
  lIStr,lUStr,lPStr: string;
begin
  if LUTdrop.Count < 1 then exit;
  lUStr := ansiuppercase(lStr);
  lPStr := parsefilename(extractfilename(lUStr));
  i := 0;
  while i < LUTdrop.Count do begin
    lIStr := StripAmpersand(ansiuppercase(LUTdrop.Items[i].caption));
    if (lIStr = lUStr) or (lIStr = lPStr) then begin
      LUTdrop.Items[i].click;
      exit;
    end;
    inc(i);
  end;
end;//SetItemNameX
(* the following code seems elegant, but is case sensitive and crashes lazarus if not found
begin
 LUTdrop.Find(lStr).Click;
  //GLForm1.OpenColorScheme( LUTdrop.Find(lStr));
end;//SetItemNameX *)

procedure SetItemNameX (lStr: string; var LUTdrop: TComboBox); overload;
var
  i: integer;
  lIStr,lUStr,lPStr: string;
begin
  if LUTdrop.Items.Count < 1 then exit;
  lUStr := ansiuppercase(lStr);
  lPStr := parsefilename(extractfilename(lUStr));
  i := 0;
  while i < LUTdrop.Items.Count do begin
    lIStr := ansiuppercase(LUTdrop.Items[i]);
    if (lIStr = lUStr) or (lIStr = lPStr) then begin
      LUTdrop.ItemIndex := i;
      exit;
    end;
    inc(i);
  end;
end;//SetItemNameX

function CLUTDir: string;
begin
  //result := extractfilepath(paramstr(0))+'lut';
  result := AppDir+'lut';
  {$IFDEF UNIX}
  if fileexists(result) then exit;
  result := '/usr/share/mricrogl/lut';
  if fileexists(result) then exit;
  result := AppDir+'lut'
  {$ENDIF}
  if fileexists(result) then exit;
  result := AppDir+'Resources'+pathdelim+'lut'

end;

function CLUT2disk(lRead: boolean; lFilename: string; var lCLUTrec: TCLUTrec): boolean;
//Read or write initialization variables to disk
var
  lIniFile: TIniFile;
  lI: integer;
begin
  result := false;
  if lRead then
    AutoContrast(lCLUTrec);
  if (lRead) and (not Fileexists(lFilename)) then
        exit;
  lIniFile := TIniFile.Create(lFilename);
  IniFloat(lRead,lIniFile, 'min',lCLUTrec.min);
  IniFloat(lRead,lIniFile, 'max',lCLUTrec.max);
  IniInt(lRead,lIniFile, 'numnodes',lCLUTrec.numnodes);
  if (lCLUTrec.numnodes > 1) and (lCLUTrec.numnodes <= 256) then begin
    for lI := 0 to (lCLUTrec.numnodes-1) do begin
      IniByte(lRead,lIniFile, 'nodeintensity'+inttostr(lI),lCLUTrec.nodes[lI].intensity);
      IniRGBA(lRead,lIniFile, 'nodergba'+inttostr(lI),lCLUTrec.nodes[lI].rgba);
    end;
  end else
    AutoContrast (lCLUTrec);
  lIniFile.Free;
  result := true;
end;

function RemoveSpecial (S: string): string;
var
  i: integer;
begin
  result := '';
  if length(S) < 1 then
    exit;
  for i:= 1 to length(S) do
    if ord(S[i]) <> 38 then result := result + S[i];
end;

procedure LUTChange(Sender: TObject);
begin
  if (Sender as TMenuItem).Tag = 0 then
    AutoContrast (gCLUTrec)
  else
     CLUT2disk(true,ClutDir+pathdelim+removespecial((Sender as TMenuItem).caption)+'.clut', gCLUTrec);
  if (gCLUTrec.min = gCLUTrec.max) then
    RangeRec(gTexture3D.MinThreshScaled,gTexture3D.MaxThreshScaled);
end;

procedure FindColorSchemes(out lS: TStringList);
var
	lSearchRec: TSearchRec;
        lStr : string;
begin
  lS := TStringList.Create;
  if FindFirst(CLUTdir+pathdelim+'*.clut', faAnyFile, lSearchRec) = 0 then
	 repeat
               lStr := ParseFileName(ExtractFileName(lSearchRec.Name));
               if (length(lStr) > 0) and (lStr[1] <> '.') then
                  lS.Add(lStr);
	 until (FindNext(lSearchRec) <> 0);
  FindClose(lSearchRec);
  lS.sort;
end;

procedure UpdateColorSchemes (var LUTdrop: TComboBox);
var
  lS: TStringList;
begin
  FindColorSchemes(lS);
  if lS.Count > 0 then
    LUTdrop.Items.AddStrings(lS);
  Freeandnil(lS);
end;//UpdateColorSchemes

procedure LoadColorSchemes;
var
  lS: TStringList;
  NewItem: TMenuItem;
  lPos: integer;
begin
  FindColorSchemes(lS);
  for lPos := 0 to lS.Count do begin//for each MRU
		   NewItem := TMenuItem.Create(GLForm1);
       if lPos = 0 then
        NewItem.Caption := 'Grayscale'
       else
		    NewItem.Caption :=ExtractFileName(lS[lPos-1]);//NewItem.Caption :=ExtractFileName(lS[lPos-1]);//(ParseFileName(ExtractFileName(lFName)));
		   NewItem.Tag := lPos;

       NewItem.onclick :=  GLForm1.OpenColorScheme;
		   GLForm1.Scheme1.Add(NewItem);
  end;//for each MRU
  Freeandnil(lS);
end;//UpdateColorSchemes



procedure RangeRec (lMin,lMax: single);
begin
  gCLUTrec.min := lMin;
  gCLUTrec.max := lMax;
end;

function Node(lIntensity,lR,lG,lB,lA: byte): TCLUTnode;
begin
  result.intensity := lIntensity;
  result.rgba := RGBA(lR,lG,lB,lA);
end;

procedure GenerateLUT(lNodeRA: TCLUTrec; var lCLUT: TLUT);
var
  lSlope: single;
  lSpace,lI,lIprev,lS: integer;
  lMin,lMax: TCLUTnode;
begin
  if lNodeRA.numNodes < 2 then exit;
  lMin := lNodeRA.nodes[0];
  lMax := lNodeRA.nodes[lNodeRA.NumNodes-1];
  //check that nodes are in order...
  lIprev := lMin.intensity;
  for lI := 1 to (lNodeRA.numnodes-1) do begin
    if lNodeRA.nodes[lI].intensity <= lIprev then begin
      showmessage('Error, nodes not sorted or overlapping.');
      exit;
    end;
    lIprev := lNodeRA.nodes[lI].intensity;
  end;
  //clip values <= lMin to value of lMin
  for lI := 0 to lMin.Intensity do begin
    lCLUT[lI] := lMin.rgba;
    if (lCLUT[lI].rgbReserved= 0) then  lCLUT[lI] := RGBA(0,0,0,0); //some clear nodes have RGB values to help interpolation
  end;
  //clip values >= lMax to value of lMin
  for lI := lMax.Intensity to 255 do begin
    lCLUT[lI] := lMax.rgba;
  end;
  for lI := 0 to (lNodeRA.NumNodes-2) do begin
    lSpace := lNodeRA.nodes[lI+1].Intensity-lNodeRA.nodes[lI].Intensity;
    //interpolate red
    lSlope := (lNodeRA.nodes[lI+1].rgba.rgbRed-lNodeRA.nodes[lI].rgba.rgbRed)/lSpace;
    for lS := 1 to lSpace do
      lCLUT[lNodeRA.nodes[lI].Intensity+lS].rgbRed  :=lNodeRA.nodes[lI].rgba.rgbRed + round(lS * lSlope);
    //interpolate green
    lSlope := (lNodeRA.nodes[lI+1].rgba.rgbGreen-lNodeRA.nodes[lI].rgba.rgbGreen)/lSpace;
    for lS := 1 to lSpace do
      lCLUT[lNodeRA.nodes[lI].Intensity+lS].rgbGreen  :=lNodeRA.nodes[lI].rgba.rgbGreen + round(lS * lSlope);
    //interpolate blue
    lSlope := (lNodeRA.nodes[lI+1].rgba.rgbBlue-lNodeRA.nodes[lI].rgba.rgbBlue)/lSpace;
    for lS := 1 to lSpace do
      lCLUT[lNodeRA.nodes[lI].Intensity+lS].rgbBlue  :=lNodeRA.nodes[lI].rgba.rgbBlue + round(lS * lSlope);
    //interpolate alpha
    lSlope := (lNodeRA.nodes[lI+1].rgba.rgbreserved-lNodeRA.nodes[lI].rgba.rgbreserved)/lSpace;
    for lS := 1 to lSpace do
      lCLUT[lNodeRA.nodes[lI].Intensity+lS].rgbreserved  :=lNodeRA.nodes[lI].rgba.rgbreserved + round(lS * lSlope);
  end;

  //need to check this works with overlays...
  //TColor2RGBA(GLForm1.GLSceneViewer1.Buffer.BackgroundColor,Q);
  //Q.rgbReserved := 0;
  //for lI := 0 to 255 do
  //  if lCLUT[lI].rgbReserved = 0 then
  //    lCLUT[lI] := Q;
end;

(*procedure GenerateLUT(lNodeRA: TCLUTnodeRA; lNodes: integer; var lCLUT: TCLUT);
var
  lSlope: single;
  lSpace,lI,lIprev,lS: integer;
  lMin,lMax: TCLUTnode;
begin
  for lI := 0 to 255 do begin
    lCLUT[lI] := RGBA(lI,lI,0,128);
  end;
end; *)

(*procedure LinearMinMaxCLUT(lMin,lMax: TGLRGBQuad; var lCLUT: TLUT);
//creates linear RGBA values from minimum to maximum
var
  lNodeRA: TCLUTrec;
begin
  lNodeRA.nodes[0].intensity := 0;
  lNodeRA.nodes[0].rgba := lMin;
  lNodeRA.nodes[1].intensity := 255;
  lNodeRA.nodes[1].rgba := lMax;
  lNodeRA.numnodes := 2;
  GenerateLUT(lNodeRA,lCLUT);
end;*)

(*procedure AutoContrast (var lCLUTrec: TCLUTrec);
begin
  lCLUTrec.nodes[0] := node(0,0,0,0,0);
  {$IFDEF ENABLERAYCAST}
  lCLUTrec.nodes[1] := node(255,255,255,255,168);
  {$ELSE}
  lCLUTrec.nodes[1] := node(255,255,255,255,100);
  {$ENDIF}
  lCLUTrec.numnodes := 2;
  lCLUTrec.min := 0;
  lCLUTrec.max := 0;
  //RangeRec(gTexture3D.MinThreshScaled,gTexture3D.MaxThreshScaled);
end; *)

procedure AutoContrast (var lCLUTrec: TCLUTrec);
begin
  lCLUTrec.nodes[0] := node(0,0,0,0,0);
  lCLUTrec.nodes[1] := node(128,128,128,128,84);
  lCLUTrec.nodes[2] := node(255,255,255,255,168);
  lCLUTrec.numnodes := 3;
  lCLUTrec.min := 0;
  lCLUTrec.max := 0;
  //RangeRec(gTexture3D.MinThreshScaled,gTexture3D.MaxThreshScaled);
end;

procedure CLUT2TLUT(lFilename: string; var lLUT: TLUT; var lCLUTrec: TCLUTrec);
begin
  if not CLUT2disk(true, lFilename,lCLUTrec) then
    exit;
  GenerateLUT(lCLUTrec, lLUT);
end;


initialization
AutoContrast(gCLUTrec);
end.


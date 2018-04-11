unit prefs;
{$D-,O+,Q-,R-,S-}   //Delphi L-,Y-
{$H+}

interface
uses IniFiles,SysUtils,define_types,graphics,Dialogs,Classes;
const
  knMRU = 10;
  kNoRender = 0;
  kFastRender = 1;
  kNormalRender = 2;
  //kSuperRender = 3;
type
  TMRU =  array [1..knMRU] of string;
  TPrefs = record
         {$IFDEF Darwin}isDoubleBuffer,{$ENDIF}
         isTiledScreenShot,isOrientationTriangles,
         OverlayHideZeros,SkipPrefWriting,
         FlipLR, FlipYZ, SliceDetailsCubeAndText,ThresholdDetection,
         FormMaximized,Debug,ColorEditor,ProportionalStretch,OverlayColorFromZero,
         MaskOverlayWithBackground,  InterpolateOverlays, Perspective,FasterGradientCalculations,
         ShowToolbar,//ColorbarText,
         Colorbar,ForcePowerOfTwo,
         RayCastShowGLSLWarnings,RayCastViewCenteredLight,EnableYoke,
         NoveauWarning, StartupScript, RetinaDisplay, DarkMode: boolean;
         PlanarRGB,SliceView,DrawColor,RayCastQuality1to10,MaxStartupRayCastQuality1to10, FormWidth,FormHeight,
         BackgroundAlpha,OverlayAlpha,CrosshairThick,MaxVox, BitmapZoom, ColorbarColor,ColorbarPosition: integer;
         CLUTWindowColor,CLUTIntensityColor: TColor;
         GridAndBorder,BackColor,TextColor,TextBorder,CrosshairColor,HistogramColor,HistogramBack: TGLRGBQuad;
         ColorbarSize: single;
         InitScript, FontName: string;
         PrevFilename,PrevScriptName: TMRU;

  end;
function IniFile(lRead: boolean; lFilename: string; var lPrefs: TPrefs): boolean;
procedure Add2MRU (var lMRU: TMRU;  lNewFilename: string); //add new file to most-recent list
procedure IniByte(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: byte);
procedure IniInt(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: integer);
procedure IniFloat(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: single);
procedure IniRGBA(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: TGLRGBQuad);
procedure SetDefaultPrefs (var lPrefs: TPrefs; lEverything: boolean);
procedure FillMRU (var lMRU: TMRU; lSearchPath,lSearchExt: string; lForce: boolean);

implementation

uses mainunit;

function IsNovel (lName: string; var lMRU: TMRU; lnOK: integer):boolean;
var lI,lN: integer;
begin
  result := false;
  lN := lNOK;
  if lnOK > knMRU then
    lN := knMRU;
  if lN < 1 then begin
    result := true;
    exit;
  end;
  for lI := 1 to lN do
    if lMRU[lI] = lName then
      exit;
  result := true;
end;

procedure FillMRU (var lMRU: TMRU; lSearchPath,lSearchExt: string; lForce: boolean);
//e.g. SearchPath  includes final pathdelim, e.g. c:\filedir\
var
	lSearchRec: TSearchRec;
  lI,lMax,lOK: integer;
  lS: TStringList;
begin
  lOK := 0;
  if (not lForce) and (lMRU[1] <> '') then begin
      //exit; //only fill empty MRUs...
      for lI := 1 to knMRU do begin
        if (lMRU[lI] <> '') and (fileexistsEX(lMRU[lI])) and (IsNovel (lMRU[lI], lMRU, lOK)) then begin
          inc(lOK);
          lMRU[lOK] := lMRU[lI];
        end; //if file exists
      end; //for each MRU
      if lOK = knMRU then
        exit; //all slots filled;
      for lI := (lOK+1) to knMRU do
        lMRU[lI] :=  '';//empty slot
  end; //check exisiting MRUs
  lS := TStringList.Create;
  if FindFirst(lSearchPath+'*'+lSearchExt, faAnyFile, lSearchRec) = 0 then
	 repeat
      if IsNovel (lSearchPath+lSearchRec.Name, lMRU, lOK) then
        lS.Add(lSearchPath+lSearchRec.Name) ;
	 until (FindNext(lSearchRec) <> 0);
  FindClose(lSearchRec);
  lMax := lS.count;

  if lMax > 0 then begin
    lS.sort;
    if lMax > knMRU then
      lMax := knMRU;
    for lI := (lOK+1) to lMax do
      lMRu[lI] := lS[lI-1];
  end;
  Freeandnil(lS);
end;//UpdateLUT

procedure IniFloat(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: single);
//read or write an integer value to the initialization file
var
	lStr: string;
begin
        if not lRead then begin
           lIniFile.WriteString('FLT',lIdent,FloattoStr(lValue));
           exit;
        end;
	lStr := lIniFile.ReadString('FLT',lIdent, '');
	if length(lStr) > 0 then
		lValue := StrToFloat(lStr);
end; //IniFloat

procedure IniByte(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: byte);
//read or write an integer value to the initialization file
var
	lStr: string;
begin
        if not lRead then begin
           lIniFile.WriteString('BYT',lIdent,InttoStr(lValue));
           exit;
        end;
	lStr := lIniFile.ReadString('BYT',lIdent, '');
	if length(lStr) > 0 then
		lValue := StrToInt(lStr);
end; //IniFloat

procedure Add2MRU (var lMRU: TMRU;  lNewFilename: string); //add new file to most-recent list
var
  lNewM,lOldM,lStr: string;
  lPos,lN : integer;
begin
  lNewM := extractfilename(lNewFilename);
  //first, increase position of all old MRUs
  lN := 0; //Number of MRU files
  for lPos := 1 to (knMRU) do begin//first, eliminate duplicates
	  lStr := lMRU[lPos];
          lOldM := extractfilename(lStr);
          if (lStr <> '') {and (lStr <> lNewFileName)} and (lNewM <> lOldM) then begin
             inc(lN);
	     lMRU[lN] := lStr;
	  end; //keep in MRU list
  end; //for each MRU
  //next, increment positions
  if lN >= knMRU then
	 lN := knMRU - 1;
  for lPos := lN downto 1 do
	  lMRU[lPos+1] := lMRU[lPos];
  if (lN+2) < (knMRU) then //+1 as we have added a file
	 for lPos := (lN+2) to knMRU do
	   lMRU[lPos] := '';
  lMRU[1] := lNewFilename;
end;//Add2MRU

procedure SetDefaultPrefs (var lPrefs: TPrefs; lEverything: boolean);
begin
  if lEverything then begin  //These values are typically not changed...
       with lPrefs do begin
            //CrossHairs := true;
            ColorbarSize := 0.035;
            HistogramColor := RGBA(106,56,106,222);
            //HistogramGrid := RGBA(106,106,142,222);
            HistogramBack := RGBA(0,0,0,0);
            TextColor := RGBA(255,255,255,255);
            GridAndBorder := RGBA(106,106,142,222);
            //ColorBarBorder := RGBA(92,92,132,168);
            TextBorder := RGBA(92,92,132,255);
            CrosshairColor := RGBA (92,92,132,168);
            CLUTIntensityColor := RGBA2TColor (RGBA (102,26,77,255) );
            CLUTWindowColor := RGBA2TColor (RGBA (92,92,132,255) );
            //IntelWarning := true;
            NoveauWarning := true;
            FlipYZ := false;
            FlipLR := false;
            FontName := '';//default
            ThresholdDetection := true;
            isTiledScreenShot := true;
            isOrientationTriangles := false;
            {$IFDEF Darwin} isDoubleBuffer := false; {$ENDIF}
            ForcePowerOfTwo:= false;
            OverlayHideZeros := false;
            MaxVox := 2048;
            //RenderQuality := kNormalRender;
            RayCastShowGLSLWarnings := false;
            RayCastViewCenteredLight := true;
            RayCastQuality1to10 := 7;
            MaxStartupRayCastQuality1to10 := 9; //prevent user starting up at slowest Q=10
            PlanarRGB := 2;//autodetect
            BitmapZoom := 2;
            StartupScript := false;
            RetinaDisplay := true;
            DarkMode := false;
            FormMaximized := false;
            Debug := false;
            {$IFNDEF FPC}
            //REMOVED: fixed in raycastglsl with glFramebufferTexture3D -> glFramebufferTexture3DExt
            //if SysUtils.Win32MajorVersion < 6 then
            //   FasterGradientCalculations := false //GLSL-based gradients fail on when compiled with Delphi on Windows 32 NVidia 8400M (Lazarus OK)
            //else
            {$ENDIF}
            FasterGradientCalculations := true;

       end;
  end;
  with lPrefs do begin
    DrawColor := -1; //disabled
    SkipPrefWriting := false; //only done if user aborts program to view prefs with text editor
    ProportionalStretch := true;
    ColorEditor := false;
    SliceDetailsCubeAndText := true;
    ShowToolbar := true;
    SliceView := 0;
    //ColorbarText := true;
    //LowResolutionRendering := false;
    //RemoveDarkSpeckles := true;
    //Show2DSlicesDuringRendering := true;
    ColorBar := true;
    ColorbarColor := 4;
    ColorBarPosition := 1;
    //ColorBarPos:= CreateUnitRect (0.1,0.1,0.9,0.14);
    //SensibleUnitRect (ColorBarPos);
    Perspective := false;
    InterpolateOverlays := true;
    //InterpolateView := true;
    EnableYoke := true;
    MaskOverlayWithBackground := true;
    OverlayColorFromZero := false;
    //SurfaceThreshold := 25;
    BackgroundAlpha := 50;
    OverlayAlpha := 50;
    BackColor := RGBA(0,0,0,0);
    CrosshairThick := 1;
    FormWidth := 960;
    {$IFDEF FPC}FormHeight := 670;  {$ELSE}FormHeight := 690; {$ENDIF}//Delphi appears to include menubar in height, FPC does not
    //CLUTIntensityColor := RGBA2TColor (RGBA (18,80,18,255) );
  end;//with lPrefs
end; //Proc SetDefaultPrefs

procedure IniInt(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: integer);
//read or write an integer value to the initialization file
var
	lStr: string;
begin
        if not lRead then begin
           lIniFile.WriteString('INT',lIdent,IntToStr(lValue));
           exit;
        end;
	lStr := lIniFile.ReadString('INT',lIdent, '');
	if length(lStr) > 0 then
		lValue := StrToInt(lStr);
end; //IniInt

procedure IniBool(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: boolean);
//read or write a boolean value to the initialization file
var
	lStr: string;
begin
        if not lRead then begin
           lIniFile.WriteString('BOOL',lIdent,Bool2Char(lValue));
           exit;
        end;
	lStr := lIniFile.ReadString('BOOL',lIdent, '');
	if length(lStr) > 0 then
		lValue := Char2Bool(lStr[1]);
end; //IniBool

procedure IniStr(lRead: boolean; lIniFile: TIniFile; lIdent: string; var lValue: string);
//read or write a string value to the initialization file
begin
  if not lRead then begin
    lIniFile.WriteString('STR',lIdent,lValue);
    exit;
  end;
  lValue := lIniFile.ReadString('STR',lIdent, '');
end; //IniStr

procedure IniStrX(lRead: boolean; lIniFile: TIniFile; lIdent: string; var lValue: string);
//read or write a string value to the initialization file
begin
  if not lRead then begin
    if lValue = '' then
       lIniFile.WriteString('STR',lIdent,'_')
    else
        lIniFile.WriteString('STR',lIdent,lValue);
    exit;
  end;
  lValue := lIniFile.ReadString('STR',lIdent, '');
  if lValue = '_' then
     lValue := '';
end; //IniStr

procedure IniUnitRect(lRead: boolean; lIniFile: TIniFile; lIdent: string; var lValue: TUnitRect);
var
  lS: string;
  lU: TUnitRect;
begin
  if not lRead then begin
    lIniFile.WriteString('STR',lIdent,UnitRectToStr (lValue));
    exit;
  end;
	lS := lIniFile.ReadString('STR',lIdent, '');
  if StrToUnitRect (lS, lU) then
    lValue := lU;
end; //IniStr

procedure IniRGBA(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: TGLRGBQuad);
//read or write an integer value to the initialization file
var
	lStr: string;
begin
  if not lRead then begin
    //lI64 := lValue.rgbred + lValue.rgbGreen shl 8 + lValue.rgbBlue shl 16 + lValue.rgbReserved shl 24;
    //lIniFile.WriteString('RGBA',lIdent,InttoStr(lI64));
    lIniFile.WriteString('RGBA255',lIdent,RGBAToStr(lValue));
    exit;
  end;
	lStr := lIniFile.ReadString('RGBA255',lIdent, '');
  StrToRGBA(lStr,lValue);
end; //IniRGBA

procedure IniColor(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lValue: TColor);
//read or write an color value to the initialization file
var
	lC: TGLRGBQuad;
begin
  TColor2RGBA(lValue,lC);
  IniRGBA(lRead,lIniFile,lIdent,lC);
  lValue := RGBA2TColor(lC);
end; //IniColor

procedure IniMRU(lRead: boolean; lIniFile: TIniFile; lIdent: string;  var lMRU: TMRU);
var
	lI,lOK: integer;
        lStr: string;
        lMRUold: TMRU;
function Novel: boolean;
var
  lX: integer;
begin
   result  := true;
   if (lOK < 1) or (lOK > knMRU) then exit;
   result := false;
   for lX := 1 to lOK do
    if lMRU[lX] = lStr then
      exit;
   result := true;
end;
begin
  if lRead then begin //compress files so lowest values are OK
    for lI := 1 to knMRU do
        lMRUold[lI] := lMRU[lI];
    lOK := 0;
    for lI := 1 to knMRU do begin
      IniStr(lRead,lIniFile,lIdent+inttostr(lI),lStr);
      if (length(lStr) > 0) and (fileexists(lStr)) and (Novel) then begin
		    inc(lOK);
		    lMRU[lOK] := lStr;
      end else
        lMRU[lI] := '';
      end; //for each MRU
      //file empty slots
      lI := 0;
      while (lOK < knMRU) and (lI < knMRU) do begin
        lI := lI + 1;
        lStr := lMRUold[lI];
        if (length(lStr) > 0) and (fileexists(lStr)) and (Novel) then begin
		    inc(lOK);
		    lMRU[lOK] := lStr;
        end;
      end;
  end else
      for lI := 1 to knMRU do
      	IniStr(lRead,lIniFile,lIdent+inttostr(lI),lMRU[lI]); //write values
end;

procedure SetDefaultPrefsMRU (var lPrefs: TPrefs);
var
  lI: integer;
  lFilename: string;
begin
    SetDefaultPrefs(lPrefs,true);
    for lI := 1 to knMRU do begin
      lPrefs.PrevFilename[lI] := '';
      lPrefs.PrevScriptName[lI] := '';
    end;
    //load default files
    lFilename := 'mni152_2009_256';
    GLForm1.CheckFilename (lFilename,false);
    if not fileexists(lFilename) then begin
         lFilename := 'ch256';
         GLForm1.CheckFilename (lFilename,false);
    end;
    if fileexists(lFilename) then begin
       lPrefs.PrevFilename[1] := lFilename;
       FillMRU (lPrefs.PrevFilename, ExtractFileDirWithPathDelim(lPrefs.PrevFilename[1]),'.nii.gz',false);
    end;
end;

function IniFile(lRead: boolean; lFilename: string; var lPrefs: TPrefs): boolean;
//Read or write initialization variables to disk
var
  lIniFile: TIniFile;
begin
  result := false;
  if (lRead) then
    SetDefaultPrefsMRU (lPrefs);
  if (lRead) and (not FileexistsEX(lFilename)) then
        exit;
  //if lPrefs.SkipPrefWriting then showmessage('xxxx');
  if (not lRead) and (lPrefs.SkipPrefWriting) then exit; //avoid contention: user aborting program to edit prefs with text editor
  lIniFile := TIniFile.Create(lFilename);
	IniBool(lRead,lIniFile, 'ShowToolbar',lPrefs.ShowToolbar);
	IniBool(lRead,lIniFile, 'SliceDetailsCubeAndText',lPrefs.SliceDetailsCubeAndText);
        IniBool(lRead,lIniFile, 'ProportionalStretch',lPrefs.ProportionalStretch);
        IniBool(lRead,lIniFile, 'FasterGradientCalculations',lPrefs.FasterGradientCalculations);
	IniBool(lRead,lIniFile, 'ColorEditor',lPrefs.ColorEditor);
	IniBool(lRead,lIniFile, 'Debug',lPrefs.Debug);
	IniBool(lRead,lIniFile, 'FormMaximized',lPrefs.FormMaximized);
	//IniBool(lRead,lIniFile, 'SliceText',lPrefs.SliceText);
	//IniBool(lRead,lIniFile, 'ColorBarText',lPrefs.ColorBarText);
        IniBool(lRead,lIniFile, 'ThresholdDetection',lPrefs.ThresholdDetection);
 	IniBool(lRead,lIniFile, 'ForcePowerOfTwo',lPrefs.ForcePowerOfTwo);
	IniBool(lRead,lIniFile, 'StartScript',lPrefs.StartupScript);
        IniBool(lRead,lIniFile, 'RetinaDisplay',lPrefs.RetinaDisplay);
        IniBool(lRead,lIniFile, 'DarkMode',lPrefs.DarkMode);
	//IniBool(lRead,lIniFile, 'IntelWarning',lPrefs.IntelWarning);
        IniBool(lRead,lIniFile, 'NoveauWarning',lPrefs.NoveauWarning);
        IniBool(lRead,lIniFile, 'FlipYZ',lPrefs.FlipYZ);
        IniBool(lRead,lIniFile, 'FlipLR_Radiological',lPrefs.FlipLR);
        {$IFDEF FPC}IniBool(lRead,lIniFile, 'TiledScreenShot',lPrefs.isTiledScreenShot);{$ENDIF}
        {$IFDEF Darwin}IniBool(lRead,lIniFile, 'DoubleBuffer',lPrefs.isDoubleBuffer);{$ENDIF}
	//IniBool(lRead,lIniFile, 'Show2DSlicesDuringRendering',lPrefs.Show2DSlicesDuringRendering);
	IniBool(lRead,lIniFile, 'ColorBar',lPrefs.ColorBar);
	IniBool(lRead,lIniFile, 'Perspective',lPrefs.Perspective);
        IniBool(lRead,lIniFile, 'EnableYoke',lPrefs.EnableYoke);

  //IniBool(lRead,lIniFile, 'InterpolateView',lPrefs.InterpolateView);
        IniBool(lRead,lIniFile, 'SmoothOverlays',lPrefs.InterpolateOverlays);

	IniBool(lRead,lIniFile, 'OverlayColorFromZero',lPrefs.OverlayColorFromZero);
  //The MIP is unusual, so lets always turn it off when the users restarts the software
	//lPrefs.MaximumIntensityProjection := IniBool(lIniFile, 'MaximumIntensityProjection',lPrefs.MaximumIntensityProjection);
  //IniInt(lRead,lIniFile, 'SurfaceThreshold',lPrefs.SurfaceThreshold);
	IniBool(lRead,lIniFile, 'RayCastShowGLSLWarnings',lPrefs.RayCastShowGLSLWarnings);
	IniBool(lRead,lIniFile, 'RayCastViewCenteredLight',lPrefs.RayCastViewCenteredLight);


        IniInt(lRead,lIniFile, 'ColorbarColor',lPrefs.ColorbarColor);
        IniInt(lRead,lIniFile, 'ColorBarPosition',lPrefs.ColorBarPosition);

        IniInt(lRead,lIniFile, 'MaxVox',lPrefs.MaxVox);
  IniInt(lRead,lIniFile, 'PlanarRGB',lPrefs.PlanarRGB);
  IniInt(lRead,lIniFile, 'BitmapZoom',lPrefs.BitmapZoom);
  IniInt(lRead,lIniFile, 'RayCastQuality1to10',lPrefs.RayCastQuality1to10);
  IniInt(lRead,lIniFile, 'MaxStartupRayCastQuality1to10',lPrefs.MaxStartupRayCastQuality1to10);
  if (lRead) and (lPrefs.RayCastQuality1to10 > lPrefs.MaxStartupRayCastQuality1to10) then
        lPrefs.RayCastQuality1to10:= lPrefs.MaxStartupRayCastQuality1to10;
  IniInt(lRead,lIniFile, 'SliceView',lPrefs.SliceView);
  if (lPrefs.SliceView > 4) then lPrefs.SliceView := 0; //do not launch in mosaic mode
  IniInt(lRead,lIniFile, 'BackgroundAlpha',lPrefs.BackgroundAlpha);
  if (lRead) and (lPrefs.BackgroundAlpha = 100) then
     lPrefs.BackgroundAlpha := 50; //do not confuse users with inivisible backgrounds, advanced users can add this to a startup script
  IniInt(lRead,lIniFile, 'OverlayAlpha',lPrefs.OverlayAlpha);
  IniInt(lRead,lIniFile, 'FormHeight',lPrefs.FormHeight);
  IniInt(lRead,lIniFile, 'FormWidth',lPrefs.FormWidth);
  //IniInt(lRead,lIniFile, 'RenderQuality',lPrefs.RenderQuality);
  IniInt(lRead,lIniFile, 'CrosshairThick',lPrefs.CrosshairThick);
  //lPrefs.RenderQuality := Bound(lPrefs.RenderQuality,0,kNormalRender);
  //IniColor(lRead,lIniFile, 'BackgroundColor',lPrefs.BackgroundColor);
  IniColor(lRead,lIniFile, 'CLUTWindowColor',lPrefs.CLUTWindowColor);
  IniColor(lRead,lIniFile, 'CLUTIntensityColor',lPrefs.CLUTIntensityColor);
  //IniUnitRect(lRead,lIniFile, 'ColorBarPos',lPrefs.ColorBarPos);
  //SensibleUnitRect (lPrefs.ColorBarPos);
  IniRGBA(lRead,lIniFile, 'BackColor',lPrefs.BackColor);
  lPrefs.BackColor.rgbReserved := 0;
  IniRGBA(lRead,lIniFile, 'TextColor',lPrefs.TextColor);
  IniRGBA(lRead,lIniFile, 'CrosshairColor',lPrefs.CrosshairColor);
  IniRGBA(lRead,lIniFile, 'TextBorder',lPrefs.TextBorder);
  IniRGBA(lRead,lIniFile, 'GridAndBorder',lPrefs.GridAndBorder);
  IniRGBA(lRead,lIniFile, 'HistogramBack',lPrefs.HistogramBack);
  IniRGBA(lRead,lIniFile, 'HistogramColor',lPrefs.HistogramColor);
//  IniRGBA(lRead,lIniFile, 'TextColor'+inttostr(lI),lPrefs.TextColor);
//  IniRGBA(lRead,lIniFile, 'TextBorder'+inttostr(lI),lPrefs.TextBorder);
//  IniRGBA(lRead,lIniFile, 'ColorBarBorder'+inttostr(lI),lPrefs.ColorBarBorder);
  IniMRU(lRead,lIniFile,'PrevFilename',lPrefs.PrevFilename);
  IniMRU(lRead,lIniFile,'PrevScriptName',lPrefs.PrevScriptName);
  IniStrX(lRead,lIniFile,'FontName',gPrefs.FontName);
  IniFloat(lRead,lIniFile,'ColorbarSize',lPrefs.ColorbarSize);
  lIniFile.Free;
end;

end.

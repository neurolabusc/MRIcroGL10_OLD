unit commandsu;
{$include opts.inc}
{$D-,O+,Q-,R-,S-}
{$H+}
interface
{$IFDEF FPC}{$mode DELPHI}{$H+}{$ENDIF}

uses
{$IFDEF ENABLEWATERMARK}watermark,{$ENDIF}
{$IFDEF FPC}LResources,{$ENDIF}
{$IFDEF Unix} LCLIntf,{$ELSE} Windows,{$ENDIF}
 {$IFNDEF USETRANSFERTEXTURE}  scaleimageintensity,{$ENDIF}ClipBrd, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  shaderui,ExtCtrls, define_types, Menus,histogram2d,extract,slices2d, {$IFDEF COREGL} raycast_core, {$ELSE} raycast_legacy, {$ENDIF} raycast_common, savethreshold;
function EXISTS(lFilename: string): boolean; //function
function OVERLAYLOAD(lFilename: string): integer; //function
function OVERLAYLOADVOL(lFilename: string; lVol: integer): integer; //function
function OVERLAYLOADCLUSTER(lFilename: string; lThreshold, lClusterMM3: single; lSaveToDisk: boolean): integer; //function
procedure ADDNODE(INTENSITY, R,G,B,A: byte);
procedure AZIMUTH (DEG: integer);
procedure AZIMUTHELEVATION (AZI, ELEV: integer);
procedure BACKCOLOR (R,G,B: byte);
procedure BMPZOOM(Z: byte);
procedure MODELESSCOLOR(R,G,B: byte);
procedure CAMERADISTANCE (Z: single);
procedure CHANGENODE(INDEX, INTENSITY, R,G,B,A: byte);
procedure CLIP (DEPTH: single);
procedure CLIPAZIMUTHELEVATION (DEPTH,AZI,ELEV: single);
procedure CLIPFORMVISIBLE (VISIBLE: boolean);
procedure COLORBARCOORD (L,T,R,B: single);
procedure COLORBARPOSITION (P: integer);
procedure COLORBARFORMVISIBLE (VISIBLE: boolean);
procedure COLORBARTEXT (VISIBLE: boolean);
procedure COLORBARVISIBLE (VISIBLE: boolean);
procedure COLORNAME(Filename: string);
procedure CONTRASTFORMVISIBLE (VISIBLE: boolean);
procedure CONTRASTMINMAX(MIN,MAX: single);
procedure CUTOUT (L,A,S,R,P,I: single);
procedure CUTOUTFORMVISIBLE (VISIBLE: boolean);
procedure EDGEDETECT (lThresh: single; lDilateCycles: integer);//new
procedure EDGEENHANCE (BIAS,GAIN: byte);//new
procedure EXTRACT(lOtsuLevels, lDilateVox: integer; lOneContiguousObject: boolean);//newer
procedure EDGEENHANCEFORMVISIBLE (VISIBLE: boolean);
procedure FONTNAME(name: string);
procedure MEDIANSMOOTH;//new
procedure DECIMATE (lPercent: integer);
procedure ELEVATION (DEG: integer);
procedure FRAMEVISIBLE (VISIBLE: boolean);
procedure LOADDRAWING(lFilename: string);
procedure LOADDTI(lFAFilename: string);
procedure LOADIMAGE(lFilename: string);
procedure LOADIMAGEVOL(lFilename: string; lVol: integer);
procedure MAXIMUMINTENSITY (MIP_ON: boolean);
procedure MODALMESSAGE(STR: string);
procedure MODELESSMESSAGE(STR: string);
procedure MOSAIC(Str: string);
procedure MOSAICFORMVISIBLE (VISIBLE: boolean);
procedure ORTHOVIEW (X,Y,Z: single);
procedure ORTHOVIEWMM (X,Y,Z: single);
procedure OVERLAYCLOSEALL;
procedure OVERLAYCOLORNAME(lOverlay: integer; lFilename: string);
procedure OVERLAYCOLORNUMBER(lOverlay,lLUTIndex: integer);
procedure OVERLAYFORMVISIBLE (VISIBLE: boolean);
procedure OVERLAYLOADSMOOTH (SMOOTH: boolean);
procedure OVERLAYCOLORFROMZERO (FROMZERO: boolean);
procedure OVERLAYHIDEZEROS (MASK: boolean);
procedure OVERLAYMASKEDBYBACKGROUND (MASK: boolean); //new
procedure OVERLAYMINMAX (lOverlay: integer; lMin,lMax: single);
procedure OVERLAYTRANSPARENCYONBACKGROUND(lPct: integer);
procedure OVERLAYTRANSPARENCYONOVERLAY(lPct: integer);
procedure OVERLAYLAYERTRANSPARENCYONOVERLAY(lOverlay,lPct: integer);
procedure OVERLAYLAYERTRANSPARENCYONBACKGROUND(lOverlay,lPct: integer);
procedure OVERLAYVISIBLE(lOverlay: integer; Visible: boolean);
procedure PERSPECTIVE (USEPERSPECTIVE: boolean);
procedure RADIOLOGICAL (FlipLR: boolean);
procedure RESETDEFAULTS;
procedure SAVEBMP(lFilename: string);
procedure SCRIPTFORMVISIBLE (VISIBLE: boolean);
procedure SETCOLORTABLE(TABLENUM: integer);
procedure SHADERFORMVISIBLE (VISIBLE: boolean);
procedure SHADERNAME(lFilename: string);
procedure SHADERADJUST(lProperty: string; lVal: single);
procedure SHADERLIGHTAZIMUTHELEVATION (AZI, ELEV: integer);
procedure SHADERQUALITY1TO10 (Q: integer);
procedure SHADERUPDATEGRADIENTS;
procedure SHARPEN;
procedure SLICETEXT (VISIBLE: boolean);
procedure TOOLFORMVISIBLE (VISIBLE: boolean);
procedure LOADWATERMARK(lFilename: string; lX,lY: integer);
procedure VIDEOSTART (lFilename: string; lFPS: integer; lDefaultCodec: boolean);
procedure VIDEOCAPTUREFRAME;
procedure VIDEOEND;
procedure VIEWAXIAL (STD: boolean);
procedure VIEWCORONAL (STD: boolean);
procedure VIEWSAGITTAL (STD: boolean);
procedure WAIT(MSEC: integer);
procedure XBARCOLOR (R,G,B: byte);
procedure XBARTHICK (PIXELS: integer);
procedure SETPREF (PREFNAME: string; PREFVAL: integer);
procedure QUIT;//new

type
  TScriptRec =  RECORD //peristimulus plot
    Ptr: Pointer;
    Decl,Vars: string[255];
  end;
const
  knFunc = 4;
  kFuncRA : array [1..knFunc] of TScriptRec =
    ( (Ptr:@EXISTS;Decl:'EXISTS';Vars:'(lFilename: string): boolean'),

    (Ptr:@OVERLAYLOAD;Decl:'OVERLAYLOAD';Vars:'(lFilename: string): integer'),
    (Ptr:@OVERLAYLOADCLUSTER;Decl:'OVERLAYLOADCLUSTER';Vars:'(lFilename: string; lThreshold, lClusterMM3: single; lSaveToDisk: boolean): integer'),

     (Ptr:@OVERLAYLOADVOL;Decl:'OVERLAYLOADVOL';Vars:'(lFilename: string; lVol: integer): integer'));
  knProc = 82;
  kProcRA : array [1..knProc] of TScriptRec =
    (
      (Ptr:@AZIMUTH;Decl:'AZIMUTH';Vars:'(DEG: integer)'),
      (Ptr:@AZIMUTHELEVATION;Decl:'AZIMUTHELEVATION';Vars:'(AZI, ELEV: integer)'),
      (Ptr:@BACKCOLOR;Decl:'BACKCOLOR';Vars:'(R, G, B: byte)'),
      (Ptr:@BMPZOOM;Decl:'BMPZOOM';Vars:'(Z: byte)'),
      (Ptr:@MODELESSCOLOR;Decl:'MODELESSCOLOR';Vars:'(R, G, B: byte)'),
      (Ptr:@CAMERADISTANCE;Decl:'CAMERADISTANCE';Vars:'(Z: single)'),
      (Ptr:@CHANGENODE;Decl:'CHANGENODE';Vars:'(INDEX, INTENSITY, R,G,B,A: byte)'),
      (Ptr:@CLIP;Decl:'CLIP';Vars:'(DEPTH: single)'),
      (Ptr:@CLIPAZIMUTHELEVATION;Decl:'CLIPAZIMUTHELEVATION';Vars:'(DEPTH,AZI,ELEV: single)'),
      (Ptr:@CLIPFORMVISIBLE;Decl:'CLIPFORMVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@COLORBARCOORD;Decl:'COLORBARCOORD';Vars:'(L,T,R,B: single)'),
      (Ptr:@COLORBARPOSITION;Decl:'COLORBARPOSITION';Vars:'(P: integer)'),
      (Ptr:@ADDNODE;Decl:'ADDNODE';Vars:'(INTENSITY, R,G,B,A: byte)'),
      (Ptr:@COLORBARFORMVISIBLE;Decl:'COLORBARFORMVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@COLORBARTEXT;Decl:'COLORBARTEXT';Vars:'(VISIBLE: boolean)'),
      (Ptr:@COLORBARVISIBLE;Decl:'COLORBARVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@COLORNAME;Decl:'COLORNAME';Vars:'(Filename: string)'),
      (Ptr:@CONTRASTFORMVISIBLE;Decl:'CONTRASTFORMVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@CONTRASTMINMAX;Decl:'CONTRASTMINMAX';Vars:'(MIN, MAX: single)'),
      (Ptr:@CUTOUT;Decl:'CUTOUT';Vars:'(L,A,S,R,P,I: single)'),
      (Ptr:@CUTOUTFORMVISIBLE;Decl:'CUTOUTFORMVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@EDGEDETECT;Decl:'EDGEDETECT';Vars:'(lThresh: single; lDilateCycles: integer)'),//new
      (Ptr:@EDGEENHANCE;Decl:'EDGEENHANCE';Vars:'(BIAS,GAIN: byte)'),//new
      (Ptr:@FONTNAME;Decl:'FONTNAME';Vars:'(name: string)'),
      (Ptr:@EDGEENHANCEFORMVISIBLE;Decl:'EDGEENHANCEFORMVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@EXTRACT;Decl:'EXTRACT';Vars:'(lOtsuLevels, lDilateVox: integer;  lOneContiguousObject: boolean)'),//procedure EXTRACT(lOtsuLevels, lDilateVox: integer; lOneContiguousObject: boolean);
      (Ptr:@MEDIANSMOOTH;Decl:'MEDIANSMOOTH';Vars:''),
      (Ptr:@DECIMATE;Decl:'DECIMATE';Vars:'(lPercent: integer)'),
      (Ptr:@ELEVATION;Decl:'ELEVATION';Vars:'(DEG: integer)'),
      (Ptr:@FRAMEVISIBLE;Decl:'FRAMEVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@LOADDRAWING;Decl:'LOADDRAWING';Vars:'(lFilename: string)'),
      (Ptr:@LOADDTI;Decl:'LOADDTI';Vars:'(lFAFilename: string)'),
      (Ptr:@LOADIMAGE;Decl:'LOADIMAGE';Vars:'(lFilename: string)'),
      (Ptr:@LOADIMAGEVOL;Decl:'LOADIMAGEVOL';Vars:'(lFilename: string; lVol: integer)'),
      (Ptr:@MAXIMUMINTENSITY;Decl:'MAXIMUMINTENSITY';Vars:'(MIP_ON: boolean)'),
      (Ptr:@MODALMESSAGE;Decl:'MODALMESSAGE';Vars:'(STR: string)'),
      (Ptr:@MODELESSMESSAGE;Decl:'MODELESSMESSAGE';Vars:'(STR: string)'),
      (Ptr:@MOSAIC;Decl:'MOSAIC';Vars:'(Str: string)'),
      (Ptr:@MOSAICFORMVISIBLE;Decl:'MOSAICFORMVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@ORTHOVIEW;Decl:'ORTHOVIEW';Vars:'(X,Y,Z: single)'),
      (Ptr:@ORTHOVIEWMM;Decl:'ORTHOVIEWMM';Vars:'(X,Y,Z: single)'),
      (Ptr:@OVERLAYCLOSEALL;Decl:'OVERLAYCLOSEALL';Vars:''),
      (Ptr:@OVERLAYCOLORNAME;Decl:'OVERLAYCOLORNAME';Vars:'(lOverlay: integer; lFilename: string)'),
      (Ptr:@OVERLAYCOLORNUMBER;Decl:'OVERLAYCOLORNUMBER';Vars:'(lOverlay, lLUTIndex: integer)'),
      (Ptr:@OVERLAYFORMVISIBLE;Decl:'OVERLAYFORMVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@OVERLAYLOADSMOOTH;Decl:'OVERLAYLOADSMOOTH';Vars:'(SMOOTH: boolean)'),
      (Ptr:@OVERLAYCOLORFROMZERO;Decl:'OVERLAYCOLORFROMZERO';Vars:'(FROMZERO: boolean)'),
      (Ptr:@OVERLAYHIDEZEROS;Decl:'OVERLAYHIDEZEROS';Vars:'(MASK: boolean)'), //new
      (Ptr:@OVERLAYMASKEDBYBACKGROUND;Decl:'OVERLAYMASKEDBYBACKGROUND';Vars:'(MASK: boolean)'), //new
      (Ptr:@OVERLAYMINMAX;Decl:'OVERLAYMINMAX';Vars:'(lOverlay: integer; lMin,lMax: single)'),
      (Ptr:@OVERLAYTRANSPARENCYONBACKGROUND;Decl:'OVERLAYTRANSPARENCYONBACKGROUND';Vars:'(lPct: integer)'),
      (Ptr:@OVERLAYLAYERTRANSPARENCYONOVERLAY;Decl:'OVERLAYLAYERTRANSPARENCYONOVERLAY';Vars:'(lOverlay,lPct: integer)'),
      (Ptr:@OVERLAYLAYERTRANSPARENCYONBACKGROUND;Decl:'OVERLAYLAYERTRANSPARENCYONBACKGROUND';Vars:'(lOverlay,lPct: integer)'),
      (Ptr:@OVERLAYTRANSPARENCYONOVERLAY;Decl:'OVERLAYTRANSPARENCYONOVERLAY';Vars:'(lPct: integer)'),
      (Ptr:@OVERLAYVISIBLE;Decl:'OVERLAYVISIBLE';Vars:'(lOverlay: integer; Visible: boolean)'),
      (Ptr:@PERSPECTIVE;Decl:'PERSPECTIVE';Vars:'(USEPERSPECTIVE: boolean)'),
      (Ptr:@RADIOLOGICAL;Decl:'RADIOLOGICAL';Vars:'(FlipLR: boolean)'),
      (Ptr:@RESETDEFAULTS;Decl:'RESETDEFAULTS';Vars:''),
      (Ptr:@SAVEBMP;Decl:'SAVEBMP';Vars:'(lFilename: string)'),
      (Ptr:@SCRIPTFORMVISIBLE;Decl:'SCRIPTFORMVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@SETCOLORTABLE;Decl:'SETCOLORTABLE';Vars:'(TABLENUM: integer)'),

      (Ptr:@SHADERFORMVISIBLE;Decl:'SHADERFORMVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@SHADERNAME;Decl:'SHADERNAME';Vars:'(lFilename: string)'),
      (Ptr:@SHADERADJUST;Decl:'SHADERADJUST';Vars:'(lProperty: string; lVal: single)'),
      (Ptr:@SHADERLIGHTAZIMUTHELEVATION;Decl:'SHADERLIGHTAZIMUTHELEVATION';Vars:'(AZI, ELEV: integer)'),
      (Ptr:@SHADERQUALITY1TO10;Decl:'SHADERQUALITY1TO10';Vars:'(Q: integer)'),
      (Ptr:@SHADERUPDATEGRADIENTS;Decl:'SHADERUPDATEGRADIENTS';Vars:''),
      (Ptr:@SHARPEN;Decl:'SHARPEN';Vars:''),
      (Ptr:@SLICETEXT;Decl:'SLICETEXT';Vars:'(VISIBLE: boolean)'),
      (Ptr:@TOOLFORMVISIBLE;Decl:'TOOLFORMVISIBLE';Vars:'(VISIBLE: boolean)'),
      (Ptr:@LOADWATERMARK;Decl:'LOADWATERMARK';Vars:'(lFilename: string; lX,lY: integer)'),
      (Ptr:@VIDEOSTART;Decl:'VIDEOSTART';Vars:'(lFilename: string; lFPS: integer; lDefaultCodec: boolean)'),
      (Ptr:@VIDEOCAPTUREFRAME;Decl:'VIDEOCAPTUREFRAME';Vars:''),
      (Ptr:@VIDEOEND;Decl:'VIDEOEND';Vars:''),
      (Ptr:@VIEWAXIAL;Decl:'VIEWAXIAL';Vars:'(STD: boolean)'),
      (Ptr:@VIEWCORONAL;Decl:'VIEWCORONAL';Vars:'(STD: boolean)'),
      (Ptr:@VIEWSAGITTAL;Decl:'VIEWSAGITTAL';Vars:'(STD: boolean)'),
      (Ptr:@WAIT;Decl:'WAIT';Vars:'(MSEC: integer)'),
      (Ptr:@XBARCOLOR;Decl:'XBARCOLOR';Vars:'(R, G, B: byte)'),
      (Ptr:@XBARTHICK;Decl:'XBARTHICK';Vars:'(PIXELS: integer)'),
       (Ptr:@QUIT;Decl:'QUIT';Vars:''),
       (Ptr:@SETPREF;Decl:'SETPREF';Vars:'(PREFNAME: string; PREFVAL: integer)')
    );

implementation
uses
    texture_3d_unit,mainunit,prefs,clut //userdir,
    {$IFDEF ENABLEEDGE}, edgeenhanceu {$ENDIF}
    {$IFDEF ENABLECOLORBAR},colorbar {$ENDIF}
  {$IFDEF ENABLESCRIPT}, scriptengine{$ENDIF};
{$IFDEF FPC}
var
  gAVIname : string = '';
  gAVIFrame : integer = 0;
{$ELSE} //if FPC else Delphi
  {$IFNDEF ENABLEAVI}
  var
    gAVIname : string = '';
    gAVIFrame : integer = 0;
  {$ENDIF} //if not enableAVE
{$ENDIF} //Delphi

procedure BMPZOOM(Z: byte);
begin
  if (Z > 10) or (Z < 1) then
     Z := 1;
  gPrefs.BitmapZoom := Z;
end;

procedure HaltScript;
begin
  ScriptForm.Memo2.Lines.Add('Script stopped due to errors.');
  ScriptForm.Stop1Click(nil);
end;

procedure FinishRender;
begin
    if GLForm1.UpdateTimer.Enabled then
       GLForm1.UpdateTimerTimer(nil);
    repeat
      application.ProcessMessages;
    until (not gRendering) {and  (not GLForm1.UpdateTimer.Enabled)};
end;


procedure view3D;
begin
  GLForm1.SelectSliceView (0);
  //if gPrefs.OrthoSliceView then
  //   GLForm1.Select2Dor3D(true);
end;


procedure WAIT (MSEC: integer);
var
  lEND : DWord;
 // var MemoryStatus: TMemoryStatus;
begin
//MemoryStatus.dwLength := SizeOf(MemoryStatus) ;
//  GlobalMemoryStatus(MemoryStatus) ;
//GLForm1.Caption := IntToStr(MemoryStatus.dwMemoryLoad) +' Available bytes in paging file';
  if MSEC < 0 then exit;
  lEND := GetTickCount+DWord(MSEC);
  FinishRender;//June 09
  if MSEC <= 0 then exit;
  repeat
    //Application.HandleMessage;
    Application.ProcessMessages;//HandleMessage
  until (GetTickCount >= lEnd);
end;

procedure ReRender(Recalc: boolean);
begin
  //This is a kludge, but PascalScript on OSX can switch off the refresh right after it has been turned on
  // and the timers can have problems with process messages. This techniques works, but an occasional frame may not
  // be drawn if there is a slow refresh in the pipeline.
  if Recalc then
     M_Refresh := true;
  GLForm1.UpdateGL;
end;


procedure view2D;
begin
//if not gPrefs.OrthoSliceView then
  GLForm1.SelectSliceView(4);
end;


procedure RESETDEFAULTS;
begin
  FinishRender;
  SetDefaultPrefs(gPrefs,false);
  GLForm1.ResetSliders;
  GLForm1.DisplayPrefs;
end;



function ChangeEnd (lInStr,lNewEnd: string): string;
// filename_FA,V1 will return Filename_V1
var
  lLenStr,lLenEnd,lI: integer;
begin
  result := '';
  lLenStr:= length(lInStr);
  lLenEnd := length(lNewEnd);
  if lLenStr < lLenEnd then
    exit;
  result := lInStr;
  if lLenEnd < 1 then
    exit;
  for lI := 1 to lLenEnd do
    result[lLenStr-lLenEnd+lI] := lNewEnd[lI];
end;

procedure LOADIMAGEVOL(lFilename: string; lVol: integer);
begin
  FinishRender;
  if not GLForm1.LoadDatasetNIFTIVol(lFileName,false,lVol) then
     MODELESSMESSAGE('Unable to load '+lFileName);
  FinishRender;
end;

procedure LOADIMAGE(lFilename: string);
begin
  FinishRender;
  if not GLForm1.LoadDatasetNIFTIvol1(lFileName,false) then
     MODELESSMESSAGE('Unable to load '+lFileName);
  FinishRender;
end;

procedure LOADDRAWING(lFilename: string);
begin
  FinishRender;
  if not GLForm1.OpenVOI(lFilename) then
     MODELESSMESSAGE('Unable to load drawing '+lFilename);
  FinishRender;
  //GLForm1.InterpolateDrawMenuClick(nil);
end;

procedure LOADDTI(lFAFilename: string);
var
  lPath,lName,lExt,lV1: string;
begin
  GLForm1.LoadDatasetNIFTIvol1(lFAFilename,false);
  FilenameParts (gPrefs.PrevFilename[1]{lFAFilename}, lPath,lName,lExt);
  lV1 := ChangeEnd (lPath+lName,'V1')+lExt;
  if not Fileexists(lV1) then
    MODELESSMESSAGE('Unable to find FSL vector named '+lV1);
  GLForm1.Addoverlay(lV1,1);
  GLForm1.Addoverlay(lV1,2);
  GLForm1.Addoverlay(lV1,3);
  AbsImgIntensity32(gOverlayImg[1] );
  AbsImgIntensity32(gOverlayImg[2] );
  AbsImgIntensity32(gOverlayImg[3] );
  GLForm1.UpdateImageIntensityMinMax (1, 0,1);
  GLForm1.UpdateImageIntensityMinMax (2, 0,1);
  GLForm1.UpdateImageIntensityMinMax (3, 0,1);
  OVERLAYTRANSPARENCYONBACKGROUND(-2);//modulate
  OVERLAYTRANSPARENCYONOVERLAY(-1);//additive
end;

procedure OVERLAYCLOSEALL;
begin
  GLForm1.Closeoverlays1Click(nil);
end;

procedure OVERLAYCOLORNUMBER(lOverlay,lLUTIndex: integer);
begin
  GLForm1.UpdateLUT(lOverlay,lLUTIndex,true);
  GLForm1.ChangeOverlayUpdate;
end;

procedure OVERLAYVISIBLE(lOverlay: integer; Visible: boolean);
begin
  GLForm1.OverlayVisible(lOverlay, Visible);
  GLForm1.ChangeOverlayUpdate;
end;


procedure OVERLAYCOLORNAME(lOverlay: integer; lFilename: string);
var
  lLUTIndex: integer;
begin
  SetItemNameX (lFilename, GLForm1.LUTDrop);
  lLUTIndex :=  GLForm1.LUTDrop.ItemIndex;
  GLForm1.UpdateLUT(lOverlay,lLUTIndex,true);
  GLForm1.ChangeOverlayUpdate;
end;

function EXISTS(lFilename: string): boolean;
begin
	 result := FileExists(lFilename);
end;

function OVERLAYLOAD(lFilename: string): integer;
begin
  FinishRender;
  result := GLForm1.AddOverlay(lFilename,1);
  if result=0 then HaltScript;
    FinishRender;
end;

function OVERLAYLOADVOL(lFilename: string; lVol: integer): integer;
begin
  FinishRender;
  result := GLForm1.AddOverlay(lFilename,lVol);
  FinishRender;
end;

function OVERLAYLOADCLUSTER(lFilename: string; lThreshold, lClusterMM3: single; lSaveToDisk: boolean): integer;
begin
  FinishRender;
  result := SaveThresholded(lFilename, lThreshold, lClusterMM3, lSaveToDisk);
  FinishRender;
end;

procedure OVERLAYMINMAX (lOverlay: integer; lMin,lMax: single);
begin
    FinishRender;
  GLForm1.UpdateImageIntensityMinMax (lOverlay, lMin,lMax);
    FinishRender;
end;


procedure OVERLAYTRANSPARENCYONBACKGROUND(lPct: integer);
begin
  //gPrefs.BackgroundAlpha := lPct;
  GLForm1.SetBackgroundAlphaValue (lPct);
  GLForm1.ChangeOverlayUpdate;
  GLForm1.SetSubmenuWithTag(GLForm1.Onbackground1,gPrefs.BackgroundAlpha);
end;

procedure OVERLAYLAYERTRANSPARENCYONBACKGROUND(lOverlay,lPct: integer);
begin
  GLForm1.SetBackgroundAlphaLayerValue(lOverlay, lPct);
  GLForm1.ChangeOverlayUpdate;
end;

procedure OVERLAYLAYERTRANSPARENCYONOVERLAY(lOverlay,lPct: integer);
begin
  GLForm1.SetOverlayAlphaLayerValue(lOverlay, lPct);
  GLForm1.ChangeOverlayUpdate;
end;

procedure OVERLAYTRANSPARENCYONOVERLAY(lPct: integer);
begin
  //gPrefs.OverlayAlpha := lPct;
  GLForm1.SetOverlayAlphaValue (lPct);
  GLForm1.ChangeOverlayUpdate;
  GLForm1.SetSubmenuWithTag(GLForm1.Onotheroverlays1,gPrefs.OverlayAlpha);
end;

procedure OVERLAYLOADSMOOTH (SMOOTH: boolean);
begin
  gPrefs.InterpolateOverlays := SMOOTH;
  GLForm1.InterpolateMenu.Checked := SMOOTH;
end;

procedure OVERLAYHIDEZEROS(MASK: boolean);
begin
    GLForm1.OverlayHideZerosMenu.Checked := MASK;
    GLForm1.OverlayColorFromZeroMenuClick(nil);
end;

procedure OVERLAYMASKEDBYBACKGROUND (MASK: boolean);
begin
    gPrefs.MaskOverlayWithBackground := Mask;
    GLForm1.BackgroundMaskMenu.Checked := Mask;
end;

procedure OVERLAYCOLORFROMZERO (FROMZERO: boolean);
begin
  gPrefs.OverlayColorFromZero := FROMZERO;
    GLForm1.OverlayColorFromZeroMenu.Checked := FROMZERO;
    GLForm1.OverlayColorFromZeroMenuClick(nil);
end;

procedure MOSAIC(Str: string);
begin
     GLForm1.SelectSliceView(5);
    GLForm1.DrawMosaic(Str);
end;

procedure MODALMESSAGE(STR: string);
begin
  showmessage(STR);
  //MESSAGEX(STR);
end;

procedure MODELESSCOLOR (R,G,B: byte);
begin
  gRayCast.ModelessColor := RGBA(R,G,B,255);
  ReRender(false);
end;

procedure MODELESSMESSAGE(STR: string);
begin
   ScriptForm.Memo2.Lines.Add(STR);
   ScriptForm.Refresh;
  ReRender(false);
end;

procedure SLICETEXT (VISIBLE: boolean);
begin
  gPrefs.SliceDetailsCubeAndText := VISIBLE;
  ReRender(false);
end;

procedure COLORBARTEXT (VISIBLE: boolean);
begin
  ScriptForm.Memo2.Lines.Add('COLORBARTEXT no longer suppoted');   //gPrefs.ColorBarText := VISIBLE;
  //ReRender(false);
end;

procedure COLORBARVISIBLE (VISIBLE: boolean);
begin
  gPrefs.ColorBar := VISIBLE;
    ReRender(false);
end;

procedure COLORBARPOSITION(P: integer);
begin
  gPrefs.ColorBarPosition:= P;
  GLForm1.SetColorBarPosition;
  ReRender(false);
end;

procedure COLORBARCOORD (L,T,R,B: single);
begin
  ScriptForm.Memo2.Lines.Add('COLORBARCOORD replaced with COLORBARPOSITION');
  //gPrefs.ColorBarPos:= CreateUnitRect (L,T,R,B);
  //SensibleUnitRect(gPrefs.ColorBarPos);
  ReRender(false);
end;

procedure SHARPEN;
begin
  SharpenTexture(gTexture3D);
  ReRender(true);
end;

procedure MEDIANSMOOTH;
begin
ScriptForm.Memo2.Lines.Add('MEDIANSMOOTH not supported in this version');
end;

procedure QUIT;
begin
     GLForm1.Close;
end;

procedure EDGEDETECT (lThresh: single; lDilateCycles: integer);
begin
ScriptForm.Memo2.Lines.Add('EDGEDETECT not supported - use overlay_glass shader instead');
end;

procedure EXTRACT(lOtsuLevels, lDilateVox: integer; lOneContiguousObject: boolean);
begin
  view3D;
     ExtractTexture (gTexture3D, lOtsuLevels, lDilateVox, lOneContiguousObject);
    ReRender(true);
end;


procedure EDGEENHANCE (BIAS,GAIN: byte);//new
begin
 ScriptForm.Memo2.Lines.Add('EDGEENHANCE not supported - use overlay_glass shader instead');

{$IFDEF ENABLEEDGE}
OBSOLETE CODE!!!!
view3D;
  if Bias = 0 then
    CloseEdgeEnhance(gTexture3D)
  else begin
    if gTexture3D.EdgeImg = nil then
      CubicEdge(gTexture3D,3);
  end;
    gTexture3D.EdgeBias := Bias;
    gTexture3D.EdgeGain := Gain;
  ReRender(true);
  {$ENDIF}
end;

procedure EDGEENHANCEFORMVISIBLE (VISIBLE: boolean);
begin
  {$IFDEF ENABLEEDGE}
  //GLForm1.AdjustFormPos(TFOrm(EdgeForm));
  //EdgeForm.visible := VISIBLE;
  ScriptForm.Memo2.Lines.Add('EDGEENHANCEFORMVISIBLE not supported in this version');
  {$ENDIF}
end;

procedure FONTNAME(name: string);
begin
     gPrefs.FontName:= name;
     GLForm1.UpdateFont(false);
end;

procedure DECIMATE (lPercent: integer);
begin
ScriptForm.Memo2.Lines.Add('DECIMATE not supported in this version');
end;

procedure OVERLAYFORMVISIBLE (VISIBLE: boolean);
begin
  //GLForm1.Overlays1Click(nil);
  //GLForm1.visible := VISIBLE;
end;

procedure SCRIPTFORMVISIBLE (VISIBLE: boolean);
begin
  {$IFDEF ENABLESCRIPT}
  GLForm1.Scripting1Click(nil);
  ScriptForm.visible := VISIBLE;
  {$ENDIF}
end;

procedure CONTRASTFORMVISIBLE (VISIBLE: boolean);
begin
  {$IFDEF ENABLECLUT}
  GLForm1.SelectShowColorEditor(VISIBLE);
  {$ENDIF}
end;

procedure COLORBARFORMVISIBLE (VISIBLE: boolean);
begin
 ScriptForm.Memo2.Lines.Add('COLORBARFORMVISIBLE not supported in this version');
  {$IFDEF ENABLECOLORBAR}
  {$ENDIF}
end;

procedure CUTOUTFORMVISIBLE (VISIBLE: boolean);
begin
  {$IFDEF ENABLECUTOUT}
  GLForm1.SelectShowTools(VISIBLE);
  {$ENDIF}
end;

procedure CLIPFORMVISIBLE (VISIBLE: boolean);
begin
  GLForm1.SelectShowTools(VISIBLE);
end;

procedure MOSAICFORMVISIBLE (VISIBLE: boolean);
begin
  //MosaicPrefsForm.visible := VISIBLE;
end;

procedure AZIMUTH (DEG: integer);
begin
     view3D;
     gRayCast.Azimuth := gRayCast.Azimuth+ DEG;
     while gRayCast.Azimuth < 0 do
      gRayCast.Azimuth := gRayCast.Azimuth + 360;
     ReRender(false);
end;

procedure ELEVATION (DEG: integer);
begin
     view3D;
     gRayCast.Elevation := gRayCast.Elevation -Deg;
     gRayCast.Elevation := Bound(gRayCast.Elevation,-90,90);
     ReRender(false);
end;

procedure AZIMUTHELEVATION (AZI, ELEV: integer);
begin
     view3D;
     gRayCast.Elevation := ELEV;
     gRayCast.Elevation := Bound(gRayCast.Elevation,-90,90);
     gRayCast.Azimuth := AZI;
     while gRayCast.Azimuth < 0 do
      gRayCast.Azimuth := gRayCast.Azimuth + 360;
     ReRender(false);
end;

procedure CAMERADISTANCE (Z: single);
begin
  view3D;
     gRayCast.Distance := Z*2.5;//fudge factor - texture slicing camera distance ~2.5 units
  if gRayCast.Distance > kMaxDistance then
     gRayCast.Distance := kMaxDistance;
  if gRayCast.Distance < 1 then
     gRayCast.Distance := 1.0;
     ReRender(false);
end;

procedure COLORNAME(Filename: string);
begin
{$IFDEF ENABLECLUT}
SetItemNameX (Filename, GLForm1.Scheme1);
{$ENDIF}
end;

procedure SETCOLORTABLE(TABLENUM: integer);
begin
{$IFDEF ENABLECLUT}
if (TABLENUM < 0) or (TABLENUM >= GLForm1.Scheme1.Count  ) then exit;
GLForm1.Scheme1.Items[TABLENUM].click;
{$ENDIF}
end;

procedure RenderUpdate;
begin
     ReRender(true);
end;

procedure CHANGENODE(INDEX, INTENSITY, R,G,B,A: byte);
var
  lNode,lI: integer;
begin
  lNode := INDEX;
  if lNode < 0 then
    lNode := 0;
  if (lNode > (gCLUTrec.numnodes-1)) or (INTENSITY = 255) then
    lNode := gCLUTrec.numnodes-1;

  lI := INTENSITY;
  //window spans from zero to 255, so bounding nodes must be in this range....
  if lNode = 0 then
    lI := 0;
  if lNode = (gCLUTrec.numnodes-1) then
    lI := 255;
  //we need to keep the nodes in order...
  if (lNode > 0) and (lI <= gCLUTrec.nodes[lNode-1].intensity) then
    lI := gCLUTrec.nodes[lNode-1].intensity + 1;
  if (lNode < (gCLUTrec.numnodes-1)) and (lI >= gCLUTrec.nodes[lNode+1].intensity) then
    lI := gCLUTrec.nodes[lNode-1].intensity - 1;
  gCLUTrec.nodes[lNode].intensity := lI;
  gCLUTrec.nodes[lNode].rgba := RGBA(R,G,B,A);
  //gCLUTrec.nodes[lNode] := node(lI, R,G,B,A); //<-1/2010 on x86-64, pascalscript requires previous two lines...
  RenderUpdate;
end;

procedure ADDNODE(INTENSITY, R,G,B,A: byte);
var
  lNode: integer;
begin
{$IFDEF ENABLECLUT}
  lNode := AddColorNode(Intensity);
  if lNode < 0 then
    exit;
  CHANGENODE(lNode, INTENSITY, R,G,B,A);
{$ENDIF}
end;

procedure CONTRASTMINMAX(MIN,MAX: single);
begin
  {$IFDEF ENABLECLUT}
  GLForm1.SelectIntensityMinMax(Min,Max);
  rerender(true);
   {$ENDIF}
end;

procedure CLIP (DEPTH: single);
begin
  view3D;
  GLForm1.ClipTrack.position := round(Depth * GLForm1.ClipTrack.Max);
end;

procedure CLIPAZIMUTHELEVATION (DEPTH,AZI,ELEV: single);
begin
  view3D;
    GLForm1.ClipTrack.position := round(Depth * GLForm1.ClipTrack.Max);
      GLForm1.AziTrack1.position := round(Azi);
      GLForm1.ElevTrack1.position := round(Elev);
    //  rerender(false);
    //GLForm1.SetViewerClipPlaneAE (round(Depth * ClipForm.ClipTrack.Max),round(AZI),round(Elev));
end;



procedure ORTHOVIEWMM (X,Y,Z: single);
begin
  MMToFrac(X,Y,Z);
  gRayCast.OrthoX := X;
  gRayCast.OrthoY := Y;
  gRayCast.OrthoZ := Z;
 GLForm1.SelectSliceView(4);
   ReRender(false);
end;

procedure ORTHOVIEW (X,Y,Z: single);
begin
  gRayCast.OrthoX := X;
  gRayCast.OrthoY := Y;
  gRayCast.OrthoZ := Z;
 GLForm1.SelectSliceView(4);
   ReRender(false);
end;

  {$IFDEF ENABLERAYCAST}
procedure Color2RGB (Color : TColor; var r,g,b: single);
begin
  r := (Color and $ff)/$ff;
  g := ((Color and $ff00) shr 8)/$ff;
  b := ((Color and $ff0000) shr 16)/$ff;
end;
  {$ENDIF}

procedure BACKCOLOR (R,G,B: byte);
begin
  gPrefs.BackColor :=RGBA(R,G,B,0); //2014

  ReRender(false);
end;

procedure CUTOUT (L,A,S,R,P,I: single);
var
  lMax: integer;
begin
    view3D;
    {$IFDEF ENABLECUTOUT}
  lMax := GLForm1.XTrackBar.Max;
  GLForm1.XTrackBar.Position := round(L*lMax);
  GLForm1.X2TrackBar.Position := round(R*lMax);
  GLForm1.YTrackBar.Position := round(A*lMax);
  GLForm1.Y2TrackBar.Position := round(P*lMax);
  GLForm1.ZTrackBar.Position := round(S*lMax);
  GLForm1.Z2TrackBar.Position := round(I*lMax);
      // deleteGradients(gTexture3D);
  ReRender(true);
  //if gPrefs.FasterGradientCalculations then
  //   GLForm1.GradientsIdleTimerReset;

  {$ENDIF}
end;

procedure MAXIMUMINTENSITY (MIP_ON: boolean);
begin
    view3D;
  if MIP_ON then
    SetShaderAndDrop('mip')
  else
    SetShaderAndDrop(GLForm1.ShaderDrop.Items[0]);
end;

procedure VIEWAXIAL (STD: boolean);
begin
    view3D;
  if STD then
    AZIMUTHELEVATION(0,90)
  else
    AZIMUTHELEVATION(180,-90);
  ReRender(false);;
end;

procedure VIEWCORONAL (STD: boolean);
begin
    view3D;
  if STD then
    AZIMUTHELEVATION(0,0)
  else
    AZIMUTHELEVATION(180,0);
  ReRender(false);;
end;

procedure VIEWSAGITTAL (STD: boolean);
begin
    view3D;
  if STD then
    AZIMUTHELEVATION(90,0)
  else
    AZIMUTHELEVATION(270,0);
  ReRender(false);
end;

procedure PERSPECTIVE (USEPERSPECTIVE: boolean);
begin
    view3D;
  gPrefs.Perspective := USEPERSPECTIVE;
  ReRender(false);

  //GLForm1.PerspectiveMenu.checked := USEPERSPECTIVE;
  //GLForm1.PerspectiveMenuClick(nil);
end;

procedure RADIOLOGICAL (FlipLR: boolean);//lPrefs.FlipLR
begin
     gPrefs.FlipLR:= FlipLR;
     GLForm1.RadiologicalMenu.Checked := gPrefs.FlipLR;
     GLForm1.DisplayRadiological;
  ReRender(false);
end;

procedure FRAMEVISIBLE (VISIBLE: boolean);
begin
    view3D;
  GLForm1.SelectCube(VISIBLE);
end;

procedure LOADWATERMARK(lFilename: string; lX,lY: integer);
//LOADWATERMARK('C:\pas\mricrogl\source\watermark.bmp',72,290);
{$IFDEF ENABLEWATERMARK}
var  lFilenameX:string;
begin
   lFilenameX := lFilename;
   if lFilenameX = '' then begin
    gWatermark.X := 0;
    ReRender(false);
    exit;
   end;
   GLForm1.CheckFilename (lFilenameX,true);
   if not fileexists(lFilenameX) then begin
    ScriptForm.Memo2.Lines.Add('LOADWATERMARK Can''t find '+lFilenameX);
    exit;
   end;
  gWatermark.filename := lFilenameX;
  gWatermark.X := lX;
  gWatermark.Y := lY;
ReRender(false);
end;
{$ELSE}
begin
  ScriptForm.Memo2.Lines.Add('LOADWATERMARK not supported');
end;

{$ENDIF}

procedure SHADERNAME(lFilename: string);
begin
  FinishRender;
  {$IFDEF ENABLESHADER}
SetShaderAndDrop(lFilename);
  {$ENDIF}
    FinishRender;
end;

procedure SHADERFORMVISIBLE (VISIBLE: boolean);
begin
  GLForm1.SelectShowTools(VISIBLE);
end;

procedure SHADERLIGHTAZIMUTHELEVATION (AZI, ELEV: integer);
begin
  {$IFDEF ENABLESHADER}
   GLForm1.LightElevTrack.Position := Elev;
   GLForm1.LightAziTrack.Position := Azi;
   GLForm1.AziElevChange(nil);
  {$ENDIF}
end;

procedure SHADERUPDATEGRADIENTS;
begin
  {$IFDEF ENABLESHADER}
  FinishRender;
  //gTexture3D.HasGradientsx := false;
  //deleteGradients(gTexture3D);
  ReRender(true);
  {$ENDIF}
end;

procedure SHADERQUALITY1TO10 (Q: integer);
begin
  {$IFDEF ENABLESHADER}
  GLFOrm1.QualityTrack.position := Q;
  GLForm1.QualityTrackChange(nil);
  {$ENDIF}
end;

procedure SHADERADJUST(lProperty: string; lVal: single);
begin
  {$IFDEF ENABLESHADER}
    FinishRender;
  SetShaderAdjust(lProperty,lVal);
  {$ENDIF}
end;

procedure TOOLFORMVISIBLE (VISIBLE: boolean);
begin
  GLForm1.SelectShowTools(VISIBLE);
end;

procedure SETPREF (PREFNAME: string; PREFVAL: integer);
begin
  //

end;

procedure VIDEOSTART (lFilename: string; lFPS: integer; lDefaultCodec: boolean);
begin
  VIDEOEND;//save any previous recording
     gAVIname := lFilename;
   gAVIFrame := 0;

end;

procedure VIDEOCAPTUREFRAME;
var
  lFrame: integer;
  lExt,lF: string;
begin
 if (gAVIname = '') then
  exit;
 lF := gAVIname;
 inc(gAVIFrame);
 lFrame := gAVIFrame;
 lExt := UpCaseExt(lF);
 if (lExt <> '.JPG') and (lExt <> '.PNG')  then
        lF := lF + '.png';
 EnsureDirExists(lF);
 lF := ChangeFilePostfix(lF,PadStr(lFrame,4));
 FinishRender;
  GLForm1.SavePicture(lF);
 end;

procedure VIDEOEND;
begin
  {$IFDEF FPC}
   gAVIname := '';
  {$ELSE} //if FPC ELSE Delphi
  {$IFDEF ENABLEAVI}

  if GLForm1.AVIRecorder1.FPS = 0 then begin //save still images as PNG/JPG...
    GLForm1.AVIRecorder1.Filename := '';
    GLForm1.AVIRecorder1.Tag := 0;
    exit;
  end;
  if not GLForm1.AVIRecorder1.Recording then begin
    GLForm1.AVIRecorder1.Tag := 0;
    exit;
  end;
  if GLForm1.AVIRecorder1.Tag < 1 then //no video
    GLForm1.AVIRecorder1.CloseAVIFile(true{UserAbort})
  else
    GLForm1.AVIRecorder1.CloseAVIFile(false{UserAbort});
  GLForm1.AVIRecorder1.Tag := 0;
  {$ELSE}
   gAVIname := '';
  {$ENDIF}
 {$ENDIF}
end;

procedure SAVENII(lFilename: string);
begin
  //SaveImg (lFilename, gTexture3D.NIFTIhdr, bytep(gTexture3D.FiltImg));
end;

procedure SAVEBMP(lFilename: string);
var
  lF,lExt: string;
begin
  FinishRender;
  lF := lFilename;
  lExt := UpCaseExt(lF);
  if (lExt <> '.JPG') and (lExt <> '.PNG')  then
        lF := lF + '.png';
  EnsureDirExists(lF);
  GLForm1.SavePicture(lF);
end;


procedure XBARTHICK (PIXELS: integer);
begin
  gPrefs.CrosshairThick:= PIXELS;
  ReRender(false);
end;

procedure XBARCOLOR (R,G,B: byte);
begin
  gPrefs.CrosshairColor :=RGBA(R,G,B,255);
  ReRender(false);
end;

end.

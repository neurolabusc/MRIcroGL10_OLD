unit mainunit;
{$IFDEF FPC}{$H+}{$mode delphi}   {$ENDIF}
{$D-,O+,Q-,R-,S-}
{$include opts.inc}
interface
//{$IFDEF FPC}
{$DEFINE COMPILEYOKE}
//{$ENDIF}

{$IFDEF LCLcarbon}
 This program does not support Carbon
  Please choose Project/ProjectOptions, go to the CompilerOptions/Additions&Overrides and set the BuildMode pull-down to "MacOS"
{$ENDIF}
uses

{$IFDEF COMPILEYOKE}
yokesharemem, coordinates, nii_mat, math, nifti_tiff,
{$ENDIF}
{$IFDEF DGL} dglOpenGL, {$ELSE DGL} {$IFDEF COREGL}glcorearb, {$ELSE} gl,glext, {$ENDIF}  {$ENDIF DGL}
types,clipbrd,
{$IFNDEF FPC}
  messages,ShellAPI, detectmsaa,{$IFDEF PNG}pngimage, JPEG,{$ENDIF}
{$ENDIF}Dialogs, ExtCtrls, Menus,  shaderu, texture2raycast,
  StdCtrls, Controls, ComCtrls, Reslice, glcube,glclrbar,
{$IFDEF USETRANSFERTEXTURE}texture_3d_unit_transfertexture, {$ELSE} texture_3d_unit,extract,{$ENDIF}
  {$IFDEF FPC}  FileUtil, GraphType, LCLProc,LCLtype,  LCLIntf,LResources,OpenGLContext,{$ELSE}glpanel, {$ENDIF}
{$IFDEF UNIX}Process, strutils, fphttpclient,
{$ELSE}//ShellApi,
Windows,{$IFDEF FPC}uscaledpi,{$ENDIF}{$ENDIF} glmtext,
  Graphics, Classes, SysUtils, Forms, Buttons, Spin, Grids, clut, define_types,
  histogram2d, readint, {$IFDEF COREGL} raycast_core, {$ELSE} raycast_legacy, {$ENDIF} raycast_common, histogram, nifti_hdr, shaderui,
  prefs, userdir, slices2d,  autoroi, fsl_calls, drawU, dcm2nii, lut,
  extractui, scaleimageintensity;

  {$IFNDEF FPC}
  //WARNING DELPHI USER: YOU NEED TO COMMENT OUT THE LINE "GLBox:TOpenGLControl;"
    {$ENDIF}
type { TGLForm1 }
TGLForm1 = class(TForm)
    ReorientMenu: TMenuItem;
    RadiologicalMenu: TMenuItem;
    ClrbarMenu: TMenuItem;
    WhiteClrbarMenu: TMenuItem;
    TransWhiteClrbarMenu: TMenuItem;
    BlackClrbarMenu: TMenuItem;
    TransBlackClrbarMenu: TMenuItem;
    Label1: TLabel;
    Label2: TLabel;
    LightAziTrack: TTrackBar;
    LightElevTrack: TTrackBar;
    ConvertForeign1: TMenuItem;
    InterpolateRecentMenu: TMenuItem;
    InterpolateAxialMenu: TMenuItem;
    InterpolateCoronalMenu: TMenuItem;
    InterpolateSagittalMenu: TMenuItem;
    ShaderPanel: TPanel;
    QualityTrack: TTrackBar;
    S10Check: TCheckBox;
    S10Label: TLabel;
    S10Track: TTrackBar;
    S1Check: TCheckBox;
    S1Label: TLabel;
    S1Track: TTrackBar;
    S2Check: TCheckBox;
    S2Label: TLabel;
    S2Track: TTrackBar;
    S3Check: TCheckBox;
    S3Label: TLabel;
    S3Track: TTrackBar;
    S4Check: TCheckBox;
    S4Label: TLabel;
    S4Track: TTrackBar;
    S5Check: TCheckBox;
    S5Label: TLabel;
    S5Track: TTrackBar;
    S6Check: TCheckBox;
    S6Label: TLabel;
    S6Track: TTrackBar;
    S7Check: TCheckBox;
    S7Label: TLabel;
    S7Track: TTrackBar;
    S8Check: TCheckBox;
    S8Label: TLabel;
    S8Track: TTrackBar;
    S9Check: TCheckBox;
    S9Label: TLabel;
    ColEdit: TSpinEdit;
    ColOverlap: TTrackBar;
    CopyScriptBtn: TButton;
    CrossCheck: TCheckBox;
    Label3: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    LabelCheck: TCheckBox;
    MosaicText: TMemo;
    OrientDrop: TComboBox;
    MosaicPanel: TPanel;
    RowEdit: TSpinEdit;
    RowOverlap: TTrackBar;
    RunScriptBtn: TButton;
    S9Track: TTrackBar;
    ShaderDrop: TComboBox;
    Slice2DBox: TGroupBox;
    InterpolateDrawMenu: TMenuItem;
    LeftBtn: TSpeedButton;
    AnteriorBtn: TSpeedButton;
    PosteriorBtn: TSpeedButton;
    RightBtn: TSpeedButton;
    SuperiorBtn: TSpeedButton;
    InferiorBtn: TSpeedButton;
    voiBinarize1: TMenuItem;
    NearBtn: TButton;
  LUTdrop: TComboBox;
  Addoverlay1: TMenuItem;
  InterpolateMenu: TMenuItem;
  Additive1: TMenuItem;
  NoneBtn: TButton;
  OverlayHideZerosMenu: TMenuItem;
  N100transparent2: TMenuItem;
  N802: TMenuItem;
  N602: TMenuItem;
  N502: TMenuItem;
  N402: TMenuItem;
  N202: TMenuItem;
  N0opaque2: TMenuItem;
  ModulateMenu: TMenuItem;
  N100transparent1: TMenuItem;
  N801: TMenuItem;
  N601: TMenuItem;
  N501: TMenuItem;
  N401: TMenuItem;
  N201: TMenuItem;
  N0Opaque1: TMenuItem;
  OverlayColorFromZeroMenu: TMenuItem;
  BackgroundMaskMenu: TMenuItem;
  Onbackground1: TMenuItem;
    Onotheroverlays1: TMenuItem;
  Additive2: TMenuItem;
  //Thresholdmenu: TMenuItem;
  Closeoverlays1: TMenuItem;
  Overlays1: TMenuItem;
  OverlayBox: TGroupBox;
  HideRenderToolsBtn: TButton;
  Extract1: TMenuItem;
  BET1: TMenuItem;
  MosaicBox: TGroupBox;
  Import1: TMenuItem;
  ConvertDicom1: TMenuItem;
  MRU8: TMenuItem;
  MRU10: TMenuItem;
  MRU9: TMenuItem;
  MRU7: TMenuItem;
  MRU4: TMenuItem;
  MRU6: TMenuItem;
  MRU5: TMenuItem;
  MRU3: TMenuItem;
  MRU2: TMenuItem;
  MRU1: TMenuItem;
  StringGrid1: TStringGrid;
  ToolPanel: TPanel;
  ClipBox: TGroupBox;
  Label4: TLabel;
  Label5: TLabel;
  Label6: TLabel;
  ClipTrack: TTrackBar;
  AziTrack1: TTrackBar;
  ElevTrack1: TTrackBar;
  ShaderBox: TGroupBox;
  ShaderMemo: TMemo;
  IntensityBox: TGroupBox;
  MinEdit: TEdit;
  MaxEdit: TEdit;
  CutoutBox: TGroupBox;
  Xx: TLabel;
  XTrackBar: TTrackBar;
  X2TrackBar: TTrackBar;
  yY: TLabel;
  YTrackBar: TTrackBar;
  Y2TrackBar: TTrackBar;
  zZ: TLabel;
  ZTrackBar: TTrackBar;
  Z2TrackBar: TTrackBar;
  MainMenu1: TMainMenu;
  File1: TMenuItem;
  AppleMenu: TMenuItem;
  AppleAbout: TMenuItem;
  Open1: TMenuItem;
  Save1: TMenuItem;
  Exit1: TMenuItem;
  MenuSep1: TMenuItem;
  Edit1: TMenuItem;
  Copy1: TMenuItem;
  View1: TMenuItem;
  Tool1: TMenuItem;
  Orient1: TMenuItem;
  Scripting1: TMenuItem;
  Colors1: TMenuItem;
  Scheme1: TMenuItem;
  ToggleTransparency1: TMenuItem;
  Backcolor1: TMenuItem;
  Help1: TMenuItem;
  About1: TMenuItem;
  OpenDialog1: TOpenDialog;
  ColorDialog1: TColorDialog;
  UpdateTimer: TTimer;
  SaveDialog1: TSaveDialog;
  AutoRunTimer1: TTimer;
    GradientsIdleTimer: TTimer;
    Draw1: TMenuItem;
    OpenVOI1: TMenuItem;
    SaveVOI1: TMenuItem;
    CloseVOI1: TMenuItem;
    UndoVOI1: TMenuItem;
    Transparency1: TMenuItem;
    HideVOI1: TMenuItem;
    TransparencyVOIhi: TMenuItem;
    TransparencyVOImid: TMenuItem;
    TransparencyVOIlo: TMenuItem;
    DrawTool1: TMenuItem;
    NoDraw1: TMenuItem;
    Eraser1: TMenuItem;
    Advanced1: TMenuItem;
    OverwriteDrawColor1: TMenuItem;
    PasteSlice1: TMenuItem;
    CustomDrawColors1: TMenuItem;
    Smooth1: TMenuItem;
    Display1: TMenuItem;
    Render1: TMenuItem;
    Sagittal1: TMenuItem;
    Coronal1: TMenuItem;
    Axial1: TMenuItem;
    MPR1: TMenuItem;
    SaveDialogVoi: TSaveDialog;
    OpenDialogVoi: TOpenDialog;
    OpenDialogTxt: TOpenDialog;
    Mosaic1: TMenuItem;
    AutoRoi1: TMenuItem;
    NewWindow1: TMenuItem;
    ErrorTimer: TTimer;
    Sharpen1: TMenuItem;
    ApplePreferences: TMenuItem;
    Preferences1: TMenuItem;
    YokeSepMenu: TMenuItem;
    YokeMenu: TMenuItem;
    YokeTimer: TTimer;
    CollapsedToolPanel: TPanel;
    CollapseToolPanelBtn: TButton;
    Thresholdmenu: TMenuItem;
    ViewSepMenu: TMenuItem;
    LeftMenu: TMenuItem;
    RightMenu: TMenuItem;
    PosteriorMenu: TMenuItem;
    AnteriorMenu: TMenuItem;
    InferiorMenu: TMenuItem;
    SuperiorMenu: TMenuItem;
    voiDescriptives1: TMenuItem;
    VisibleClrbarMenu: TMenuItem;
    ClrbarSep: TMenuItem;
    procedure ConvertForeign1Click(Sender: TObject);
    procedure FormChangeBounds(Sender: TObject);
    procedure InterpolateDrawMenuClick(Sender: TObject);
    function OpenVOI(lFilename: string): boolean;
    procedure BackgroundMaskMenuClick(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure FormShow(Sender: TObject);
    procedure InterpolateMenuClick(Sender: TObject);
    procedure LUTdropChange(Sender: TObject);
    procedure OrientBtnClick(Sender: TObject);
    procedure OrientClick(lOrient: integer);
    procedure OrientMenuClick(Sender: TObject);
    procedure RadiologicalMenuClick(Sender: TObject);
    procedure ReorientMenuClick(Sender: TObject);
    procedure SetOverlayAlpha(Sender: TObject);
    //procedure StringGridSetCaption(aRow: integer);
    procedure StringGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure ThresholdMenuClick(Sender: TObject);
    procedure UpdateOverlaySpread;
    procedure UpdateFont(initialSetup: boolean);
    procedure DemoteOrder(lRow: integer);
    procedure ReadCell (ACol,ARow: integer; Update: boolean);
    procedure RecompileShader(oldQ, newQ: integer);
    procedure BlendOverlaysRGBA (var lTexture: TTexture);
    procedure OverlayIdleTimerReset;
    function  OverlayIntensityString(Voxel: integer): string;
    procedure OverlayColorFromZeroMenuClick(Sender: TObject);
    procedure SetBackgroundAlpha(Sender: TObject);
    procedure SetOverlayAlphaValue(NewValue: integer);
    procedure SetOverlayAlphaLayerValue(Layer, NewValue: integer);
    procedure SetBackgroundAlphaLayerValue(Layer, NewValue: integer);
    procedure SetSubmenuWithTag (var lRootMenu: TMenuItem; lTag: Integer);
    procedure SetBackgroundAlphaValue(NewValue: integer);
    procedure OverlayVisible(lOverlay: integer; lVisible: boolean);
    procedure ChangeOverlayUpdate;
    function Addoverlay(lFilename: string; lVolume: integer): integer;
    procedure Closeoverlays1Click(Sender: TObject);
    procedure StringGrid1Exit(Sender: TObject);
    procedure StringGrid1KeyPress(Sender: TObject; var Key: char);
    procedure StringGrid1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure StringGrid1SelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure UpdateImageIntensity (lOverlay: integer);
    procedure UpdateImageIntensityMinMax (lOverlay: integer; lMinIn,lMaxIn: double);
    procedure UpdateOverlaySpreadI (lIndex: integer);
    procedure UpdateLUT(lOverlay,lLUTIndex: integer; lChangeDrop: boolean);
    procedure Addoverlay1Click(Sender: TObject);
    //function Addoverlay(lFilename: string; lVolume: integer): integer;
    procedure CollapsedToolPanelClick(Sender: TObject);
    procedure HideRenderToolsBtnClick(Sender: TObject);
    procedure CopyScriptClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure RunScriptClick(Sender: TObject);
    procedure SetToolPanelWidth;
    procedure NewWindow1Click(Sender: TObject);
    procedure Preferences1Click(Sender: TObject);
    function ScreenShot(Zoom: integer): TBitmap;
    procedure AutoDetectVOI;
    procedure AutoRoi1Click(Sender: TObject);
    procedure ConvertDicom1Click(Sender: TObject);
    procedure CustomDrawColors1Click(Sender: TObject);
    procedure ErrorTimerTimer(Sender: TObject);
    procedure Sharpen1Click(Sender: TObject);
    procedure  ShowmessageError(Str:string);
    procedure LoadDraw;
    function MouseMoveVOI (X, Y: Integer): boolean;
function MouseUpVOI (Shift: TShiftState; X, Y: Integer): boolean;
    function MouseDownVOI (Shift: TShiftState; X, Y: Integer): boolean;
  procedure CloseVOI1Click(Sender: TObject);
  procedure Extract1Click(Sender: TObject);
  procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure BET1Click(Sender: TObject);
  procedure GradientsIdleTimerTimer(Sender: TObject);
  procedure SetColorBarPosition;
  procedure Label4Click(Sender: TObject);
  procedure Label5Click(Sender: TObject);
  procedure Label6Click(Sender: TObject);
  procedure DrawTool1Click(Sender: TObject);
  procedure MinMaxEditExit(Sender: TObject);
  procedure OpenVOI1Click(Sender: TObject);
  procedure PasteSlice1Click(Sender: TObject);
  procedure SetViewClick(Sender: TObject);
  procedure ResetSliders;
  procedure OrthoClick(X,Y: integer);
  procedure SaveVOI1Click(Sender: TObject);
  procedure ShowOrthoSliceInfo (isYoke: boolean);
  procedure Quit2TextEditor;
  function GLBoxBackingWidth: integer;
  function GLBoxBackingHeight: integer;
    procedure ClipTrackChange(Sender: TObject);
    procedure AppDropFiles(Sender: TObject; const FileNames: array of String);
    procedure OpenColorScheme(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure Smooth1Click(Sender: TObject);
    procedure ToolPanelClick(Sender: TObject);
    procedure UpdateContrast (Xa,Ya, Xb, Yb: integer);
    procedure GLboxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; lX, lY: Integer);
    procedure GLboxMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure Backcolor1Click(Sender: TObject);
    procedure Orient1Click(Sender: TObject);
    procedure LoadStartupImage;
    procedure ShaderBoxResize(Sender: TObject);
    procedure Tool1Click(Sender: TObject);
    procedure TransparencyVOIClick(Sender: TObject);
    procedure UndoVOI1Click(Sender: TObject);
    procedure UniformChange(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure ExitButton1Click(Sender: TObject);
    procedure CheckForUpdates(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OverlayBoxCreate;
    procedure UpdateClrbar;
    procedure ClrbarClr(i: integer);
    procedure ClrbarMenuClick(Sender: TObject);
    procedure DrawClrbar (lScrnWid, lScrnHt, zoom, zoomOffsetX, zoomOffsetY: integer; ClrbarSizeFracX: single);
    procedure DrawCube (lScrnWid, lScrnHt, zoom, zoomOffsetX, zoomOffsetY: integer);
    procedure TextArrow (X,Y,Sz: single; NumStr: string; orient: integer;FontColor,ArrowColor: TGLRGBQuad);

    procedure GLboxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; lX, lY: Integer);
    procedure GLboxMouseMove(Sender: TObject; Shift: TShiftState; lX, lY: Integer);
        procedure GLboxDblClick(Sender: TObject);
    procedure OpenMRU(Sender: TObject);//open template or MRU
    function LoadDatasetNIFTIvolx(lFilename: string; lStopScript: boolean): boolean;
    procedure   TerminateRendering;
    procedure UpdateMosaic(Sender: TObject);
    procedure UpdateMRU;//most-recently-used menu
    function LoadDatasetNIFTIvol(lFilename: string; lStopScript: boolean; lVolume: integer): boolean;
    procedure AdjustFormPos (var lForm: TForm);
    procedure GLboxPaint(Sender: TObject);
    procedure GLboxResize(Sender: TObject);
    procedure ClrbarMenu1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    //procedure FormResize(Sender: TObject);
    procedure AziElevChange(Sender: TObject);
    procedure QualityTrackChange(Sender: TObject);
    procedure ShaderDropChange(Sender: TObject);
    procedure UpdateTimerTimer(Sender: TObject);
    procedure ToggleTransparency1Click(Sender: TObject);
    function CheckFilename (var lFilenameX: string; lBitmap: boolean): boolean;
    procedure FormClose(Sender: TObject; var TheAction: TCloseAction);
    procedure HideBtnClick(Sender: TObject);
    procedure CutoutNearestSector(Sender: TObject);
    procedure CutoutChange(Sender: TObject);
    procedure MinMaxEditKeyPress(Sender: TObject; var Key: Char);
    procedure MinMaxEditKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Overlays1Click(Sender: TObject);
    function loadLabelsITK(fnm: string): boolean;
    procedure  loadLabelsDefault;
    procedure Mosaic1Click(Sender: TObject);
    procedure DrawMosaic(Str: string);
    procedure SelectSliceView(lView: integer);
    procedure SelectShowColorEditor(lShow: boolean);
    function LoadDatasetNIFTIvol1(lFilename: string; lStopScript: boolean): boolean;
    procedure SelectShowTools(lShow: boolean);
    procedure SelectIntensityMinMax(lMin,lMax: single);
    procedure SelectCube(lShow: boolean);
    procedure StopTimers;
    procedure Scripting1Click(Sender: TObject);
    procedure SetFormSize(FormWidth,FormHeight: integer);
    procedure Copy1Click(Sender: TObject);
    procedure SavePicture (lFilename: string);
    procedure Save1Click(Sender: TObject);
    procedure DisplayRadiological;
    procedure DisplayPrefs;
    procedure StopScripts;
    procedure AutoRunTimer1Timer(Sender: TObject);
    procedure UpdateGL;
    procedure GradientsIdleTimerReset;
    procedure voiBinarize1Click(Sender: TObject);
    procedure voiDescriptives1Click(Sender: TObject);
    procedure YokeMenuClick(Sender: TObject);
    procedure YokeTimerTimer(Sender: TObject);
    procedure ClearText(ScrnWid, lScrnHt: integer);
    procedure DrawText(lScrnWid, lScrnHt, zoom, zoomOffsetX, zoomOffsetY: integer);
    {$IFDEF LCLCocoa} procedure SetRetina; {$ENDIF}
  private
    {$IFNDEF FPC}    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES; {$ENDIF}
  public
    { public declarations }
    M_reload: integer;
  end;
const
 //kCloseVOI_reload = -1;
 //kOpenBlankVOI_reload = -2;
 kOpenExistingVOI_reload = -3;
const
  kMinOverlayIndex = 1;
  kMaxOverlays = 32;
var
  M_refresh: boolean;
  GLForm1: TGLForm1;
  gPrefs: TPrefs;
  gTexture3D: TTexture;
  gRendering: boolean = false;
  gInitialSetup: boolean = true;
  gOpenOverlays : integer = 0;
  gOverlayImg : array [kMinOverlayIndex..kMaxOverlays] of TMRIcroHdr;
  gTypeInCell: boolean = false;
    gEnterCell: boolean = false;
  gOverlayCLUTrec : array [kMinOverlayIndex..kMaxOverlays] of TCLUTrec;
  gOverlayAlpha : array [kMinOverlayIndex..kMaxOverlays] of integer;
  gBackgroundAlpha : array [kMinOverlayIndex..kMaxOverlays] of integer;
  gPrevCol: integer = 0;
  gPrevRow: integer = 0;
  gRetinaScale: single = 1;
  gCube : TGLCube;
  gClrbar: TGLClrbar;
  gText: TGLText;

implementation

{$IFDEF ENABLEOVERLAY} uses {$IFDEF LCLCocoa}glcocoanscontext,{$ENDIF} nifti_types, savethreshold, nii_reslice {$IFDEF ENABLESCRIPT}, scriptengine{$ENDIF};{$ENDIF}
{$IFDEF FPC} {$R *.lfm}   {$ENDIF}
{$IFNDEF FPC} {$R *.dfm} {$ENDIF}
var
  MouseStartPt, MousePt: TPoint;
  //gnClrbar: integer;
  gFontSz, gFontPx: single;
{$IFDEF FPC}
GLBox:TOpenGLControl;
{$ELSE}
GLbox : TGLPanel;
{$ENDIF}

procedure TGLForm1.ClearText(ScrnWid, lScrnHt: integer);
const
  sizeFrac = 0.035;
begin
     if ScrnWid < lScrnHt then
        gFontSz := round(ScrnWid * sizeFrac)
     else
         gFontSz := round(lScrnHt * sizeFrac);
     gFontPx := gFontSz;
     gFontSz := gFontSz/gText.BaseHeight;
     gText.ClearText;
     gText.TextColor(255,128,128);
end;


procedure TGLForm1.TextArrow (X,Y,Sz: single; NumStr: string; orient: integer;FontColor,ArrowColor: TGLRGBQuad);
begin
     if (gPrefs.BackColor.rgbRed = FontColor.rgbRed) and (gPrefs.BackColor.rgbGreen = FontColor.rgbGreen) and (gPrefs.BackColor.rgbBlue = FontColor.rgbBlue) then
        gText.TextColor(255-FontColor.rgbRed, 255-FontColor.rgbGreen, 255-FontColor.rgbBlue)

     else
         gText.TextColor(FontColor.rgbRed, FontColor.rgbGreen, FontColor.rgbBlue);
     //Caption := inttostr(orient);
     //1=left,2=top,3=right,4=bottom,5=above
     if orient = 5 then //centered directly below XY
        gText.TextOut(X- (gText.TextWidth(gFontSz,NumStr)*0.5) ,Y-(gFontPx*1.2),gFontSz,NumStr);
     if orient = 6 then //left of X, Below Y
        gText.TextOut(X+(gFontPx*0.1) ,Y-(gFontPx*1.2),gFontSz,NumStr)
     else   //??
        gText.TextOut(X- (gText.TextWidth(gFontSz,NumStr)*0.5) ,Y-(gFontPx*1.2),gFontSz,NumStr);
end;

procedure TGLForm1.DrawText(lScrnWid, lScrnHt, zoom, zoomOffsetX, zoomOffsetY: integer);
begin
(*glDisable(GL_CULL_FACE);
glMatrixMode(GL_MODELVIEW);
glLoadIdentity;
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
//glOrtho (0, Width, 0, Height, 0.1, 40);
//glTranslatef(zoom*zoomOffsetX, zoom*zoomOffsetY, 0);
glEnable (GL_BLEND);
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
glDisable(GL_DEPTH_TEST);
glDisable(GL_CULL_FACE);
glMatrixMode(GL_MODELVIEW);
glLoadIdentity;
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
glOrtho (0, Width div zoom , 0, Height div zoom, 0.1, 40);
glTranslatef(zoomOffsetX, zoomOffsetY, 0);
glEnable (GL_BLEND);
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
glDisable(GL_DEPTH_TEST);  *)
gText.DrawText;

end;

procedure SetLutFromZero(var lMin,lMax: single);
//if both min and max are positive, returns 0..max
//if both min and max are negative, returns min..0
begin
    SortSingle(lMin,lMax);
    if (lMin > 0) and (lMax > 0) then
      lMin := 0
    else if (lMin < 0) and (lMax < 0) then
      lMax := 0;
end;

procedure TGLForm1.UpdateClrbar;
var
   i: integer;
   lMin, lMax: single;
   LUT: TLUT;
begin
   (*  //
     for i := 0 to 255 do begin
      LUT[i].rgbRed := i;
      LUT[i].rgbGreen := 0;
      LUT[i].rgbBlue := 0;
  end;*)
  if gOpenOverlays < 1 then begin
     GenerateLUT(gCLUTrec, LUT);
     gClrbar.SetLUT(1, LUT, gCLUTrec.min,gCLUTrec.max);
     exit;
  end; //
  for i := 1 to gOpenOverlays do begin
    lMin := gOverlayImg[i].WindowScaledMin;
    lMax := gOverlayImg[i].WindowScaledMax;
    SortSingle(lMin,lMax);
    if gOverlayImg[i].LutFromZero then
      SetLutFromZero(lMin,lMax);

    gClrbar.SetLUT(i, gOverlayImg[i].LUT, lMin,lMax);
  end;

end;

procedure TGLForm1.DrawClrbar (lScrnWid, lScrnHt, zoom, zoomOffsetX, zoomOffsetY: integer; ClrbarSizeFracX: single);

begin
     gClrbar.ForcedSizeFracX:= ClrbarSizeFracX;
     gClrbar.Draw(max(gOpenOverlays,1),lScrnWid, lScrnHt, zoom, zoomOffsetX, zoomOffsetY);
end;

procedure TGLForm1.DrawCube (lScrnWid, lScrnHt, zoom, zoomOffsetX, zoomOffsetY: integer);
begin
     gCube.Azimuth:= -gRayCast.Azimuth;
     gCube.Elevation:= gRayCast.Elevation;
     if (gPrefs.ColorbarPosition = 1) or (gPrefs.ColorbarPosition = 2) then
       gCube.TopLeft:= true
     else
          gCube.TopLeft:= false;
     gCube.Draw(lScrnWid, lScrnHt,zoom, zoomOffsetX, zoomOffsetY);
end;

function TGLForm1.GLBoxBackingWidth: integer;
begin
   {$IFDEF LCLCocoa}
     result := Round(GLBox.Width * LBackingScaleFactor(GLBox.Handle));
   {$ELSE}
    result := GLBox.Width;
   {$ENDIF}
end;

function TGLForm1.GLBoxBackingHeight: integer;
begin
   {$IFDEF LCLCocoa}
   result := Round(GLBox.Height * LBackingScaleFactor(GLBox.Handle));
   {$ELSE}
    result := GLBox.Height;
   {$ENDIF}
end;

{$IFDEF LCLCocoa}
procedure TGLForm1.SetRetina;
begin
  (*if gPrefs.RetinaDisplay then
     GLBox.Options := [ocoMacRetinaMode]
  else
    GLBox.Options := [];
  GLBox.MultiSampling:=GLBox.MultiSampling;
  *)

  LSetWantsBestResolutionOpenGLSurface(gPrefs.RetinaDisplay, GLBox.Handle);
  //GLBox.WantsBestResolutionOpenGLSurface:=gPrefs.RetinaDisplay;
  if (GLbox.Height < 1) or (GLBoxBackingHeight <= GLbox.Height) then
     gRetinaScale := 1
  else
      gRetinaScale := GLBoxBackingHeight/GLbox.Height;
end;
{$ENDIF}


procedure TGLForm1.YokeMenuClick(Sender: TObject);
begin
 {$IFDEF COMPILEYOKE}
  YokeTimer.Enabled := YokeMenu.Checked;
 {$ENDIF}
end;


procedure TGLForm1.YokeTimerTimer(Sender: TObject);
{$IFDEF COMPILEYOKE}
var
   lAzimuth, lElevation,lXmm,lYmm,lZmm: single;
   lInvMat: TMatrix ;
   lOK: boolean;
begin
  YokeTimer.Enabled := YokeMenu.Checked;
  if not YokeMenu.Checked then exit;
  if (gPrefs.SliceView = 5) then exit;//not for mosaics
  if not GetShareFloats(lXmm,lYmm,lZmm, lAzimuth, lElevation) then
     exit;
  if  (gPrefs.SliceView < 1) or (gPrefs.SliceView > 5) then  begin //not 2D slice view: assume rendering
        GLBox.Invalidate;
        gRayCast.Azimuth := round(lAzimuth);
        gRayCast.Elevation := round(lElevation);
        exit;
  end;
  lInvMat := Hdr2InvMat (gTexture3D.NIftiHdr,lOK);
  if (not lOK) or (gTexture3D.FiltDim[1] < 2) or (gTexture3D.FiltDim[2] < 2) or (gTexture3D.FiltDim[3] < 2) then exit;
  mm2Voxel (lXmm,lYmm,lZmm, lInvMat);
  gRayCast.OrthoX := (lXmm-1)/(gTexture3D.FiltDim[1]-1);
  gRayCast.OrthoY := (lYmm-1)/(gTexture3D.FiltDim[2]-1);
  gRayCast.OrthoZ := (lZmm-1)/(gTexture3D.FiltDim[3]-1);
  ShowOrthoSliceInfo (true);
  GLBox.Invalidate;
end;
{$ELSE}
begin
 //
end;

{$ENDIF}

{$IFDEF FPC}
{$IFDEF COREGL}
Type
TFrameBuffer = record
  depthBuf,frameBuf, tex: GLUint;
  w, h: integer;
end;

procedure initFrame (var f : TFrameBuffer);
begin
     f.tex := 0;
     f.depthBuf := 0;
     f.frameBuf := 0;
end;

procedure freeFrame (var f : TFrameBuffer);
begin
  //Delete resources
  glDeleteTextures(1, @f.tex);
  glDeleteTextures(1, @f.depthBuf);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glDeleteFramebuffers(1, @f.frameBuf);
  //Bind 0, which means render to back buffer, as a result, frameBuf is unbound
end;

function setFrame (wid, ht: integer; var f : TFrameBuffer; isMultiSample: boolean) : boolean; //returns true if multi-sampling
//http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-14-render-to-texture/
var
   w,h: integer;
   //drawBuf: GLenum;
   drawBuf: array[0..1] of GLenum;

begin
     w := wid;
     h := ht;
     if isMultiSample then begin
        w := w * 2;
        h := h * 2;
     end;
     result := isMultiSample;
     if (w = f.w) and (h = f.h) then begin
        {$IFDEF COREGL}
         glBindFramebuffer(GL_FRAMEBUFFER, f.frameBuf);
        {$ELSE}
         glBindFramebuffer(GL_FRAMEBUFFER_EXT, f.frameBuf);
        {$ENDIF}
         exit;
     end;
     freeframe(f);
     f.w := w;
     f.h := h;
     //https://www.opengl.org/wiki/Framebuffer_Object_Examples#Quick_example.2C_render_to_texture_.282D.29
     glGenTextures(1, @f.tex);
     glBindTexture(GL_TEXTURE_2D, f.tex);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
     glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA8, f.w, f.h, 0,GL_RGBA, GL_UNSIGNED_BYTE, nil); //RGBA16 for AO
     glGenFramebuffers(1, @f.frameBuf);
     glBindFramebuffer(GL_FRAMEBUFFER, f.frameBuf);
     //Attach 2D texture to this FBO
     glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, f.tex, 0);

     //glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, f.tex, 0);
     // Create the depth buffer
    glGenTextures(1, @f.depthBuf);
    glBindTexture(GL_TEXTURE_2D, f.depthBuf);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH24_STENCIL8, f.w, f.h, 0, GL_DEPTH_STENCIL, GL_UNSIGNED_INT_24_8, nil);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_TEXTURE_2D, f.depthBuf, 0);
     //glDrawBuffers(1, @drawBuf); // "1" is the size of DrawBuffers
     drawBuf[0] := GL_COLOR_ATTACHMENT0;
     drawBuf[1] := GL_COLOR_ATTACHMENT1;
     glDrawBuffers(1, @drawBuf[0]); // draw colors only
     if(glCheckFramebufferStatus(GL_FRAMEBUFFER) <> GL_FRAMEBUFFER_COMPLETE) then begin
       GLForm1.ShowmessageError('Frame buffer error 0x'+inttohex(glCheckFramebufferStatus(GL_FRAMEBUFFER),4) );
       exit;
     end;
end;

function TGLForm1.ScreenShot(Zoom: integer): TBitmap;
var
  RawImage: TRawImage;
  p: array of byte;
  zoom2, w, h, x, y, BytePerPixel: integer;
  z:longword;
  //fbuf, ftex: GLUint;
  f : TFrameBuffer;
  DestPtr: PInteger;
  origSz : TPoint;
  maxXY : array[0..1] of GLuint;
begin
 GLBox.MakeCurrent;
 glGetIntegerv(GL_MAX_VIEWPORT_DIMS, @maxXY);
 //caption := inttostr(maxXY[0]) +'x'+inttostr(maxXY[1]);
 zoom2 := Zoom;
 origSz.X := gRayCast.WINDOW_WIDTH;
 origSz.Y := gRayCast.WINDOW_HEIGHT;
 w := GLBox.BackingWidth * zoom2;
 h := GLbox.BackingHeight * zoom2;
 if (w > maxXY[0]) or (h > maxXY[1]) then begin
  w := GLBox.BackingWidth;
  h := GLbox.BackingHeight;
  zoom2 := 1
 end;
  Result:=TBitmap.Create;
  Result.Width:=w;
  Result.Height:=h;
  Result.PixelFormat := pf24bit; //if pf32bit the background color is wrong, e.g. when alpha = 0
  RawImage := Result.RawImage;
  BytePerPixel := RawImage.Description.BitsPerPixel div 8;
  setlength(p, 4*w* h);
  //GLBox.MakeCurrent;
  (*fbuf := 0;
  ftex := 0;
  glGenTextures(1, @ftex);
  glBindTexture(GL_TEXTURE_2D, ftex);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA8, w, h, 0,GL_RGBA, GL_UNSIGNED_BYTE, nil); //RGBA16 for AO
  glGenFramebuffers(1, @fbuf);
  glBindFramebuffer(GL_FRAMEBUFFER, fbuf);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, ftex, 0); *)
  initFrame(f);
  setFrame (w, h, f, false);
  gRendering:=true;
  //Attach 2D texture to this FBO
  //gRayCast.ScreenCapture := true;
  //gPrefs.RayCastQuality1to10 := 10;
  gRayCast.WINDOW_WIDTH := w;
  gRayCast.WINDOW_HEIGHT  := h;
  //DisplayGLz(gTexture3D,fbuf);
  DisplayGLz(gTexture3D,f.frameBuf);
  glFlush;
  glFinish;//<-this would pause until all jobs finished: generally a bad idea! required here
  GLbox.SwapBuffers;
  //CreateRender(w, h, false); //draw to framebuffer fScreenShot
  {$IFDEF Darwin} //http://lists.apple.com/archives/mac-opengl/2006/Nov/msg00196.html
  glReadPixels(0, 0, w, h, $80E1, $8035, @p[0]); //OSX-Darwin   GL_BGRA = $80E1;  GL_UNSIGNED_INT_8_8_8_8_EXT = $8035;
  {$ELSE}
   {$IFDEF Linux}
     glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, @p[0]); //Linux-Windows   GL_RGBA = $1908; GL_UNSIGNED_BYTE
   {$ELSE}
    glReadPixels(0, 0, w, h, $80E1, GL_UNSIGNED_BYTE, @p[0]); //Linux-Windows   GL_RGBA = $1908; GL_UNSIGNED_BYTE
   {$ENDIF}
  {$ENDIF}
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  freeFrame(f);
  //glDeleteFramebuffers(1, @fbuf);
  //glDeleteTextures(1, @ftex);
  gRendering:=false;
  //gRayCast.ScreenCapture := false;
  gRayCast.WINDOW_WIDTH := origSz.X;
  gRayCast.WINDOW_HEIGHT  := origSz.Y;
   GLbox.ReleaseContext;
  z := 0;
  if BytePerPixel <> 4 then begin
    for y:= h-1 downto 0 do begin
         DestPtr := PInteger(RawImage.Data);
         Inc(PByte(DestPtr), y * RawImage.Description.BytesPerLine );
         for x := 1 to w do begin
             DestPtr^ := p[z] + (p[z+1] shl 8) + (p[z+2] shl 16);
             Inc(PByte(DestPtr), BytePerPixel);
             z := z + 4;
         end;
     end; //for y : each line in image
  end else begin
      for y:= h-1 downto 0 do begin
          DestPtr := PInteger(RawImage.Data);
          Inc(PByte(DestPtr), y * RawImage.Description.BytesPerLine );
          System.Move(p[z], DestPtr^, w * BytePerPixel );
          z := z + ( w * 4 );
    end; //for y : each line in image
  end;
  setlength(p, 0);
  GLbox.invalidate;
end;


{$ELSE} //not COREGL
function ScreenShotX1: TBitmap; //native resolution: no framebuffer, automatic multisampling
var
  p: bytep0;
  x, y: integer;
  prevQ, w,h, BytePerPixel: int64;
  z:longword;
  RawImage: TRawImage;
  DestPtr: PInteger;
  maxXY: array[0..1] of GLuint;
begin
  prevQ := gPrefs.RayCastQuality1to10;
  gPrefs.RayCastQuality1to10 := 10;
  if ((prevQ <> 10) and (gPrefs.SliceView = 0)) then
   GLForm1.recompileShader(prevQ, 10);
  GLBox.MakeCurrent;
  DisplayGL(gTexture3D);
  w := GLForm1.GLBoxBackingWidth;
  h := GLForm1.GLboxBackingHeight;
  Result:=TBitmap.Create;
  Result.Width:=w;
  Result.Height:=h;
  Result.PixelFormat := pf24bit; //if pf32bit the background color is wrong, e.g. when alpha = 0
  RawImage := Result.RawImage;
  //GLForm1.ShowmessageError('GLSL error '+inttostr(RawImage.Description.RedShift)+' '+inttostr(RawImage.Description.GreenShift) +' '+inttostr(RawImage.Description.BlueShift));
  BytePerPixel := RawImage.Description.BitsPerPixel div 8;
  GetMem(p, w*h*4);
  {$IFDEF Darwin} //http://lists.apple.com/archives/mac-opengl/2006/Nov/msg00196.html
  glReadPixels(0, 0, w, h, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, @p[0]); //OSX-Darwin
  {$ELSE}
  glReadPixels(0, 0, w, h, GL_BGRA, GL_UNSIGNED_BYTE, @p[0]); //Linux-Windows
  {$ENDIF}
  z := 0;
  if BytePerPixel <> 4 then begin
    for y:= h-1 downto 0 do begin
         DestPtr := PInteger(RawImage.Data);
         Inc(PByte(DestPtr), y * RawImage.Description.BytesPerLine );
         for x := 1 to w do begin
             DestPtr^ := p[z] + (p[z+1] shl 8) + (p[z+2] shl 16);
             Inc(PByte(DestPtr), BytePerPixel);
             z := z + 4;
         end;
     end; //for y : each line in image
  end else begin
      for y:= h-1 downto 0 do begin
          DestPtr := PInteger(RawImage.Data);
          Inc(PByte(DestPtr), y * RawImage.Description.BytesPerLine );
          System.Move(p[z], DestPtr^, w * BytePerPixel );
          z := z + ( w * 4 );
    end; //for y : each line in image
  end;
  FreeMem(p);
  GLbox.ReleaseContext;
  if ((prevQ <> 10) and (gPrefs.SliceView = 0)) then begin
     gPrefs.RayCastQuality1to10 := prevQ;
     GLForm1.recompileShader(10, gPrefs.RayCastQuality1to10);
  end;
end;

function ScreenShotTiled(Zoom: integer): TBitmap;
var
  p: bytep0;
  x, y, tile: integer;
  prevQ, w,h, wz,hz,  tilex,tiley, BytePerPixel: int64;
  z:longword;
  RawImage: TRawImage;
  DestPtr: PInteger;
begin
  prevQ := gPrefs.RayCastQuality1to10;
  gPrefs.RayCastQuality1to10 := 10;
  if (prevQ <> 10) then
     GLForm1.recompileShader(prevQ, 10);
  gRayCast.ScreenCapture := true;
  GLBox.MakeCurrent;
  w := GLForm1.GLBoxBackingWidth;
  h := GLForm1.GLboxBackingHeight;
  wz := w*Zoom;
  hz := h*Zoom;
  Result:=TBitmap.Create;
  Result.Width:=wz;
  Result.Height:=hz;
  Result.PixelFormat := pf24bit; //if pf32bit the background color is wrong, e.g. when alpha = 0
  RawImage := Result.RawImage;
  //GLForm1.ShowmessageError('GLSL error '+inttostr(RawImage.Description.RedShift)+' '+inttostr(RawImage.Description.GreenShift) +' '+inttostr(RawImage.Description.BlueShift));
  BytePerPixel := RawImage.Description.BitsPerPixel div 8;
  Result.BeginUpdate(False);
  GetMem(p, w*h*4);
  //GLForm1.Caption := inttostr(Zoom);
  //tic := gettickcount;
  for tile := 0 to ((Zoom * Zoom) - 1) do begin
    tilex := (tile mod zoom) * w;
    tiley := (tile div zoom) * h;
    DisplayGLz(gTexture3D, Zoom, -tilex, -tiley, 0 {to screen}, true {tiled});
    {$IFDEF Darwin} //http://lists.apple.com/archives/mac-opengl/2006/Nov/msg00196.html
    glReadPixels(0, 0, w, h, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, @p[0]); //OSX-Darwin
    {$ELSE}
     glReadPixels(0, 0, w, h, GL_BGRA, GL_UNSIGNED_BYTE, @p[0]); //Linux-Windows
    {$ENDIF}
    z := 0;
    if BytePerPixel = 4 then begin
      for y:=0 to h-1 do begin
        DestPtr := PInteger(RawImage.Data);
        Inc(PByte(DestPtr), (( (hz-1) - (Y+tiley)) * RawImage.Description.BytesPerLine) + (tilex * BytePerPixel));
        System.Move(p^[z], DestPtr^, w * BytePerPixel );
        z := z + ( w * 4 );
      end; //for y
    end else begin //below  BytePerPixel <> 4, e.g. Windows
      for y:=0 to h-1 do begin
        DestPtr := PInteger(RawImage.Data);
        Inc(PByte(DestPtr), (( (hz-1) - (Y+tiley)) * RawImage.Description.BytesPerLine) + (tilex * BytePerPixel));
        for x:=0 to w-1 do begin
          DestPtr^ := (p^[z])+(p^[z+1] shl 8)+(p^[z+2]  shl 16);
          Inc(PByte(DestPtr), BytePerPixel);
          z := z + 4;
        end;
      end; //for y
    end; //if BytePerPixel = 4 else ...
  end; //for each tile
  Result.EndUpdate(False);
  FreeMem(p);
  GLbox.ReleaseContext;
  gRayCast.ScreenCapture := false;
  if (prevQ <> 10) then begin
     gPrefs.RayCastQuality1to10 := prevQ;
     GLForm1.recompileShader(10, gPrefs.RayCastQuality1to10);
  end;
  {$IFDEF LCLCocoa}
  GLBox.Invalidate; //at least for Cocoa we need to reset this or the user will see the final tile
  {$ENDIF}
  //clipbox.caption := inttostr(gettickcount - tic);
end;

//not IFDEF TILED_SCREENSHOT
Type
TFrameBuffer = record
  depthBuf,frameBuf, tex: GLUint; //we need depth buffer for 2D cube
  w, h: integer;
end;

procedure initFrame (var f : TFrameBuffer);
begin
     f.tex := 0;
     f.depthBuf := 0;
     f.frameBuf := 0;
end;

procedure freeFrame (var f : TFrameBuffer);
begin
  glDeleteTextures(1, @f.tex);
  glDeleteTextures(1, @f.depthBuf);
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
  glDeleteFramebuffersEXT(1, @f.frameBuf);
  //Bind 0, which means render to back buffer, as a result, frameBuf is unbound
end;


//{$DEFINE multisample}
{$IFDEF multisample}
  //How to get this to work on MacOS?
  //https://stackoverflow.com/questions/33587682/opengl-how-can-i-attach-a-depth-buffer-to-a-framebuffer-using-a-multisampled-2d
{$ELSE}

function setFrame (wid, ht: integer; var f : TFrameBuffer; isMultiSample: boolean) : boolean; //returns true if multi-sampling
//http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-14-render-to-texture/
var
   w,h: integer;
   drawBuf: array[0..1] of GLenum;
begin
     w := wid;
     h := ht;
     if isMultiSample then begin
        w := w * 2;
        h := h * 2;
     end;
     result := isMultiSample;
     if (w = f.w) and (h = f.h) then begin
         glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, f.frameBuf);
         exit;
     end;
     freeframe(f);
     f.w := w;
     f.h := h;
     //https://www.opengl.org/wiki/Framebuffer_Object_Examples#Quick_example.2C_render_to_texture_.282D.29
     glGenTextures(1, @f.tex);
     glBindTexture(GL_TEXTURE_2D, f.tex);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
     glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA8, f.w, f.h, 0,GL_RGBA, GL_UNSIGNED_BYTE, nil); //RGBA16 for AO
     glGenFramebuffersEXT(1, @f.frameBuf);
     glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, f.frameBuf);
     //Attach 2D texture to this FBO
     glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, f.tex, 0);

     //glFramebufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, f.tex, 0);
     // Create the depth buffer
    glGenTextures(1, @f.depthBuf);
    glBindTexture(GL_TEXTURE_2D, f.depthBuf);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH24_STENCIL8, f.w, f.h, 0, GL_DEPTH_STENCIL, GL_UNSIGNED_INT_24_8, nil);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_STENCIL_ATTACHMENT, GL_TEXTURE_2D, f.depthBuf, 0);
     //glDrawBuffers(1, @drawBuf); // "1" is the size of DrawBuffers
     drawBuf[0] := GL_COLOR_ATTACHMENT0;
     drawBuf[1] := GL_COLOR_ATTACHMENT1;
     glDrawBuffers(1, @drawBuf[0]); // draw colors only
     if(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT) <> GL_FRAMEBUFFER_COMPLETE) then begin
       GLForm1.ShowmessageError('Frame buffer error 0x'+inttohex(glCheckFramebufferStatus(GL_FRAMEBUFFER),4) );
       exit;
     end;
end;
{$ENDIF}
function ScreenShotNoTile(Zoom: integer): TBitmap;
var
  p: bytep0;
  x, y: integer;
  prevQ, w,h, BytePerPixel: int64;
  z:longword;
  RawImage: TRawImage;
  DestPtr: PInteger;
  maxXY: array[0..1] of GLuint;
  f: TFrameBuffer;
begin
  prevQ := gPrefs.RayCastQuality1to10;
  gPrefs.RayCastQuality1to10 := 10;
  if ((prevQ <> 10) and (gPrefs.SliceView = 0)) then
     GLForm1.recompileShader(prevQ, 10);
  gRayCast.ScreenCapture := true;
  GLBox.MakeCurrent;
  glGetIntegerv(GL_MAX_VIEWPORT_DIMS, @maxXY);
  //caption := inttostr(maxXY[0]) +'x'+inttostr(maxXY[1]);
  w := GLForm1.GLBoxBackingWidth * Zoom;
  h := GLForm1.GLboxBackingHeight * Zoom;
  MosaicScale(w, h, Zoom);
  if (w > maxXY[0]) or (h > maxXY[1]) then begin
    //OpenGL unable to create such a large bitmap
    if (gPrefs.SliceView  <> 5) then begin
      result := ScreenShotX1;
      exit;
    end else begin
        w := GLForm1.GLBoxBackingWidth;
        h := GLForm1.GLboxBackingHeight;
        zoom := 1;
    end;
  end;
  Result:=TBitmap.Create;
  Result.Width:=w;
  Result.Height:=h;
  Result.PixelFormat := pf24bit; //if pf32bit the background color is wrong, e.g. when alpha = 0
  RawImage := Result.RawImage;
  //GLForm1.ShowmessageError('GLSL error '+inttostr(RawImage.Description.RedShift)+' '+inttostr(RawImage.Description.GreenShift) +' '+inttostr(RawImage.Description.BlueShift));
  BytePerPixel := RawImage.Description.BitsPerPixel div 8;
  Result.BeginUpdate(False);
  GetMem(p, w*h*4);
  initFrame(f);
  setFrame (w, h, f, false);
  //tic := gettickcount;
  gRayCast.WINDOW_WIDTH := w;
  gRayCast.WINDOW_HEIGHT  := h;
  InitGL (false);
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, f.frameBuf); //<- required for 2D views
  DisplayGLz(gTexture3D, 1, 0, 0, f.frameBuf, false);
  {$IFDEF Darwin} //http://lists.apple.com/archives/mac-opengl/2006/Nov/msg00196.html
  glReadPixels(0, 0, w, h, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, @p[0]); //OSX-Darwin
  {$ELSE}
  glReadPixels(0, 0, w, h, GL_BGRA, GL_UNSIGNED_BYTE, @p[0]); //Linux-Windows
  {$ENDIF}
  z := 0;
  if BytePerPixel <> 4 then begin
    for y:= h-1 downto 0 do begin
         DestPtr := PInteger(RawImage.Data);
         Inc(PByte(DestPtr), y * RawImage.Description.BytesPerLine );
         for x := 1 to w do begin
             DestPtr^ := p[z] + (p[z+1] shl 8) + (p[z+2] shl 16);
             Inc(PByte(DestPtr), BytePerPixel);
             z := z + 4;
         end;
     end; //for y : each line in image
  end else begin
      for y:= h-1 downto 0 do begin
          DestPtr := PInteger(RawImage.Data);
          Inc(PByte(DestPtr), y * RawImage.Description.BytesPerLine );
          System.Move(p[z], DestPtr^, w * BytePerPixel );
          z := z + ( w * 4 );
    end; //for y : each line in image
  end;
  FreeMem(p);
  gRayCast.WINDOW_WIDTH := GLForm1.GLBoxBackingWidth;
  gRayCast.WINDOW_HEIGHT  := GLForm1.GLBoxBackingHeight;
  glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);  //draw to display
  freeFrame(f);
  Result.EndUpdate(False);
  InitGL (false);
  GLbox.ReleaseContext;

  gRayCast.ScreenCapture := false;
  if ((prevQ <> 10) and (gPrefs.SliceView = 0)) then begin
     gPrefs.RayCastQuality1to10 := prevQ;
     GLForm1.recompileShader(10, gPrefs.RayCastQuality1to10);
  end;
  {$IFDEF LCLCocoa}
  GLBox.Invalidate; //at least for Cocoa we need to reset this or the user will see the final tile
  {$ENDIF}
  //clipbox.caption := inttostr(gettickcount - tic);
end;

function TGLForm1.ScreenShot(Zoom: integer): TBitmap;
begin
  if (Zoom = 1) and (gPrefs.SliceView  <> 5) then begin
     result := ScreenShotX1;
     exit;
  end;
  if (gPrefs.isTiledScreenShot) and (gPrefs.SliceView  <> 5) then
     result := ScreenShotTiled(Zoom)
  else
      result := ScreenShotNoTile(Zoom);

end;

{$ENDIF} //if COREGL else not CORE

{$ELSE} //If FPC else Delphi

function TGLForm1.ScreenShot(Zoom: integer): TBitmap;
var
  p: bytep0;
  tile, w,h, wz,hz, x, y, tilex,tiley, BytePerPixel: integer;
  z:longword;
  DestPtr: PInteger;
begin
  gRayCast.ScreenCapture := true;
  GLBox.MakeCurrent;
  w := GLBox.Width;
  h := GLbox.Height;
  wz := w*Zoom;
  hz := h*Zoom;
  Result:=TBitmap.Create;
  Result.Width:=wz;
  Result.Height:=hz;
  Result.PixelFormat := pf24bit;
  BytePerPixel := 3;
  GetMem(p, w*h*4);
  for tile := 0 to ((Zoom * Zoom) - 1) do begin
    tilex := (tile mod zoom) * w;
    tiley := (tile div zoom) * h;
    DisplayGLz(gTexture3D, Zoom, -tilex, -tiley,0,true);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, @p[0]);
    z := 0;
    for y:=0 to h-1 do begin
      DestPtr := Result.ScanLine[(hz-1) - (Y+tiley)]; //[ Y+tiley];
      //if tilex > 0 then
      Inc(PByte(DestPtr), tilex * BytePerPixel);
      for x:=0 to w-1 do begin
          DestPtr^ := p^[z+2]+(p^[z+1] shl 8)+(p^[z] shl 16);
          Inc(PByte(DestPtr), BytePerPixel);
          z := z + 4;
      end;
    end;
  end;
  FreeMem(p);
  GLbox.ReleaseContext;
  gRayCast.ScreenCapture := false;
end;
{$ENDIF}

procedure  TGLForm1.loadLabelsDefault;
var
   nColors: integer;
   NewItem: TMenuItem;
   s: string;
begin
     while DrawTool1.Count > 2 do
           DrawTool1.Delete(2); //delete all pens except disable and erase
     for nColors := 1 to 9 do begin
         NewItem := TMenuItem.Create(Self);
         NewItem.onclick :=  DrawTool1Click;
         NewItem.AutoCheck := true;
         NewItem.RadioItem := true;
         NewItem.GroupIndex := 189;
         NewItem.Tag := nColors;
         {$IFDEF Darwin}
         NewItem.ShortCut := ShortCut(Word(inttostr(nColors)[1]), [ssMeta]);
         {$ELSE}
         NewItem.ShortCut := ShortCut(Word(inttostr(nColors)[1]), [ssCtrl]);
         {$ENDIF}
         case nColors of
              2: s := 'Green';
              3: s := 'Blue';
              4: s := 'Orange';
              5: s := 'Purple';
              6: s := 'Cyan';
              7: s := 'Brick';
              8: s := 'Lime';
              9: s := 'Sky';
              else s := 'Red';
         end;
         NewItem.Caption := s;
         DrawTool1.Add(NewItem);
     end; //for each color
end;

function str2int (s: string): integer;
begin
result := 0;
try
   result := StrToInt(s);    // Trailing blanks are not supported
except
on Exception : EConvertError do
   ShowMessage(Exception.Message);
end;
end;

function  TGLForm1.loadLabelsITK(fnm: string): boolean;
label
  666;
var
  strs, strDelim : TStringList;
  l, nColors, R,G,B,Idx: integer;
  lValid : boolean;
   NewItem: TMenuItem;
   s: string;
begin
 result := false;
 if not fileexists(fnm) then exit;
 strs := TStringList.Create;
 strDelim := TStringList.Create;
 //strLabel := TStringList.Create;
 strs.LoadFromFile(fnm);
 if (strs.Count < 1) then goto 666;
 lValid := false;
 nColors := 0;
 While DrawTool1.Count > 2 do
        DrawTool1.Delete(2); //delete all pens except disable and erase
 for l := 0 to (strs.Count-1) do begin
     if strs.Strings[l] = '# ITK-SnAP Label Description File' then
        lValid := true
     else if strs.Strings[l][1] = '#' then
        //
     else begin
        strDelim.DelimitedText := strs.Strings[l];
        if (strDelim.Count = 8) then begin
           idx := str2int(strDelim.Strings[0]);
           if (idx > 0) and (idx < 256) then begin
             r := str2int(strDelim.Strings[1]);
             g := str2int(strDelim.Strings[2]);
             b := str2int(strDelim.Strings[3]);
             voiColor (idx, r, g, b);
             inc(nColors);
              NewItem := TMenuItem.Create(Self);
             NewItem.onclick :=  DrawTool1Click;
             NewItem.AutoCheck := true;
             NewItem.RadioItem := true;
             NewItem.GroupIndex := 189;
             NewItem.Tag := idx;
             if nColors < 10 then begin
                s := inttostr(nColors);
                {$IFDEF Darwin}
                NewItem.ShortCut := ShortCut(Word(s[1]), [ssMeta]);
                {$ELSE}
                NewItem.ShortCut := ShortCut(Word(s[1]), [ssCtrl]);
                {$ENDIF}
             end;
             NewItem.Caption :=strDelim.Strings[7];
             DrawTool1.Add(NewItem);
             //strLabel.Add (strDelim.Strings[7]);
           end; //idx 1..255
        end; //8 items
     end; //not comment
 end; //for each line

 if (not lValid)or (nColors < 1) then begin
   Showmessage('This does not appear to be a valid ITK-SnAP Label Description File');
   goto 666;
 end;
 result := true;

 666:
 strDelim.free;
 strs.Free;
 if not result then
    loadLabelsDefault;
 GLBox.Invalidate; //refresh colors
end;

procedure TGLForm1.StopScripts;
begin
  {$IFDEF ENABLESCRIPT}
  ScriptForm.Stop1Click(nil);
  {$ENDIF}
end;



procedure TGLForm1.UpdateGL;
begin
  GLBox.invalidate;//IF YOU GET AN ERROR HERE UNCOMMENT THE LINE "//GLBox:TOpenGLControl; "
  //caption := '----'+inttostr(random(888));
end;
{$IFNDEF FPC}
procedure TGLForm1.WMDropFiles(var Msg: TWMDropFiles);  //implement drag and drop
var  CFileName: array[0..MAX_PATH] of Char;
begin
  try
   if DragQueryFile(Msg.Drop, 0, CFileName, MAX_PATH) > 0 then begin
      LoadDatasetNIFTIvol1(CFilename,true);
      Msg.Result := 0;
    end;
  finally
    DragFinish(Msg.Drop);
  end;
end;//Proc WMDropFiles
{$ENDIF}

procedure ScreenRes(var lVidX,lVidY: integer);
{$IFDEF FPC}
begin
    lVidX := Screen.Width;
    lVidY := Screen.Height;
end;
{$ELSE}
var
   DC: HDC;
begin
  DC := GetDC(0);
  try
   lVidX :=(GetDeviceCaps(DC, HORZRES));
   lVidY :=(GetDeviceCaps(DC, VERTRES));
  finally
       ReleaseDC(0, DC);
  end; // of try/finally
end;//screenres
{$ENDIF}

procedure TGLForm1.SetFormSize(FormWidth,FormHeight: integer);
//{$IFNDEF Darwin}
var
  lVidX,lVidY: integer;
  //{$ENDIF}
begin
  //{$IFNDEF Darwin}  //Previously Darwin did not  resize the GLSceneViewer correctly... seems to work 0.9.30 with Intel Sandy Bridge

 ScreenRes(lVidX,lVidY);
 {$IFDEF FPC} {$IFNDEF UNIX}
 if Screen.PixelsPerInch <> 96 then begin
  FormWidth := round(FormWidth* (96/Screen.PixelsPerInch));
  FormHeight := round(FormHeight* (96/Screen.PixelsPerInch));
   //ClipBox.Caption := INTTOSTR(Screen.PixelsPerInch)+'  '+ inttostr(FormWidth)+'x'+inttostr(FormHeight)+'  '+inttostr(lVidx)+'x'+inttostr(lVidY);
 end;
{$ENDIF}{$ENDIF}

  if lVidX > FormWidth then
    GLForm1.Width := FormWidth;
  if (lVidy-20) > FormHeight then //give a bit of room for dock
    GLForm1.Height := FormHeight;
end;

procedure TGLForm1.StopTimers;
begin
  UpdateTimer.enabled := false;
end;

(*procedure TGLForm1.SelectIntensityMinMax(lMin,lMax: single);
var
  mn,mx,range: single;
  lLog10: integer;
begin
    if lMin > lMax then begin
      mn := lMax;
      mx := lMin;
    end else begin
      mn := lMin;
      mx := lMax;
    end;
    lLog10 := trunc(log10( mx-mn))-1;
    mn := roundto(mn,lLog10);
    mx := roundto(mx,lLog10);

    gCLUTrec.min := mn;
    gCLUTrec.max := mx;
    MinEdit.text := float2str(mn, 3);
    MaxEdit.text := float2str(mx,3);
    M_refresh := true;
end; *)
procedure TGLForm1.SelectIntensityMinMax(lMin,lMax: single);
var
  mn,mx,range: single;
  lDec: integer;
begin
    if lMin > lMax then begin
      mn := lMax;
      mx := lMin;
    end else begin
      mn := lMin;
      mx := lMax;
    end;
    range := abs(lMax-lMin);
    lDec := 2 - trunc(log10(range));
    if lDec < 0 then
      lDec := 0;
    if lDec > 8 then
      lDec := 8;
    (*if range > 10000 then
      lDec := 0
    else if range > 1000 then
      lDec := 1
    else if range > 100 then
      lDec := 2
    else if range > 10 then
      lDec := 3
    else if range > 0.05 then
      lDec := 4
    else
      lDec := 6;*)
    gCLUTrec.min := mn;
    gCLUTrec.max := mx;
    MinEdit.text := realtostr(mn,lDec);
    MaxEdit.text := realtostr(mx,lDec);
    M_refresh := true;
end;

procedure TGLForm1.SelectCube(lShow: boolean);
begin
   Orient1.checked := lShow;
   Orient1Click(nil);
end;

(*procedure TGLForm1.Select2Dor3D(l3D: boolean);
begin
  OrthoSlice.checked := not l3D;
  gPrefs.OrthoSliceView := OrthoSlice.checked;
  GLbox.Invalidate;
end; *)

procedure TGLForm1.SelectShowTools(lShow: boolean);
begin
  Tool1.checked := lShow;
  Tool1Click(nil);
end;

procedure TGLForm1.SelectShowColorEditor(lShow: boolean);
begin
  ToggleTransparency1.checked := lshow;
  ToggleTransparency1Click(nil);
end;

function TGLForm1.LoadDatasetNIFTIvol1(lFilename: string; lStopScript: boolean): boolean;
begin
  result := LoadDatasetNIFTIVol(lFilename, lStopScript, 1);
end;

function AddExtSearchImg (var lFilenameX: string): boolean;
//see if we can find a file by adding .nii, .hdr or .nii.gz to filename..
var lFilename: string;
begin
  result := true;
  if fileexists(lFilenameX) then exit;
  lFilename := lFilenameX;
  lFilenameX := lFilename+'.hdr';
  if fileexists(lFilenameX) then
    exit;
  lFilenameX := lFilename+'.nii';
  if fileexists(lFilenameX) then
    exit;
  lFilenameX := lFilename+'.voi';
  if fileexists(lFilenameX) then
    exit;
  lFilenameX := lFilename+'.nii.gz';
  if fileexists(lFilenameX) then
    exit;
  if (UpCaseExt(lFilename) = '.NII') then begin
      lFilenameX := lFilename+'.gz';
      if fileexists(lFilenameX) then
        exit;
  end;
  result := false;
end;

function AddExtSearchBMP (var lFilenameX: string): boolean;
//see if we can find a file by adding .nii, .hdr or .nii.gz to filename..
var lFilename: string;
begin
  result := true;
  if fileexists(lFilenameX) then exit;
  lFilename := lFilenameX;
  lFilenameX := lFilename+'.png';
  if fileexists(lFilenameX) then
    exit;
  lFilenameX := lFilename+'.jpg';
  if fileexists(lFilenameX) then
    exit;
  lFilenameX := lFilename+'.bmp';
  if fileexists(lFilenameX) then
    exit;
  result := false;
end;

function AddExtSearch (var lFilenameX: string; lBitmap: boolean): boolean;
begin
  if lBitmap then
    result := AddExtSearchBMP(lFilenameX)
  else
    result := AddExtSearchImg(lFilenameX);
end;

procedure TGLForm1.DrawMosaic(Str: string);
begin
  gRayCast.MosaicString := Str;
  GLBox.invalidate;
end;

{$IFDEF Darwin}
function ParentOfAppFolder: string;
var
   lS,lSapp: String;
   lL,lP : integer;
begin
    result := '';
    lS := extractfilepath(paramstr(0));
    lL:= length(lS);
    lP := lL;
    lSapp := '';
    while (lP > 1) and (lSapp <> '.APP') do begin
          if lS[lP] = pathdelim then
             lSapp := ''
          else
              lSapp := upcase(lS[lP])+lSapp;

          dec(lP);
    end;
    if lP < 2 then
       exit;
    lSapp := '';
    for lL := 1 to lP do
        lSapp := lSapp + lS[lL];
    result := ExtractFileDirWithPathDelim(lSapp);
end;
{$ENDIF}

function TGLForm1.CheckFilename (var lFilenameX: string; lBitmap: boolean): boolean;
//find a file even if the file name is missing an extension or does not have a path
var
  lFilename: string;
begin
  result := false;
  if lFilenameX = '' then exit;
  result := true;
  if fileexists(lFilenameX) then exit;
  lFilename := lFilenameX;
  lFilenameX := GetCurrentDir + pathdelim + lFilename;
  if AddExtSearch(lFilenameX,lBitmap) then
    exit;
  lFilenameX := lFilename;
  if AddExtSearch(lFilenameX,lBitmap) then
    exit;
  {$IFDEF Darwin}
  lFilenameX := ParentOfAppFolder + extractfilename(lFilename);
  if AddExtSearch(lFilenameX,lBitmap) then
    exit;
  lFilenameX := AppDir2 + extractfilename(lFilename);
  if AddExtSearch(lFilenameX,lBitmap) then
    exit;
  {$ENDIF}
  lFilenameX := DefaultsDir('') + extractfilename(lFilename);
  if AddExtSearch(lFilenameX,lBitmap) then
    exit;
  lFilenameX := ExtractFileDirWithPathDelim(gPrefs.PrevFilename[1]) + extractfilename(lFilename);
  if AddExtSearch(lFilenameX,lBitmap) then
    exit;
  lFilenameX := ExtractFileDirWithPathDelim(gPrefs.PrevScriptName[1]) + extractfilename(lFilename);
  if AddExtSearch(lFilenameX,lBitmap) then
    exit;
  lFilenameX := ExtractFileDirWithPathDelim(GetCurrentDir) + extractfilename(lFilename);
  if AddExtSearch(lFilenameX,lBitmap) then
    exit;
  //next Aug 2009 - check executable's directory... (same as CurrentDir for Windows, different for Linux)
  lFilenameX := ExtractFileDirWithPathDelim(paramstr(0)) + extractfilename(lFilename);
  if AddExtSearch(lFilenameX,lBitmap) then
    exit;
  //unable to find a match!
  lFilenameX := lFilename;
  if fileexists(lFilenameX) then exit;
  result := false;
end;

procedure TGLForm1.ResetSliders;
begin
  //make sure we are not showing cutout when we load a new image... otherwise gradient might be cut
  //SetShader(ShaderDir+pathdelim+ShaderDrop.Items[0]);
  ShaderDrop.ItemIndex := 0;
  ShaderDropChange(nil);
 GLForm1.Closeoverlays1Click(nil);
  XTrackBar.Position := 0;
  X2TrackBar.Position := 0;
  ClipTrack.Position := 0;
  gRayCast.Distance := kDefaultDistance;
  gRayCast.Azimuth := 110;
  gRayCast.Elevation := 15;
  gRayCast.LightAzimuth := 0;
  gRayCast.LightElevation := 70;
end;

procedure TGLForm1.TerminateRendering;
//OSX crashes when you open a modal dialog while OpenGL is working...
begin
 UpdateTimer.Enabled := false;
 while gRendering do
       application.ProcessMessages;
end;

procedure TGLForm1.RunScriptClick(Sender: TObject);
begin
 GLForm1.DrawMosaic(MosaicText.Text);
end;
procedure TGLForm1.CopyScriptClick(Sender: TObject);
begin
 {$IFDEF FPC}
   Clipboard.AsText := MosaicText.Text;
   //MosaicText.Text := 'not yet implemented';
 {$ELSE}
 Clipboard.AsText := MosaicText.Text;
 {$ENDIF}
end;

procedure TGLForm1.UpdateMosaic(Sender: TObject);
var
  lRi,lCi,lR,lC,lRxC,lI: integer;
  lInterval: single;
  lOrthoCh: Char;
  lStr: string;
begin
  //if not MosaicPrefsForm.Visible then exit;
  lR := RowEdit.value;
  lC := ColEdit.value;
  lRxC := lR * lC;
  if lRxC < 1 then
    exit;
  if (lRxC > 1) and (CrossCheck.Checked) then
    lInterval := 1 / (lRxC) //with cross-check, final image will be 0.5
  else
    lInterval := 1 / (lRxC+1);
  lCi := OrientDrop.ItemIndex;
  case lCi of
    1 : lStr := 'C';//coronal
    2 : lStr := 'S'; //Sag
    3 : lStr := 'Z'; //rev Sag
    else lStr := 'A'; //axial
  end; //Case
  case lCi of
    1 : lOrthoCh := 'S';//coronal
    2 : lOrthoCh := 'C'; //Sag
    3 : lOrthoCh := 'C'; //rev Sag
    else lOrthoCh := 'S'; //axial
  end; //Case
  lStr := lStr + ' ';
  //next Labels...
  if LabelCheck.checked then
    lStr := lStr + 'L+ ';
  //next horizonatal overlap
  if ColOverlap.Position <> 0 then
    lStr := lStr +'H '+ FloatToStrF(ColOverlap.Position/10, ffFixed, 4, 3)+ ' ';
  //next vertical overlap
  if RowOverlap.Position <> 0 then
    lStr := lStr +'V '+ FloatToStrF(RowOverlap.Position/10, ffFixed, 4, 3) + ' ';
  //next draw rows....
  lI := 0;
  for lRi := 1 to lR do begin
    for lCi := 1 to lC do begin
      inc(lI);
      if (lI = lRxC) and (CrossCheck.Checked) then
        lStr := lStr +lOrthoCh + ' 0.5' //maybe "X" used to disable text on cross slice? perhaps "L-"
        //lStr := lStr + 'X '+lOrthoCh + ' 0.5'
      else
        lStr := lStr + FloatToStrF(lI * lInterval, ffFixed, 8, 4);
      if lCi < lC then
        lStr := lStr + ' ';
    end; //for each column
    if lRi < lR then
      lStr := lStr +';';
  end;//for each row
  MosaicText.Text := lStr;
  GLForm1.DrawMosaic(lStr);
end;

function TGLForm1.LoadDatasetNIFTIvol(lFilename: string; lStopScript: boolean; lVolume: integer): boolean;
var
  lFilenameX: string;
begin
  result := false;
  UpdateTimer.Enabled := false;
  if lStopScript then
    StopScripts;
    while gRendering do
      application.ProcessMessages;
  gRendering := true;
  if (not voiIsEmpty) and (voiIsModified) then
	SaveVOI1Click(nil);
  lFilenameX := lFilename;
  if lFilenameX <> '' then
    result := CheckFilename (lFilenameX,false);
  //caption := lFilename +' --> '+lFilenameX;
  ResetSliders;
  if lVolume > 0 then
    M_Reload := lVolume
  else
    M_reload := 1;
  //caption := inttostr(lVolume)+'  '+inttostr(M_reload);
  OpenDialog1.FileName := lFilenameX;
  AreaInitialized := false;
  gRendering := false;
  GLbox.Invalidate;
  GLForm1.Refresh;
end; //LoadDatasetNIFTI

function TGLForm1.LoadDatasetNIFTIvolx(lFilename: string; lStopScript: boolean): boolean;
var
  lnVol : integer;
begin
  UpdateTimer.Enabled:=false;
  result := false;

  {x$IFDEF USETRANSFERTEXTURE}
 //x lnVol := 1;
{x$ELSE}
  if lFilename = '' then
     lnVol := 1
  else
    lnVol :=  NIFTIvolumes(lFilename);
    //caption := inttostr(lnVol);
   //if lnVol < 1 then  lnVol := 1;
  if lnVol < 1 then
      exit;
    if lnVol > 1 then
      lnVol := ReadIntForm.GetInt(extractfilename(lFilename)+' select volume',1,1,lnVol);
   {x$ENDIF}
    result := LoadDatasetNIFTIVol(lFilename, lStopScript, lnVol);
end;

procedure TGLForm1.OpenMRU(Sender: TObject);//open template or MRU
//Templates have tag set to 0, Most-Recently-Used items have tag set to position in gMRUstr
var
	lFilename: string;
begin
     if Sender = nil then
        lFilename := gPrefs.PrevFilename[1]
     else
         lFilename := gPrefs.PrevFilename[(Sender as TMenuItem).tag];

 LoadDatasetNIFTIvolx(lFilename,true);
end;

procedure TGLForm1.UpdateMRU;//most-recently-used menu
const

     kMenuItems = 5;//515) Check Darwin: no File/Exit with OSX users quit from application menu
var
  lPos,lN,lM : integer;
begin
 lN := File1.Count-kMenuItems;
  if lN > knMRU then
    lN := knMRU;
 lM := kMenuItems;
  for lPos :=  1 to lN do begin
      if gPrefs.PrevFilename[lPos] <> '' then
                    begin

          File1.Items[lM].Caption :=ExtractFileName(gPrefs.PrevFilename[lPos]);//(ParseFileName(ExtractFileName(lFName)));
	  File1.Items[lM].Tag := lPos;
          File1.Items[lM].onclick :=  OpenMRU; //Lazarus
          File1.Items[lM].Visible := true;
          //Number key shortcuts used for pens!
          //if lPos < 10 then
          {$IFDEF Darwin}
          File1.Items[lM].ShortCut := ShortCut(Word('1')+ord(lPos-1), [ssMeta]);
          {$ELSE}
          //File1.Items[lM].ShortCut := ShortCut(Word('1')+ord(lPos-1), [ssCtrl]);
          {$ENDIF}
      end else
          File1.Items[lM].Visible := false;
      inc(lM);
  end;//for each MRU
end;  //UpdateMRU

procedure TGLForm1.OpenColorScheme(Sender: TObject);
begin
    LUTChange(sender);
    MinEdit.Text := floattostr(gCLUTrec.min);
    MaxEdit.Text := floattostr(gCLUTrec.max);
    UpdateTimer.Enabled  := true;
end;

(*procedure TGLForm1.FormResize(Sender: TObject);
begin
  AreaInitialized := false;
  GLbox.Invalidate;
  ShaderBoxResize(Sender);
end;  *)

procedure TGLForm1.ExitButton1Click(Sender: TObject);
begin
     Close;
end;

procedure TGLForm1.SelectSliceView(lView: integer);
begin
 gPrefs.SliceView := lView;
 case gPrefs.SliceView of
      1: Axial1.checked := true;
      2: Coronal1.checked := true;
      3: Sagittal1.checked := true;
      4: MPR1.checked := true;
      5: Mosaic1.checked := true;
      else Render1.checked := true;

 end;
 //{$IFDEF FPC} GLBox.Invalidate; {$ENDIF} //this will crash Delphi as GLBox not yet created
end;

procedure TGLForm1.DisplayRadiological;
begin
     if gPrefs.FlipLR then begin  //radiological view shows Left on Right
        if LeftBtn.Caption = 'R' then exit;
        LeftBtn.Caption := 'R';
        RightBtn.Caption := 'L';
        Slice2DBox.refresh;
        exit;
     end;
     if LeftBtn.Caption = 'L' then exit;
     LeftBtn.Caption := 'L';
     RightBtn.Caption := 'R';
     Slice2DBox.refresh;
end;

procedure TGLForm1.DisplayPrefs;
begin
 Orient1.checked := gPrefs.SliceDetailsCubeAndText;
 RadiologicalMenu.Checked := gPrefs.FlipLR;
 DisplayRadiological;
 ToggleTransparency1.checked := gPrefs.ColorEditor;
 Tool1.checked := gPrefs.ShowToolbar;
 ToolPanel.Visible := gPrefs.ShowToolbar;
 CollapsedToolPanel.Visible := not  ToolPanel.Visible;
 //OrthoSlice.checked := gPrefs.OrthoSliceView;
 VisibleClrbarMenu.Checked := gPrefs.Colorbar;
 SelectSliceView(gPrefs.SliceView);
 OverlayColorFromZeroMenu.checked := gPrefs.OverlayColorFromZero;
 SetToolPanelWidth; //4/2017: show correct tool panel when script runs ResetDefaults()
end;

function SimpleGetInt(lPrompt: string; lMin,lDefault,lMax: integer): integer;
var
  lStr: string;
begin
 result := lDefault;
 lStr := inttostr(lDefault);
 if not InputQuery ('Enter a value '+inttostr(lMin)+'..'+inttostr(lMax), lPrompt, lStr) then  exit;
 result := strtoint(lStr);
 result := Bound (result,lMin,lMax);
end;

const
kFname=0;
kLUT=1;
kMin=2;
kMax=3;

procedure InitOverlay (lOverlayIndex: integer);
begin
  gOverlayImg[lOverlayIndex].ImgBufferItems := 0;
  gOverlayImg[lOverlayIndex].ScrnBufferItems := 0;
  gOverlayImg[lOverlayIndex].ImgBufferUnaligned := nil;
  gOverlayImg[lOverlayIndex].ImgBuffer := nil;
  gOverlayImg[lOverlayIndex].ScrnBuffer := nil;
end;

procedure InitOverlays;
var
  I: integer;
begin
    gOpenOverlays := 0;
    for I := kMinOverlayIndex to kMaxOverlays do
      InitOverlay(I);
end;

procedure TGLForm1.OverlayBoxCreate;
begin
 InitOverlays;
 InterpolateMenu.checked := gPrefs.InterpolateOverlays;
 OverlayColorFromZeroMenu.checked := gPrefs.OverlayColorFromZero;
 SetSubmenuWithTag(Onotheroverlays1,gPrefs.OverlayAlpha);
 SetOverlayAlphaValue( gPrefs.OverlayAlpha);
 SetBackgroundAlphaValue( gPrefs.BackgroundAlpha);
 SetSubmenuWithTag(Onbackground1,gPrefs.BackgroundAlpha);
 StringGrid1.Selection := TGridRect(Rect(-1, -1, -1, -1));
 StringGrid1.DefaultRowHeight := LUTdrop.Height+1;
 StringGrid1.DefaultColWidth := (StringGrid1.width div 4)-2;
 {$IFDEF FPC} {$IFNDEF UNIX} //removed July 2017: Lazarus 1.8 repainting issues?
 //if Screen.PixelsPerInch <> 96 then
 //    StringGrid1.DefaultColWidth := round(StringGrid1.width* (Screen.PixelsPerInch/96) * 0.25) - 2;
{$ENDIF}{$ENDIF}
 //{$ENDIF}
 //LUTdrop.Visible := False;
 //UpdateColorSchema;
 StringGrid1.Cells[kFname, 0] := 'Name';
 StringGrid1.Cells[kLUT, 0] := 'Color';
 StringGrid1.Cells[kMin, 0] := 'Min';
 StringGrid1.Cells[kMax, 0] := 'Max';

   LUTdrop.Items.Clear;
  LUTdrop.Items.Add('Grayscale');
  LUTdrop.Items.Add('Red');
  LUTdrop.Items.Add('Green');
  LUTdrop.Items.Add('Blue');
  LUTdrop.Items.Add('Violet [r+b]');
  LUTdrop.Items.Add('Yellow [r+g]');
  LUTdrop.Items.Add('Cyan [g+b]');
  UpdateColorSchemes(LUTdrop);
end;

procedure TGLForm1.FormCreate(Sender: TObject);
 var
  lQuality, i: integer;
  forceReset: boolean;
  s: string;
  c: char;
begin
{$IFDEF FPC} Application.ShowButtonGlyphs:= sbgNever; {$ENDIF}
  forceReset := false;
  gPrefs.InitScript := '';
  i := 1;
  while i <= ParamCount do begin
     s := ParamStr(i);
     if (length(s)> 1) and (s[1]='-') then begin
         c := upcase(s[2]);
         if c='R' then
            forceReset := true
         else if (i < paramcount) and (c='S') then begin
           inc(i);
           gPrefs.InitScript := ParamStr(i);
         end;
     end else //length > 1 char
       gPrefs.initScript := ParamStr(i);
     inc(i);
   end; //for each parameter
  if (not ResetIniDefaults) and (not forceReset) then
    IniFile(true,IniName,gPrefs)
  else begin
    SetDefaultPrefs(gPrefs,true);//reset everything to defaults!
    lQuality := SimpleGetInt('Set graphics card (0=old, 1=poor, 2=ok, 3=great)',0,3,3);
    if lQuality = 0 then gPrefs.ForcePowerOfTwo := True
    else
        gPrefs.ForcePowerOfTwo := False;
    if lQuality = 1 then begin gPrefs.MaxVox := 90; gPrefs.RayCastQuality1to10 := 8; end;
    if lQuality = 2 then begin gPrefs.MaxVox := 256;  gPrefs.RayCastQuality1to10 := 5; end;
    if lQuality = 3 then begin gPrefs.MaxVox := 2048; gPrefs.RayCastQuality1to10 := 8; end;
    if gPrefs.FasterGradientCalculations then
      lQuality := 1
    else
        lQuality := 0;
    lQuality := SimpleGetInt('Set gradient calculation (0=slow[CPU], 1=fast[GPU])',0,lQuality,1);
    gPrefs.FasterGradientCalculations:= (lQuality <> 0);
  end;
  //gPrefs.FasterGradientCalculations := true;
  OpenDialog1.filter := kImgPlusVOIFilter;
  M_reload := 0;
  InitTexture(gTexture3D);
  OverlayBoxCreate;//after we read defaults
  //{$IFNDEF FPC}
  // gPrefs.FasterGradientCalculations := false; //Delphi GPU code crashes Windows XP computers - Lazarus fine for XP, Delphi fine for Win 7+
  //{$ENDIF}
 {$IFDEF USETRANSFERTEXTURE}
  IntensityBox.Visible := false;
 {$ENDIF}
 {$IFNDEF ENABLESCRIPT}Scripting1.visible := false;{$ENDIF}
 {$IFNDEF ENABLEOVERLAY}Overlays1.Visible := false;{$ENDIF}
 {$IFNDEF ENABLEMOSAICS}  Mosaic1.Visible := false;{$ENDIF}
 {$IFNDEF ENABLECUTOUT}
  CutoutBox.Visible := false;
 {$ELSE}
    {$IFDEF USETRANSFERTEXTURE}showmessage('Compiler error: 8-bit image with transfer texture does not yet support cutouts');{$ENDIF}
 {$ENDIF}
 UpdateMRU;
 LoadColorSchemes;
 DisplayPrefs;
 FormCreateShaders; //CreateAllControls;
  {$IFDEF FPC}
  {$IFDEF Darwin}Application.OnDropFiles:= AppDropFiles; {$ENDIF} //for OSX: respond if user drops icon on dock
  Application.ShowButtonGlyphs:= sbgNever;
  GLbox:= TOpenGLControl.Create(GLForm1);
  {$IFDEF COREGL}
  GLbox.OpenGLMajorVersion:= 3;
  GLbox.OpenGLMinorVersion:= 3;
  {$ENDIF}
  GLbox.AutoResizeViewport:= true;   // http://www.delphigl.com/forum/viewtopic.php?f=10&t=11311
  GLBox.Parent := GLForm1;
  GLBox.MultiSampling:= 4;
  GLBox.OnMouseWheel := GLboxMouseWheel;
  GLBox.OnPaint := GLboxPaint;
  {$ELSE}
  DragAcceptFiles(GLForm1.Handle, True);
  lQuality :=  DetectMutliSampleMode(4,GLForm1);
  GLBox := TGLPanel.Create(GLForm1);
  GLBox.Parent := GLForm1;
  rglSetupGL(GLbox, lQuality);
  {$ENDIF}
  GLBox.Align := alClient;
  //GLBox.ParentBackground:= false;
  GLBox.OnMouseDown := GLboxMouseDown;
  GLBox.OnMouseMove := GLboxMouseMove;
  GLBox.OnMouseUp := GLboxMouseUp;
  GLBox.OnDblClick :=  GLboxDblClick;
  GLBox.OnResize:= GLboxResize;
  //GLBox.DepthBits:= 0; //if set to zero, uncomment raycastglsl.pas glEnable(GL_CULL_FACE);
 ShaderDropChange(Sender);
 if gPrefs.FormMaximized then
  GLForm1.WindowState := wsMaximized
 else
  SetFormSize(gPrefs.FormWidth,gPrefs.FormHeight);
 //VolumeFilename := '+';
  MousePt.X := -1;
  //  loadlabelsITK('/Users/rorden/Documents/test.txt');
  {$IFDEF Darwin} //only for Carbon compile
      //    OnDropFiles := DropFiles;
      //GLBox.DoubleBuffered:= false; // DoubleBuffered
          Help1.visible := false;
        //Edit1.visible := false;
        NewWindow1.Visible:= true;
        Exit1.visible := false;//with OSX users quit from application menu
        Open1.ShortCut := ShortCut(Word('O'), [ssMeta]);
        Overlays1.ShortCut := ShortCut(Word('O'), [ssShift, ssMeta]);
        Tool1.ShortCut := ShortCut(Word('T'), [ssMeta]);
        //ToggleTransparency1.ShortCut := ShortCut(Word('A'), [ssMeta]);
        Backcolor1.ShortCut := ShortCut(Word('B'), [ssMeta]);
        InterpolateRecentMenu.ShortCut := ShortCut(Word('X'), [ssMeta]);
        //Copy1.ShortCut := ShortCut(Word('C'), [ssMeta]);
        //SaveVOI1.ShortCut :=  ShortCut(Word('S'), [ssMeta]);
        HideVOI1.ShortCut := ShortCut(Word('H'), [ssMeta]);
        PasteSlice1.ShortCut :=  ShortCut(Word('V'), [ssMeta]);
        UndoVOI1.ShortCut :=  ShortCut(Word('Z'), [ssMeta]);
        Eraser1.ShortCut :=  ShortCut(Word('E'), [ssMeta]);
        NoDraw1.ShortCut :=  ShortCut(Word('D'), [ssMeta]);
        Render1.ShortCut :=  ShortCut(Word('R'), [ssMeta]);
        Axial1.ShortCut :=  ShortCut(Word('A'), [ssMeta]);
        Coronal1.ShortCut :=  ShortCut(Word('C'), [ssMeta]);
        Sagittal1.ShortCut :=  ShortCut(Word('S'), [ssMeta]);
        MPR1.ShortCut :=  ShortCut(Word('M'), [ssMeta]);
        YokeMenu.ShortCut :=  ShortCut(Word('Y'), [ssMeta]);
        //in Cocoa: non-active menu intercepts keystrokes, so user typing in script form can not type "A" if that is used by main forms Axial menu
        LeftMenu.ShortCut :=  ShortCut(Word('L'), [ssCtrl]);
        RightMenu.ShortCut :=  ShortCut(Word('R'), [ssCtrl]);
        AnteriorMenu.ShortCut :=  ShortCut(Word('A'), [ssCtrl]);
        PosteriorMenu.ShortCut :=  ShortCut(Word('P'), [ssCtrl]);
        SuperiorMenu.ShortCut :=  ShortCut(Word('S'), [ssCtrl]);
        InferiorMenu.ShortCut :=  ShortCut(Word('I'), [ssCtrl]);
        {$ELSE}
        LeftMenu.ShortCut :=  ShortCut(Word('L'), [ssAlt]);
        RightMenu.ShortCut :=  ShortCut(Word('R'), [ssAlt]);
        AnteriorMenu.ShortCut :=  ShortCut(Word('A'), [ssAlt]);
        PosteriorMenu.ShortCut :=  ShortCut(Word('P'), [ssAlt]);
        SuperiorMenu.ShortCut :=  ShortCut(Word('S'), [ssAlt]);
        InferiorMenu.ShortCut :=  ShortCut(Word('I'), [ssAlt]);
   AppleMenu.visible := false;
 {$ENDIF}
 {$IFNDEF UNIX}BET1.Visible := false; {$ENDIF}
 QualityTrack.Position := gPrefs.RayCastQuality1to10;
 loadLabelsDefault;
 {$IFDEF COMPILEYOKE}
 if gPrefs.EnableYoke then begin
   YokeSepMenu.visible := true;
   YokeMenu.visible := true;
   CreateSharedMem(self);
   SetShareFloats2D(0,0,0);
   SetShareFloats2D(0,0,0); //twice so previous is set
   SetShareFloats3D(gRayCast.Azimuth, gRayCast.Elevation);
   SetShareFloats3D(gRayCast.Azimuth, gRayCast.Elevation); //twice so previous is set
 end;
 //SetShareMem (0,0,0, gRayCast.Azimuth, gRayCast.Elevation);
 //SetShareMem (0,0,0, gRayCast.Azimuth, gRayCast.Elevation); //twice to overwrite previous
 //YokeTimer.Enabled := gYoke;
{$ENDIF}
SetToolPanelWidth;
//gPrefs.FasterGradientCalculations := true;
//GLForm1.Caption:= inttostr(GetFontData(GLForm1.Font.Handle).Height)+'  '+inttostr(Screen.PixelsPerInch);
end;


function InColorBox(X, Y: Integer): boolean;
begin
    result := (X>=0) and (Y>=0) and (X < 260) and (Y < 260);
end;

procedure Bound (var Val: integer; Min,Max: integer);
begin
     if Val < Min then
        Val := Min;
     if Val > Max then
        Val := Max;
end;

procedure OrthoPix2Frac (X, Y: integer; var lOrient: integer; var lXfrac,lYfrac,lZfrac: single);
var
   lI: integer;
   lZoomDim: array [1..3] of single;
begin
   SetZooms (lZoomDim[1],lZoomDim[2],lZoomDim[3],gTexture3D);
   for lI := 1 to 3 do
     lZoomDim[lI] := lZoomDim[lI]*abs(gRayCast.OrthoZoom) * gTexture3D.FiltDim[lI];
   if (gPrefs.SliceView = 1) then begin  //if Axial
      lOrient := 1;
      lXfrac := X/lZoomDim[1];
      lYfrac := (lZoomDim[2]- (Y) )/lZoomDim[2];
      lZfrac := gRayCast.OrthoZ;
      exit;
   end; //Axial
   if (gPrefs.SliceView = 2) then begin  //if Coronal
      lOrient := 2;
      lXfrac := X/lZoomDim[1];
      lYfrac := gRayCast.OrthoY;
      lZFrac := (lZoomDim[3]-Y)/lZoomDim[3];
      exit;
   end; //Coronal
   if (gPrefs.SliceView = 3) then begin  //if Sagittal
      lOrient := 3;
      lXfrac := gRayCast.OrthoX;
      lYfrac := (X )/lZoomDim[2];
      lZFrac := (lZoomDim[3]-Y)/lZoomDim[3];
      exit;
   end; //Sagittal
   //following code for MPR views...
   if (X < lZoomDim[1]) and (Y < lZoomDim[3]) then begin //coronal
         lOrient := 2;
         lXfrac := X/lZoomDim[1];
         lYfrac := gRayCast.OrthoY;
         lZFrac := (lZoomDim[3]-Y)/lZoomDim[3];
   end else if (X < (lZoomDim[1] + lZoomDim[2])) and (Y < lZoomDim[3]) then begin //sag
         lOrient := 3;
         lXfrac := gRayCast.OrthoX;
         lYfrac := (X-lZoomDim[1] )/lZoomDim[2];
         lZFrac := (lZoomDim[3]-Y)/lZoomDim[3];
   end else if (X < lZoomDim[1]) and (Y < (lZoomDim[3]+lZoomDim[2])) then begin //axial
         lOrient := 1;
         lXfrac := X/lZoomDim[1];
         lYfrac := (lZoomDim[2]- (Y-lZoomDim[3]) )/lZoomDim[2];
         lZfrac := gRayCast.OrthoZ;
        //exit;
   end else
          lOrient := 0;
end;


procedure BoundF (var v: single; lMin,lMax: single);
begin
     if (v < lMin) then
       v := lMin
     else if (v > lMax) then
       v := lMax;
end;

procedure OrthoCoordMidSlice(X,Y,Z: single);
begin
 X := round(FracToSlice(gRayCast.OrthoX,gTexture3D.FiltDim[1]))-0.5 + X;
 Y := round(FracToSlice(gRayCast.OrthoY,gTexture3D.FiltDim[2]))-0.5 + Y;
 Z := round(FracToSlice(gRayCast.OrthoZ,gTexture3D.FiltDim[3]))-0.5 + Z;
 boundF(X,0.5, gTexture3D.FiltDim[1]-0.5);
 boundF(Y,0.5, gTexture3D.FiltDim[2]-0.5);
 boundF(Z,0.5, gTexture3D.FiltDim[3]-0.5);
 gRayCast.OrthoX := X/gTexture3D.FiltDim[1];
 gRayCast.OrthoY := Y/gTexture3D.FiltDim[2];
 gRayCast.OrthoZ := Z/gTexture3D.FiltDim[3];
(*//2015    FCX
  exit;
 lX := round(FracToSlice(gRayCast.OrthoX,gTexture3D.FiltDim[1]));
 lY := round(FracToSlice(gRayCast.OrthoY,gTexture3D.FiltDim[2]));
 lZ := round(FracToSlice(gRayCast.OrthoZ,gTexture3D.FiltDim[3]));
 //exit;
 lX := lX - 0.5;
 lY :=lY - 0.5;
 lZ :=lZ - 0.5;
 gRayCast.OrthoX := lX/gTexture3D.FiltDim[1];
 gRayCast.OrthoY := lY/gTexture3D.FiltDim[2];
 gRayCast.OrthoZ := lZ/gTexture3D.FiltDim[3];
 glform1.caption := floattostr(gRayCast.OrthoX)+' '+inttostr(gTexture3D.FiltDim[1])+'   '+floattostr(lX);
  *)
end;

procedure TGLForm1.OrthoClick(X,Y: integer);
 var
   lOrient: integer;
   lXfrac,lYfrac,lZfrac: single;

 begin
   OrthoPix2Frac (X, Y, lOrient,lXfrac,lYfrac,lZfrac);
   if lOrient < 1 then exit;
   gRayCast.OrthoX := lXfrac;
   gRayCast.OrthoY := lYfrac;
   gRayCast.OrthoZ := lZfrac;
   //OrthoCoordMidSlice;
   ShowOrthoSliceInfo (false);
   GLBox.Invalidate;
   if AutoRoiForm.Visible and (ssShift in KeyDataToShiftState(vk_Shift))  then
      AutoRoiForm.OriginBtnClick(nil);
end;
(*procedure TGLForm1.OrthoClick(X,Y: integer);
var
  lI: integer;
  lZoomDim: array [1..3] of single;
begin
  SetZooms (lZoomDim[1],lZoomDim[2],lZoomDim[3],gTexture3D);

  for lI := 1 to 3 do
    lZoomDim[lI] := lZoomDim[lI]*abs(gRayCast.OrthoZoom) * gTexture3D.FiltDim[lI];
  if (X < lZoomDim[1]) and (Y < lZoomDim[3]) then begin //coronal
    gRayCast.OrthoX := X/lZoomDim[1];
    gRayCast.OrthoZ := (lZoomDim[3]-Y)/lZoomDim[3];
    ShowOrthoSliceInfo;
    GLBox.Invalidate;
    exit;
  end;
  if (X < (lZoomDim[1] + lZoomDim[2])) and (Y < lZoomDim[3]) then begin //sag
    gRayCast.OrthoY := (X-lZoomDim[1] )/lZoomDim[2];
    gRayCast.OrthoZ := (lZoomDim[3]-Y)/lZoomDim[3];
      ShowOrthoSliceInfo;
    GLBox.Invalidate;
    exit;
  end;
  if (X < lZoomDim[1]) and (Y < (lZoomDim[3]+lZoomDim[2])) then begin //axial
    gRayCast.OrthoX := X/lZoomDim[1];
    gRayCast.OrthoY := (lZoomDim[2]- (Y-lZoomDim[3]) )/lZoomDim[2];
      ShowOrthoSliceInfo;
    GLBox.Invalidate;
    exit;
  end;
  //GLSceneViewer1DblClick(nil);
end; *)
{$IFDEF LCLCocoa}
procedure Mouse2Retina(var X,Y: integer);
begin
     if not gPrefs.RetinaDisplay then exit;
     X := round(X * gRetinaScale);
     Y := round(Y * gRetinaScale);
end;
{$ELSE}
procedure Mouse2Retina(var X,Y: integer);
begin
     //Retina display is MacOS feature
end;
{$ENDIF}

procedure TGLForm1.GLboxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; lX, lY: Integer);
var
  X,Y: integer;
begin
  {$IFNDEF FPC}
  GLBox.SetFocus;//without this the scroll wheel can adjust previously selected combobox
  {$ENDIF}
  if gPrefs.SliceView = 5 then exit; //mosaic
  X := lX; Y := lY; Mouse2Retina(X,Y);
  MouseStartPt.X := -1;
  if MouseDownVOI(Shift,X, Y) then exit; //intercepted by draw tool
  if  (SSRight in Shift) then begin
     MouseStartPt.X := X;
     MouseStartPt.Y := Y;
     exit;
  end;
  if (ssAlt in Shift) then begin
   if InColorBox(abs(X),abs(Y)) then
     ToggleTransparency1.Click
   else begin
     //OrthoSlice.Click;
   end;
   exit;
 end;
  if (gPrefs.ColorEditor) and (InColorBox(X,Y)) then begin
    ClutMouseDown(Button, Shift, X, Y);
    M_refresh := true;
    GLbox.invalidate;
    exit;
  end;
  If gPrefs.SliceView <> 0 then begin
    OrthoClick(X,Y);
    exit;
  end;
  MousePt.X := X;
  MousePt.Y := Y;
end;

procedure TGLForm1.GLboxMouseMove(Sender: TObject; Shift: TShiftState; lX,
  lY: Integer);
var
  zoom: single;
  X,Y: integer;
begin
 if gPrefs.SliceView = 5 then exit; //mosaic
 X := lX; Y := lY; Mouse2Retina(X,Y);
 if MouseMoveVOI (X, Y) then exit;
  if (SSLeft in Shift)  and (InColorBox(abs(X),abs(Y))) and (gPrefs.ColorEditor) and (gSelectedNode >= 0) then begin
     CLUTMouseMove(Shift, X, Y);
     M_refresh := true;
     GLbox.invalidate;
    exit;
  end;
  If (SSLeft in Shift)  and (gPrefs.SliceView <> 0) then begin
    OrthoClick(X,Y);
    exit;
  end;
  if MousePt.X < 1 then //only change if dragging mouse
     exit; //mouse button not down
  If  ((ssRight in Shift) or (ssShift in Shift)) then begin //change render depth
     if (gPrefs.SliceView = 0) then begin
         Zoom := ((Y-MousePt.Y)*0.025);
        gRayCast.Distance := gRayCast.Distance - zoom;
        if gRayCast.Distance > kMaxDistance then
           gRayCast.Distance := kMaxDistance;
        if gRayCast.Distance < 1 then
           gRayCast.Distance := 1.0;
     end;
  end else begin
     gRayCast.Azimuth := (gRayCast.Azimuth + (X-MousePt.X)) mod 360;
     while gRayCast.Azimuth < 0 do gRayCast.Azimuth := gRayCast.Azimuth + 360;
     gRayCast.Elevation := gRayCast.Elevation + (Y-MousePt.Y);
     Bound(gRayCast.Elevation,-90,90);
     {$IFDEF COMPILEYOKE}
     SetShareFloats3D(gRayCast.Azimuth, gRayCast.Elevation);
     {$ENDIF}
  end;
  MousePt.X := X;
  MousePt.Y := Y;
  GLbox.Invalidate;
end;

function VoxInten (lVox: integer): single;
var
  lV: integer;
begin
  result := 0;
  if (lVox < 1) then exit;
  if gTexture3D.RawUnscaledImg16 <> nil then
     result := gTexture3D.RawUnscaledImg16^[lVox]
  else if gTexture3D.RawUnscaledImg32 <> nil then
       result := gTexture3D.RawUnscaledImg32^[lVox]
  else if (gTexture3D.RawUnscaledImg8 <> nil) then
       result := gTexture3D.RawUnscaledImg8^[lVox]
  else if (gTexture3D.RawUnscaledImgRGBA <> nil) then begin
       lV := (lVox-1) * 4; //4 bytes (RGBA)
       result := 1/3*(gTexture3D.RawUnscaledImgRGBA^[lV+1]+gTexture3D.RawUnscaledImgRGBA^[lV+2]+gTexture3D.RawUnscaledImgRGBA^[lV+3]) ;
  end;
end;

procedure Raw2ScaledIntensity (var v: single);
begin

  if gTexture3D.NIFTIhdr.scl_slope = 0 then
	  v := v+gTexture3D.NIFTIhdr.scl_inter
  else
	  v := (v * gTexture3D.NIFTIhdr.scl_slope)+gTexture3D.NIFTIhdr.scl_inter;
end;

procedure TGLForm1.UpdateContrast (Xa,Ya, Xb, Yb: integer);
var
  X,Y, Xs,Xe,Ys,Ye,lOrients,lOriente,lVox, lLog10: integer;
  lXfrac,lYfrac,lZfrac,lMin, lMax, lVoxInten: single;
begin
     if (Xa = Xb) and (Ya = Yb) then exit;
     Xs := Xa; Xe := Xb; Ys := Ya; Ye := Yb;
     SortInteger(Xs,Xe);
     SortInteger(Ys,Ye);
     if gTexture3D.isLabels then exit;
     OrthoPix2Frac (Xs, Ys, lOrients,lXfrac,lYfrac,lZfrac);
     OrthoPix2Frac (Xe, Ye, lOriente,lXfrac,lYfrac,lZfrac);
     if lOrients <> lOriente then exit;
     lVox := FracToVox (lXfrac,lYfrac,lZfrac, gTexture3D.FiltDim[1], gTexture3D.FiltDim[2],gTexture3D.FiltDim[3]);
     lMin  := VoxInten(lVox);
     lMax := lMin;
     for Y := Ys to Ye do begin
       for X := Xs to Xe do begin
         OrthoPix2Frac (X, Y, lOrients,lXfrac,lYfrac,lZfrac);
         lVox := FracToVox (lXfrac,lYfrac,lZfrac, gTexture3D.FiltDim[1], gTexture3D.FiltDim[2],gTexture3D.FiltDim[3]);
         lVoxInten  := VoxInten(lVox);
         if (lVoxInten < lMin) then lMin := lVoxInten;
         if (lVoxInten > lMax) then lMax := lVoxInten;
       end;
     end;
     Raw2ScaledIntensity(lMin);
     Raw2ScaledIntensity(lMax);
     if lMax > lMin then begin
        lLog10 := trunc(log10( lMax-lMin))-1;
        lMin := roundto(lMin,lLog10);
        lMax := roundto(lMax,lLog10);
     end;
     SelectIntensityMinMax(lMin,lMax);
     glbox.Invalidate;
end;

procedure TGLForm1.GLboxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; lX, lY: Integer);
var
  X,Y: integer;
begin
 if (gPrefs.SliceView = 5) then exit; //mosaic
 X := lX; Y := lY; Mouse2Retina(X,Y);
 MouseUpVOI (Shift, X, Y) ;
 //if (SSRight in Shift) then begin
 if (gPrefs.SliceView <> 0) and (MouseStartPt.X >= 0) then begin
    UpdateContrast(MouseStartPt.X,MouseStartPt.Y,X,Y);
    //Caption := inttostr( MouseStartPt.X)+'  '+inttostr(X);
 end;
  MousePt.X := -X;
  MousePt.Y := -Y;
  gSelectedNode := -gSelectedNode;
end;

procedure TGLForm1.SetColorBarPosition;
begin
  if (gPrefs.ColorBarPosition < 1) or (gPrefs.ColorBarPosition > 4) then gPrefs.ColorBarPosition := 1;
  case gPrefs.ColorBarPosition of
      3: begin gClrbar.isTopOrRight := true; gClrbar.isVertical:=false; end; //top row
      4: begin gClrbar.isTopOrRight := true; gClrbar.isVertical:=true; end; //right column
      1: begin gClrbar.isTopOrRight := false; gClrbar.isVertical:=false; end;//bottom row
      2: begin gClrbar.isTopOrRight := false; gClrbar.isVertical:=true; end;//left column
  end;
   //gClrbar.isTopOrRight := true; gClrbar.isVertical:=false;
end;

procedure TGLForm1.GLboxDblClick(Sender: TObject);
var
  AbsNode: integer;
begin

  AbsNode := Abs(gSelectedNode);
  if (not (gPrefs.ColorEditor)) or (not InColorBox(abs(MousePt.X),abs(MousePt.Y))) then begin
    if not gPrefs.Colorbar then
      exit;
    gPrefs.ColorBarPosition := gPrefs.ColorBarPosition + 1;
    SetColorbarPosition;
    GLbox.invalidate;
    exit;
  end;
   ColorDialog1.Color := RGBA2TColor(gCLUTrec.nodes[AbsNode].rgba);
   if not ColorDialog1.Execute then
    exit;
   TColor2RGBA(ColorDialog1.Color, gCLUTrec.nodes[AbsNode].rgba);
   M_refresh := true;
   GLbox.invalidate;
end;

procedure TGLForm1.Quit2TextEditor;
{$IFDEF UNIX}
var
  AProcess: TProcess;
  {$IFDEF LINUX} I: integer; EditorFName : string; {$ENDIF}
begin
    {$IFDEF LINUX}
    EditorFName := FindDefaultExecutablePath('gedit');
   if EditorFName = '' then
     EditorFName := FindDefaultExecutablePath('tea');
    if EditorFName = '' then
      EditorFName := FindDefaultExecutablePath('nano');
    if EditorFName = '' then
      EditorFName := FindDefaultExecutablePath('pico');
    if EditorFName = '' then begin
       Showmessage(ExtractFilename(paramstr(0))+' will now quit. You can then use a text editor to modify the file '+IniName);
       Clipboard.AsText := EditorFName;
    end else begin
      EditorFName := '"'+EditorFName +'" "'+IniName+'"';
      Showmessage(ExtractFilename(paramstr(0))+' will now quit. Modify the settings with the command "'+EditorFName+'"');
         AProcess := TProcess.Create(nil);
         AProcess.InheritHandles := False;
         AProcess.Options := [poNewProcessGroup, poNewConsole];
         AProcess.ShowWindow := swoShow;
        for I := 1 to GetEnvironmentVariableCount do
            AProcess.Environment.Add(GetEnvironmentString(I));
         AProcess.Executable := EditorFName;
         AProcess.Execute;
         AProcess.Free;
    end;
    Clipboard.AsText := EditorFName;
    GLForm1.close;
    exit;
    {$ENDIF}
    Showmessage('Preferences will be opened in a text editor. The program '+ExtractFilename(paramstr(0))+' will now quit, so that the file will not be overwritten.');
    AProcess := TProcess.Create(nil);
    {$IFDEF UNIX}
      //AProcess.CommandLine := 'open -a TextEdit '+IniName;
      AProcess.Executable := 'open';
      AProcess.Parameters.Add('-e');
      AProcess.Parameters.Add(IniName);
    {$ELSE}
      AProcess.CommandLine := 'notepad '+IniName;
    {$ENDIF}
   Clipboard.AsText := AProcess.CommandLine;
  //AProcess.Options := AProcess.Options + [poWaitOnExit];
  AProcess.Execute;
  AProcess.Free;
  GLForm1.close;
end;
{$ELSE} //ShellExecute(Handle,'open', 'c:\windows\notepad.exe','c:\SomeText.txt', nil, SW_SHOWNORMAL) ;
begin
  gPrefs.SkipPrefWriting := true;
    Showmessage('Preferences will be opened in a text editor. The program '+ExtractFilename(paramstr(0))+' will now quit, so that the file will not be overwritten.');
   //GLForm1.SavePrefs;
    ShellExecute(Handle,'open', 'notepad.exe',PAnsiChar(AnsiString(IniName)), nil, SW_SHOWNORMAL) ;
  //WritePrefsOnQuit.checked := false;
  GLForm1.close;
end;
{$ENDIF}

(*procedure NewInstanceX;
 var
   AProcess: TProcess;
 begin
 //showmessage('xxx');
   AProcess := TProcess.Create(nil);
   AProcess.
   AProcess.CommandLine := 'open -n  '+paramstr(0);
   AProcess.CommandLine:= 'open -n /Users/rorden/Documents/osx/MRIcroGL.app/Contents/MacOS/MRIcroGL &';
   Clipboard.AsText := AProcess.CommandLine;
   //showmessage(AProcess.CommandLine);
   AProcess.Execute;
   AProcess.Free;
end; *)

procedure TGLForm1.About1Click(Sender: TObject);
const
  kSamp = 36;
var
  s: dword;
  debug : boolean;
  i: integer;
  str, fpsstr: string;
begin
   If (ssShift in KeyDataToShiftState(vk_Shift)) then begin
      M_Refresh := TRUE;
      GLForm1.UpdateTimer.Enabled := true;
      //GLbox.Invalidate;
    exit;
  end;
  debug := gPrefs.Debug;
  gPrefs.Debug := true; //display gradient timing
        M_Refresh := TRUE;
      //deleteGradients(gTexture3D);
 s := gettickcount;
 fpsstr := '';
 if (gPrefs.SliceView = 0) then begin //rendering
 for i := 1 to kSamp do begin
     gRayCast.Azimuth := (gRayCast.Azimuth + 10) mod 360;
     GLbox.Repaint;
  end;
  fpsstr := kCR+' FPS '+realtostr((kSamp*1000)/(gettickcount-s),1) ;
end;
   gPrefs.Debug := debug;
   {$IFDEF CPU64}
   str := '64-bit';
   {$ELSE}
   str := '32-bit';
   {$ENDIF}
   {$IFDEF Windows}str := str + ' Windows '; {$ENDIF}
   {$IFDEF LINUX}str := str + ' Linux '; {$ENDIF}
   {$IFDEF Darwin}str := str + ' OSX '; {$ENDIF}
   {$IFDEF LCLQT}str := str + ' (QT) '; {$ENDIF}
   {$IFDEF LCLGTK2}str := str + ' (GTK2) '; {$ENDIF}
   {$IFDEF LCLCocoa}str := str + ' (Cocoa) ';{$ENDIF}
   {$IFDEF LCLCarbon}str := str + ' (Carbon) '; {$ENDIF}
   {$IFDEF DGL} str := str +' (DGL) '; {$ENDIF}//the DGL library has more dependencies - report this if incompatibilities are found
  str := 'MRIcroGL '+str+' '+kVers
   {$IFDEF LCLCocoa}+kCR+' '+paramstr(0){$ENDIF}
   +kCR+' www.mricro.com :: BSD 2-Clause License (opensource.org/licenses/BSD-2-Clause)'
   +kCR+' Dimensions '+inttostr(gTexture3D.NIFTIhdr.dim[1])+'x'+inttostr(gTexture3D.NIFTIhdr.dim[2])+'x'+inttostr(gTexture3D.NIFTIhdr.dim[3])
   +kCR+' Bytes per voxel '+inttostr(gTexture3D.NIFTIhdr.bitpix div 8)
   +kCR+' Spacing '+realtostr(gTexture3D.NIFTIhdr.pixdim[1],2)+'x'+realtostr(gTexture3D.NIFTIhdr.pixdim[2],2)+'x'+realtostr(gTexture3D.NIFTIhdr.pixdim[3],2)
    +kCR+' Description  '+  trim(gTexture3D.NIFTIhdr.descrip)
    +kCR + gShader.Vendor
    + fpsstr
   +kCR+'Press "Abort" to quit and open settings '+ininame;
  i := MessageDlg(str,mtInformation,[mbAbort, mbOK],0);
  if i  = mrAbort then Quit2TextEditor;
end;

procedure TGLForm1.GLboxMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if Wheeldelta < 0 then
     gRayCast.Distance := gRayCast.Distance - 0.1
  else
      gRayCast.Distance := gRayCast.Distance + 0.1;
  if gRayCast.Distance > kMaxDistance then
     gRayCast.Distance := kMaxDistance;
  if gRayCast.Distance < 1 then
     gRayCast.Distance := 1.0;
  GLbox.Invalidate;
end;

function RGB2Color (r,g,b: single) : TColor;
begin
  result := round(r*255)+round(g*255) shl 8 + round(b*255) shl 16;
end;

procedure Color2RGB (Color : TColor; var r,g,b: single);
begin
  r := (Color and $ff)/$ff;
  g := ((Color and $ff00) shr 8)/255;
  b := ((Color and $ff0000) shr 16)/255;
end;

procedure TGLForm1.Backcolor1Click(Sender: TObject);
var
  c: byte;
begin
 If (ssShift in KeyDataToShiftState(vk_Shift)) then begin
         if gPrefs.BackColor.rgbGreen = 0 then
            c := 255
         else
             c := 0;
             gPrefs.BackColor.rgbRed:= c;
          gPrefs.BackColor.rgbGreen:= c;
          gPrefs.BackColor.rgbBlue:= c;
          gPrefs.BackColor.rgbReserved := 0;
          if gTexture3D.isLabels then M_Refresh := true; //make background match
          GLbox.Invalidate;
          exit;
 end;
 ColorDialog1.Color := RGBA2TColor(gPrefs.BackColor);
  if not ColorDialog1.Execute then
    exit;
  TColor2RGBA(ColorDialog1.Color,gPrefs.BackColor );
  gPrefs.BackColor.rgbReserved := 0;
  if gTexture3D.isLabels then M_Refresh := true; //make background match
  GLbox.Invalidate;
end;

procedure TGLForm1.Orient1Click(Sender: TObject);
begin
  gPrefs.SliceDetailsCubeAndText := Orient1.checked;
  GLbox.Invalidate;
end;

procedure TGLForm1.Tool1Click(Sender: TObject);
begin
  ToolPanel.visible := Tool1.checked;
  CollapsedToolPanel.Visible := not  Tool1.checked;
  GLForm1.Resize;
end;

procedure TGLForm1.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TGLForm1.LoadStartupImage;
var
  lFilename : string;
begin
  (*if gPrefs.PrevFilename[1] = '' then begin
      lFilename := 'mni152_2009_256';
      CheckFilename (lFilename,false);
      if not fileexists(lFilename) then begin
         lFilename := 'ch256';
         CheckFilename (lFilename,false);
      end;
      if fileexists(lFilename) then begin
         OpenDialog1.filename := lFilename;
        gPrefs.PrevFilename[1] := lFilename;
        FillMRU (gPrefs.PrevFilename, ExtractFileDirWithPathDelim(gPrefs.PrevFilename[1]),'.nii.gz',false);
        UpdateMRU;
      end;
  end else  *)
    lFilename := gPrefs.PrevFilename[1];
  {$IFDEF ENABLESCRIPT}
 AutoRunTimer1.enabled := ScriptForm.OpenParamScript;  //if user passes script as parameter when launching program, e.g. "mricrogl ~/myscript.gls"
 if not AutoRunTimer1.enabled then begin

     if gPrefs.StartupScript then begin
       //AutoRunTimer1.enabled := ScriptForm.OpenStartupScript;
       ScriptForm.OpenStartupScript;
       AutoRunTimer1.enabled := true; //run first script even if no script named 'startupscript' found
    end;
  end;
  if AutoRunTimer1.enabled then lFilename := '';   //we will run a script - don't waste time with external image
  {$ENDIF}
  CheckFilename (lFilename,false);
  if fileexists(lFilename) then begin
             OpenDialog1.filename := lFilename;
             Load_From_NIfTI (gTexture3D,lFilename,gPrefs.ForcePowerOfTwo, 1)
  end else
    Load_From_NIfTI (gTexture3D,'',gPrefs.ForcePowerOfTwo, 1);
end;

procedure TGLForm1.ShaderBoxResize(Sender: TObject);
begin
  if not ShaderBox.Visible then exit;
  if (ShaderPanel.Height <> ShaderPanelHeight) then
    ShaderPanel.Height := ShaderPanelHeight;
end;

(*const
kMinMemoSz= 32;
var
   lDesiredControlSz: integer;//420;
begin
  if not ShaderBox.Visible then exit;
  //if (ShaderBox.Height < 740) and (ShaderBox.Parent <> OverflowPanel) then
  //  ShaderBox.Parent := OverflowPanel
  //  else if (ShaderBox.Parent <> ToolPanel) then
  //    ShaderBox.Parent := ToolPanel;
  lDesiredControlSz := ShaderPanelHeight;
     if ShaderBox.ClientHeight > (lDesiredControlSz+kMinMemoSz) then begin
        ShaderMemo.Height := ShaderBox.ClientHeight - lDesiredControlSz;
        ShaderMemo.visible := true;
     end
     else
         ShaderMemo.visible := false;//ShaderMemo.Height := kMinMemoSz;
end;*)

procedure TGLForm1.ShowOrthoSliceInfo (isYoke: boolean);
//Updated Sept 2014 to include overlay information
var
  lXmm,lYmm,lZmm,lVoxInten : single;
  lVox: integer;
begin
     if gPrefs.SliceView = 0 then exit;
     lXmm := SliceMM (gRayCast.OrthoX,kSagLeftOrient); //Sag
     lYmm := SliceMM (gRayCast.OrthoY,kCoronalOrient); //Coronal
     lZmm := SliceMM (gRayCast.OrthoZ,kAxialOrient); //Axial
     {$IFDEF COMPILEYOKE}
     if (not isYoke) then
        SetShareFloats2D(lXmm,lYmm,lZmm);
     {$ENDIF}

     lVox := FracToVox (gRayCast.OrthoX,gRayCast.OrthoY,gRayCast.OrthoZ, gTexture3D.FiltDim[1], gTexture3D.FiltDim[2],gTexture3D.FiltDim[3]);
     if lVox < 1 then
        exit;
     lVoxInten  := VoxInten(lVox);
     if (gTexture3D.isLabels) and ( High(gTexture3D.LabelRA) > 0) then begin
         if (lVoxInten >=0) and (lVoxInten <= High(gTexture3D.LabelRA)) then
         {$IFDEF ENABLEOVERLAY}
          Caption := realtostr(lXmm,1)+'x'+realtostr(lYmm,1)+'x'+realtostr(lZmm,1)+'='+gTexture3D.LabelRA[round(lVoxInten)]+OverlayIntensityString(lVox);
          {$ELSE}
          Caption := realtostr(lXmm,1)+'x'+realtostr(lYmm,1)+'x'+realtostr(lZmm,1)+'='+gTexture3D.LabelRA[round(lVoxInten)];
          {$ENDIF}
         exit;
     end;
     Raw2ScaledIntensity(lVoxInten);
     {$IFDEF ENABLEOVERLAY}
     Caption := realtostr(lXmm,1)+'x'+realtostr(lYmm,1)+'x'+realtostr(lZmm,1)+'='+realtostr(lVoxInten,3) +OverlayIntensityString(lVox);
     {$ELSE}
     Caption := realtostr(lXmm,1)+'x'+realtostr(lYmm,1)+'x'+realtostr(lZmm,1)+'='+realtostr(lVoxInten,3);
     {$ENDIF}
end;

procedure TGLForm1.LoadDraw;
var
  lDestHdr: TMRIcroHdr;
begin
  if  (length(OpenDialogVoi.Filename) < 1) or (not fileexists(OpenDialogVoi.Filename)) then begin
     exit;
  end;
  if Reslice2Targ(OpenDialogVoi.Filename,gTexture3D.NIFTIhdr,lDestHdr,false,1 )='' then begin
       showmessage('Failed to load drawing '+OpenDialogVoi.Filename);
       caption := 'Failed to load drawing'+ OpenDialogVoi.Filename;
       exit;

  end;
  if not ImgToUint8  (lDestHdr,  lDestHdr.ImgBuffer) then begin//binarizes image <=0 -> 0, else 1
      freemem(lDestHdr.ImgBuffer);
      caption := 'datatype '+inttostr(lDestHdr.NIFTIHdr.datatype)+' bpp '+ inttostr(lDestHdr.ImgBufferBPP);
      showmessage('This version can only load 8-bit images for drawing');
      exit;
  end;

     voiCreate(gTexture3D.FiltDim[1], gTexture3D.FiltDim[2],gTexture3D.FiltDim[3], ByteP0(@lDestHdr.ImgBuffer^));
     //voiBinarize;
     freemem(lDestHdr.ImgBuffer);
end;

procedure TGLForm1.AutoDetectVOI;
begin
     if (not IsVOIExt(OpenDialog1.Filename)) and (fileexists (ParseFileName (OpenDialog1.FileName)+'.voi') ) then begin
           OpenDialogVoi.Filename := ParseFileName (OpenDialog1.FileName)+'.voi';
           M_reload := kOpenExistingVOI_reload;
     end;

end;

procedure TGLForm1.AutoRoi1Click(Sender: TObject);
begin
     AutoROIForm.Show;
end;

procedure TGLForm1.ConvertDicom1Click(Sender: TObject);
begin
  dcm2niiForm.showmodal;
end;

procedure TGLForm1.ClrbarClr(i: integer);
begin
 if (i < 1) or (i > 4) then i := 4;
 gPrefs.ColorbarColor:= i;
 Case i of
      1: begin
        gClrbar.BackColor := (RGBA(255,255,255,255));
        gClrbar.FontColor := (RGBA(0,0,0,255));
        WhiteClrbarMenu.checked := true;
      end;
      2: begin
        gClrbar.BackColor := (RGBA(255,255,255,168));
        gClrbar.FontColor := (RGBA(0,0,0,255));
        TransWhiteClrbarMenu.checked := true;
      end;
      3: begin
        gClrbar.BackColor := (RGBA(0,0,0,255));
        gClrbar.FontColor := (RGBA(255,255,255,255));
        BlackClrbarMenu.checked := true;
      end;
      else begin
        gClrbar.BackColor := (RGBA(0,0,0,168));
        gClrbar.FontColor := (RGBA(255,255,255,255));
        TransBlackClrbarMenu.checked := true;
      end;
 end;
end;

procedure TGLForm1.ClrbarMenuClick(Sender: TObject);
begin
     ClrbarClr((sender as TMenuItem).Tag);
     GLBox.Invalidate;
end;

procedure TGLForm1.GLboxPaint(Sender: TObject);
//var
//  OK: boolean;
//  i: integer;
//  LUT: TLUT;
begin

  if (gRendering) or (gRayCast.ScreenCapture) then exit;
  gRendering:=true;
  if gInitialSetup then begin //first time only!
    {$IFDEF DGL}
    InitOpenGL;
    ReadExtensions;
    ReadImplementationProperties;
    {$ELSE DGL}
    {$IFDEF COREGL}
    if not  Load_GL_VERSION_3_3_CORE then
       GLForm1.ShowmessageError('Unable to load OpenGL v3.3 Core: '+gpuReport);
    {$ELSE COREGL}
    if not  Load_GL_version_2_1 then
       GLForm1.ShowmessageError('Unable to load OpenGL v2.1: '+gpuReport);
    Load_GL_EXT_framebuffer_object;
    //Load_GL_ARB_framebuffer_object;
    Load_GL_EXT_texture_object;
    {$ENDIF COREGL}
    {$ENDIF DGL}
    {$IFDEF LCLCocoa}
    SetRetina;
    // GLBox.WantsBestResolutionOpenGLSurface:= gPrefs.RetinaDisplay;
    {$ENDIF}
    gRayCast.WINDOW_WIDTH := GLBoxBackingWidth;
    gRayCast.WINDOW_HEIGHT := GLboxBackingHeight;
    LoadStartupImage;
    AutoDetectVOI;
    gCube := TGLCube.Create(GLBox);
    gCube.TopLeft:= true;
    UpdateFont(true);
    SetColorbarPosition;
(*    ClrbarClr(gPrefs.ColorbarColor);
      for i := 0 to 255 do begin
      LUT[i].rgbRed := i;
      LUT[i].rgbGreen := 0;
      LUT[i].rgbBlue := 0;
  end;
  gClrbar.SetLUT(1, LUT, 10,20);
  for i := 0 to 255 do begin
      LUT[i].rgbRed := 0;
      LUT[i].rgbGreen := i;
      LUT[i].rgbBlue := 0;
  end;
  gClrbar.SetLUT(2, LUT, -5,5); *)
    ClrbarClr(gPrefs.ColorbarColor);
    GLBox.MakeCurrent();

    {$IFDEF LINUX}
    if gPrefs.NoveauWarning then WarningIfNoveau;
    {$ENDIF}
  end;

  if not AreaInitialized then begin
    gRayCast.WINDOW_WIDTH := GLBoxBackingWidth;
    gRayCast.WINDOW_HEIGHT := GLboxBackingHeight;
    if (GLbox.Height < 1) or (GLBoxBackingHeight <= GLbox.Height) then
       gRetinaScale := 1
    else
        gRetinaScale := GLBoxBackingHeight/GLbox.Height;
    if M_reload > 0 then begin
      voiClose;
      if Load_From_NIfTI (gTexture3D,OpenDialog1.Filename,gPrefs.ForcePowerOfTwo, M_reload) then begin
      Add2MRU(gPrefs.PrevFileName,OpenDialog1.Filename);

      UpdateMRU;
      M_reload := 0;
      AutoDetectVOI;
    end else
      M_reload := 0;
    end;
    InitGL (gInitialSetup);
    gRayCast.slices := round(FloatMaxVal(gTexture3D.FiltDim[1], gTexture3D.FiltDim[2],gTexture3D.FiltDim[3]) );
    if gRayCast.slices < 1 then
       gRayCast.slices := 100;
    AreaInitialized:=true;
    MinEdit.Text := float2str(gCLUTrec.min,3);
    MaxEdit.Text := float2str(gCLUTrec.max,3);
    if (gPrefs.SliceView > 0) and (gPrefs.SliceView < 5)  then
       ShowOrthoSliceInfo (false);
    if gInitialSetup then begin
       gInitialSetup := false;
       UpdateTimer.enabled := true;
    end;
  end;
  if (M_reload = kOpenExistingVOI_reload) then begin
     LoadDraw;
  end;
  M_reload := 0;
  if M_Refresh then begin
      {$IFNDEF USETRANSFERTEXTURE}
      Calculate_Transfer_Function;
      CreateHisto (gTexture3D,gCLUTrec.Min,gCLUTrec.Max,gTexture3D.WindowHisto, true);
      {$ELSE}
      UpdateTransferFunctionX(gCLUTrec,gRayCast.TransferTexture1D);
      CreateHisto (gTexture3D,gCLUTrec.Min,gCLUTrec.Max,gTexture3D.WindowHisto, true);
      {$ENDIF}
      UpdateClrbar;
      M_Refresh := false;
  end;
  DisplayGL(gTexture3D);
  {$IFDEF FPC}
  {$IFDEF LCLCarbon}
   GLbox.SwapBuffers; //DoubleBuffered
  {$ELSE}
  {$IFDEF Darwin} if gPrefs.isDoubleBuffer then {$ENDIF}
     GLbox.SwapBuffers; //DoubleBuffered
  {$ENDIF}
  (*if ( gRayCast.WINDOW_WIDTH = GLBox.BackingWidth) and (gRayCast.WINDOW_HEIGHT = GLbox.BackingHeight) then begin
    if gPrefs.isDoubleBuffer then
       GLbox.SwapBuffers //DoubleBuffered
  end else begin
        GLBox.Invalidate;

  end;*)
  {$ENDIF}
  gRendering:=false;
end;

procedure TGLForm1.GLboxResize(Sender: TObject);
begin
    AreaInitialized := false;
    GLbox.Invalidate;
    UpdateTimer.Enabled:=true;
end;

procedure TGLForm1.Open1Click(Sender: TObject);
begin
  TerminateRendering;
  if not OpenDialog1.Execute then
    LoadDatasetNIFTIvolx('',true)
  else
    LoadDatasetNIFTIvolx(OpenDialog1.FileName,true);
end;

procedure TGLForm1.ClipTrackChange(Sender: TObject);
begin
  gRayCast.ClipAzimuth:=AziTrack1.position;
  gRayCast.ClipElevation:=ElevTrack1.position;
  gRayCast.ClipDepth := ClipTrack.Position;
  {$IFNDEF FPC}  //On Windows changing this can make the other labels on the groupbox vanish
  ClipBox.Caption := 'Clip A:'+inttostr(AziTrack1.Position)+' E:'+inttostr(ElevTrack1.Position);
  {$ENDIF}
  //
  GLBox.Invalidate;
end;

procedure TGLForm1.AziElevChange(Sender: TObject);
begin
  gRayCast.LightAzimuth := LightAziTrack.Position;
  gRayCast.LightElevation := LightElevTrack.Position;
  GLBox.Invalidate;
end;

procedure TGLForm1.RecompileShader(oldQ, newQ: integer);
//recompile shader to-from level 10 (which uses bicubic)
begin
     if (oldQ = newQ) then exit; //no change
     if (oldQ <> 10) and (newQ <> 10) then exit; //neither used bicubic
     GLBox.MakeCurrent(false);
     InitGL (false);
     {$IFNDEF USETRANSFERTEXTURE}
     Calculate_Transfer_Function;
     CreateHisto (gTexture3D,gCLUTrec.Min,gCLUTrec.Max,gTexture3D.WindowHisto, true);
     {$ELSE}
     UpdateTransferFunctionX(gCLUTrec,gRayCast.TransferTexture1D);
     CreateHisto (gTexture3D,gCLUTrec.Min,gCLUTrec.Max,gTexture3D.WindowHisto, true);
     {$ENDIF}
     GLBox.ReleaseContext;
end;

procedure TGLForm1.QualityTrackChange(Sender: TObject);
var
  lPrev: integer;
begin
  lPrev := gPrefs.RayCastQuality1to10;
  gPrefs.RayCastQuality1to10 :=  QualityTrack.position;
  RecompileShader(lPrev, gPrefs.RayCastQuality1to10); //switch shader CUBIC_FILTER
  GLbox.Invalidate;
end;

procedure TGLForm1.ShaderDropChange(Sender: TObject);
begin
  SetShader(ShaderDir+pathdelim+ShaderDrop.Items[ShaderDrop.ItemIndex]+'.txt');
end;

procedure TGLForm1.UniformChange(Sender: TObject);
begin
  ShaderMemo.lines.BeginUpdate;
  ShaderMemo.lines.clear;
  ReportUniformChange(Sender);
  ShaderMemo.Lines.EndUpdate;
  GLbox.Invalidate;
end;

procedure TGLForm1.UpdateTimerTimer(Sender: TObject);
begin
 GLForm1.Refresh;
 // StringGridSetCaption(gPrevRow);
 UpdateTimer.Enabled := false;
  M_refresh := true;
  GLbox.Invalidate;
end;

procedure TGLForm1.ToggleTransparency1Click(Sender: TObject);
begin

  gPrefs.ColorEditor := ToggleTransparency1.checked;
  GLbox.Invalidate;
end;

procedure TGLForm1.FormClose(Sender: TObject; var TheAction: TCloseAction);
begin
 gRendering:=true;
  UpdateTimer.Enabled := false;
  GradientsIdleTimer.Enabled := false;
  StopScripts;
    if (not voiIsEmpty) and (voiIsModified) then
	SaveVOI1Click(nil);
  gPrefs.FormWidth := glForm1.Width;
  gPrefs.FormHeight := glForm1.Height;
  gPrefs.FormMaximized := glForm1.WindowState = wsMaximized;
  gPrefs.ShowToolbar := Tool1.checked;
 IniFile(false,IniName,gPrefs);
 Closeoverlays1Click(nil);
 InitTexture(gTexture3D);
 {$IFNDEF FPC}DragAcceptFiles(GLForm1.Handle, False);{$ENDIF}

 //gClipboardBitmap.Free;
end;

procedure TGLForm1.HideBtnClick(Sender: TObject);
begin
  XTrackBar.Position := 0;
  X2TrackBar.Position := 0;
  {$IFDEF FPC} CutoutChange(nil); {$ENDIF}
end;

type
  T4D = record
         X,Y,Z,D: single;
  end;

procedure TGLForm1.CutoutNearestSector(Sender: TObject);
var
  lDx: single;
  lMin,lTest: T4D;
  lDirection: integer;
begin

 lDx := sqrt(1/3); //unit circle: by pythgorean equation...
  lMin.D := 1.0 / 0.0;
  while gRaycast.Azimuth < 0 do gRaycast.Azimuth := gRaycast.Azimuth+ 360;
  //caption := inttostr(gRaycast.Azimuth)+'  '+inttostr(gRayCast.Elevation);
  for lDirection := 1 to 8 do begin
      if lDirection <= 4 then
        lTest.X := lDx
      else
        lTest.X := -lDx;
      Case lDirection of
        1,2,5,6: lTest.Y := lDx;
        else lTest.Y := -lDx;
      end;//Y case
      if odd(lDirection) then
        lTest.Z := lDx
      else
        lTest.Z := -lDx;
      if gRayCast.Elevation < 0 then
        lTest.D := (lTest.Z)
      else
        lTest.D := -(lTest.Z);
      if (gRaycast.Azimuth >= 90) and (gRaycast.Azimuth < 270) then    //gRayCast.Azimuth
        lTest.D := lTest.D-(lTest.Y)
      else
        lTest.D := lTest.D+(lTest.Y);
      if (gRaycast.Azimuth >= 0) and (gRaycast.Azimuth < 180) then //gRayCast.Azimuth
        lTest.D := lTest.D+(lTest.X)
      else
        lTest.D := lTest.D-(lTest.X);
      //lTest.D := sqrt(lTest.D);//pythagorean theorem Dx = sqrt(x^2+y^2+z^2)
      if lTest.D < lMin.D then begin //we have found a new minimum
        lMin.X := lTest.X;
        lMin.Y := lTest.Y;
        lMin.Z := lTest.Z;
        lMin.D := lTest.D;
        //showmessage(floattostr(lTest.D));
      end;//new minimum  end; //
    end; //for each possible hemiquadrant
      //now set quadrants based on outcome...
      if lMin.X < 0 then begin
        XTrackBar.Position := 0;
        X2TrackBar.Position := 500;
      end else begin
        XTrackBar.Position := 500;
        X2TrackBar.Position := 1000;
      end;
      if lMin.Y < 0 then begin
        YTrackBar.Position := 0;
        Y2TrackBar.Position := 500;
      end else begin
        YTrackBar.Position := 500;
        Y2TrackBar.Position := 1000;
      end;
      if lMin.Z < 0 then begin
        ZTrackBar.Position := 0;
        Z2TrackBar.Position := 500;
      end else begin
        ZTrackBar.Position := 500;
        Z2TrackBar.Position := 1000;
      end;
     {$IFDEF FPC} CutoutChange(nil); {$ENDIF}
end; //CutoutNearestSector

procedure TGLForm1.CutoutChange(Sender: TObject);
begin
  M_Refresh := TRUE;
  {$IFDEF ENABLESCRIPT}
  {$IFDEF darwin}
  //OSX can not use a timer during scripting
  if ScriptForm.PSScript1.running then
     exit;
  {$ENDIF}
  {$ENDIF}
  GLForm1.UpdateTimer.Enabled := true;
  if gPrefs.FasterGradientCalculations then
     GradientsIdleTimerReset;
end;

(*procedure TGLForm1.OrthoSliceClick(Sender: TObject);
begin
  gPrefs.OrthoSliceView := OrthoSlice.checked;
  GLbox.Invalidate;
end; *)

function Str2FloatSafe(S: string; var FloatVal: single): boolean;
var
  NewVal: single;
  errorPos: integer;
begin
  result := false;
  if length(S) < 1 then exit;
   Val(S, NewVal, errorPos);
  result := (errorPos = 0);
  if result then FloatVal := NewVal;
end;

procedure TGLForm1.MinMaxEditKeyPress(Sender: TObject; var Key: Char);
const
  AllowDec = true; FAllowNeg = true;
//var
  //p : integer;
  //s: string;
begin
 case Key of
  '-','0'..'9'  : ;
  '.',','   : if AllowDec AND (pos(DecimalSeparator,(Sender as TEdit).Text)=0)
                then  Key := DecimalSeparator
                else  Key:=#0;
  #8        : ;
  (*#45       : if FAllowNeg then
                begin
                  s := (Sender as TEdit).Text;
                  if (length(s) < 1) or (s[1] <> '-') then
                    (Sender as TEdit).Text := '-'+s
                  else
                     (Sender as TEdit).Text := Copy(s, 2,length(s)-1);
                  (Sender as TEdit).SelStart := length(s)+1;
                 Key:=#0;
                end;*)
  else
    Key:=#0;
 end;
end;

procedure TGLForm1.MinMaxEditKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Str2FloatSafe(MinEdit.Text,gCLUTrec.min) and Str2FloatSafe(MaxEdit.Text,gCLUTrec.max) then begin
    M_refresh := true;
    UpdateTimer.Enabled := true;
 end;
end;

procedure TGLForm1.ClrbarMenu1Click(Sender: TObject);
begin
  gPrefs.Colorbar := VisibleClrbarMenu.checked;
  GLBox.invalidate;
end;

procedure TGLForm1.AdjustFormPos (var lForm: TForm);
{$IFDEF FPC}
const
     kBorderHt = 30;
     kBorderWid = 10;
{$ELSE}
const
     kBorderHt = 0;
     kBorderWid = 0;
{$ENDIF}
const
{$IFDEF FPC}
kExtra = 8;
{$ELSE}
kExtra = 0;
{$ENDIF}
var
  lPos: integer;
  lVidX,lVidY,lLeft,lTop: integer;
begin
  ScreenRes(lVidX,lVidY);
  lPos := lForm.Tag;
  if odd(lPos) then begin//form on left
    lLeft := GLForm1.Left-lForm.Width-kBorderWid;
    if lLeft < 0 then //try putting the form on the right
       lLeft := GLForm1.Left+GLForm1.Width+kExtra; //form on right
  end else begin
    lLeft := GLForm1.Left+GLForm1.Width+kExtra;//-default: right
    if ((lLeft+ lForm.Width) > lVidX) then
       lLeft := GLForm1.Left-lForm.Width-kBorderWid; //try on right
  end;
  if lPos < 3 then begin //align with top
    lTop := GLForm1.Top; //default - align with top
    if lTop < 0 then //backup - top of screen
       lTop := 0;
  end else if lPos > 4 then begin //align with vertical middle
    lTop := GLForm1.Top+(GLForm1.Height div 2)-(lForm.Height div 2)+kBorderHt; //default - align with bottom
    if ((lTop+lForm.Height) > lVidY) then
       lTop := GLForm1.Top; //backup - align with top
    if lTop < 0 then
       lTop := 0;
  end else begin //align with bottom
    lTop := GLForm1.Top+GLForm1.Height-lForm.Height+kBorderHt; //default - align with bottom
    if ((lTop+lForm.Height) > lVidY) then
       lTop := GLForm1.Top; //backup - align with top
    if lTop < 0 then
       lTop := 0;
  end;
  if (lPos = 0) or ((lLeft+ lForm.Width) > lVidX) or (lLeft < 0)
    or (lTop < 0) or ((lTop+lForm.Height) > lVidY) then
    lForm.Position := poScreenCenter
  else begin
    lForm.Position := poDesigned;
    lForm.Left := lLeft;
    lForm.Top := lTop;
  end;
end;

procedure TGLForm1.Overlays1Click(Sender: TObject);
begin
//
end;

procedure TGLForm1.Mosaic1Click(Sender: TObject);
begin
 gPrefs.SliceView := (Sender as TMenuItem).tag;

 SetToolPanelWidth;
 //AdjustFormPos(TFOrm(MosaicPrefsForm));
 UpdateMosaic(Sender);
end;

procedure TGLForm1.Scripting1Click(Sender: TObject);
begin
{$IFDEF ENABLESCRIPT}
  AdjustFormPos(TForm(ScriptForm));
  ScriptForm.SHow;
{$ENDIF}
end;

function GetFloat(lStr: string; lMin,lDefault,lMax: single): single;
var
   s: string;
begin
  s := floattostr(ldefault);
  InputQuery('Integer required',lStr,s);
  try
     	result := StrToFloat(S);
  except
    on Exception : EConvertError do
      result := ldefault;
  end;
  if result < lmin then
  	 result := lmin;
  if result > lmax then
end;

procedure TGLForm1.BET1Click(Sender: TObject);
var
  lFrac: single;
  lB: string;
begin
  if not OpenDialog1.Execute then
    exit;
  lFrac := GetFloat('Brain extraction fraction (smaller values lead to larger brain volume)',0.1,0.45,0.9);
  lB := FSLbet(OpenDialog1.FileName,lFrac);
   LoadDatasetNIFTIvol1(lB,true);
end;

procedure TGLForm1.GradientsIdleTimerReset;
begin
     GradientsIdleTimer.Enabled := false;
     GradientsIdleTimer.Enabled := true;
     M_Refresh := TRUE;
end;

procedure TGLForm1.voiBinarize1Click(Sender: TObject);
begin
 voiBinarize(1);
 //voiInterpolate;
 GLForm1.UpdateGL;
end;

procedure TGLForm1.voiDescriptives1Click(Sender: TObject);
begin
  voiDescriptives;
end;

procedure TGLForm1.GradientsIdleTimerTimer(Sender: TObject);
begin
     GradientsIdleTimer.Enabled := false;
     GLbox.Invalidate;
end;

procedure IncTrackBar (T: TTrackBar; isDepthTrack: boolean);
var
   i: integer;
begin
     i := (T.Max div 4);
     i := ((i+T.Position) div i) * i;
     if i >= T.Max then i := T.Min;
     T.position := i;
     if not(isDepthTrack) and (T.position <> 0) and (GLForm1.ClipTrack.position = 0) then
       GLForm1.ClipTrack.Position := GLForm1.ClipTrack.Max div 2;
end;

procedure TGLForm1.Label4Click(Sender: TObject);
begin
     IncTrackBar(ClipTrack, true);
end;

procedure TGLForm1.Label5Click(Sender: TObject);
begin
 IncTrackBar(AziTrack1, false);
end;

procedure TGLForm1.Label6Click(Sender: TObject);
begin
       IncTrackBar(ElevTrack1, false);
end;

procedure TGLForm1.Extract1Click(Sender: TObject);
begin
 {$IFDEF USETRANSFERTEXTURE}
  showmessage('Not yet available in this version');
 {$ELSE}
 if gTexture3D.RawUnscaledImgRGBA <> nil then begin
   showmessage('Only able to extract grayscale images (not RGB color images).');
    exit;
 end;
 ExtractForm.ShowModal;
 ExtractTexture (gTexture3D, ExtractForm.OtsuLevelsEdit.value, ExtractForm.DilateEdit.value, ExtractForm.OneContiguousObjectCheck.checked);
 M_refresh := true;
 UpdateTimer.Enabled := true;
 {$ENDIF}
end;


procedure TGLForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  X,Y,Z: single;
begin
 //if not GLForm1.Focused then exit; //e.g. do not intercept key srokes if use is editing a script!
 //Requires Form.KeyPreview := true;
 if gPrefs.SliceView < 1 then exit;
 X := 0; Y := 0; Z := 0;
 Case Key of
   36: Y := -1.0; //home  Fn+left_arrow on OSX
   35: Y := +1.0; //end   Fn+right_arrow on OSX
   37: X := -1.0; //left arrow
   38: Z := +1.0; //up arrow
   39: X := +1.0; //right arrow
   40: Z := -1.0; //down arrow
 end; //case Key
 if (X = 0) and (Y = 0) and (Z = 0) then exit;
 OrthoCoordMidSlice(X,Y,Z);
 (*X := round(FracToSlice(gRayCast.OrthoX,gTexture3D.FiltDim[1]))-0.5 + X;
 Y := round(FracToSlice(gRayCast.OrthoY,gTexture3D.FiltDim[2]))-0.5 + Y;
 Z := round(FracToSlice(gRayCast.OrthoZ,gTexture3D.FiltDim[3]))-0.5 + Z;
 boundF(X,0.5, gTexture3D.FiltDim[1]-0.5);
 boundF(Y,0.5, gTexture3D.FiltDim[2]-0.5);
 boundF(Z,0.5, gTexture3D.FiltDim[3]-0.5);
 gRayCast.OrthoX := X/gTexture3D.FiltDim[1];
 gRayCast.OrthoY := Y/gTexture3D.FiltDim[2];
 gRayCast.OrthoZ := Z/gTexture3D.FiltDim[3]; *)
 UpdateGL;
end;

procedure TGLForm1.MinMaxEditExit(Sender: TObject);
begin
    //Cursor := crDefault;
end;


procedure TGLForm1.UpdateFont(initialSetup: boolean);
var
  p,f: string;
  OK: boolean;
begin
     p := (ClutDir+pathdelim+gPrefs.FontName+'.png');
     f := (ClutDir+pathdelim+gPrefs.FontName+'.json');
     if (gPrefs.FontName = '') or (not fileexists(p)) or (not fileexists(f)) then begin
       gPrefs.FontName := '';
       p := '';
     end;
     if initialSetup then begin
       gClrbar:= TGLClrbar.Create(p, GLBox);
       if (gPrefs.ColorbarSize < 0.01) or (gPrefs.ColorbarSize > 0.3) then
          gPrefs.ColorbarSize := gClrbar.SizeFraction;
       gClrbar.SizeFraction := gPrefs.ColorbarSize;
       gText := TGLText.Create(p,OK,GLBox);
     end
     else begin
         gText.ChangeFontName(p, GLBox);
         gClrBar.ChangeFontName(p, GLBox);
         GLBox.Invalidate;
     end;
end;

{$IFDEF UNIX}
function latestGitRelease(url: string): string;
//Returns string for latest release (error will return empty string)
//example
// latestGitRelease('https://api.github.com/repos/rordenlab/dcm2niix/releases/latest');
//will return
// "v1.0.20171204"
const
     key = '"tag_name":"';
var
  s, e: integer;
  cli: TFPHTTPClient;
begin
  result := '';
  cli := TFPHTTPClient.Create(nil);
  cli.AddHeader('User-Agent','Mozilla/5.0 (compatible; fpweb)');
  try
    try
      result := Cli.Get(url);
    except
      result := '';
    end;
  finally
    cli.free
  end;
  if length(result) < 1 then exit;
  s := posex(key, result);
  if s < 1 then begin
     result := '';
     exit;
  end;
  s := s+length(key);
  e:= posex('"', result, s);
  if e < 1 then begin
     result := '';
     exit;
  end;
  result := copy(result, s, e-s);
end;

procedure ReportGitVer(localVer, api, url, exe: string);
var
  gitVer, exeNam: string;
  git, local: integer;
begin
  if length(localVer) < 8 then begin  //last 8 digits are date: v.1.0.20170101
    MessageDlg(exeNam,'Unable to detect version:  '+exe, mtConfirmation,[mbOK],0) ;
    //showmessage('Unable to detect latest version:  '+exe);
    Clipboard.AsText := exe+' : '+ localVer;
    exit;
  end;
  gitVer := latestGitRelease(api);
  if length(gitVer) < 8 then begin  //last 8 digits are date: v.1.0.20170101
      showmessage('Unable to detect latest version: are you connected to the web and do you have libssl installed? '+api);
      exit;
  end;
  exeNam := ExtractFileName(exe);
  if CompareText(gitVer, localVer) = 0 then begin
      //showmessage('You are running the latest release '+localVer);
      MessageDlg(exeNam,'You are running the latest release '+localVer, mtConfirmation,[mbOK],0) ;
      exit;
  end;
  git := strtointdef(RightStr(gitVer,8),0);
  local := strtointdef(RightStr(localVer,8),0);
  if local > git then
     MessageDlg(exeNam,'You are running a beta release '+localVer+', the latest stable release is '+gitVer+' Visit '+url +' to update '+exe, mtConfirmation,[mbOK],0)

     //showmessage('You are running a beta release '+localVer+', the latest stable release is '+gitVer+' Visit '+url +' to update '+exe)
  else
    MessageDlg(exeNam,'You are running an old release '+localVer+', the latest stable release is '+gitVer+' Visit '+url +' to update '+exe, mtConfirmation,[mbOK],0)
          //showmessage('You are running an old release '+localVer+', the latest stable release is '+gitVer+' Visit '+url +' to update '+exe);
end;

procedure CheckForUpdatesMRIcroGL;
const
     kBase = '/neurolabusc/MRIcroGL/releases/latest';
     kUrl = 'https://github.com' + kBase;
     kApi = 'https://api.github.com/repos' + kBase;
begin
     ReportGitVer(kVers, kApi, kUrl, paramstr(0));
end;

function delimStr(s, default: string; idx: integer): string;
//e.g. delimStr('Chris Rorden's dcm2niiX version v1.0.20171215 GCC6.1.0',5) returns 'v1.0.20171215'
var
   strs : TStringList;
begin
     result := default;
     strs := TStringList.Create;
     strs.DelimitedText := s;
     if (strs.Count >= idx) then
        result := strs[idx-1]; //string lists are indexed from 0
     strs.Free;
end;

procedure CheckForUpdatesDcm2niix;
const
     kBase = '/rordenlab/dcm2niix/releases/latest';
     kUrl = 'https://github.com' + kBase;
     kApi = 'https://api.github.com/repos' + kBase;
var
  exe, cmd, line1, localVer: string;
begin
    exe := dcm2niiForm.getExeName;
    if not fileexists(exe) then begin
       showmessage('Unable to find dcm2niix installed '+ exe);
       exit;
    end;
    cmd := '"'+exe +'" -h';
    dcm2niiForm.RunCmd(cmd, false, line1);
    localVer := delimStr(line1, line1, 5);
    ReportGitVer(localVer, kApi, kUrl, exe);
end;

(*
//this is an alternate method, using dcm2niix's internal methods: has additional dependencies (sed, awk) and Unix only
procedure CheckForUpdatesDcm2niix;
var
  exe, cmd: string;
  ret: integer;
begin
     exe := dcm2niiForm.getExeName;
     if not fileexists(exe) then begin
        showmessage('Unable to find dcm2niix installed '+ exe);
     end;
     cmd := '"'+exe +'" -u';
     ret := dcm2niiForm.RunCmd(cmd, false);
     if ret = 3 then
        showmessage('Unable to check dcm2niix version')
     else if ret = 2 then
          showmessage('Your version of dcm2niix is more recent than latest stable release '+exe)
     else if ret = 1 then
        showmessage('Your version of dcm2niix is obsolete '+exe)
     else
         showmessage('Your version of dcm2niix is up to date');
end;*)


procedure TGLForm1.CheckForUpdates(Sender: TObject);
begin
     CheckForUpdatesMRIcroGL;
     CheckForUpdatesDcm2niix;
end;
{$ELSE}
procedure TGLForm1.CheckForUpdates(Sender: TObject);
begin
	//not available for windows
end;

{$ENDIF}

procedure PrefMenuClick;
var
  PrefForm: TForm;
  bmpEdit: TEdit;
  {$IFDEF FPC}TiledCheck,{$ENDIF}
  {$IFDEF LCLCocoa} RetinaCheck,{$ENDIF} flipCheck: TCheckBox;
  {$IFDEF FPC}UpdateBtn: TButton;{$ENDIF}
  OkBtn, AdvancedBtn: TButton;
  bmpLabel: TLabel;
  searchRec: TSearchRec;
  s: string;
  FontCombo : TComboBox;
  isFontChanged, isFlipChanged,isAdvancedPrefs  {$IFDEF LCLCocoa}, isRetinaChanged {$ENDIF}: boolean;
begin
  PrefForm:=TForm.Create(nil);
  PrefForm.SetBounds(100, 100, 520, 212);
  PrefForm.Caption:='Preferences';
  PrefForm.Position := poScreenCenter;
  PrefForm.BorderStyle := bsDialog;
  {$IFNDEF FPC}PrefForm.AutoSize := true;{$ENDIF}
  //flipCheck
  flipCheck:=TCheckBox.create(PrefForm);
  flipCheck.Checked := gPrefs.FlipYZ;
  flipCheck.Caption:='Flip Y/Z axis (animal scans)';
  flipCheck.Left := 8;
  flipCheck.Top := 18;
  flipCheck.Parent:=PrefForm;
  //Bitmap Scale
  bmpLabel:=TLabel.create(PrefForm);
  bmpLabel.Left := 8;
  bmpLabel.Top := 48;
  bmpLabel.Width := PrefForm.Width - 86;
  bmpLabel.Caption := 'Bitmap zoom (large values create huge images)';
  bmpLabel.Parent:=PrefForm;
  //bmp edit
  bmpEdit := TEdit.Create(PrefForm);
  bmpEdit.Left := PrefForm.Width - 76;
  bmpEdit.Top := 48;
  bmpEdit.Width := 60;
  bmpEdit.Text := inttostr(gPrefs.BitmapZoom);
  bmpEdit.Parent:=PrefForm;
  //Font name
  FontCombo:=TComboBox.create(PrefForm);
  FontCombo.Parent:=PrefForm;
  FontCombo.Left := 8;
  FontCombo.Top := 78;
  FontCombo.Width := PrefForm.Width -16;
  FontCombo.Items.Add('Default Font');
  //add fonts
  FontCombo.ItemIndex:= 0;
  if FindFirst(ClutDir+pathdelim+'*.json', faAnyFile, searchRec) = 0 then begin
    repeat
      s :=ParseFileName(ExtractFileName(searchRec.Name));
      if (length(s) > 1) and (s[1] <> '.') and (fileexists(ClutDir+pathdelim+s+'.png')) then begin
         FontCombo.Items.Add(s);
         if (s = gPrefs.FontName) then
            FontCombo.ItemIndex := FontCombo.Items.Count-1;
      end;
    until (FindNext(searchRec) <> 0);
  end; //find fonts
  FindClose(searchRec);
  FontCombo.Style := csDropDownList;
  FontCombo.Parent:=PrefForm;
  //Tiled Check
  {$IFDEF FPC}
  TiledCheck:=TCheckBox.create(PrefForm);
  TiledCheck.Checked := gPrefs.isTiledScreenShot;
  TiledCheck.Caption:='Tiled bitmaps (more compatible)';
  TiledCheck.Left := 8;
  TiledCheck.Top := 108;
  TiledCheck.Parent:=PrefForm;
  {$ENDIF}
  //Retina Check
  {$IFDEF LCLCocoa}
  RetinaCheck:=TCheckBox.create(PrefForm);
  RetinaCheck.Checked := gPrefs.RetinaDisplay;
  RetinaCheck.Caption:='Retina display (better but slower)';
  RetinaCheck.Left := 8;
  RetinaCheck.Top := 138;
  RetinaCheck.Parent:=PrefForm;
  {$ENDIF}
  //UpdateBtn
  {$IFDEF UNIX}
  UpdateBtn:=TButton.create(PrefForm);
  UpdateBtn.Caption:='Check for updates';
  UpdateBtn.Left := 28;
  UpdateBtn.Width:= 168;
  UpdateBtn.Top := 168;
  UpdateBtn.Parent:=PrefForm;
  UpdateBtn.OnClick:= GLForm1.CheckForUpdates;
  {$ENDIF}
  //UpdateBtn.ModalResult:= mrOK;

  //OK button
  OkBtn:=TButton.create(PrefForm);
  OkBtn.Caption:='OK';
  OkBtn.Left := PrefForm.Width - 128;
  OkBtn.Width:= 100;
  OkBtn.Top := 168;
  OkBtn.Parent:=PrefForm;
  OkBtn.ModalResult:= mrOK;
  //Advanced button
  AdvancedBtn:=TButton.create(PrefForm);
  AdvancedBtn.Caption:='Advanced';
  AdvancedBtn.Left := PrefForm.Width - 256;
  AdvancedBtn.Width:= 100;
  AdvancedBtn.Top := 168;
  AdvancedBtn.Parent:=PrefForm;
  AdvancedBtn.ModalResult:= mrYesToAll;
  {$IFDEF Windows} ScaleDPI(PrefForm, 96);  {$ENDIF}
  PrefForm.ShowModal;
  if (PrefForm.ModalResult <> mrOK) and (PrefForm.ModalResult <> mrYesToAll) then begin
  	FreeAndNil(PrefForm);
  	exit; //if user closes window with out pressing "OK"
  end;
  isFlipChanged := (gPrefs.FlipYZ <> FlipCheck.Checked);
  gPrefs.FlipYZ:= FlipCheck.Checked;
  gPrefs.BitmapZoom:= strtointdef(bmpEdit.Text,1);
  if gPrefs.BitmapZoom < 1 then gPrefs.BitmapZoom := 1;
  if gPrefs.BitmapZoom > 10 then gPrefs.BitmapZoom := 10;
  isAdvancedPrefs := (PrefForm.ModalResult = mrYesToAll);
  {$IFDEF FPC}
  gPrefs.isTiledScreenShot := TiledCheck.Checked;
  {$ENDIF}
  {$IFDEF LCLCocoa}
  isRetinaChanged := gPrefs.RetinaDisplay <> RetinaCheck.Checked;
  gPrefs.RetinaDisplay := RetinaCheck.Checked;
  {$ENDIF}
  s := '';
  if FontCombo.ItemIndex > 0 then
     s := FontCombo.Items[FontCombo.ItemIndex];
  isFontChanged := (s <> gPrefs.FontName);
  gPrefs.FontName := s;
  FreeAndNil(PrefForm);
  if  isAdvancedPrefs then begin
     GLForm1.Quit2TextEditor;
     exit;
  end;
  if isFlipChanged then
       GLForm1.OpenMRU(nil);
  if isFontChanged then
       GLForm1.UpdateFont(false);
  {$IFDEF LCLCocoa}
  if isRetinaChanged then begin
     GLForm1.SetRetina;
     //GLBox.WantsBestResolutionOpenGLSurface:=gPrefs.RetinaDisplay;
    AreaInitialized := false;
    //M_Refresh := true;
     GLForm1.UpdateTimer.enabled := true;
  end;
  {$ENDIF}

end; // PrefMenuClick()

procedure SetBitmapZoom;
begin
     gPrefs.BitmapZoom := ReadIntForm.GetInt('Bitmap zoom (large values create huge images)',1,gPrefs.BitmapZoom,10);
end; // SetBitmapZoom()

procedure TGLForm1.Preferences1Click(Sender: TObject);
begin
     PrefMenuClick;//SetBitmapZoom;
end;

procedure TGLForm1.NewWindow1Click(Sender: TObject);
{$IFNDEF UNIX}
begin
   ShellExecute(handle,'open',PChar(paramstr(0)), '','',SW_SHOWNORMAL); //uses ShellApi;
end;
{$ELSE}
var
    AProcess: TProcess;
    i : integer;
    //http://wiki.freepascal.org/Executing_External_Programs
begin
  IniFile(false,IniName,gPrefs);  //load new window with latest settings
  AProcess := TProcess.Create(nil);
  AProcess.InheritHandles := False;
  //AProcess.Options := [poNoConsole];  //poNoConsole is Windows only! http://lazarus-ccr.sourceforge.net/docs/fcl/process/tprocess.options.html
  //AProcess.ShowWindow := swoShow; //Windows only http://www.freepascal.org/docs-html/fcl/process/tprocess.showwindow.html
  for I := 1 to GetEnvironmentVariableCount do
      AProcess.Environment.Add(GetEnvironmentString(I));
  {$IFDEF Darwin}
  AProcess.Executable := 'open';
  AProcess.Parameters.Add('-n');
  AProcess.Parameters.Add('-a');
  AProcess.Parameters.Add(paramstr(0));
  {$ELSE}
  AProcess.Executable := paramstr(0);
  {$ENDIF}
  //AProcess.Parameters.Add('/Users/rorden/Documents/osx/MRIcroGL.app/Contents/MacOS/MRIcroGL');
  AProcess.Execute;
  AProcess.Free;
end;
{$ENDIF}

procedure  TGLForm1.Copy1Click(Sender: TObject);
var bmp: TBitmap;
begin
  if (ssShift in KeyDataToShiftState(vk_Shift)) then
    setBitmapZoom;
  bmp := ScreenShot(gPrefs.BitmapZoom);
  Clipboard.Assign(bmp);
  bmp.Free;
end;

(*procedure  TGLForm1.Copy1Click(Sender: TObject);
{$IFNDEF FPC}
var
  MyFormat : Word;
  AData    : THandle;
  APalette : hPalette;  // Wrong in D3-D7 online example
{$ENDIF}
begin
  if not GenerateClipboardImage then exit;
  {$IFDEF FPC}
  gClipboardBitmap.SaveToClipboardFormat(2);
  {$ELSE}
   gClipboardBitmap.SaveToClipBoardFormat(MyFormat,AData,APalette);
    ClipBoard.SetAsHandle(MyFormat,AData);
  {$ENDIF}
end; *)

{$IFNDEF FPC}
{$IFDEF PNG} //proprietary PNGIMAGE IN PATH

procedure SaveImgAsPNGCore (var lImage: TBitmap; lFilename: string);
var
  PNG: TPNGObject;
begin
	if (lImage = nil) then begin
		Showmessage('No image found to save.');
		exit;
	end;
  PNG := TPNGObject.Create;
  try
    PNG.Assign(lImage);    //Convert data into png
    PNG.SaveToFile(ChangeFileExt(lFilename,'.png'));
  finally
    PNG.Free;
  end
end;
{$ELSE}
procedure SaveImgAsPNGCore (var lImage: TBitmap; lFilename: string);
begin
	if (lImage = nil) then begin
		Showmessage('No image found to save.');
		exit;
	end;
  lImage.SaveToFile(ChangeFileExt(lFilename,'.bmp'));
end;

{$ENDIF}
{$ELSE}
procedure SaveImgAsPNGCore (lImage: TBitmap; lFilename: string);
var
  PNG: TPortableNetworkGraphic;
begin
	if (lImage = nil) then begin
		Showmessage('No image found to save.');
		exit;
	end;
  PNG := TPortableNetworkGraphic.Create;
  try
    PNG.Assign(lImage);    //Convert data into png
    PNG.SaveToFile(ChangeFileExt(lFilename,'.png'));
  finally
    PNG.Free;
  end
end;
{$ENDIF}

{$IFDEF FPC}
procedure SaveImgAsJPGCore (lImage: TBitmap; lFilename: string);
var
  JpegImg : TJpegImage;
begin
   JpegImg := TJpegImage.Create;
   try
    JpegImg.Assign(lImage) ;
    JpegImg.SaveToFile(ChangeFileExt(lFilename,'.jpg')) ;
   finally
    JpegImg.Free
   end;
end;
{$ELSE}
procedure SaveImgAsJPGCore (lImage: TBitmap; lFilename: string);
begin
  lImage.SaveToFile(ChangeFileExt(lFilename,'.bmp'));
end;
{$ENDIF}

procedure TGLForm1.SavePicture(lFilename: string);
var bmp: TBitmap;
begin
  bmp := ScreenShot(gPrefs.BitmapZoom);
  if (UpCaseExt(lFilename) = '.JPG') or (UpCaseExt(lFilename) = '.JPEG') then
    SaveImgAsJPGCore (bmp, lFilename)
  else
    SaveImgAsPNGCore (bmp, lFilename);
  bmp.Free;
end; //proc SavePicture


procedure TGLForm1.Save1Click(Sender: TObject);
begin
 if (ssShift in KeyDataToShiftState(vk_Shift)) then
    setBitmapZoom;
 {$IFNDEF FPC}{$IFNDEF PNG}
 SaveDialog1.DefaultExt := '*.bmp';
 SaveDialog1.Filter := 'Bitmap|*.bmp';
 {$ENDIF}{$ENDIF}
 if (SaveDialog1.initialDir = '') and fileexists(OpenDialog1.Filename) then
    SaveDialog1.initialDir := ExtractFileDirWithPathDelim(OpenDialog1.Filename);
  if not SaveDialog1.execute then
    exit;
  SavePicture (SaveDialog1.Filename);
end; //proc Save1Click

procedure TGLForm1.AutoRunTimer1Timer(Sender: TObject);
begin
  AutoRunTimer1.Enabled := false;
  {$IFDEF ENABLESCRIPT}
  ScriptForm.Compile1Click(nil);
  {$ENDIF}
end;

procedure TGLForm1.TransparencyVOIClick(Sender: TObject);
var
  alpha: integer;
begin
 alpha := (Sender as TMenuItem).tag;
 if (alpha = 0) and (not HideVOI1.checked) then begin //unhide
     if TransparencyVOIhi.checked then
       alpha := TransparencyVOIhi.tag
     else  if TransparencyVOIlo.checked then
       alpha := TransparencyVOIlo.tag
     else
       alpha := TransparencyVOImid.tag
 end;
 if alpha > 0 then
    HideVOI1.checked := false;
 voiChangeAlpha(alpha);
 UpdateGL;
end;

{$IFDEF FPC}
// http://bugs.freepascal.org/view.php?id=7797
function SetExtensionFromFilterAtIndex(InName, Filter: String; Index: Integer): String;
var
  ext: string;
  p, pipe: Integer;
begin
 result := InName;
 ext := UpCaseExt(InName);
 if length(ext) > 0 then exit;
  Result := '';
  if Index < 1 then Exit;
  p := 0;
  pipe := 0;
  while (p < Length(Filter)) do begin
    Inc(p);
    if Filter[p] = '|' then Inc(pipe);
    if (pipe = 2 * (Index - 1)) then break;
  end;
  if (p = length(Filter)) then exit;
  System.Delete(Filter,1,p);
  p := Pos('|',Filter);
  if (p = 0) then exit;
  System.Delete(Filter,1,p);
  Filter := Copy(Filter,1,MaxInt);
  p := Pos(';',Filter);
  pipe := Pos('|',Filter);
  if (pipe < p) or (p = 0) then p := pipe;
  if (p > 0) then System.Delete(Filter,p,Length(Filter) - p +1);
   Filter  := StringReplace(Filter, '*', '',[rfReplaceAll, rfIgnoreCase]);
  if (Pos('?',Filter) > 0) {or (Pos('*',Filter) > 0)} then exit;
  //showmessage(ext+' -> '+filter);
  Result := InName+Filter;
end;
{$ENDIF}

procedure TGLForm1.SaveVOI1Click(Sender: TObject);
var
  ptr: bytep0;
  lHdr: TNIFTIHdr;
  lSrcHdr,lDestHdr: TMRIcroHdr;
begin
 {$IFNDEF USETRANSFERTEXTURE}
     ptr := voiGetVolume;
     if voiIsEmpty then begin
        showmessage('The drawing is empty: nothing to save');
        exit;
     end;
     if not voiIsModified then begin
        showmessage('This drawing has not been changed. Are you sure you want to save an identical copy?');
     end;
     //
     (*if (SaveDialogVoi.initialDir = '') and fileexists(OpenDialog1.Filename) then begin
        SaveDialogVoi.initialDir := ExtractFileDirWithPathDelim(OpenDialog1.Filename);
        SaveDialogVoi.FileName := SaveDialogVoi.initialDir;
     end else
         SaveDialogVoi.FileName :=  ParseFileName (OpenDialog1.FileName); *)
     if fileexists(OpenDialog1.filename) then begin
        //SaveDialogVoi.FileName :=  ChangeFileExt (OpenDialog1.FileName,'.voi');
        SaveDialogVoi.FileName :=  ChangeFileExtX (OpenDialog1.FileName,'.voi');
        SaveDialogVoi.initialDir :=  ExtractFilePath (OpenDialog1.FileName);
     end;
     if not SaveDialogVoi.Execute then exit;
     {$IFDEF FPC} //recent versions of Lazarus (1.2) do handle this, but will put .gz not .nii.gz
      SaveDialogVoi.FileName := SetExtensionFromFilterAtIndex(SaveDialogVoi.FileName, SaveDialogVoi.Filter, SaveDialogVoi.FilterIndex); //8/8/2014 check on OSX 10.4
     {$ENDIF}
     //showmessage(SaveDialogVoi.FileName);
     lHdr := gTexture3D.NIFTIhdr;
     lHdr.bitpix := 8;
     lHdr.datatype := kDT_UNSIGNED_CHAR;
     lHdr.intent_code := kNIFTI_INTENT_NONE;
     lHdr.intent_name[1] := 'B';//Binary
     lHdr.scl_slope := 1;
     lHdr.scl_inter := 0;
     lHdr.dim[0] := 3;//3D
     lHdr.dim[4] := 1;//3D
     lSrcHdr.NIFTIhdr := lHdr;
     lDestHdr.NIFTIhdr := lHdr;
     //we rotate images to nearest orthogonal, but SPM/FSL expect identical slicing, so re-orient VOI to match raw image!
     Reslice2TargCore (lSrcHdr, bytep(ptr), gTexture3D.NiftiHdrRaw, lDestHdr, false , 1);
     //SaveImg (SaveDialogVoi.FileName, lSrcHdr.NIFTIhdr, bytep(ptr));
     //showmessage(inttostr(lDestHdr.NIFTIhdr.dim[1])+'x'+inttostr(lDestHdr.NIFTIhdr.dim[2])+'x'+inttostr(lDestHdr.NIFTIhdr.dim[3]));
     if lDestHdr.ImgBufferUnaligned = nil then  exit;
     SaveImg (SaveDialogVoi.FileName, lDestHdr.NIFTIhdr, lDestHdr.ImgBuffer);
     freemem(lDestHdr.ImgBufferUnaligned);
     voiSetModified(false);
     {$ENDIF}
end;

procedure TGLForm1.CloseVOI1Click(Sender: TObject);
begin
  if (not voiIsEmpty) and (voiIsModified) then
    SaveVOI1Click(nil);
  //closeDraw;  2015
  NoDraw1.Click;
  voiClose;
  //M_reload := kCloseVOI_reload;
  GLbox.Invalidate;
end;

function TGLForm1.OpenVOI(lFilename: string): boolean;
var
   lFilenameX : string;
begin
  lFilenameX := lFilename;
  GLForm1.CheckFilename (lFilenameX,false); //e.g. "nam" -> "c:\nam.voi"
  result := fileexists(lFilenameX);
  if not result then
    exit;
  GLForm1.OpenDialogVoi.Filename := lFilenameX;
  GLForm1.M_reload := kOpenExistingVOI_reload;
  GLbox.Invalidate;
end;

procedure TGLForm1.InterpolateDrawMenuClick(Sender: TObject);
begin
 voiInterpolate ((sender as tMenuItem).tag);
 GLForm1.UpdateGL;
end;

procedure TGLForm1.ConvertForeign1Click(Sender: TObject);
var
  Opt : TOpenOptions;
  lF: integer;
begin
  Opt := OpenDialog1.Options;
  OpenDialog1.filter := 'Images|*.*';
  OpenDialog1.Options := [ofAllowMultiSelect,ofFileMustExist {,ofNoChangeDir}];
  if not OpenDialog1.Execute then begin
    OpenDialog1.Options := Opt;
    OpenDialog1.filter := kImgPlusVOIFilter;
    exit;
  end;
  OpenDialog1.filter := kImgPlusVOIFilter;
  OpenDialog1.Options := Opt;
  if OpenDialog1.Files.Count < 1 then
    exit;
  for lF := 0 to (OpenDialog1.Files.Count-1) do
    SaveForeignAsNifti(OpenDialog1.Files[lF]);
end;

procedure TGLForm1.FormChangeBounds(Sender: TObject);
{$IFDEF LCLCocoa} var lprev: single; {$ENDIF}
begin
   {$IFDEF LCLCocoa}
   if (gPrefs.RetinaDisplay)  then begin //detect if window moved between retina and non-retina display
      lprev := gRetinaScale;
      SetRetina;
      if (lprev <> gRetinaScale) then
         GLboxResize(Sender);
   end;
   {$ENDIF}
end;


procedure TGLForm1.OpenVOI1Click(Sender: TObject);
begin
  OpenDialogVoi.filter := kImgPlusVOIFilter;
  OpenDialogVoi.initialDir := OpenDialog1.InitialDir;
  if not OpenDialogVoi.Execute then exit;
  if not OpenVOI(OpenDialogVoi.Filename) then
    Showmessage('Unable to find drawing '+OpenDialogVoi.Filename);
end;

procedure TGLForm1.DrawTool1Click(Sender: TObject);
begin
 if not (sender is TMenuItem) then exit;
(Sender as TMenuItem).checked := true;
     gPrefs.DrawColor := (Sender as TMenuItem).tag;
     if AutoRoiForm.Visible then
        AutoRoiForm.PreviewBtnClick(Sender);
     (*if (gPrefs.DrawColor >= 0) and (not voiIsOpen) then begin
        voiCreate(gTexture3D.FiltDim[1], gTexture3D.FiltDim[2],gTexture3D.FiltDim[3], nil);
        GLbox.Invalidate;
     end; *)

end;

procedure TGLForm1.UndoVOI1Click(Sender: TObject);
begin
  voiUndo;
  GLbox.Invalidate;
end;

function TGLForm1.MouseDownVOI (Shift: TShiftState; X, Y: Integer): boolean;
var
  lOrient, lPen: integer;
  lXfrac,lYfrac,lZfrac: single;
begin
     result := false;
     if (AutoROIForm.visible) then exit;
     if (ssCtrl in Shift) then exit;
     if (gPrefs.SliceView < 1) or (gPrefs.DrawColor < 0)  then exit;
     if  (not voiIsOpen) then begin //clicked after VOI/Close - lets create a new one
        voiCreate(gTexture3D.FiltDim[1], gTexture3D.FiltDim[2],gTexture3D.FiltDim[3], nil);
     end;
     OrthoCoordMidSlice(0,0,0);
     //if (not voiActiveX) then exit;
     OrthoPix2Frac (X, Y, lOrient, lXfrac,lYfrac,lZfrac);
     if (ssShift in Shift) then begin
        if gPrefs.DrawColor <> 0 then
           lPen := 0
        else
          lPen := 1;
     end else
         lPen := gPrefs.DrawColor;
     if (ssAlt in Shift) then begin
        if gPrefs.FlipLR then
           voiMouseFloodFill(lPen, lOrient, 1-lXfrac, lYfrac, lZfrac)
        else
            voiMouseFloodFill(lPen, lOrient, lXfrac, lYfrac, lZfrac);
        GLbox.Invalidate;
     end else begin
       if gPrefs.FlipLR then
          voiMouseDown(lPen, lOrient, 1-lXfrac, lYfrac, lZfrac)
       else
         voiMouseDown(lPen, lOrient, lXfrac, lYfrac, lZfrac);
     end;
     result := true;
     //caption := inttostr(lOrient)+':'+floattostr(lXFrac)+'x'+floattostr(lYFrac)+'x'+floattostr(lZFrac);
end;

function TGLForm1.MouseMoveVOI (X, Y: Integer): boolean;
var
  lXfrac,lYfrac,lZfrac: single;
  lOrient, lActiveOrient: integer;
begin
     result := false;
     if (gPrefs.SliceView < 1) or (gPrefs.DrawColor < 0)  then exit;
     lActiveOrient := voiActiveOrient;
     if (lActiveOrient < 1) then exit;
     OrthoPix2Frac (X, Y, lOrient, lXfrac,lYfrac,lZfrac);
     result := true;
     if (lActiveOrient <> lOrient) then
        exit;
     if gPrefs.FlipLR then
        voiMouseMove(1-lXfrac, lYfrac, lZfrac)
     else
         voiMouseMove(lXfrac, lYfrac, lZfrac);
        GLbox.Invalidate;
end;

function TGLForm1.MouseUpVOI (Shift: TShiftState; X, Y: Integer): boolean;
var
  lXfrac,lYfrac,lZfrac: single;
  lOrient: integer;
begin
     result := false;
     if (gPrefs.SliceView < 1) or (gPrefs.DrawColor < 0)  then exit;
     if (voiActiveOrient < 1) then exit;
     OrthoPix2Frac (X, Y, lOrient, lXfrac,lYfrac,lZfrac);
     //voiMouseUp(lXfrac, lYfrac, lZfrac,not (ssCtrl in Shift) );// not (ssCtrl in Shift));  (ssCtrl in Shift)
     voiMouseUp(not (ssCtrl in Shift), OverwriteDrawColor1.checked );
     GLbox.Invalidate;
     result := true;
end;

procedure TGLForm1.Smooth1Click(Sender: TObject);
begin
  voiSmoothIntensity (nil);
  GLbox.Invalidate;
end;

procedure TGLForm1.ToolPanelClick(Sender: TObject);
begin
  if (gPrefs.SliceView < 1) or (gPrefs.SliceView > 5) then //already rendering
     exit;
  Render1.Click;
end;

procedure TGLForm1.PasteSlice1Click(Sender: TObject);
begin
     voiPasteSlice(gRayCast.OrthoX, gRayCast.OrthoY,gRayCast.OrthoZ);
     GLbox.Invalidate;
end;

procedure TGLForm1.SetToolPanelWidth;
var
  ShowRenderTools: boolean;
begin
 ShowRenderTools :=  (gPrefs.SliceView < 1) or (gPrefs.SliceView > 5); //rendering
 HideRenderToolsBtn.Visible := ShowRenderTools;
 ClipBox.Visible := ShowRenderTools;
 ShaderBox.Visible := ShowRenderTools;
 if ShaderBox.Visible then ShaderBoxResize(nil);
 (*ViewSepMenu.Visible := ShowRenderTools;
 LeftMenu.Visible := ShowRenderTools;
 RightMenu.Visible := ShowRenderTools;
 AnteriorMenu.Visible := ShowRenderTools;
 PosteriorMenu.Visible := ShowRenderTools;
 InferiorMenu.Visible := ShowRenderTools;
 SuperiorMenu.Visible := ShowRenderTools; *)
 CutoutBox.visible := ShowRenderTools;
 Slice2DBox.Visible := ((not ShowRenderTools) and (gPrefs.SliceView <> 5));
 MosaicBox.Visible := gPrefs.SliceView = 5;
end;

procedure TGLForm1.FormDestroy(Sender: TObject);
begin
 //IniFile(false,IniName,gPrefs);
gCube.Free;
gText.Free;
gClrBar.Free;
 {$IFDEF COMPILEYOKE}
   YokeTimer.Enabled := false;
   CloseSharedMem;
  {$ENDIF}
end;


procedure TGLForm1.CollapsedToolPanelClick(Sender: TObject);
begin
  Tool1.Click;
  Self.ActiveControl := nil;
end;

procedure TGLForm1.HideRenderToolsBtnClick(Sender: TObject);
begin
    ClipBox.visible := not ClipBox.visible;
    CutoutBox.visible := not CutoutBox.visible;
    ShaderBoxResize(Sender);
    Self.ActiveControl := nil;
end;

procedure CloseOverlay (lOverlayIndex: integer);
begin
 GLForm1.ActiveControl := nil; //GLForm1.MinEdit.SetFocus;
 GLForm1.LUTdrop.visible := false;
  GLForm1.StringGrid1.Selection := TGridRect(Rect(-1, -1, -1, -1));
  if gOverlayImg[lOverlayIndex].ImgBufferUnaligned <> nil then
    freemem(gOverlayImg[lOverlayIndex].ImgBufferUnaligned);
  if gOverlayImg[lOverlayIndex].ScrnBuffer <> nil then
    freemem(gOverlayImg[lOverlayIndex].ScrnBuffer);
  InitOverlay(lOverlayIndex);
end;

procedure CloseOverlays;
var
  I: integer;
begin
  GLForm1.StringGrid1.Selection:=TGridRect(Rect(-1,-1,-1,-1));
    for I := kMinOverlayIndex to kMaxOverlays do
      CloseOverlay(I);
    gOpenOverlays := 0;
end;

procedure TGLForm1.UpdateImageIntensityMinMax (lOverlay: integer; lMinIn,lMaxIn: double);
var
   lMin,lMax: single;
begin
 if (lOverlay > gOpenOverlays) then exit;
    if lMinIn > lMaxin then begin
       lMin := lMaxIn;
       lMax := lMinIn;
    end else begin
        lMin := lMinIn;
        lMax := lMaxIn;
    end;
   gOverlayImg[lOverlay].WindowScaledMin := lMin;
   gOverlayImg[lOverlay].WindowScaledMax := lMax;
   StringGrid1.Cells[kMin,lOverlay] := float2str(lMin,3);
   StringGrid1.Cells[kMax,lOverlay] := float2str(lMax,3);
   //StringGrid1.Cells[kMin,lOverlay] := floattostrf(lMin, ffGeneral, 8, 3); //requires extended precision: lMin = 2.6 yields 2.5999999
   //StringGrid1.Cells[kMax,lOverlay] := floattostrf(lMax, ffGeneral, 8, 3);
   //StringGrid1.Cells[kMin,lOverlay] := floattostr(lMin);
   //StringGrid1.Cells[kMax,lOverlay] := floattostr(lMax);
   UpdateImageIntensity(lOverlay);
end;

procedure TGLForm1.ChangeOverlayUpdate;
begin
     {$IFDEF FPC}{$IFDEF Windows} //July2017: Lazarus 1.8.0 does not repaint?
     StringGrid1.Refresh;
     {$ENDIF}{$ENDIF}
     M_Refresh := true;
     // deleteGradients(gTexture3D);
     GLForm1.UpdateTimer.enabled := true;
end;

procedure TGLForm1.Closeoverlays1Click(Sender: TObject);
begin
 GLForm1.ActiveControl := nil;
 OverlayBox.Visible := false;//StringGrid1.Visible := false;
 LUTdrop.Visible := false;
 CloseOverlays;
 gOpenOverlays := 0;
 StringGrid1.RowCount := StringGrid1.FixedRows+1;
 ChangeOverlayUpdate;
end;

function HasDigit (var lS: string): boolean;
//do not attempt to convert '-', '.', or '-.' as a number...
var
   lI,lLen: integer;
begin
     result := false;
     lLen := length (lS);
     if lLen < 1 then
        exit;
     for lI := 1 to lLen do begin
         if lS[lI] in ['0'..'9'] then begin
            result := true;
            exit;
         end;
     end;
end;

procedure TGLForm1.ReadCell (ACol,ARow: integer; Update: boolean);
var
  lF: single;
  lS: string;
begin
  if (ARow < GLForm1.StringGrid1.FixedRows) or (ARow > kMaxOverlays) then
    exit;
  if (ACol <> kMin) and (ACol <> kMax) then
    exit;
  lS := StringGrid1.Cells[ACol,ARow];
  if not HasDigit(lS) then
    exit;
  try
       lF := strtofloat(lS);
  except
          exit;
          {on EConvertError do begin
             Msg('Unable to convert the string '+lStr+' to a number');
             result := 1;
             exit;
          end;}
  end; {except}
  if ACol = kMin then
    gOverlayImg[ARow].WindowScaledMin := lF
  else
    gOverlayImg[ARow].WindowScaledMax := lF;
  if Update then UpdateImageIntensity(ARow);
end;

procedure TGLForm1.StringGrid1Exit(Sender: TObject);
begin
 ReadCell(gPrevCol,gPrevRow, true);
end;

function IsDigit (letter : char) : boolean;
//  If letter is a digit, 0 through 9, true is returned.
//  Otherwise, false is returned.
begin
  if ((letter <= '9') and (letter >= '0')) then
    IsDigit := true
  else
    IsDigit := false;
end;

procedure TGLForm1.OverlayIdleTimerReset;
begin
     GradientsIdleTimer.enabled := false;//reset
     GradientsIdleTimer.enabled := true;
end;

procedure TGLForm1.StringGrid1KeyPress(Sender: TObject; var Key: char);
const
  EnterKey = #13;
  BackspaceKey = #8;
  ControlC = #3;   //  Copy
  ControlV = #22;  //  Paste
var
  ACol,ARow: integer;
  //S: string;
begin

ACol := abs(GLForm1.StringGrid1.Selection.Right);
  ARow := abs(GLForm1.StringGrid1.Selection.Top);
  //if ((ACol <> gPrevCol) or (ACol <> gPrevCol)) and    ChangeOverlayUpdate;
  gPrevCol := ACol;
  gPrevRow := ARow;

  if (not (IsDigit (Key) or (Key = decimalseparator) or (Key = '+') or (Key = '-') or
        (Key = ControlC) or (Key = ControlV) or (Key = BackspaceKey) or
        (Key = EnterKey))) then begin
    Key := #0;
    exit;
  end;
  if (Key = kTab) then begin
    OverlayIdleTimerReset;
    exit;
  end;
  if (Key = kTab) or (Key = kCR) then begin
    ReadCell(gPrevCol,gPrevRow, true);
    OverlayIdleTimerReset;
    exit;
  end;
  gTypeInCell := true;
   {$IFNDEF LCLCocoa}
 OverlayIdleTimerReset;
{$ENDIF}

(*	if(( GLForm1.StringGrid1.Selection.Top = GLForm1.StringGrid1.Selection.Bottom ) and
		( GLForm1.StringGrid1.Selection.Left = GLForm1.StringGrid1.Selection.Right )) then begin
        if gEnterCell then begin
           S := ''
        end else
			  S := GLForm1.StringGrid1.Cells[ GLForm1.StringGrid1.Selection.Left,GLForm1.StringGrid1.Selection.Top ] ;
        gEnterCell := false;
        if ( ( Key = kDEL ) or ( Key = kBS ) )then begin
            if( length( S ) > 0 ) then begin
                setlength( S, length( S ) - 1 ) ;
            end;
        end else
			    S := S + Key ;
		//StringGrid1.Cells[ StringGrid1.Selection.Left, StringGrid1.Selection.Top ] := S ;
   {$IFDEF FPC} GLForm1.StringGrid1.Cells[ GLForm1.StringGrid1.Selection.Left,GLForm1.StringGrid1.Selection.Top ] := S;
    {$ENDIF}
	end ;    *)
          ReadCell(gPrevCol,gPrevRow, false);
end;

procedure CopyImg2Mem(var lH: TMRIcroHdr; var lAScrnBuffer,lAImgBuffer : Bytep; var lAUnaligned: Pointer);
var
  lABytes: integer;
begin
if lH.ImgBuffer <> nil then begin
  lABytes := lH.ImgBufferItems * lH.ImgBufferBPP;
  GetMem(lAUnaligned ,lABytes+15);
  {$IFDEF FPC}
     lAImgBuffer := Align(lAUnaligned,16); // not commented - check this
  {$ELSE}
     lAImgBuffer := ByteP($fffffff0 and (integer(lAUnaligned)+15));
  {$ENDIF}
  System.Move(lH.ImgBuffer^,lAImgBuffer^,lABytes);
  FreeMem(lH.ImgBufferUnaligned);
  lH.ImgBufferUnaligned := nil;

end else
  lAUnaligned := nil;
if lH.ScrnBuffer <> nil then begin
  GetMem(lAScrnBuffer ,lH.ScrnBufferItems);
  System.Move(lH.ScrnBuffer^,lAScrnBuffer^,lH.ScrnBufferItems);
  FreeMem(lH.ScrnBuffer);
end else
  lAScrnBuffer := nil;
end;

procedure CopyMem2Img(var lH: TMRIcroHdr; var lAScrnBuffer,lAImgBuffer : Bytep; var lAUnaligned: Pointer);
var
  lABytes: integer;
begin
 if lAUnaligned <>  nil then begin
    lABytes := lH.ImgBufferItems * lH.ImgBufferBPP;
  GetMem(lH.ImgBufferUnaligned ,lABytes+15);

  {$IFDEF FPC}
     lH.ImgBuffer := Align(lH.ImgBufferUnaligned,16); // not commented - check this
  {$ELSE}
     lH.ImgBuffer := ByteP($fffffff0 and (integer(lH.ImgBufferUnaligned)+15));
  {$ENDIF}
  System.Move(lAImgBuffer^,lH.ImgBuffer^,lABytes);
  FreeMem(lAUnaligned);
end;
 if lAScrnBuffer <>  nil then begin
  GetMem(lH.ScrnBuffer ,lH.ScrnBufferItems);
  System.Move(lAScrnBuffer^,lH.ScrnBuffer^,lH.ScrnBufferItems);//src, dest, bytes
  FreeMem(lAScrnBuffer);
 end;
end;

 procedure TGLForm1.UpdateOverlaySpreadI (lIndex: integer);
//var
//  lP,lV : string;
begin
  {if lVolume > 1 then
    lV := ':'+inttostr(lVolume)
  else
    lV := '';}
  GLForm1.StringGrid1.Cells[kFName, lIndex] := parsefilename(extractfilename(gOverlayImg[lIndex].HdrFileName));
  GLForm1.StringGrid1.Cells[kLUT, lIndex] := GLForm1.LutDrop.Items[gOverlayImg[lIndex].LUTindex];
  UpdateImageIntensityMinMax(lIndex,gOverlayImg[lIndex].WindowScaledMin,gOverlayImg[lIndex].WindowScaledMax);
  //if gOverlayImg[lIndex].LUTvisible then
  //  GLForm1.StringGrid1.Cells[kVis, lIndex] := '+'
  //else
  //  GLForm1.StringGrid1.Cells[kVis,lIndex] := '-';
end;

procedure TGLForm1.UpdateOverlaySpread;
var
  i: integer;
begin
  if gOpenOverlays < 1 then
    exit;
  for i := 1 to gOpenOverlays do
    UpdateOverlaySpreadI(i);
end;

procedure TGLForm1.LUTdropChange(Sender: TObject);
var intRow: Integer;
begin
  inherited;
  if GLForm1.Lutdrop.Tag < 1 then
     exit;
  intRow := GLForm1.StringGrid1.Row;
  if intRow < 0 then
    intRow := GLForm1.Lutdrop.Tag;
  if (intRow < 1) or (intRow > kMaxOverlays) then
    exit;
  GLForm1.StringGrid1.Cells[kLUT, intRow] := GLForm1.LutDrop.Items[GLForm1.LUTdrop.ItemIndex];
  UpdateLUT(intRow,GLForm1.LUTdrop.ItemIndex,false);
  ChangeOverlayUpdate;
  GLForm1.StringGrid1.Selection:=TGridRect(Rect(-1,-1,-1,-1));
end;

procedure TGLForm1.OrientClick(lOrient: integer);
var
  elev, azi: integer;
  X,Y,Z: single;
begin
 //if not GLForm1.Focused then exit; //e.g. do not intercept key srokes if use is editing a script!
 //Requires Form.KeyPreview := true;
 if gPrefs.SliceView > 0 then begin
    X := 0; Y := 0; Z := 0;
    Case lOrient of
         0: X := -1.0; //LEFT
         1: X := +1.0; //RIGHT
         2: Y := -1.0; //POSTERIOR
         3: Y := +1.0; //ANTERIOR
         4: Z := -1.0; //INFERIOR
         5: Z := +1.0; //SUPERIOR
    end; //case Key
    if (X = 0) and (Y = 0) and (Z = 0) then exit;
    //caption := format('%g %g %g',[X,Y,Z]) ;

    OrthoCoordMidSlice(X,Y,Z);
    ShowOrthoSliceInfo (false);
    updateGL;
    exit;
 end;
 //if not GLForm1.Focused then exit; //disable when user is typing scripts
  case lOrient  of
       4: elev := -90;
       5: elev := 90;
       else elev := 0;
  end;
  case lOrient  of
       0: azi := 90;
       1: azi := 270;
       2,5: azi := 0;
       else azi := 180;
  end;
  gRayCast.Elevation := elev;
  gRayCast.Azimuth := azi;
  updateGL;
end;

procedure TGLForm1.OrientBtnClick(Sender: TObject);
begin
OrientClick( (Sender as TSpeedButton).tag);
end;

procedure TGLForm1.OrientMenuClick(Sender: TObject);
begin
 OrientClick( (Sender as TMenuItem).tag);
end;

procedure TGLForm1.RadiologicalMenuClick(Sender: TObject);
begin
  gPrefs.FlipLR:= RadiologicalMenu.Checked;
  DisplayRadiological;
  GLbox.Invalidate;
end;

procedure TGLForm1.ReorientMenuClick(Sender: TObject);
{$IFNDEF FPC}
begin
    showmessage('Feature not available for Delphi');

end;
{$ELSE}
//{$DEFINE REORIENTDEBUG}
label
  245;
var
  lImg: Bytep;
  s: string;
  dx, dy, dz: single;
  btn : array  [1..6] of string = ('red','green','blue','purple','orange','yellow');
  M, Mhdr: TMatrix;
  i, dim1,dim2,dim3, btnR,btnA,btnS: integer;
  lHdr: TNIFTIHdr;
begin
 if (lHdr.bitpix = 24) then begin
    showmessage('Rotation not available for RGB images');
    exit;
 end;
 {$IFNDEF REORIENTDEBUG}
 gPrefs.isOrientationTriangles := true;
 if gPrefs.SliceView <> 4 then
    MPR1.click;
 btnR := QuestionDlg ('Reorient image','Which arrow is pointing toward participant’s RIGHT?',
      mtInformation,[ 1,btn[1], 2,btn[2], 3,btn[3], 4,btn[4], 5,btn[5], 6,btn[6] ],'');
 if (btnR <= 2) then
    btnA := QuestionDlg ('Reorient image','Which arrow is pointing toward participant’s ANTERIOR?',
         mtCustom,[ 3,btn[3], 4,btn[4], 5,btn[5], 6,btn[6] ],'')
 else if (btnR <= 4) then
    btnA := QuestionDlg ('Reorient image','Which arrow is pointing toward participant’s ANTERIOR?',
         mtCustom,[ 1,btn[1], 2,btn[2], 5,btn[5], 6,btn[6] ],'')
 else
     btnA := QuestionDlg ('Reorient image','Which arrow is pointing toward participant’s ANTERIOR?',
         mtCustom,[ 1,btn[1], 2,btn[2], 3,btn[3], 4,btn[4] ],'');
 if (max(btnR,btnA) <= 4) then
    btnS := QuestionDlg ('Reorient image','Which arrow is pointing toward participant’s SUPERIOR?',
         mtCustom,[5,btn[5], 6,btn[6] ],'')
 else if (min(btnR,btnA) >= 3) then
    btnS := QuestionDlg ('Reorient image','Which arrow is pointing toward participant’s SUPERIOR?',
         mtCustom,[1,btn[1], 2,btn[2] ],'')
 else
     btnS := QuestionDlg ('Reorient image','Which arrow is pointing toward participant’s SUPERIOR?',
          mtCustom,[3,btn[3], 4,btn[4] ],'');
 if (btnR=2) and (btnA=4) and (btnS=6) then begin
    showmessage('Image already oriented');
    goto 245;
 end;
 {$ELSE}
 btnR := 2;
 btnA := 4;
 btnS := 5;
 {$ENDIF}
 dim1 := (btnR + 1) div 2;
 dim2 := (btnA + 1) div 2;
 dim3 := (btnS + 1) div 2;
 M := zero3D;
 if odd(btnR) then
    M.matrix[1,dim1] := -1
 else
     M.matrix[1,dim1] := 1;
 if odd(btnA) then
    M.matrix[2,dim2] := -1
 else
     M.matrix[2,dim2] := 1;
 if odd(btnS) then
    M.matrix[3,dim3] := -1
 else
     M.matrix[3,dim3] := 1;
 M.matrix[4,4] := 1;
 lHdr := gTexture3D.NIFTIhdr;
 s := format('M = [%g %g %g %g; %g %g %g %g; %g %g %g %g; %g %g %g %g]; nii_reorient('''',M);',
     [M.matrix[1,1], M.matrix[1,2], M.matrix[1,3], M.matrix[1,4],
     M.matrix[2,1], M.matrix[2,2], M.matrix[2,3], M.matrix[2,4],
     M.matrix[3,1], M.matrix[3,2], M.matrix[3,3], M.matrix[3,4],
     M.matrix[4,1], M.matrix[4,2], M.matrix[4,3], M.matrix[4,4] ]);
 clipboard.AsText:= s;
 Mhdr := matrix3D(
      lHdr.srow_x[0],lHdr.srow_x[1],lHdr.srow_x[2],lHdr.srow_x[3],
      lHdr.srow_y[0],lHdr.srow_y[1],lHdr.srow_y[2],lHdr.srow_y[3],
      lHdr.srow_z[0],lHdr.srow_z[1],lHdr.srow_z[2],lHdr.srow_z[3]);
 M := multiplymatrices(M,Mhdr);

 //update S_Form
 for i := 0 to 4 do begin
     lHdr.srow_x[i] := M.matrix[1,i+1];
     lHdr.srow_y[i] := M.matrix[2,i+1];
     lHdr.srow_z[i] := M.matrix[3,i+1];
 end;
 //update q_form
 nifti_mat44_to_quatern( M, lHdr.quatern_b,lHdr.quatern_c,lHdr.quatern_d,
   lHdr.qoffset_x,lHdr.qoffset_y,lHdr.qoffset_z,dx, dy, dz, lHdr.pixdim[0]);

 //check format
 if (lHdr.bitpix > 24) then begin
	lHdr.datatype := kDT_FLOAT;
	lHdr.bitpix := 32;
	lHdr.scl_slope := 1;
	lHdr.scl_inter := 0;
end;
// showmessage(inttostr(lHdr.dim[4]));
if (lHdr.dim[4] > 1) then
   showmessage('Only able to rotate 1st volume. Check clipboard for Matlab script')
else
    showmessage('Check clipboard for Matlab script');
lHdr.dim[0] := 3;//3D
lHdr.dim[4] := 1;//3D
 if gTexture3D.RawUnscaledImg16 <> nil then
    lImg := bytep(gTexture3D.RawUnscaledImg16)
 else if gTexture3D.RawUnscaledImg32 <> nil then
      lImg := bytep(gTexture3D.RawUnscaledImg32)
 else if (gTexture3D.RawUnscaledImg8 <> nil) then
      lImg := bytep(gTexture3D.RawUnscaledImg8)
 else
     goto 245;
 //save results
 if fileexists(OpenDialog1.filename) then begin
    //SaveDialogVoi.FileName :=  ChangeFileExtX (OpenDialog1.FileName,'.nii');
    SaveDialogVoi.FileName :=  ChangeFilePrefixExt(OpenDialog1.FileName,'r', '.nii');
    SaveDialogVoi.initialDir :=  ExtractFilePath (OpenDialog1.FileName);
 end;
 s := SaveDialogVoi.Filter;
 SaveDialogVoi.Filter := 'SPM/FSL (.nii)|.nii|FSL (.nii.gz)|.nii.gz|Volume of Interest (.voi)|.voi';
 if not SaveDialogVoi.Execute then begin
   SaveDialogVoi.Filter := s;
   goto 245;
 end;
 {$IFDEF FPC} //recent versions of Lazarus (1.2) do handle this, but will put .gz not .nii.gz
  SaveDialogVoi.FileName := SetExtensionFromFilterAtIndex(SaveDialogVoi.FileName, SaveDialogVoi.Filter, SaveDialogVoi.FilterIndex); //8/8/2014 check on OSX 10.4
 {$ENDIF}
 SaveDialogVoi.Filter := s;
 SaveImg (SaveDialogVoi.FileName, lHdr, lImg);
 245:
 gPrefs.isOrientationTriangles := false;
end;
{$ENDIF}
(*type
  TVec =  array [1..3] of single;
function isSame(a,b: TVec): boolean;
begin
     result := (a[1]=b[1]) and (a[2]=b[2]) and (a[3]=b[3]);
end;

var
  mat: TMatrix;
  Origin, Right, Anterior,Superior: TVec;
  lAzimuth, lElevation: single;
  dimx, dimy, dimz, integer;
  //lXmm,lYmm,lZmm, ,lXmmR,lYmmR,lZmmR,lXmmA,lYmmA,lZmmA,lXmmS,lYmmS,lZmmS: single;
begin

 if gPrefs.DrawColor <> -1 then
   NoDraw1.Click;
  if gPrefs.SliceView <> 4 then
     MPR1.click;
  //set crosshair to center of volume
  gRayCast.OrthoX := 0.5;
  gRayCast.OrthoY := 0.5;
  gRayCast.OrthoZ := 0.5;
  ShowOrthoSliceInfo (true);
  GLBox.Invalidate;
  showmessage('Please click on a location on the RIGHT side of the image');
  GetShareFloats(Origin[1],Origin[2],Origin[3], lAzimuth, lElevation);
  repeat
        application.ProcessMessages();
        GetShareFloats(Right[1],Right[2],Right[3], lAzimuth, lElevation);
  until not isSame(Origin, Right);
  showmessage('Please click on a location on the ANTERIOR side of the image');
  repeat
        application.ProcessMessages();
        GetShareFloats(Anterior[1],Anterior[2],Anterior[3], lAzimuth, lElevation);
  until not isSame(Right, Anterior);
  showmessage('Please click on a location on the SUPERIOR side of the image');
  repeat
        application.ProcessMessages();
        GetShareFloats(Superior[1],Superior[2],Superior[3], lAzimuth, lElevation);
  until not isSame(Anterior, Superior);
  //compare each click to center of volume

 mat := Eye3D;
*)
 (*  Origin[1] := SliceMM (0.5,kSagLeftOrient); //Sag
  Origin[2] := SliceMM (0.5,kCoronalOrient); //Coronal
  Origin[3] := SliceMM (0.5,kAxialOrient); //Axial
*)


procedure TGLForm1.InterpolateMenuClick(Sender: TObject);
begin
 gPrefs.InterpolateOverlays := InterpolateMenu.checked;
end;

procedure TGLForm1.BackgroundMaskMenuClick(Sender: TObject);
begin
 gPrefs.MaskOverlayWithBackground := BackgroundMaskMenu.checked;
 ChangeOverlayUpdate;
end;

procedure TGLForm1.SetOverlayAlpha(Sender: TObject);
begin
 gPrefs.OverlayAlpha := (Sender as TMenuItem).tag;
 SetOverlayAlphaValue (gPrefs.OverlayAlpha);
 ChangeOverlayUpdate;
end;

procedure TGLForm1.ThresholdMenuClick(Sender: TObject);
var loutmm3, lClusterMM3, lThresh: single;
begin
  if (gOpenOverlays >= kMaxOverlays) then begin
     Showmessage('Error: too many overlays open (choose "Close overlays" command)');
     exit;
  end;
  loutmm3 := abs(gTexture3D.NIFTIhdr.pixdim[1]*gTexture3D.NIFTIhdr.pixdim[2]*gTexture3D.NIFTIhdr.pixdim[3]);
  if loutmm3 = 0 then begin
     showmessage('Error: current background image reports impossible voxel spacing. Solution: first load a valid background image');
     exit;
  end;
     ResliceForm.BGLabel.Caption:= 'Reslice to match '+realtostr(loutmm3,2)+'mm^3 voxels of background image';
  ResliceForm.showmodal;
  if ResliceForm.ModalResult <> mrOK then exit;
  Str2FloatSafe(ResliceForm.ThreshEdit.Text,lThresh) ;
  Str2FloatSafe(ResliceForm.ClusterEdit.Text,lClusterMM3) ;
  savethresholdedUI(lThresh, lClusterMM3, ResliceForm.SaveCheck.checked);
end;

function TGLForm1.Addoverlay(lFilename: string; lVolume: integer): integer;
var
  lL: integer;
  lFilenameX: string;
begin
  result := -1;
  GLForm1.StringGrid1.Selection := TGridRect(Rect(2, 3, 2, 3));
  lL := kMaxOverlays;
  //  if gShader.OverlayEmis then lL := 3;
  if gOpenOverlays >= lL then begin
      showmessage('Too many overlays open. Please close an overlay before adding a new one.');
      exit;
  end;
  if (gTexture3D.FiltDim[1] < 1) or (gTexture3D.FiltDim[2] < 1) or (gTexture3D.FiltDim[3] < 1) then begin
    showmessage('Please load a background image before loading an overlay.');
    exit;
  end;
  lFilenameX := lFilename;
  GLForm1.CheckFilename (lFilenameX,false);
  if not fileexists(lFilenameX) then begin
    {$IFDEF ENABLESCRIPT} ScriptForm.Stop1Click(nil); {$ENDIF} //OSX crashes if you give a modal dialog while script is running
    showmessage('Unable to find overlay named '+lFilename);
    exit;
  end;
  OverlayBox.visible := true; //GLForm1.StringGrid1.Visible := true;
  inc (gOpenOverlays);
  OverlayBox.Height :=  2+ ( (2+gOpenOverlays)*(StringGrid1.DefaultRowHeight+1));
  {$IFDEF FPC} {$IFNDEF UNIX}
 if Screen.PixelsPerInch <> 96 then begin
   OverlayBox.Height :=  2+  round((2+gOpenOverlays)*(StringGrid1.DefaultRowHeight+2));  end;
{$ENDIF}{$ENDIF}
  GLForm1.StringGrid1.RowCount := GLForm1.StringGrid1.FixedRows+gOpenOverlays;
  if Reslice2Targ (lFilenameX, gTexture3D.NIFTIhdr,gOverlayImg[gOpenOverlays],gPrefs.InterpolateOverlays,lVolume) = '' then begin
    showmessage('Error loading overlay.');
    dec (gOpenOverlays);
    exit;
  end;
  ComputeThreshOverlay (gOverlayImg[gOpenOverlays]);
  //caption := format('%g %g',[gOverlayImg[gOpenOverlays].AutoBalMinUnscaled, gOverlayImg[gOpenOverlays].AutoBalMaxUnscaled]);

  if (gOverlayImg[gOpenOverlays].RGB)  then begin //RGB images
    gOverlayImg[gOpenOverlays].AutoBalMinUnscaled := 0.1;
    gOverlayImg[gOpenOverlays].AutoBalMaxUnscaled := 255;
    //Dec2016: texture_3d_unit now handles planar/RGB conversion, so following lines change:
    if (lVolume mod 3) = 1 then //red
      lL := 1   //TODO : check  with Windows/Linux: LOADIMAGE('avg152T1'); OVERLAYLOAD('visiblehuman');
    else if (lVolume mod 3) = 2 then  //green
      lL := 2
     else //blue
      lL := 3;
    UpdateLUT(gOpenOverlays,lL,true);
  end else //not RGB
    UpdateLUT(gOpenOverlays,gOpenOverlays,true);
   gOverlayImg[gOpenOverlays].LUTvisible := true;
   if (gOverlayImg[gOpenOverlays].AutoBalMinUnscaled < 0) and (gOverlayImg[gOpenOverlays].AutoBalMaxUnscaled > 0) then begin
      if (odd(gOpenOverlays)) then begin
         if (abs(gOverlayImg[gOpenOverlays].AutoBalMinUnscaled) > gOverlayImg[gOpenOverlays].AutoBalMaxUnscaled) then
            gOverlayImg[gOpenOverlays].AutoBalMaxUnscaled := gOverlayImg[gOpenOverlays].AutoBalMinUnscaled / 2
         else
             gOverlayImg[gOpenOverlays].AutoBalMinUnscaled := gOverlayImg[gOpenOverlays].AutoBalMaxUnscaled / 2;
      end else begin
          if (abs(gOverlayImg[gOpenOverlays].AutoBalMinUnscaled) < gOverlayImg[gOpenOverlays].AutoBalMaxUnscaled) then
             gOverlayImg[gOpenOverlays].AutoBalMaxUnscaled := gOverlayImg[gOpenOverlays].AutoBalMinUnscaled / 2
          else
              gOverlayImg[gOpenOverlays].AutoBalMinUnscaled := gOverlayImg[gOpenOverlays].AutoBalMaxUnscaled / 2;
      end;

   end;
  gOverlayImg[gOpenOverlays].WindowScaledMin := gOverlayImg[gOpenOverlays].AutoBalMinUnscaled;
  gOverlayImg[gOpenOverlays].WindowScaledMax := gOverlayImg[gOpenOverlays].AutoBalMaxUnscaled;
  //caption := format('%g %g',[gOverlayImg[gOpenOverlays].WindowScaledMin, gOverlayImg[gOpenOverlays].WindowScaledMax]);
  gOverlayImg[gOpenOverlays].LutFromZero := gPrefs.OverlayColorFromZero;
  UpdateOverlaySpreadI(gOpenOverlays);
  UpdateImageIntensity (gOpenOverlays);
  ChangeOverlayUpdate;
  GLForm1.LUTdrop.Visible := false;
  result :=gOpenOverlays;
  //RGB
  if (gOverlayImg[gOpenOverlays].RGB) then begin
    if (lVolume < 3) then
      result :=Addoverlay(lFilename, lVolume+1)
    else
     Additive2.Click;//additive
  end; //RGB
end;


procedure TGLForm1.DemoteOrder(lRow: integer);
var
  lSwap:integer;
  lAImg : TMRIcroHdr;
  lOverlayCLUTrec : TCLUTrec;
  lAUnaligned,lBUnaligned: Pointer; //raw address of Image Buffer: address may not be aligned
  lAScrnBuffer,lAImgBuffer,lBScrnBuffer,lBImgBuffer: Bytep;
begin
  if (gOpenOverlays < 2 ) or (lRow > gOpenOverlays) or (lRow < 1) then
    exit;
  if lRow = gOpenOverlays then
     lSwap := 1
   else
     lSwap := lRow+1;
  lOverlayCLUTrec := gOverlayCLUTrec[lSwap];
  gOverlayCLUTrec[lSwap] := gOverlayCLUTrec[lRow];
  gOverlayCLUTrec[lRow] := lOverlayCLUTrec;
  //This next bit is involved, as for speed we do not use dynamic memory allocation...
  //Copy and purge memory allocation
  CopyImg2Mem(gOverlayImg[lRow], lAScrnBuffer,lAImgBuffer,lAUnaligned);
  CopyImg2Mem(gOverlayImg[lSwap], lBScrnBuffer,lBImgBuffer,lBUnaligned);
  //Swap image headers
  lAImg := gOverlayImg[lRow];
  gOverlayImg[lRow] := gOverlayImg[lSwap];
  gOverlayImg[lSwap] := lAImg;
  //allocate and include image data
  CopyMem2Img(gOverlayImg[lSwap], lAScrnBuffer,lAImgBuffer,lAUnaligned);
  CopyMem2Img(gOverlayImg[lRow], lBScrnBuffer,lBImgBuffer,lBUnaligned);
  UpdateOverlaySpread;
end;

procedure TGLForm1.StringGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
begin
 if aRow < 1 then exit;
 if not (gOverlayImg[aRow].LUTvisible) then begin
    with TStringGrid(Sender) do
     begin
       //paint the background Green
       Canvas.Font.Color := clRed;
       //Canvas.Brush.Color := clBlack;
       //Canvas.FillRect(aRect);
       Canvas.TextOut(aRect.Left+2,aRect.Top+2,Cells[ACol, ARow]);
     end;
  end;
end;

(*procedure TGLForm1.StringGridSetCaption(aRow: integer);
begin
    if (aRow < 1) or (aRow > gOpenOverlays) then exit;
    //writes 2.599999 instead of 2.6
    GLForm1.Caption := format('%s : %s %g..%g', [GLForm1.StringGrid1.Cells[0, aRow], GLForm1.StringGrid1.Cells[kLUT, aRow], gOverlayImg[aRow].WindowScaledMin, gOverlayImg[aRow].WindowScaledMax] );
end;*)


procedure TGLForm1.StringGrid1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Row: integer;
begin
  if (gOpenOverlays < 1) then exit;
  if (X >  (GLForm1.StringGrid1.ColWidths[kFName])) then
    exit; //not one of the first two colums
  Row := GLForm1.StringGrid1.DefaultRowHeight div 2;
  Row := round((Y-Row)/GLForm1.StringGrid1.DefaultRowHeight);
  GLForm1.LUTdrop.visible := false;
  if (Row < 1) or (Row > gOpenOverlays) then exit;
  StringGrid1.Hint := GLForm1.StringGrid1.Cells[0, Row];
  If  ((ssRight in Shift) or (ssShift in Shift)) then begin //hide overlay
      OverlayVisible(Row, (not gOverlayImg[Row].LUTvisible) );
      ChangeOverlayUpdate;
      exit;
  end;
  if (gOpenOverlays < 2) then
    exit; //can not shuffle order of a single item!
  //if (X <= kVisWid) then begin
  //    OverlayVisible(Row, (not gOverlayImg[Row].LUTvisible) );
  //  ChangeOverlayUpdate;
  //end else
    DemoteOrder(Row);

end;

procedure TGLForm1.StringGrid1SelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
var R: TYPES.TRect;
begin
  if (gTypeInCell) then UpdateImageIntensity(gPrevRow); // ChangeOverlayUpdate;
  if (ARow < 1) or (ARow > gOpenOverlays) then exit;
  StringGrid1.Hint := GLForm1.StringGrid1.Cells[0, ARow];
  if (ACol < kLUT) or (ACol > kMax) then exit;
  ReadCell(gPrevCol,gPrevRow, false);
  if (ACol = kLUT) and  (ARow <> 0) then begin
    //Size and position the combo box to fit the cell
    R := StringGrid1.CellRect(ACol, ARow);
    R.Left := R.Left + GLForm1.StringGrid1.Left;
    R.Right := R.Right + GLForm1.StringGrid1.Left;
    R.Top := R.Top + GLForm1.StringGrid1.Top;
    R.Bottom := R.Bottom + GLForm1.StringGrid1.Top;
    //Show the combobox
    with GLForm1.LUTdrop do begin
      Tag := 0;
      Left := R.Left + 1;
      Top := R.Top + 1;
      Width := (R.Right + 1) - R.Left;
      Height := (R.Bottom + 1) - R.Top;
      ItemIndex := Items.IndexOf(GLForm1.StringGrid1.Cells[ACol, ARow]);
      Visible := True;
      SetFocus;
      Tag := ARow;
    end;
  end else begin
      GLForm1.LUTdrop.visible := false;
      ReadCell(ACol,ARow, false);
      gEnterCell := true;
  end;
  CanSelect := True;
end;

procedure TGLForm1.UpdateImageIntensity (lOverlay: integer);
begin
     gTypeInCell := false;
     RescaleImgIntensity(gOverlayImg[lOverlay] );
    if gPrefs.OverlayHideZeros then HideZeros(gOverlayImg[lOverlay] );
  ChangeOverlayUpdate;
end;

procedure TGLForm1.UpdateLUT(lOverlay,lLUTIndex: integer; lChangeDrop: boolean);
//6776
begin
  if gOpenOverlays > kMaxOverlays then
    exit;
  if lLUTIndex >= LUTdrop.Items.Count then
    gOverlayImg[lOverlay].LUTindex:= 0
  else
    gOverlayImg[lOverlay].LUTindex:= lLUTIndex;
  if lChangeDrop then begin
    StringGrid1.Cells[kLUT, lOverlay] := LUTdrop.Items[gOverlayImg[lOverlay].LUTindex];
    //LUTdrop.ItemIndex := gOverlayImg[lOverlay].LUTindex;
  end;
  LUTdropLoad(gOverlayImg[lOverlay].LUTindex, gOverlayImg[lOverlay].LUT, LUTdrop.Items[lLUTindex], gOverlayCLUTrec[lOverlay]);
end;


function ImgIntensityStr(var lHdr: TMRIcroHdr; lVox: integer ): string;
var
  v: single;
  l16Buf : SmallIntP;
  l32Buf : SingleP;
begin
  result := '';
  if (lHdr.ImgBufferBPP  = 4) then begin
	   l32Buf := SingleP(lHdr.ImgBuffer );
     v := l32Buf^[lVox] ;
  end else if (lHdr.ImgBufferBPP  = 2) then begin
	   l16Buf := SmallIntP(lHdr.ImgBuffer );
     v := l16Buf^[lVox] ;
  end else if lHdr.ImgBufferBPP  = 1 then
	  v := lHdr.ImgBuffer[lVox]
  else
    exit;
  v := (v * lHdr.NiftiHdr.scl_slope)+lHdr.NiftiHdr.scl_inter;
  result := ' '+realtostr(v,3);
end;

procedure GenerateSlice (l32bitOutput: RGBQuadp; l8BitInput: bytep; lLUT: TLUT; lSlicePixels: integer);
var
  lI: integer;
begin
  if lSlicePixels < 1 then
    exit;
  for lI := 1 to lSlicePixels do begin
    l32bitOutput^[lI] := lLUT[l8BitInput^[lI]];
  end;//each voxel
end;

procedure MinMax (var lMin,lMax: integer; lVal: integer);
begin
    if lVal < lMin then
      lMin := lVal;
    if lVal > lMax then
      lMax := lVal;
end;

procedure AlphaBlend32(lBGQuad,lOverlayQuad : RGBQuadp; lBG0Clr,lOverlay0Clr: DWord; lSlicePixels, lOverlayTransPct: integer; lMaskWithBackground: boolean);  // 630
var
	lBGwt,lOverlaywt,lPixel,lPos:integer;
	lBGp,lOverlayP: ByteP;
	lBGQuadp,lOverlayDWordp : DWordp;
procedure ModulateBlendX;
var
  lMin,lMax,I,J: integer;
  lSlope,lWt: single;
begin
    J := 4;
    lMin := lBGp^[lPos];
    lMax := lBGp^[lPos];
    for I := 1 to lSlicePixels do begin
        MinMax(lMin,lMax,lBGp^[J]);
        inc(J,4);
    end;
    if lMin >= lMax then
      exit;//no range
    lSlope := 1/(lMax-lMin);
    J := 1;
    for I := 1 to lSlicePixels do begin
         lWt := (lBGp^[J+3]-lMin)*lSlope;
         lBGp^[J] := round(lWt*lOverlayP^[J]);
         inc(J);
         lBGp^[J] := round(lWt*lOverlayP^[J]);
         inc(J);
         lBGp^[J] := round(lWt*lOverlayP^[J]);
         inc(J);
         inc(J); //skip alpha
    end;
end; //nested ModulateBlendX
begin
     lBGp := ByteP(lBGQuad);
     lOverlayP := ByteP(lOverlayQuad);
     lOverlayDWordp := DWordp(lOverlayQuad);
     lBGQuadp := DWordp(lBGQuad);
     //next: transparency weighting
     lBGwt := round((lOverlayTransPct)/100 * 1024);
     lOverlaywt := round((100-lOverlayTransPct)/100 * 1024);
     //lOverlayByte := 12;//round((255-lOverlayTransPct)/100 * 255);
     //next redraw each pixel
     lPos := 1;
     if lOverlayTransPct > -1 then begin
        for lPixel := 1 to lSlicePixels do begin
            if lOverlayDWordp^[lPixel] = lOverlay0Clr then begin
	            inc(lPos,4);
            end else if (lOverlayP^[lPos+3] = 0) or ((lBGp^[lPos+3] = 0 )  and (lMaskWithBackground)) then  begin
		            inc(lPos,4)
            end else if lBGQuadp^[lPixel] = lOverlay0Clr then begin
		          lBGp^[lPos] := lOverlayP^[lPos];
		          inc(lPos);
		          lBGp^[lPos] := lOverlayP^[lPos];
		          inc(lPos);
		          lBGp^[lPos] := lOverlayP^[lPos];
		          inc(lPos);
              lBGp^[lPos] := lOverlayP^[lPos];//lOverlayByte;
          	inc(lPos);

      end else begin
		    lBGp^[lPos] := (lBGp^[lPos]*lBGwt+lOverlayP^[lPos]*lOverlaywt) shr 10;
		    inc(lPos);
		    lBGp^[lPos] := (lBGp^[lPos]*lBGwt+lOverlayP^[lPos]*lOverlaywt) shr 10;
		    inc(lPos);
		    lBGp^[lPos] := (lBGp^[lPos]*lBGwt+lOverlayP^[lPos]*lOverlaywt) shr 10;
		    inc(lPos);
        if (not lMaskWithBackground) and (lBGp^[lPos]< lOverlayP^[lPos] {lOverlayByte}) then
          lBGp^[lPos] := lOverlayP^[lPos];//lOverlayByte;
		    inc(lPos);
      end;
	  end;//for each pixel
  end else if lOverlayTransPct = -2 then begin
    ModulateBlendX;// (lSlicePixels,lPos);//,lBGp,lOverlayP);
  end else begin //less than one : additive
	  for lPixel := 1 to lSlicePixels do begin
      if lOverlayDWordp^[lPixel] = lOverlay0Clr then
		    inc(lPos,4)
	    else if (lBGp^[lPos+3] = 0 ) and (lMaskWithBackground) then
		    inc(lPos,4)
	    else begin
		    if lOverlayP^[lPos] > lBGp^[lPos] then lBGp^[lPos] := lOverlayP^[lPos];
		    inc(lPos);
		    if lOverlayP^[lPos] > lBGp^[lPos] then lBGp^[lPos] := lOverlayP^[lPos];
		    inc(lPos);
		    if lOverlayP^[lPos] > lBGp^[lPos] then lBGp^[lPos] := lOverlayP^[lPos];
		    inc(lPos);
        if (not lMaskWithBackground) and (lOverlayP^[lPos] > lBGp^[lPos])  then
          lBGp^[lPos] := lOverlayP^[lPos];
		    inc(lPos);
	    end;
	  end; //for each pixel
  end; //additive
end;


procedure TGLForm1.BlendOverlaysRGBA (var lTexture: TTexture);
var
  lOverlaySlice2P: RGBQuadp;
  lOffset,lRGBOffset: integer;
  l1st: boolean;
  lSlicePixels,lSliceBytes,lSlice,lO,lVox,lA,lAlpha: integer;
  lTextureOverlayImgRGBA: Bytep0;
begin
  lVox := lTexture.FiltDim[1]*lTexture.FiltDim[2]*lTexture.FiltDim[3];
  if (lVox < 1) or ((gPrefs.BackgroundAlpha = 100) and (gShader.OverlayVolume = 0)) or (gOpenOverlays < 1) or (lTexture.DataType <> GL_RGBA) then
    exit;
  for lO := 1 to gOpenOverlays do
      if lVox <> gOverlayImg[lO].ScrnBufferItems then
        exit;//error - sizes do not match
  lSlicePixels :=lTexture.FiltDim[1]*lTexture.FiltDim[2];
  lSliceBytes:= lSlicePixels*sizeof(TGLRGBQuad);
  lTextureOverlayImgRGBA := nil;
  SetLengthB(lTextureOverlayImgRGBA,lVox*sizeof(TGLRGBQuad));
  //lTextureOverlayImg := nil;
  //SetLengthB(lTextureOverlayImg,lVox);
  getmem(lOverlaySlice2P,lSliceBytes);
  lOffset := 1;
  lRGBOffset := 0;
  for lSlice := 1 to lTexture.FiltDim[3] do begin
    l1st := true;
    for lO := 1 to gOpenOverlays do begin
      if gOverlayImg[lO].LUTvisible then begin
        if l1st then begin
          l1st := false;
          GenerateSlice(@lTextureOverlayImgRGBA^[lRGBOffset],@gOverlayImg[lO].ScrnBuffer^[lOffset],gOverlayImg[lO].LUT,lSlicePixels);
        end else begin
          GenerateSlice(lOverlaySlice2P,@gOverlayImg[lO].ScrnBuffer^[lOffset],gOverlayImg[lO].LUT,lSlicePixels);
          AlphaBlend32(@lTextureOverlayImgRGBA^[lRGBOffset],lOverlaySlice2P, DWord(gOverlayImg[1].LUT[0]),DWord(gOverlayImg[lO].LUT[0]), lSlicePixels, gOverlayAlpha[lO], false{gPrefs.MaskOverlayWithBackground} );  // 630
        end;
      end;
    end;
    //AlphaBlend32(RGBquadp(@lTexture.FiltImg^[lRGBOffset]),@lTexture.OverlayImgRGBA^[lRGBOffset], 0,DWord(gOverlayImg[1].LUT[0]), lSlicePixels, gPrefs.BackgroundAlpha,gPrefs.MaskOverlayWithBackground);  // 630
    //if (gShader.OverlayVolume < 1) then
       AlphaBlend32(RGBquadp(@lTexture.FiltImg^[lRGBOffset]),@lTextureOverlayImgRGBA^[lRGBOffset], 0,DWord(gOverlayImg[1].LUT[0]), lSlicePixels, gPrefs.BackgroundAlpha,gPrefs.MaskOverlayWithBackground);  // 630
    //else
    //    AlphaBlend32(RGBquadp(@lTexture.FiltImg^[lRGBOffset]),@lTexture.OverlayImgRGBA^[lRGBOffset], 0,DWord(gOverlayImg[1].LUT[0]), lSlicePixels, 90,gPrefs.MaskOverlayWithBackground);  // 630
    lOffset := lOffset + lSlicePixels;
    lRGBOffset := lRGBOffset + lSliceBytes;
  end;
  freemem(lOverlaySlice2P);
  lAlpha :=  255- ((gPrefs.BackgroundAlpha*255) div 100);
  if (gShader.OverlayVolume < 1) then begin
     if (lAlpha < 32) then lAlpha := 32
  end else begin
      if (lAlpha < 64) then lAlpha := 64;  //the GLSL shader does not scale output, so provide sharp gradients
  end;
  //lAlpha := lAlpha div 4;
  //GLForm1.Caption :='>>>'+ inttostr(lAlpha) ;
  lA := 0;
  for lO := 0 to (lVox-1) do begin
      if (lTextureOverlayImgRGBA^[lA]+lTextureOverlayImgRGBA^[lA+1]+lTextureOverlayImgRGBA^[lA+2]) > 0 then
         lTextureOverlayImgRGBA^[lA+3]:=lAlpha;
      lA := lA+4;
  end;
  CreateVolumeGL (lTexture, gRayCast.intensityOverlay3D,PChar(lTextureOverlayImgRGBA));
  CreateGradientVolume (lTexture, gRayCast.gradientOverlay3D,lTextureOverlayImgRGBA, true);
  SetLengthB(lTextureOverlayImgRGBA,0);
end; //BlendOverlaysRGBA

function  TGLForm1.OverlayIntensityString(Voxel: integer): string;
var
  lO: integer;
begin
  result := '';
  if (gOpenOverlays < 1) then exit;
  //result := 'x';
  for lO := 1 to gOpenOverlays do begin
    //RescaleImgIntensity(gOverlayImg[lOverlay] );
    result := result + ImgIntensityStr(gOverlayImg[lO], Voxel )
  end
end;

procedure TGLForm1.SetOverlayAlphaValue(NewValue: integer);
var
  i: integer;
begin
  gPrefs.OverlayAlpha := NewValue;
  for i := kMinOverlayIndex to kMaxOverlays do
    gOverlayAlpha[i] := NewValue;
end;

procedure TGLForm1.OverlayColorFromZeroMenuClick(Sender: TObject);
var
  lO: integer;
begin
  gPrefs.OverlayHideZeros:= OverlayHideZerosMenu.Checked;
  gPrefs.OverlayColorFromZero := OverlayColorFromZeroMenu.checked;
  if  gOpenOverlays < 1 then
    exit;
  for lO := 1 to gOpenOverlays do
    gOverlayImg[lO].LutFromZero := gPrefs.OverlayColorFromZero;
  for lO := 1 to gOpenOverlays do begin
    RescaleImgIntensity(gOverlayImg[lO] );
    if gPrefs.OverlayHideZeros then HideZeros(gOverlayImg[lO]);
  end;
  ChangeOverlayUpdate;
end;

procedure TGLForm1.SetBackgroundAlpha(Sender: TObject);
begin
 gPrefs.BackgroundAlpha := (Sender as TMenuItem).tag;
  SetBackgroundAlphaValue (gPrefs.BackgroundAlpha);
 //StatusPanelUpdate;
 ChangeOverlayUpdate;
end;


procedure TGLForm1.OverlayVisible(lOverlay: integer; lVisible: boolean);
begin
  if (lOverlay > gOpenOverlays) or (lOverlay < 1) then
    exit;
  gOverlayImg[lOverlay].LUTvisible := lVisible{not gOverlayImg[lOverlay].LUTvisible};
  UpdateOverlaySpreadI(lOverlay);
end;

procedure TGLForm1.SetOverlayAlphaLayerValue(Layer, NewValue: integer);
begin
  if (Layer < kMinOverlayIndex) or (Layer > kMaxOverlays) then
    exit;
  gOverlayAlpha[Layer] := NewValue;
end;

procedure TGLForm1.SetBackgroundAlphaLayerValue(Layer, NewValue: integer);
begin
  if (Layer < kMinOverlayIndex) or (Layer > kMaxOverlays) then
    exit;
  gBackgroundAlpha[Layer] := NewValue;
end;

procedure TGLForm1.SetSubmenuWithTag (var lRootMenu: TMenuItem; lTag: Integer);
var
	lCount,lSubMenu: integer;
begin
	lCount := lRootMenu.Count;
	if lCount < 1 then exit;
	for lSubMenu := (lCount-1) downto 0 do
		if lRootmenu.Items[lSubmenu].Tag = lTag then begin
			lRootmenu.Items[lSubmenu].Checked := true;
			exit
		end;
	//will exit unless tag not found: default select 1st item
	lRootmenu.Items[0].Checked := true;
	//While Recent1.Count > 0 do Recent1.Items[0].Free;
end;

procedure TGLForm1.SetBackgroundAlphaValue(NewValue: integer);
var
  i: integer;
begin
  gPrefs.BackgroundAlpha := NewValue;
  for i := kMinOverlayIndex to kMaxOverlays do
    gBackgroundAlpha[i] := NewValue;
end;

procedure TGLForm1.Addoverlay1Click(Sender: TObject);
//6776
var
  lFilename: string;
  lF,lnVol: integer;
  Opt : TOpenOptions;
begin
  lF :=  kMaxOverlays;
  if gOpenOverlays >= lF then begin
      showmessage('Too many overlays open. Please close an overlay before adding a new one.');
      exit;
  end;
      StringGrid1.Selection := TGridRect(Rect(-1, -1, -1, -1));
  if (gTexture3D.FiltDim[1] < 1) or (gTexture3D.FiltDim[2] < 1) or (gTexture3D.FiltDim[3] < 1) then begin
    showmessage('Please load a background image before loading an overlay.');
    exit;
  end;
  Opt := OpenDialog1.Options;
  OpenDialog1.Options := [ofAllowMultiSelect,ofFileMustExist];
  if not OpenDialog1.Execute then begin
    OpenDialog1.Options := Opt;
    exit;
  end;
  OpenDialog1.Options := Opt;
  if OpenDialog1.Files.Count < 1 then
    exit;
  for lF := 0 to (OpenDialog1.Files.Count-1) do begin
    lFilename :=  OpenDialog1.Files[lF];
    lnVol :=  NIFTIvolumes(lFilename);
    if lnVol < 1 then
      exit;
    if ScriptForm.PSScript1.Running then
      lnVol := 1
    else if lnVol > 1 then
      ReadIntForm.GetInt('4D image: select volume',1,1,lnVol); // 5/2017 https://github.com/neurolabusc/MRIcroGL/issues/4
    AddOverlay(lFilename,lnVol);
  end;
end;

procedure TGLForm1.SetViewClick(Sender: TObject);
begin
     gPrefs.SliceView := (Sender as TMenuItem).tag;
     Mosaic1Click(Sender);
     SetToolPanelWidth;
     if (gPrefs.SliceView <> 5) then gRayCast.MosaicString := '';
     GLbox.Invalidate;
end;

procedure TGLForm1.CustomDrawColors1Click(Sender: TObject);
begin
 if (OpenDialogTxt.Execute) then
    loadLabelsITK(OpenDialogTxt.Filename)
 else
     loadLabelsDefault;
end;

procedure TGLForm1.ErrorTimerTimer(Sender: TObject);
//we can not open a dialog in a openGL context, so we show error messages later
begin
  ErrorTimer.Enabled:= false;
  if length(IntensityBox.Hint) < 1 then
     showmessage('Unspecified OpenGL error')
  else
      showmessage(IntensityBox.Hint);
  GLForm1.IntensityBox.Hint := '';
end;

procedure TGLForm1.Sharpen1Click(Sender: TObject);
begin
  if gTexture3D.isLabels then exit; //we can not sharpen indexed colors
  SharpenTexture(gTexture3D);
  UpdateTimer.enabled := true;
end;

procedure  TGLForm1.ShowmessageError(Str:string);
begin
     if (GLForm1.IntensityBox.Hint = '') then //Show 1st error
        GLForm1.IntensityBox.Hint := Str;
     GLForm1.ErrorTimer.Enabled := true;
end;

procedure TGLForm1.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
var
 lFilename: string;
begin
if (dcm2niiForm.visible) and ((dcm2niiForm.Active) or (dcm2niiForm.Focused)) then begin
  dcm2niiForm.FormDropFiles(Sender, FileNames);
  exit;
end;
if AutoRunTimer1.enabled then exit;
//AutoRunTimer1.Enabled := false;  //if user opens with application, disable startup script in OSX
if length(FileNames) < 1 then
   exit;
lFilename := Filenames[0];
LoadDatasetNIFTIvolx(lFileName,true);
end;

procedure TGLForm1.FormShow(Sender: TObject);
begin
  //CheckForUpdates(nil);
end;

procedure TGLForm1.AppDropFiles(Sender: TObject; const FileNames: array of String);
begin
     FormDropFiles(Sender, Filenames);
end;

initialization
  DecimalSeparator := '.';
end.


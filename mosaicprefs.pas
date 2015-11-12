unit mosaicprefs;

interface
{$D-,L-,O+,Q-,R-,Y-,S-}
uses
{$IFDEF FPC}LResources,  {$ELSE}
   Windows, 
  {$ENDIF}
   SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Spin, Buttons, ClipBrd;

type

  { TMosaicPrefsForm }

  TMosaicPrefsForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    ColOverlap: TTrackBar;
    RowOverlap: TTrackBar;
    ColEdit: TSpinEdit;
    RowEdit: TSpinEdit;
    OrientDrop: TComboBox;
    Label3: TLabel;
    Label4: TLabel;
    CopyScript: TSpeedButton;
    RunScript: TSpeedButton;
    CrossCheck: TCheckBox;
    LabelCheck: TCheckBox;
    MosaicText: TMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure UpdateMosaic(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RunScriptClick(Sender: TObject);
    procedure CopyScriptClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MosaicPrefsForm: TMosaicPrefsForm;

implementation
{$IFDEF FPC} {$R *.lfm}   {$ENDIF}
{$IFNDEF FPC}
{$R *.dfm}
{$ENDIF}

uses mainunit;

procedure TMosaicPrefsForm.UpdateMosaic(Sender: TObject);
var
  lRi,lCi,lR,lC,lRxC,lI: integer;
  lInterval: single;
  lOrthoCh: Char;
  lStr: string;
begin

  if not MosaicPrefsForm.Visible then
    exit;
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
        lStr := lStr + 'X '+lOrthoCh + ' 0.5'
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

procedure TMosaicPrefsForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  //   M_Refresh := true;
  //GLForm1.UpdateGL;
end;

procedure TMosaicPrefsForm.FormShow(Sender: TObject);
begin
  OrientDrop.ItemIndex := 0;
  UpdateMosaic(nil);
end;

procedure TMosaicPrefsForm.RunScriptClick(Sender: TObject);
begin
  GLForm1.DrawMosaic(MosaicText.Text);
end;

procedure TMosaicPrefsForm.CopyScriptClick(Sender: TObject);
begin
     {$IFDEF FPC}
       Clipboard.AsText := MosaicText.Text;
       //MosaicText.Text := 'not yet implemented';
     {$ELSE}
     Clipboard.AsText := MosaicText.Text;
     {$ENDIF}
end;

initialization
{$IFDEF FPC}
//  {$I mosaicprefs.lrs}
{$ENDIF}
end.
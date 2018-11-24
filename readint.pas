unit readint;

interface

uses
 {$IFDEF FPC} LResources,{$ENDIF}
  Buttons{only Lazarus?},SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Spin, types;

type

  { TReadIntForm }

  TReadIntForm = class(TForm)
    ReadIntEdit: TSpinEdit;
    ReadIntLabel: TLabel;
    OKBtn: TButton;
    procedure FormCreate(Sender: TObject);
    function GetInt(lStr: string; lMin,lDefault,lMax: integer): integer;
    procedure OKBtnClick(Sender: TObject);

	  private
	{ Private declarations }
  public

	{ Public declarations }
  end;

var
  ReadIntForm: TReadIntForm;

implementation

//uses nifti_img_view,{license,} MultiSlice, render;
  {$IFDEF FPC} {$R *.lfm}   {$ENDIF}
  {$IFNDEF FPC}
{$R *.DFM}
{$ENDIF}

  {$ifdef LCLCocoa}
uses mainunit, nsappkitext; //darkmode
{$ENDIF}
 function TReadIntForm.GetInt(lStr: string; lMin,lDefault,lMax: integer): integer;
 var
   w,h: integer;
 begin
      ReadIntLabel.caption := lStr+' ['+inttostr(lMin)+'..'+inttostr(lMax)+']';
      ReadIntEdit.AnchorSide[akLeft].Side := asrRight;
      ReadIntEdit.AnchorSide[akLeft].Control := ReadIntLabel;
      ReadIntEdit.Anchors := ReadIntEdit.Anchors + [akLeft];
      ReadIntEdit.BorderSpacing.Left := 12;
      ReadIntEdit.MinValue := lMin;
      ReadIntEdit.MaxValue := lMax;
      ReadIntEdit.Value := lDefault;
      OKBtn.AnchorSide[akLeft].Side := asrRight;
      OKBtn.AnchorSide[akLeft].Control := ReadIntLabel;
      OKBtn.Anchors := OKBtn.Anchors + [akLeft];
      OKBtn.BorderSpacing.Left := 12;
      ReadIntForm.HandleNeeded;
      ReadIntForm.GetPreferredSize(w,h);
      ReadIntForm.Width:= w+12;
      {$IFDEF LCLCocoa}
      //ReadIntForm.PopupMode:= pmAuto; //see issue 33616
      setThemeMode(ReadIntForm, gPrefs.DarkMode);
      {$ENDIF}
      ReadIntForm.ShowModal;
      result :=  ReadIntEdit.Value;
 end;

procedure TReadIntForm.FormCreate(Sender: TObject);
begin
  //ScaleDPI(Self,48);
end;

procedure TReadIntForm.OKBtnClick(Sender: TObject);
begin
     ReadIntForm.ModalResult := mrOK;
end;




initialization
{$IFDEF FPC}
 // {$I readint.lrs}
{$ENDIF}

end.

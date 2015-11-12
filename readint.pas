unit readint;

interface

uses
 {$IFDEF FPC} LResources,uscaledpi,{$ENDIF} 
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
 function TReadIntForm.GetInt(lStr: string; lMin,lDefault,lMax: integer): integer;
 begin
	  //result := lDefault;
      ReadIntLabel.caption := lStr+' ['+inttostr(lMin)+'..'+inttostr(lMax)+']';
	  ReadIntEdit.MinValue := lMin;
	  ReadIntEdit.MaxValue := lMax;
	  ReadIntEdit.Value := lDefault;

   //ReadIntForm.OKBtn.Focused := true;
     //ReadIntForm.OKBtn.SetFocus;
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

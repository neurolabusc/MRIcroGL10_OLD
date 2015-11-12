unit reslice;
{$IFDEF FPC} {$mode delphi}{$ENDIF}
{$H+}
interface

uses
{$IFDEF FPC}LResources,{$ELSE} Spin, {$ENDIF}
  Classes, SysUtils,   Forms, Controls, Graphics, Dialogs,
  StdCtrls;

type
  { TResliceForm }
  TResliceForm = class(TForm)
    BGLabel: TLabel;
    OKbtn: TButton;
    CancelBtn: TButton;
    ThreshLabel: TLabel;
    ThreshEdit: TEdit;
    ClusterEdit: TEdit;
    SaveCheck: TCheckBox;
    ClusterLabel: TLabel;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  ResliceForm: TResliceForm;

implementation


initialization
{$IFDEF FPC} {$R *.lfm}   {$ENDIF}
{$IFNDEF FPC} {$R *.dfm} {$ENDIF}
end.


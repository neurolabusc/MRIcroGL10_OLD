unit extractui;

{$IFDEF FPC}{$mode delphi}{$ENDIF}

interface

uses
{$IFDEF FPC}LResources, FileUtil, {$ENDIF}
  Classes, SysUtils,  Forms, Controls, Graphics, Dialogs,
  StdCtrls, Spin;

type

  { TExtractForm }

  TExtractForm = class(TForm)
    OneContiguousObjectCheck: TCheckBox;
    OKBtn: TButton;
    OtsuLevelsEdit: TSpinEdit;
    DilateEdit: TSpinEdit;
    ReadIntLabel: TLabel;
    ReadIntLabel1: TLabel;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  ExtractForm: TExtractForm;

implementation
{$IFDEF FPC} {$R *.lfm}   {$ENDIF}
{$IFNDEF FPC} {$R *.dfm} {$ENDIF}


end.


object ExtractForm: TExtractForm
  Left = 423
  Top = 77
  BorderStyle = bsDialog
  Caption = 'Extract Objects (Remove Haze)'
  ClientHeight = 138
  ClientWidth = 524
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object ReadIntLabel: TLabel
    Left = 144
    Top = 16
    Width = 231
    Height = 13
    Caption = 'Otsu levels: larger values for larger volumes (1..5)'
  end
  object ReadIntLabel1: TLabel
    Left = 144
    Top = 40
    Width = 279
    Height = 13
    Caption = 'Edge dilation voxels: larger values for larger volumes (0..12)'
  end
  object OneContiguousObjectCheck: TCheckBox
    Left = 8
    Top = 72
    Width = 313
    Height = 17
    Caption = 'Only extract single largest object'
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
  object OKBtn: TButton
    Left = 432
    Top = 96
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
  end
  object OtsuLevelsEdit: TSpinEdit
    Left = 16
    Top = 8
    Width = 121
    Height = 22
    MaxValue = 5
    MinValue = 1
    TabOrder = 1
    Value = 3
  end
  object DilateEdit: TSpinEdit
    Left = 16
    Top = 40
    Width = 121
    Height = 22
    MaxValue = 12
    MinValue = 0
    TabOrder = 2
    Value = 2
  end
end

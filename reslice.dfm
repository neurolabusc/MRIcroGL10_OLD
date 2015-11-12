object ResliceForm: TResliceForm
  Left = 389
  Top = 87
  BorderStyle = bsDialog
  Caption = 'Reslice overlay to match background'
  ClientHeight = 173
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object BGLabel: TLabel
    Left = 24
    Top = 16
    Width = 41
    Height = 13
    Caption = 'BGLabel'
  end
  object ThreshLabel: TLabel
    Left = 24
    Top = 48
    Width = 88
    Height = 13
    Caption = 'Threshold intensity'
  end
  object ClusterLabel: TLabel
    Left = 24
    Top = 80
    Width = 133
    Height = 13
    Caption = 'Minimum cluster size (mm^3)'
  end
  object SaveCheck: TCheckBox
    Left = 24
    Top = 112
    Width = 153
    Height = 17
    Caption = 'Save image to disk'
    Checked = True
    State = cbChecked
    TabOrder = 0
  end
  object CancelBtn: TButton
    Left = 200
    Top = 142
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object OKbtn: TButton
    Left = 288
    Top = 142
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 2
  end
  object ThreshEdit: TEdit
    Left = 200
    Top = 40
    Width = 176
    Height = 21
    TabOrder = 3
    Text = '2'
  end
  object ClusterEdit: TEdit
    Left = 200
    Top = 72
    Width = 176
    Height = 21
    TabOrder = 4
    Text = '0'
  end
end

object MosaicPrefsForm: TMosaicPrefsForm
  Tag = 3
  Left = 520
  Top = 102
  BorderStyle = bsDialog
  Caption = 'Mosaic Settings'
  ClientHeight = 210
  ClientWidth = 327
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 24
    Width = 40
    Height = 13
    Caption = 'Columns'
  end
  object Label2: TLabel
    Left = 16
    Top = 48
    Width = 27
    Height = 13
    Caption = 'Rows'
  end
  object Label3: TLabel
    Left = 16
    Top = 84
    Width = 51
    Height = 13
    Caption = 'Orientation'
  end
  object Label4: TLabel
    Left = 8
    Top = 148
    Width = 77
    Height = 13
    Caption = 'Script Command'
  end
  object CopyScript: TSpeedButton
    Left = 104
    Top = 144
    Width = 73
    Height = 22
    Caption = 'Copy Script'
    OnClick = CopyScriptClick
  end
  object RunScript: TSpeedButton
    Left = 184
    Top = 144
    Width = 73
    Height = 22
    Caption = 'Run Script'
    OnClick = RunScriptClick
  end
  object ColOverlap: TTrackBar
    Left = 176
    Top = 12
    Width = 150
    Height = 32
    Max = 9
    Min = -9
    Position = -1
    TabOrder = 0
    TickMarks = tmTopLeft
    OnChange = UpdateMosaic
  end
  object RowOverlap: TTrackBar
    Left = 176
    Top = 44
    Width = 150
    Height = 32
    Max = 9
    Min = -9
    Position = -3
    TabOrder = 1
    OnChange = UpdateMosaic
  end
  object ColEdit: TSpinEdit
    Left = 80
    Top = 16
    Width = 97
    Height = 22
    MaxValue = 20
    MinValue = 1
    TabOrder = 2
    Value = 3
    OnChange = UpdateMosaic
  end
  object RowEdit: TSpinEdit
    Left = 80
    Top = 48
    Width = 97
    Height = 22
    MaxValue = 20
    MinValue = 1
    TabOrder = 3
    Value = 2
    OnChange = UpdateMosaic
  end
  object OrientDrop: TComboBox
    Left = 88
    Top = 80
    Width = 145
    Height = 22
    Style = csOwnerDrawFixed
    ItemHeight = 16
    TabOrder = 4
    OnChange = UpdateMosaic
    Items.Strings = (
      'Axial'
      'Coronal'
      'Sagittal+'
      'Sagittal-')
  end
  object CrossCheck: TCheckBox
    Left = 16
    Top = 112
    Width = 137
    Height = 17
    Alignment = taLeftJustify
    Caption = 'Show cross slice'
    TabOrder = 5
    OnClick = UpdateMosaic
  end
  object LabelCheck: TCheckBox
    Left = 184
    Top = 112
    Width = 137
    Height = 17
    Alignment = taLeftJustify
    Caption = 'Label slice number'
    TabOrder = 6
    OnClick = UpdateMosaic
  end
  object MosaicText: TMemo
    Left = 8
    Top = 176
    Width = 313
    Height = 25
    TabOrder = 7
  end
end

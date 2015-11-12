object dcm2niiForm: Tdcm2niiForm
  Left = 435
  Top = 172
  Width = 780
  Height = 480
  Caption = 'dcm2nii'
  Color = clBtnFace
  Constraints.MinHeight = 120
  Constraints.MinWidth = 640
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 772
    Height = 32
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      772
      32)
    object outnameLabel: TLabel
      Left = 160
      Top = 8
      Width = 63
      Height = 13
      Caption = 'Output Name'
    end
    object Label2: TLabel
      Left = 6
      Top = 8
      Width = 46
      Height = 13
      Caption = 'Compress'
    end
    object outputFolderLabel: TLabel
      Left = 432
      Top = 8
      Width = 64
      Height = 13
      Caption = 'Output Folder'
    end
    object VerboseLabel: TLabel
      Left = 88
      Top = 8
      Width = 39
      Height = 13
      Caption = 'Verbose'
    end
    object compressCheck: TCheckBox
      Left = 60
      Top = 6
      Width = 19
      Height = 17
      TabOrder = 0
      OnClick = compressCheckClick
    end
    object outnameEdit: TEdit
      Left = 232
      Top = 4
      Width = 193
      Height = 21
      Hint = 
        'Name for NIfTI images. Special characers are %f (Folder name) %i' +
        ' (ID) %n (patient Name) %p (Protocol name) %s (Series number) %t' +
        ' (Time)'
      TabOrder = 1
      Text = '%f%s'
      OnKeyUp = outnameEditKeyUp
    end
    object outputFolderName: TButton
      Left = 502
      Top = 2
      Width = 268
      Height = 25
      Anchors = [akLeft, akTop, akRight]
      Caption = 'input folder'
      TabOrder = 2
      OnClick = outputFolderNameClick
    end
    object VerboseCheck: TCheckBox
      Left = 132
      Top = 6
      Width = 19
      Height = 17
      TabOrder = 3
      OnClick = compressCheckClick
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 32
    Width = 772
    Height = 402
    Align = alClient
    TabOrder = 1
  end
  object MainMenu1: TMainMenu
    Left = 32
    Top = 56
    object FileMenu: TMenuItem
      Caption = 'File'
      object DicomMenu: TMenuItem
        Caption = 'DICOM to NIfTI...'
        OnClick = DicomMenuClick
      end
      object ParRecMenu: TMenuItem
        Caption = 'PAR/REC to NIfTI...'
        OnClick = ParRecMenuClick
      end
      object ResetMenu: TMenuItem
        Caption = 'Reset Defaults'
        OnClick = ResetMenuClick
      end
    end
    object EditMenu: TMenuItem
      Caption = 'Edit'
      object CopyMenu: TMenuItem
        Caption = 'Copy'
        OnClick = CopyMenuClick
      end
    end
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Philips research (*.par)|*.par'
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Title = 'Open existing file'
    Left = 80
    Top = 56
  end
end

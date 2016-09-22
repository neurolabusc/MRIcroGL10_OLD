object dcm2niiForm: Tdcm2niiForm
  Left = 435
  Top = 173
  Width = 790
  Height = 479
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
    Width = 774
    Height = 32
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      774
      32)
    object outnameLabel: TLabel
      Left = 200
      Top = 8
      Width = 63
      Height = 13
      Caption = 'Output Name'
    end
    object Label2: TLabel
      Left = 4
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
      Left = 74
      Top = 8
      Width = 39
      Height = 13
      Caption = 'Verbose'
    end
    object VerboseLabel1: TLabel
      Left = 142
      Top = 8
      Width = 25
      Height = 13
      Hint = 'Create Brain Imaging Data Structure file'
      Caption = 'BIDS'
      ParentShowHint = False
      ShowHint = True
    end
    object compressCheck: TCheckBox
      Left = 54
      Top = 6
      Width = 19
      Height = 17
      TabOrder = 0
      OnClick = compressCheckClick
    end
    object outnameEdit: TEdit
      Left = 264
      Top = 4
      Width = 161
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
      Width = 278
      Height = 25
      Anchors = [akLeft, akTop, akRight]
      Caption = 'input folder'
      TabOrder = 2
      OnClick = outputFolderNameClick
    end
    object VerboseCheck: TCheckBox
      Left = 120
      Top = 6
      Width = 19
      Height = 17
      TabOrder = 3
      OnClick = compressCheckClick
    end
    object bidsCheck: TCheckBox
      Left = 172
      Top = 6
      Width = 19
      Height = 17
      TabOrder = 4
      OnClick = compressCheckClick
    end
  end
  object Memo1: TMemo
    Left = 0
    Top = 32
    Width = 774
    Height = 388
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

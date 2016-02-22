object GLForm1: TGLForm1
  Left = 936
  Top = 58
  Width = 675
  Height = 740
  Caption = 'MRIcroGL'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnMouseWheel = GLboxMouseWheel
  OnResize = GLboxResize
  PixelsPerInch = 96
  TextHeight = 13
  object ToolPanel: TPanel
    Left = 0
    Top = 0
    Width = 264
    Height = 681
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    OnClick = ToolPanelClick
    object CutoutBox: TGroupBox
      Left = 0
      Top = 269
      Width = 264
      Height = 110
      Align = alTop
      Caption = 'Cutout'
      TabOrder = 0
      object xX: TLabel
        Left = 12
        Top = 20
        Width = 7
        Height = 13
        Caption = 'X'
      end
      object yY: TLabel
        Left = 12
        Top = 51
        Width = 7
        Height = 13
        Caption = 'Y'
      end
      object zZ: TLabel
        Left = 12
        Top = 82
        Width = 7
        Height = 13
        Caption = 'Z'
      end
      object XTrackBar: TTrackBar
        Left = 20
        Top = 16
        Width = 92
        Height = 30
        Max = 1000
        Position = 1000
        TabOrder = 0
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object YTrackBar: TTrackBar
        Left = 20
        Top = 47
        Width = 92
        Height = 30
        Max = 1000
        Position = 1000
        TabOrder = 1
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object ZTrackBar: TTrackBar
        Left = 20
        Top = 78
        Width = 92
        Height = 30
        Max = 1000
        TabOrder = 2
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object X2TrackBar: TTrackBar
        Left = 110
        Top = 16
        Width = 92
        Height = 30
        Max = 1000
        TabOrder = 3
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object Y2TrackBar: TTrackBar
        Left = 110
        Top = 47
        Width = 92
        Height = 30
        Max = 1000
        TabOrder = 4
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object Z2TrackBar: TTrackBar
        Left = 110
        Top = 78
        Width = 92
        Height = 30
        Max = 1000
        TabOrder = 5
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object NearBtn: TButton
        Left = 200
        Top = 32
        Width = 59
        Height = 25
        Caption = 'Near'
        TabOrder = 6
        OnClick = CutoutNearestSector
      end
      object NoneBtn: TButton
        Left = 200
        Top = 66
        Width = 59
        Height = 25
        Caption = 'None'
        TabOrder = 7
        OnClick = HideBtnClick
      end
    end
    object ShaderBox: TGroupBox
      Left = 0
      Top = 601
      Width = 264
      Height = 80
      Align = alClient
      Caption = 'Shader'
      TabOrder = 1
      object Label1: TLabel
        Left = 146
        Top = 20
        Width = 8
        Height = 13
        Hint = 'Higher quality looks nicer but is slower to render'
        Caption = 'Q'
        ParentShowHint = False
        ShowHint = True
      end
      object Label2: TLabel
        Left = 6
        Top = 46
        Width = 23
        Height = 13
        Hint = 'Set the elevation and azimuth of the illumination'
        Caption = 'Light'
        ParentShowHint = False
        ShowHint = True
      end
      object ShaderDrop: TComboBox
        Left = 4
        Top = 16
        Width = 132
        Height = 21
        Style = csDropDownList
        DropDownCount = 24
        ItemHeight = 13
        TabOrder = 0
        OnChange = ShaderDropChange
        Items.Strings = (
          'none')
      end
      object QualityTrack: TTrackBar
        Left = 162
        Top = 16
        Width = 96
        Height = 25
        Min = 1
        Position = 3
        TabOrder = 1
        TickStyle = tsNone
        OnChange = QualityTrackChange
      end
      object ElevTrack: TTrackBar
        Left = 44
        Top = 42
        Width = 96
        Height = 25
        Max = 90
        Min = -90
        Position = 5
        TabOrder = 2
        TickStyle = tsNone
        OnChange = AziElevChange
      end
      object AziTrack: TTrackBar
        Left = 162
        Top = 42
        Width = 96
        Height = 25
        Max = 180
        Min = -180
        TabOrder = 3
        TickStyle = tsNone
        OnChange = AziElevChange
      end
      object Memo1: TMemo
        Left = 2
        Top = 51
        Width = 260
        Height = 27
        Align = alBottom
        Lines.Strings = (
          '')
        TabOrder = 4
      end
    end
    object ClipBox: TGroupBox
      Left = 0
      Top = 161
      Width = 264
      Height = 108
      Align = alTop
      Caption = 'Clipping'
      TabOrder = 2
      object Label4: TLabel
        Left = 6
        Top = 20
        Width = 29
        Height = 13
        Caption = 'Depth'
        OnClick = Label4Click
      end
      object Label5: TLabel
        Left = 6
        Top = 81
        Width = 44
        Height = 13
        Caption = 'Elevation'
        OnClick = Label6Click
      end
      object Label6: TLabel
        Left = 6
        Top = 51
        Width = 37
        Height = 13
        Caption = 'Azimuth'
        OnClick = Label5Click
      end
      object ClipTrack: TTrackBar
        Left = 64
        Top = 16
        Width = 172
        Height = 30
        Max = 999
        TabOrder = 0
        TickStyle = tsNone
        OnChange = ClipTrackChange
      end
      object ElevTrack1: TTrackBar
        Left = 64
        Top = 76
        Width = 172
        Height = 30
        Max = 180
        Min = -180
        Frequency = 45
        TabOrder = 1
        TickStyle = tsNone
        OnChange = ClipTrackChange
      end
      object AziTrack1: TTrackBar
        Left = 64
        Top = 46
        Width = 172
        Height = 30
        Max = 360
        PageSize = 1
        Frequency = 45
        Position = 180
        TabOrder = 2
        TickStyle = tsNone
        OnChange = ClipTrackChange
      end
    end
    object IntensityBox: TGroupBox
      Left = 0
      Top = 0
      Width = 264
      Height = 44
      Align = alTop
      Caption = 'Intensity Minimum...Maximum'
      TabOrder = 3
      object MaxEdit: TEdit
        Left = 136
        Top = 16
        Width = 120
        Height = 21
        TabOrder = 0
        OnKeyPress = MinMaxEditKeyPress
        OnKeyUp = MinMaxEditKeyUp
      end
      object MinEdit: TEdit
        Left = 8
        Top = 16
        Width = 120
        Height = 21
        TabOrder = 1
        OnKeyPress = MinMaxEditKeyPress
        OnKeyUp = MinMaxEditKeyUp
      end
    end
    object CollapseToolPanelBtn: TButton
      Left = 248
      Top = 2
      Width = 12
      Height = 12
      Hint = 'Hide tool panel'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = CollapsedToolPanelClick
    end
    object MosaicBox: TGroupBox
      Left = 0
      Top = 379
      Width = 264
      Height = 222
      Align = alTop
      Caption = 'Mosaic'
      TabOrder = 5
      object Label7: TLabel
        Left = 6
        Top = 22
        Width = 40
        Height = 13
        Caption = 'Columns'
      end
      object Label3: TLabel
        Left = 6
        Top = 48
        Width = 27
        Height = 13
        Caption = 'Rows'
      end
      object Label8: TLabel
        Left = 6
        Top = 82
        Width = 51
        Height = 13
        Caption = 'Orientation'
      end
      object ColEdit: TSpinEdit
        Left = 48
        Top = 16
        Width = 97
        Height = 22
        MaxValue = 20
        MinValue = 1
        TabOrder = 0
        Value = 3
        OnChange = UpdateMosaic
      end
      object RowEdit: TSpinEdit
        Left = 48
        Top = 48
        Width = 97
        Height = 22
        MaxValue = 20
        MinValue = 1
        TabOrder = 1
        Value = 2
        OnChange = UpdateMosaic
      end
      object ColOverlap: TTrackBar
        Left = 148
        Top = 16
        Width = 112
        Height = 30
        Max = 9
        Min = -9
        Position = -1
        TabOrder = 2
        TickStyle = tsNone
        OnChange = UpdateMosaic
      end
      object RowOverlap: TTrackBar
        Left = 148
        Top = 47
        Width = 112
        Height = 30
        Max = 9
        Min = -9
        Position = -3
        TabOrder = 3
        TickStyle = tsNone
        OnChange = UpdateMosaic
      end
      object OrientDrop: TComboBox
        Left = 64
        Top = 78
        Width = 145
        Height = 22
        Style = csOwnerDrawFixed
        ItemHeight = 16
        ItemIndex = 0
        TabOrder = 4
        Text = 'Axial'
        OnChange = UpdateMosaic
        Items.Strings = (
          'Axial'
          'Coronal'
          'Sagittal+'
          'Sagittal-')
      end
      object CrossCheck: TCheckBox
        Left = 6
        Top = 104
        Width = 91
        Height = 17
        Caption = 'Cross slice'
        TabOrder = 5
        OnClick = UpdateMosaic
      end
      object LabelCheck: TCheckBox
        Left = 144
        Top = 104
        Width = 112
        Height = 17
        Caption = 'Label slice number'
        TabOrder = 6
        OnClick = UpdateMosaic
      end
      object MosaicText: TMemo
        Left = 2
        Top = 157
        Width = 260
        Height = 63
        Align = alBottom
        TabOrder = 7
      end
      object CopyScriptBtn: TButton
        Left = 8
        Top = 128
        Width = 97
        Height = 25
        Caption = 'Copy Script'
        TabOrder = 8
        OnClick = CopyScriptClick
      end
      object RunScriptBtn: TButton
        Left = 144
        Top = 128
        Width = 97
        Height = 25
        Caption = 'Run Script'
        TabOrder = 9
        OnClick = RunScriptClick
      end
    end
    object HideRenderToolsBtn: TButton
      Left = 228
      Top = 2
      Width = 12
      Height = 12
      Hint = 'Show or hide rendering tools (useful for small screens)'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      OnClick = HideRenderToolsBtnClick
    end
    object OverlayBox: TGroupBox
      Left = 0
      Top = 44
      Width = 264
      Height = 117
      Align = alTop
      Caption = 'Overlays'
      TabOrder = 7
      Visible = False
      object StringGrid1: TStringGrid
        Left = 2
        Top = 15
        Width = 260
        Height = 100
        Align = alClient
        BorderStyle = bsNone
        ColCount = 4
        DefaultColWidth = 82
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goTabs]
        ScrollBars = ssNone
        TabOrder = 0
        OnExit = StringGrid1Exit
        OnKeyPress = StringGrid1KeyPress
        OnMouseDown = StringGrid1MouseDown
        OnSelectCell = StringGrid1SelectCell
        RowHeights = (
          24
          24)
      end
      object LUTdrop: TComboBox
        Left = 24
        Top = 72
        Width = 73
        Height = 19
        Style = csOwnerDrawFixed
        DropDownCount = 36
        ItemHeight = 13
        TabOrder = 1
        Visible = False
        OnChange = LUTdropChange
      end
    end
  end
  object CollapsedToolPanel: TPanel
    Left = 264
    Top = 0
    Width = 4
    Height = 681
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    Visible = False
    OnClick = CollapsedToolPanelClick
  end
  object MainMenu1: TMainMenu
    Left = 272
    Top = 80
    object File1: TMenuItem
      Caption = 'File'
      object NewWindow1: TMenuItem
        Caption = 'New window'
        ShortCut = 16462
        OnClick = NewWindow1Click
      end
      object Open1: TMenuItem
        Caption = 'Open'
        ShortCut = 16463
        OnClick = Open1Click
      end
      object Save1: TMenuItem
        Caption = 'Save'
        OnClick = Save1Click
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
        ShortCut = 16472
        OnClick = Exit1Click
      end
      object MenuSep1: TMenuItem
        Caption = '-'
      end
      object MRU1: TMenuItem
        Caption = 'MRU1'
      end
      object MRU2: TMenuItem
        Caption = 'MRU2'
      end
      object MRU3: TMenuItem
        Caption = 'MRU3'
      end
      object MRU4: TMenuItem
        Caption = 'MRU4'
      end
      object MRU5: TMenuItem
        Caption = 'MRU5'
      end
      object MRU6: TMenuItem
        Caption = 'MRU6'
      end
      object MRU7: TMenuItem
        Caption = 'MRU7'
      end
      object MRU8: TMenuItem
        Caption = 'MRU8'
      end
      object MRU9: TMenuItem
        Caption = 'MRU9'
      end
      object MRU10: TMenuItem
        Caption = 'MRU10'
      end
    end
    object Edit1: TMenuItem
      Caption = 'Edit'
      object Copy1: TMenuItem
        Caption = 'Copy'
        OnClick = Copy1Click
      end
    end
    object Overlays1: TMenuItem
      Caption = 'Overlays'
      object Addoverlay1: TMenuItem
        Caption = 'Add overlay'
        OnClick = Addoverlay1Click
      end
      object Thresholdmenu: TMenuItem
        Caption = 'Add overlay (remove small clusters)'
        OnClick = ThresholdMenuClick
      end
      object Closeoverlays1: TMenuItem
        Caption = 'Close overlays'
        OnClick = Closeoverlays1Click
      end
      object Onbackground1: TMenuItem
        Caption = 'Transparency on background'
        object N0opaque1: TMenuItem
          AutoCheck = True
          Caption = '0% opaque'
          GroupIndex = 123
          RadioItem = True
          OnClick = SetBackgroundAlpha
        end
        object N201: TMenuItem
          Tag = 20
          AutoCheck = True
          Caption = '20%'
          GroupIndex = 123
          RadioItem = True
          OnClick = SetBackgroundAlpha
        end
        object N401: TMenuItem
          Tag = 40
          AutoCheck = True
          Caption = '40%'
          GroupIndex = 123
          RadioItem = True
          OnClick = SetBackgroundAlpha
        end
        object N501: TMenuItem
          Tag = 50
          AutoCheck = True
          Caption = '50%'
          GroupIndex = 123
          RadioItem = True
          OnClick = SetBackgroundAlpha
        end
        object N601: TMenuItem
          Tag = 60
          AutoCheck = True
          Caption = '60%'
          GroupIndex = 123
          RadioItem = True
          OnClick = SetBackgroundAlpha
        end
        object N801: TMenuItem
          Tag = 80
          AutoCheck = True
          Caption = '80%'
          GroupIndex = 123
          RadioItem = True
          OnClick = SetBackgroundAlpha
        end
        object N100transparent1: TMenuItem
          Tag = 100
          AutoCheck = True
          Caption = '100% transparent'
          GroupIndex = 123
          RadioItem = True
          OnClick = SetBackgroundAlpha
        end
        object Additive1: TMenuItem
          Tag = -1
          AutoCheck = True
          Caption = 'Additive'
          GroupIndex = 123
          RadioItem = True
          OnClick = SetBackgroundAlpha
        end
        object ModulateMenu: TMenuItem
          Tag = -2
          AutoCheck = True
          Caption = 'Modulate'
          GroupIndex = 123
          RadioItem = True
          OnClick = SetBackgroundAlpha
        end
      end
      object Onotheroverlays1: TMenuItem
        Caption = 'Transparency on other overlays'
        object N0opaque2: TMenuItem
          AutoCheck = True
          Caption = '0% opaque'
          GroupIndex = 133
          RadioItem = True
          OnClick = SetOverlayAlpha
        end
        object N202: TMenuItem
          Tag = 20
          AutoCheck = True
          Caption = '20%'
          GroupIndex = 133
          RadioItem = True
          OnClick = SetOverlayAlpha
        end
        object N402: TMenuItem
          Tag = 40
          AutoCheck = True
          Caption = '40%'
          GroupIndex = 133
          RadioItem = True
          OnClick = SetOverlayAlpha
        end
        object N502: TMenuItem
          Tag = 50
          AutoCheck = True
          Caption = '50%'
          GroupIndex = 133
          RadioItem = True
          OnClick = SetOverlayAlpha
        end
        object N602: TMenuItem
          Tag = 60
          AutoCheck = True
          Caption = '60%'
          GroupIndex = 133
          RadioItem = True
          OnClick = SetOverlayAlpha
        end
        object N802: TMenuItem
          Tag = 80
          AutoCheck = True
          Caption = '80%'
          GroupIndex = 133
          RadioItem = True
          OnClick = SetOverlayAlpha
        end
        object N100transparent2: TMenuItem
          Tag = 100
          AutoCheck = True
          Caption = '100% transparent'
          GroupIndex = 133
          RadioItem = True
          OnClick = SetOverlayAlpha
        end
        object Additive2: TMenuItem
          Tag = -1
          AutoCheck = True
          Caption = 'Additive'
          GroupIndex = 133
          RadioItem = True
          OnClick = SetOverlayAlpha
        end
      end
      object InterpolateMenu: TMenuItem
        AutoCheck = True
        Caption = 'Smooth when loading'
        Checked = True
        OnClick = InterpolateMenuClick
      end
      object BackgroundMaskMenu: TMenuItem
        AutoCheck = True
        Caption = 'Background masks overlays'
        Checked = True
        OnClick = BackgroundMaskMenuClick
      end
      object OverlayColorFromZeroMenu: TMenuItem
        AutoCheck = True
        Caption = 'Overlay color from zero'
        OnClick = OverlayColorFromZeroMenuClick
      end
      object OverlayhideZerosMenu: TMenuItem
        AutoCheck = True
        Caption = 'Overlay hide zeros'
        OnClick = OverlayColorFromZeroMenuClick
      end
    end
    object Import1: TMenuItem
      Caption = 'Import'
      object ConvertDicom1: TMenuItem
        Caption = 'Convert DICOM to NIfTI'
        ShortCut = 16452
        OnClick = ConvertDicom1Click
      end
    end
    object Draw1: TMenuItem
      Caption = 'Draw'
      object OpenVOI1: TMenuItem
        Caption = 'Open VOI'
        OnClick = OpenVOI1Click
      end
      object SaveVOI1: TMenuItem
        Caption = 'Save VOI'
        OnClick = SaveVOI1Click
      end
      object CloseVOI1: TMenuItem
        Caption = 'Close VOI'
        OnClick = CloseVOI1Click
      end
      object UndoVOI1: TMenuItem
        Caption = 'Undo'
        ShortCut = 16474
        OnClick = UndoVOI1Click
      end
      object Transparency1: TMenuItem
        Caption = 'Transparency'
        object HideVOI1: TMenuItem
          AutoCheck = True
          Caption = 'Hide/Unhide'
          ShortCut = 16456
          OnClick = TransparencyVOIClick
        end
        object TransparencyVOIhi: TMenuItem
          Tag = 64
          AutoCheck = True
          Caption = '25%'
          GroupIndex = 121
          RadioItem = True
          OnClick = TransparencyVOIClick
        end
        object TransparencyVOImid: TMenuItem
          Tag = 128
          AutoCheck = True
          Caption = '50%'
          Checked = True
          GroupIndex = 121
          RadioItem = True
          OnClick = TransparencyVOIClick
        end
        object TransparencyVOIlo: TMenuItem
          Tag = 230
          Caption = '90%'
          GroupIndex = 121
          RadioItem = True
          OnClick = TransparencyVOIClick
        end
      end
      object DrawTool1: TMenuItem
        Caption = 'Draw color'
        object NoDraw1: TMenuItem
          Tag = -1
          AutoCheck = True
          Caption = 'None (disable draw mode)'
          Checked = True
          GroupIndex = 189
          RadioItem = True
          OnClick = DrawTool1Click
        end
        object Eraser1: TMenuItem
          AutoCheck = True
          Caption = 'Erase'
          GroupIndex = 189
          RadioItem = True
          ShortCut = 16432
          OnClick = DrawTool1Click
        end
      end
      object Advanced1: TMenuItem
        Caption = 'Advanced'
        object OverwriteDrawColor1: TMenuItem
          AutoCheck = True
          Caption = 'Overwrite draw colors'
          Checked = True
        end
        object PasteSlice1: TMenuItem
          Caption = 'Clone slice'
          OnClick = PasteSlice1Click
        end
        object CustomDrawColors1: TMenuItem
          Caption = 'Custom draw colors'
          OnClick = CustomDrawColors1Click
        end
        object Smooth1: TMenuItem
          Caption = 'Smooth and refine drawing'
          OnClick = Smooth1Click
        end
        object AutoRoi1: TMenuItem
          Caption = 'Automatic VOI'
          OnClick = AutoRoi1Click
        end
      end
    end
    object Display1: TMenuItem
      Caption = 'Display'
      object Render1: TMenuItem
        AutoCheck = True
        Caption = 'Render'
        GroupIndex = 212
        RadioItem = True
        ShortCut = 16466
        OnClick = SetViewClick
      end
      object Axial1: TMenuItem
        Tag = 1
        AutoCheck = True
        Caption = 'Axial'
        GroupIndex = 212
        RadioItem = True
        ShortCut = 16449
        OnClick = SetViewClick
      end
      object Coronal1: TMenuItem
        Tag = 2
        AutoCheck = True
        Caption = 'Coronal'
        GroupIndex = 212
        RadioItem = True
        ShortCut = 16451
        OnClick = SetViewClick
      end
      object Sagittal1: TMenuItem
        Tag = 3
        AutoCheck = True
        Caption = 'Sagittal'
        GroupIndex = 212
        RadioItem = True
        ShortCut = 16467
        OnClick = SetViewClick
      end
      object MPR1: TMenuItem
        Tag = 4
        AutoCheck = True
        Caption = 'Multi Planar (A+C+S)'
        GroupIndex = 212
        RadioItem = True
        ShortCut = 16461
        OnClick = SetViewClick
      end
      object Mosaic1: TMenuItem
        Tag = 5
        AutoCheck = True
        Caption = 'Mosaic'
        GroupIndex = 212
        RadioItem = True
        OnClick = Mosaic1Click
      end
      object YokeSepMenu: TMenuItem
        Caption = '-'
        GroupIndex = 212
      end
      object YokeMenu: TMenuItem
        AutoCheck = True
        Caption = 'Yoke'
        GroupIndex = 212
        ShortCut = 16473
        OnClick = YokeMenuClick
      end
    end
    object View1: TMenuItem
      Caption = 'View'
      object Tool1: TMenuItem
        AutoCheck = True
        Caption = 'Tool panel'
        Checked = True
        ShortCut = 16468
        OnClick = Tool1Click
      end
      object Orient1: TMenuItem
        AutoCheck = True
        Caption = 'Text and orientation cube'
        OnClick = Orient1Click
      end
      object Scripting1: TMenuItem
        Caption = 'Scripting'
        OnClick = Scripting1Click
      end
      object Extract1: TMenuItem
        Caption = 'Extract object[s]'
        OnClick = Extract1Click
      end
      object BET1: TMenuItem
        Caption = 'Brain extract'
        OnClick = BET1Click
      end
      object Sharpen1: TMenuItem
        Caption = 'Sharpen'
        OnClick = Sharpen1Click
      end
    end
    object Colors1: TMenuItem
      Caption = 'Color'
      object Scheme1: TMenuItem
        Caption = 'Scheme'
      end
      object ToggleTransparency1: TMenuItem
        AutoCheck = True
        Caption = 'Edit colors'
        OnClick = ToggleTransparency1Click
      end
      object Colorbar1: TMenuItem
        AutoCheck = True
        Caption = 'Colorbar'
        OnClick = Colorbar1Click
      end
      object Backcolor1: TMenuItem
        Caption = 'Back color'
        ShortCut = 16450
        OnClick = Backcolor1Click
      end
    end
    object Help1: TMenuItem
      Caption = 'Help'
      object About1: TMenuItem
        Caption = 'About'
        OnClick = About1Click
      end
      object Preferences1: TMenuItem
        Caption = 'Preferences'
        OnClick = Preferences1Click
      end
    end
    object AppleMenu: TMenuItem
      Caption = 'Apple'
      object AppleAbout: TMenuItem
        Caption = 'About MRIcroGL'
        OnClick = About1Click
      end
      object ApplePreferences: TMenuItem
        Caption = 'Preferences'
        OnClick = Preferences1Click
      end
    end
  end
  object OpenDialog1: TOpenDialog
    Filter = 'NIFTI|*.nii;*.hdr;*.nii.gz'
    Left = 272
    Top = 48
  end
  object ColorDialog1: TColorDialog
    Left = 272
    Top = 112
  end
  object UpdateTimer: TTimer
    Enabled = False
    Interval = 200
    OnTimer = UpdateTimerTimer
    Left = 272
    Top = 16
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = '*.png'
    Filter = 'PNG (lossless)|*.png|JPEG (lossy)|*.jpg'
    Left = 272
    Top = 144
  end
  object AutoRunTimer1: TTimer
    Enabled = False
    Interval = 250
    OnTimer = AutoRunTimer1Timer
    Left = 272
    Top = 184
  end
  object GradientsIdleTimer: TTimer
    Enabled = False
    OnTimer = GradientsIdleTimerTimer
    Left = 360
    Top = 32
  end
  object SaveDialogVoi: TSaveDialog
    Filter = 
      'Volume of interest (*.voi)|.voi|FSL (.nii.gz)|.nii.gz|SPM/FSL (.' +
      'nii)|.nii'
    Title = 'Save drawing as'
    Left = 280
    Top = 264
  end
  object OpenDialogVoi: TOpenDialog
    Title = 'Open drawing'
    Left = 320
    Top = 264
  end
  object OpenDialogTxt: TOpenDialog
    Filter = 'IK-SNaP label description file|.txt'
    Title = 'Open ITK-SNaP labels'
    Left = 376
    Top = 280
  end
  object ErrorTimer: TTimer
    Enabled = False
    Interval = 50
    OnTimer = ErrorTimerTimer
    Left = 384
    Top = 104
  end
  object YokeTimer: TTimer
    Enabled = False
    Interval = 200
    OnTimer = YokeTimerTimer
    Left = 384
    Top = 160
  end
end

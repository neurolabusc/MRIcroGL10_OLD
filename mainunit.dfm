object GLForm1: TGLForm1
  Left = 812
  Top = 28
  Width = 1045
  Height = 916
  Caption = 'MRIcroGL'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
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
  PixelsPerInch = 120
  TextHeight = 16
  object ToolPanel: TPanel
    Left = 0
    Top = 0
    Width = 325
    Height = 844
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    OnClick = ToolPanelClick
    object CutoutBox: TGroupBox
      Left = 0
      Top = 568
      Width = 325
      Height = 135
      Align = alTop
      Caption = 'Cutout'
      TabOrder = 0
      object xX: TLabel
        Left = 15
        Top = 25
        Width = 8
        Height = 16
        Caption = 'X'
      end
      object yY: TLabel
        Left = 15
        Top = 63
        Width = 9
        Height = 16
        Caption = 'Y'
      end
      object zZ: TLabel
        Left = 15
        Top = 101
        Width = 8
        Height = 16
        Caption = 'Z'
      end
      object XTrackBar: TTrackBar
        Left = 25
        Top = 21
        Width = 113
        Height = 36
        Max = 1000
        Position = 1000
        TabOrder = 0
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object YTrackBar: TTrackBar
        Left = 25
        Top = 58
        Width = 113
        Height = 37
        Max = 1000
        Position = 1000
        TabOrder = 1
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object ZTrackBar: TTrackBar
        Left = 25
        Top = 96
        Width = 113
        Height = 37
        Max = 1000
        TabOrder = 2
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object X2TrackBar: TTrackBar
        Left = 135
        Top = 21
        Width = 114
        Height = 36
        Max = 1000
        TabOrder = 3
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object Y2TrackBar: TTrackBar
        Left = 135
        Top = 58
        Width = 114
        Height = 37
        Max = 1000
        TabOrder = 4
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object Z2TrackBar: TTrackBar
        Left = 135
        Top = 96
        Width = 114
        Height = 37
        Max = 1000
        TabOrder = 5
        TickStyle = tsNone
        OnChange = CutoutChange
      end
      object NearBtn: TButton
        Left = 246
        Top = 39
        Width = 73
        Height = 31
        Caption = 'Near'
        TabOrder = 6
        OnClick = CutoutNearestSector
      end
      object NoneBtn: TButton
        Left = 246
        Top = 81
        Width = 73
        Height = 31
        Caption = 'None'
        TabOrder = 7
        OnClick = HideBtnClick
      end
    end
    object ShaderBox: TGroupBox
      Left = 0
      Top = 791
      Width = 325
      Height = 53
      Align = alClient
      Caption = 'Shader'
      TabOrder = 1
      object ShaderMemo: TMemo
        Left = 2
        Top = 145
        Width = 321
        Height = 41
        Align = alClient
        BevelOuter = bvNone
        Lines.Strings = (
          '')
        TabOrder = 0
      end
      object ShaderPanel: TPanel
        Left = 2
        Top = 18
        Width = 321
        Height = 127
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object Label1: TLabel
          Left = 181
          Top = 9
          Width = 10
          Height = 16
          Hint = 'Higher quality looks nicer but is slower to render'
          Caption = 'Q'
          ParentShowHint = False
          ShowHint = True
        end
        object Label2: TLabel
          Left = 7
          Top = 40
          Width = 28
          Height = 16
          Hint = 'Set the elevation and azimuth of the illumination'
          Caption = 'Light'
          ParentShowHint = False
          ShowHint = True
        end
        object S1Label: TLabel
          Tag = 1
          Left = 7
          Top = 72
          Width = 16
          Height = 16
          Caption = 'S1'
          ParentShowHint = False
          ShowHint = False
        end
        object S2Label: TLabel
          Tag = 2
          Left = 7
          Top = 104
          Width = 16
          Height = 16
          Caption = 'S2'
          ParentShowHint = False
          ShowHint = False
        end
        object S3Label: TLabel
          Tag = 3
          Left = 7
          Top = 136
          Width = 16
          Height = 16
          Caption = 'S3'
          ParentShowHint = False
          ShowHint = False
        end
        object S4Label: TLabel
          Tag = 4
          Left = 7
          Top = 168
          Width = 16
          Height = 16
          Caption = 'S4'
          ParentShowHint = False
          ShowHint = False
        end
        object S5Label: TLabel
          Tag = 5
          Left = 7
          Top = 200
          Width = 16
          Height = 16
          Caption = 'S5'
          ParentShowHint = False
          ShowHint = False
        end
        object S6Label: TLabel
          Tag = 6
          Left = 7
          Top = 232
          Width = 16
          Height = 16
          Caption = 'S6'
          ParentShowHint = False
          ShowHint = False
        end
        object S7Label: TLabel
          Tag = 7
          Left = 7
          Top = 264
          Width = 16
          Height = 16
          Caption = 'S7'
          ParentShowHint = False
          ShowHint = False
        end
        object S8Label: TLabel
          Tag = 8
          Left = 7
          Top = 296
          Width = 16
          Height = 16
          Caption = 'S8'
          ParentShowHint = False
          ShowHint = False
        end
        object S9Label: TLabel
          Tag = 9
          Left = 7
          Top = 328
          Width = 16
          Height = 16
          Caption = 'S9'
          ParentShowHint = False
          ShowHint = False
        end
        object S10Label: TLabel
          Tag = 10
          Left = 7
          Top = 360
          Width = 23
          Height = 16
          Caption = 'S10'
          ParentShowHint = False
          ShowHint = False
        end
        object ShaderDrop: TComboBox
          Left = 5
          Top = 5
          Width = 162
          Height = 24
          Style = csDropDownList
          DropDownCount = 24
          ItemHeight = 16
          TabOrder = 0
          OnChange = ShaderDropChange
          Items.Strings = (
            'none')
        end
        object QualityTrack: TTrackBar
          Left = 199
          Top = 5
          Width = 119
          Height = 29
          Min = 1
          Position = 3
          TabOrder = 1
          TickStyle = tsNone
          OnChange = QualityTrackChange
        end
        object LightElevTrack: TTrackBar
          Left = 54
          Top = 37
          Width = 119
          Height = 29
          Max = 90
          Min = -90
          Position = 5
          TabOrder = 2
          TickStyle = tsNone
          OnChange = AziElevChange
        end
        object LightAziTrack: TTrackBar
          Left = 199
          Top = 37
          Width = 119
          Height = 29
          Max = 180
          Min = -180
          TabOrder = 3
          TickStyle = tsNone
          OnChange = AziElevChange
        end
        object S1Track: TTrackBar
          Tag = 1
          Left = 199
          Top = 69
          Width = 118
          Height = 29
          Max = 100
          Position = 50
          TabOrder = 4
          TickStyle = tsNone
          OnChange = UniformChange
        end
        object S1Check: TCheckBox
          Tag = 1
          Left = 176
          Top = 72
          Width = 25
          Height = 17
          TabOrder = 5
          OnClick = UniformChange
        end
        object S2Check: TCheckBox
          Tag = 2
          Left = 176
          Top = 104
          Width = 25
          Height = 17
          TabOrder = 6
          OnClick = UniformChange
        end
        object S2Track: TTrackBar
          Tag = 2
          Left = 199
          Top = 101
          Width = 118
          Height = 29
          Max = 100
          Position = 50
          TabOrder = 7
          TickStyle = tsNone
          OnChange = UniformChange
        end
        object S3Track: TTrackBar
          Tag = 3
          Left = 199
          Top = 133
          Width = 118
          Height = 29
          Max = 100
          Position = 50
          TabOrder = 8
          TickStyle = tsNone
          OnChange = UniformChange
        end
        object S3Check: TCheckBox
          Tag = 3
          Left = 176
          Top = 136
          Width = 25
          Height = 17
          TabOrder = 9
          OnClick = UniformChange
        end
        object S4Track: TTrackBar
          Tag = 4
          Left = 199
          Top = 165
          Width = 118
          Height = 29
          Max = 100
          Position = 50
          TabOrder = 10
          TickStyle = tsNone
          OnChange = UniformChange
        end
        object S4Check: TCheckBox
          Tag = 4
          Left = 176
          Top = 168
          Width = 25
          Height = 17
          TabOrder = 11
          OnClick = UniformChange
        end
        object S5Track: TTrackBar
          Tag = 5
          Left = 199
          Top = 197
          Width = 118
          Height = 29
          Max = 100
          Position = 50
          TabOrder = 12
          TickStyle = tsNone
          OnChange = UniformChange
        end
        object S5Check: TCheckBox
          Tag = 5
          Left = 176
          Top = 200
          Width = 25
          Height = 17
          TabOrder = 13
          OnClick = UniformChange
        end
        object S6Track: TTrackBar
          Tag = 6
          Left = 199
          Top = 229
          Width = 118
          Height = 29
          Max = 100
          Position = 50
          TabOrder = 14
          TickStyle = tsNone
          OnChange = UniformChange
        end
        object S6Check: TCheckBox
          Tag = 6
          Left = 176
          Top = 232
          Width = 25
          Height = 17
          TabOrder = 15
          OnClick = UniformChange
        end
        object S7Check: TCheckBox
          Tag = 7
          Left = 176
          Top = 264
          Width = 25
          Height = 17
          TabOrder = 16
          OnClick = UniformChange
        end
        object S7Track: TTrackBar
          Tag = 7
          Left = 199
          Top = 261
          Width = 118
          Height = 29
          Max = 100
          Position = 50
          TabOrder = 17
          TickStyle = tsNone
          OnChange = UniformChange
        end
        object S8Track: TTrackBar
          Tag = 8
          Left = 199
          Top = 293
          Width = 118
          Height = 29
          Max = 100
          Position = 50
          TabOrder = 18
          TickStyle = tsNone
          OnChange = UniformChange
        end
        object S8Check: TCheckBox
          Tag = 8
          Left = 176
          Top = 296
          Width = 25
          Height = 17
          TabOrder = 19
          OnClick = UniformChange
        end
        object S9Track: TTrackBar
          Tag = 9
          Left = 199
          Top = 325
          Width = 118
          Height = 29
          Max = 100
          Position = 50
          TabOrder = 20
          TickStyle = tsNone
          OnChange = UniformChange
        end
        object S9Check: TCheckBox
          Tag = 9
          Left = 176
          Top = 328
          Width = 25
          Height = 17
          TabOrder = 21
          OnClick = UniformChange
        end
        object S10Track: TTrackBar
          Tag = 10
          Left = 199
          Top = 357
          Width = 118
          Height = 29
          Max = 100
          Position = 50
          TabOrder = 22
          TickStyle = tsNone
          OnChange = UniformChange
        end
        object S10Check: TCheckBox
          Tag = 10
          Left = 176
          Top = 360
          Width = 25
          Height = 17
          TabOrder = 23
          OnClick = UniformChange
        end
      end
    end
    object ClipBox: TGroupBox
      Left = 0
      Top = 146
      Width = 325
      Height = 133
      Align = alTop
      Caption = 'Clipping'
      TabOrder = 2
      object Label4: TLabel
        Left = 7
        Top = 25
        Width = 36
        Height = 16
        Caption = 'Depth'
        OnClick = Label4Click
      end
      object Label5: TLabel
        Left = 7
        Top = 101
        Width = 56
        Height = 16
        Caption = 'Elevation'
        OnClick = Label6Click
      end
      object Label6: TLabel
        Left = 7
        Top = 63
        Width = 46
        Height = 16
        Caption = 'Azimuth'
        OnClick = Label5Click
      end
      object ClipTrack: TTrackBar
        Left = 79
        Top = 21
        Width = 211
        Height = 36
        Max = 999
        TabOrder = 0
        TickStyle = tsNone
        OnChange = ClipTrackChange
      end
      object ElevTrack1: TTrackBar
        Left = 79
        Top = 94
        Width = 211
        Height = 36
        Max = 180
        Min = -180
        Frequency = 45
        TabOrder = 1
        TickStyle = tsNone
        OnChange = ClipTrackChange
      end
      object AziTrack1: TTrackBar
        Left = 79
        Top = 57
        Width = 211
        Height = 37
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
      Width = 325
      Height = 54
      Align = alTop
      Caption = 'Intensity Minimum...Maximum'
      TabOrder = 3
      object MaxEdit: TEdit
        Left = 167
        Top = 21
        Width = 148
        Height = 24
        TabOrder = 0
        OnKeyPress = MinMaxEditKeyPress
        OnKeyUp = MinMaxEditKeyUp
      end
      object MinEdit: TEdit
        Left = 10
        Top = 21
        Width = 148
        Height = 24
        TabOrder = 1
        OnKeyPress = MinMaxEditKeyPress
        OnKeyUp = MinMaxEditKeyUp
      end
    end
    object CollapseToolPanelBtn: TButton
      Left = 305
      Top = 2
      Width = 15
      Height = 15
      Hint = 'Hide tool panel'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = CollapsedToolPanelClick
    end
    object MosaicBox: TGroupBox
      Left = 0
      Top = 279
      Width = 325
      Height = 289
      Align = alTop
      Caption = 'Mosaic'
      TabOrder = 5
      object MosaicText: TMemo
        Left = 2
        Top = 190
        Width = 321
        Height = 97
        Align = alClient
        TabOrder = 0
      end
      object MosaicPanel: TPanel
        Left = 2
        Top = 18
        Width = 321
        Height = 172
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object Label7: TLabel
          Left = 7
          Top = 11
          Width = 52
          Height = 16
          Caption = 'Columns'
        end
        object Label3: TLabel
          Left = 7
          Top = 43
          Width = 34
          Height = 16
          Caption = 'Rows'
        end
        object Label8: TLabel
          Left = 7
          Top = 85
          Width = 64
          Height = 16
          Caption = 'Orientation'
        end
        object ColEdit: TSpinEdit
          Left = 59
          Top = 5
          Width = 119
          Height = 26
          MaxValue = 20
          MinValue = 1
          TabOrder = 0
          Value = 3
          OnChange = UpdateMosaic
        end
        object RowEdit: TSpinEdit
          Left = 59
          Top = 43
          Width = 119
          Height = 26
          MaxValue = 20
          MinValue = 1
          TabOrder = 1
          Value = 2
          OnChange = UpdateMosaic
        end
        object ColOverlap: TTrackBar
          Left = 182
          Top = 5
          Width = 138
          Height = 36
          Max = 9
          Min = -9
          Position = -1
          TabOrder = 2
          TickStyle = tsNone
          OnChange = UpdateMosaic
        end
        object RowOverlap: TTrackBar
          Left = 182
          Top = 42
          Width = 138
          Height = 37
          Max = 9
          Min = -9
          Position = -3
          TabOrder = 3
          TickStyle = tsNone
          OnChange = UpdateMosaic
        end
        object OrientDrop: TComboBox
          Left = 79
          Top = 80
          Width = 178
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
          Left = 7
          Top = 112
          Width = 112
          Height = 21
          Caption = 'Cross slice'
          TabOrder = 5
          OnClick = UpdateMosaic
        end
        object LabelCheck: TCheckBox
          Left = 177
          Top = 112
          Width = 138
          Height = 21
          Caption = 'Label slice number'
          TabOrder = 6
          OnClick = UpdateMosaic
        end
        object CopyScriptBtn: TButton
          Left = 10
          Top = 141
          Width = 119
          Height = 29
          Caption = 'Copy Script'
          TabOrder = 7
          OnClick = CopyScriptClick
        end
        object RunScriptBtn: TButton
          Left = 177
          Top = 141
          Width = 120
          Height = 29
          Caption = 'Run Script'
          TabOrder = 8
          OnClick = RunScriptClick
        end
      end
    end
    object HideRenderToolsBtn: TButton
      Left = 281
      Top = 2
      Width = 14
      Height = 15
      Hint = 'Show or hide rendering tools (useful for small screens)'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      OnClick = HideRenderToolsBtnClick
    end
    object OverlayBox: TGroupBox
      Left = 0
      Top = 54
      Width = 325
      Height = 92
      Align = alTop
      Caption = 'Overlays'
      TabOrder = 7
      Visible = False
      object StringGrid1: TStringGrid
        Left = 2
        Top = 18
        Width = 321
        Height = 72
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
        Left = 30
        Top = 89
        Width = 89
        Height = 19
        Style = csOwnerDrawFixed
        DropDownCount = 36
        ItemHeight = 13
        TabOrder = 1
        Visible = False
        OnChange = LUTdropChange
      end
    end
    object Slice2DBox: TGroupBox
      Left = 0
      Top = 703
      Width = 325
      Height = 88
      Align = alTop
      Caption = '2D Slices'
      TabOrder = 8
      object LeftBtn: TSpeedButton
        Left = 8
        Top = 40
        Width = 29
        Height = 29
        Caption = 'L'
      end
      object AnteriorBtn: TSpeedButton
        Tag = 3
        Left = 48
        Top = 16
        Width = 29
        Height = 29
        Caption = 'A'
      end
      object PosteriorBtn: TSpeedButton
        Tag = 2
        Left = 48
        Top = 53
        Width = 29
        Height = 27
        Caption = 'P'
      end
      object RightBtn: TSpeedButton
        Tag = 1
        Left = 88
        Top = 40
        Width = 29
        Height = 29
        Caption = 'R'
      end
      object SuperiorBtn: TSpeedButton
        Tag = 5
        Left = 200
        Top = 16
        Width = 29
        Height = 29
        Caption = 'S'
      end
      object InferiorBtn: TSpeedButton
        Tag = 4
        Left = 200
        Top = 53
        Width = 29
        Height = 27
        Caption = 'I'
      end
    end
  end
  object CollapsedToolPanel: TPanel
    Left = 325
    Top = 0
    Width = 5
    Height = 844
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
      object ConvertForeign1: TMenuItem
        Caption = 'Convert foreign to NIfTI'
      end
      object ReorientMenu: TMenuItem
        Caption = 'Rotate volume'
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
        object voiBinarize1: TMenuItem
          Caption = 'Binarize'
          OnClick = voiBinarize1Click
        end
        object interpolateDrawMenu: TMenuItem
          Caption = 'Interpolate between slices'
          object InterpolateRecentMenu: TMenuItem
            Caption = 'Last two slices '
            ShortCut = 16472
            OnClick = InterpolateDrawMenuClick
          end
          object InterpolateAxialMenu: TMenuItem
            Tag = 1
            Caption = 'All axial gaps'
            OnClick = InterpolateDrawMenuClick
          end
          object InterpolateCoronalMenu: TMenuItem
            Tag = 2
            Caption = 'All coronal gaps'
            OnClick = InterpolateDrawMenuClick
          end
          object InterpolateSagittalMenu: TMenuItem
            Tag = 3
            Caption = 'All sagittal gaps'
            OnClick = InterpolateDrawMenuClick
          end
        end
        object voiDescriptives1: TMenuItem
          Caption = 'Descriptives'
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
      object ViewSepMenu: TMenuItem
        Caption = '-'
        GroupIndex = 212
      end
      object LeftMenu: TMenuItem
        Caption = 'Left'
        GroupIndex = 212
        ShortCut = 76
        OnClick = OrientMenuClick
      end
      object RightMenu: TMenuItem
        Tag = 1
        Caption = 'Right'
        GroupIndex = 212
        ShortCut = 82
        OnClick = OrientMenuClick
      end
      object PosteriorMenu: TMenuItem
        Tag = 2
        Caption = 'Posterior'
        GroupIndex = 212
        ShortCut = 80
        OnClick = OrientMenuClick
      end
      object AnteriorMenu: TMenuItem
        Tag = 3
        Caption = 'Anterior'
        GroupIndex = 212
        ShortCut = 65
        OnClick = OrientMenuClick
      end
      object InferiorMenu: TMenuItem
        Tag = 4
        Caption = 'Inferior'
        GroupIndex = 212
        ShortCut = 73
        OnClick = OrientMenuClick
      end
      object SuperiorMenu: TMenuItem
        Tag = 5
        Caption = 'Superior'
        GroupIndex = 212
        ShortCut = 83
        OnClick = OrientMenuClick
      end
      object RadiologicalMenu: TMenuItem
        AutoCheck = True
        Caption = 'Radiological (FlipLR)'
        GroupIndex = 212
        OnClick = RadiologicalMenuClick
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
      object ClrbarMenu: TMenuItem
        Caption = 'Colorbar'
        OnClick = ClrbarMenu1Click
        object VisibleClrbarMenu: TMenuItem
          AutoCheck = True
          Caption = 'Visible'
          RadioItem = True
          OnClick = ClrbarMenu1Click
        end
        object ClrbarSep: TMenuItem
          Caption = '-'
        end
        object WhiteClrbarMenu: TMenuItem
          Tag = 1
          AutoCheck = True
          Caption = 'White'
          GroupIndex = 193
          RadioItem = True
          OnClick = ClrbarMenuClick
        end
        object TransWhiteClrbarMenu: TMenuItem
          Tag = 2
          AutoCheck = True
          Caption = 'Translucent White'
          GroupIndex = 193
          RadioItem = True
          OnClick = ClrbarMenuClick
        end
        object BlackClrbarMenu: TMenuItem
          Tag = 3
          AutoCheck = True
          Caption = 'Black'
          GroupIndex = 193
          RadioItem = True
          OnClick = ClrbarMenuClick
        end
        object TransBlackClrbarMenu: TMenuItem
          Tag = 4
          AutoCheck = True
          Caption = 'Translucent Black'
          Checked = True
          GroupIndex = 193
          RadioItem = True
          OnClick = ClrbarMenuClick
        end
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

unit autoroi;

interface
{$include opts.inc}
uses
 {$IFNDEF FPC}

  Spin,
 {$ELSE}
 Spin,lResources,
 {$ENDIF}
 {$IFNDEF FPC} Windows,{$ENDIF}
 SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, StdCtrls,  ExtCtrls, {$IFDEF COREGL} raycast_core, {$ELSE} raycast_legacy, {$ENDIF} raycast_common;    //define_types,

type
  { TAutoROIForm }
  TAutoROIForm = class(TForm)
    AutoROIBtn: TButton;
    CancelBtn: TButton;
    OriginBtn: TButton;
    ROIconstraint: TComboBox;
    OriginLabel: TLabel;
    //RadiusEdit: TSpinEdit;
    //VarianceEdit: TSpinEdit;
    DiffLabel: TLabel;
    Label2: TLabel;
    Timer1: TTimer;
    Label4: TLabel;
    VarianceEdit: TSpinEdit;
    RadiusEdit: TSpinEdit;
        procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
 procedure OriginBtnClick(Sender: TObject);
	procedure PreviewBtnClick(Sender: TObject);
	procedure FormShow(Sender: TObject);
	procedure FormCreate(Sender: TObject);
	procedure FormHide(Sender: TObject);
	procedure AutoROIBtnClick(Sender: TObject);
	procedure CancelBtnClick(Sender: TObject);
	procedure AutoROIchange(Sender: TObject);
	procedure Timer1Timer(Sender: TObject);
	procedure FormDestroy(Sender: TObject);
  private
	{ Private declarations }
  public
	{ Public declarations }
  end;

//procedure ROICluster ({lInROIBuf: bytep;} lXdim, lYDim, lZDim,lXOriginIn,lYOrigin,lZOrigin: integer; lDeleteNotFill: boolean);
var
  AutoROIForm: TAutoROIForm;
  gOriginX,gOriginY,gOriginZ: single;
implementation
 uses mainunit, drawU;
 {$IFNDEF FPC}
 {$R *.DFM}
 {$ENDIF}


procedure TAutoROIForm.OriginBtnClick(Sender: TObject);
begin
 gOriginX := gRayCast.OrthoX;
 gOriginY := gRayCast.OrthoY;
 gOriginZ := gRayCast.OrthoZ;
 //OriginLabel.Caption := 'Origin: '+ Format('%.2f',[gOriginX])+'x'+ Format('%.2f',[gOriginY]) +'x'+Format('%.2f',[gOriginZ]);
 PreviewBtnClick(sender);
end;

procedure TAutoROIForm.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
   //
end;

procedure TAutoROIForm.PreviewBtnClick(Sender: TObject);
var
  clr: integer;
begin
 {$IFDEF USETRANSFERTEXTURE}
 showmessage('recompile');
 {$ELSE}
    //GLForm1.DrawTool1.Menu.Items[2].click;
   //showmessage('Please select a drawing color (Draw menu)');
 if  (not voiIsOpen) then begin //clicked after VOI/Close - lets create a new one
    voiCreate(gTexture3D.FiltDim[1], gTexture3D.FiltDim[2],gTexture3D.FiltDim[3], nil);
 end;
 voiUndo;
 clr :=  gPrefs.DrawColor;
 if (clr < 1) then clr := 1;
 voiMorphologyFill(gTexture3D.FiltImg, clr, gTexture3D.PixMM[1], gTexture3D.PixMM[2], gTexture3D.PixMM[3], gOriginX, gOriginY, gOriginZ, VarianceEdit.Value,  RadiusEdit.value, ROIconstraint.itemIndex);
 GLForm1.UpdateGL;
 {$ENDIF}
end;

procedure TAutoROIForm.FormShow(Sender: TObject);
begin
 (*if (gPrefs.DrawColor < 1) and (GLForm1.DrawTool1.Count > 2) then
    GLForm1.DrawTool1.Items[2].Click;*)
 if (GLForm1.Width+GLForm1.Left+AutoRoiForm.Width) < Screen.Width then begin
    AutoRoiForm.Left := GLForm1.Width+GLForm1.Left+1;
    AutoRoiForm.Top := GLForm1.Top+GLForm1.Height-AutoRoiForm.Height;
 end else if (GLForm1.Left > AutoRoiForm.Width) then begin
    AutoRoiForm.Left := GLForm1.Left-AutoRoiForm.Width-1;
    AutoRoiForm.Top := GLForm1.Top+GLForm1.Height-AutoRoiForm.Height;
 end;
//EnsureVOIOpen;
//CreateUndoVol;
        voiCloseSlice;
	AutoROIForm.ModalResult := mrCancel;
	//ROIconstraint.Enabled := true;// (gMRIcroOverlay[kVOIOverlayNum].ScrnBufferItems > 1);
	OriginBtn.OnClick(sender);
        AutoROIForm.Refresh;
	 //DeleteCheck.enabled := (gROIBupSz > 1);
	 //ROIConstrainCheck.enabled := (gROIBupSz > 1);
end;

procedure TAutoROIForm.FormCreate(Sender: TObject);
begin
  //writeln('Create AutoROI');
end;

procedure TAutoROIForm.FormHide(Sender: TObject);
begin
     //767 GLForm1.DrawTool1.Items[0].click;
     GLForm1.NoDraw1.Click;

end;

procedure TAutoROIForm.AutoROIBtnClick(Sender: TObject);
begin
	AutoROIForm.ModalResult := mrOK;
	AutoROIForm.close;
end;

procedure TAutoROIForm.CancelBtnClick(Sender: TObject);
begin
        voiUndo;
        GLForm1.UpdateGL;
	 AutoROIForm.close;

end;

procedure TAutoROIForm.AutoROIchange(Sender: TObject);
begin
     if not AutoROIForm.visible then exit;
     Timer1.Enabled := true;
end;

procedure TAutoROIForm.Timer1Timer(Sender: TObject);
begin
Timer1.Enabled := false;
PreviewBtnClick(sender);
end;

procedure TAutoROIForm.FormDestroy(Sender: TObject);
begin
	 //if gImageBackupSz <> 0 then Freemem(gImageBackupBuffer);
     //gImageBackupSz := 0;
end;

  {$IFDEF FPC}
initialization
  {$I autoroi.lrs}
{$ENDIF}

end.

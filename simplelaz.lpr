program simplelaz;

{$mode objfpc}{$H+}
{$include opts.inc}
uses
{$IFDEF FPC}{$IFNDEF UNIX} uscaledpi,

{$ENDIF}{$IFDEF LINUX} Graphics, uscaledpi, {$ENDIF}{$ENDIF}
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
{$IFDEF COREGL} {$ELSE} raycast_legacy, {$ENDIF}
  Interfaces, Forms, lazopenglcontext, mainunit, autoroi, readint,
  nifti_dicom, clustering, savethreshold, reslice, drawu, dcm2nii, shaderui,
  clut,  raycast_common, pascalscript, extractui, nifti_tiff,
  dcm_load, commandsu, prefs, define_types, scriptengine;

{$IFNDEF UNIX}{$R simplelaz.res}{$ENDIF}

begin
  Application.Title:='MRIcroGL';

  Application.Initialize;
  Application.CreateForm(TGLForm1, GLForm1);
  Application.CreateForm(TReadIntForm, ReadIntForm);
  Application.CreateForm(TScriptForm, ScriptForm);
  Application.CreateForm(TResliceForm, ResliceForm);
  Application.CreateForm(Tdcm2niiForm, dcm2niiForm);
  Application.CreateForm(TAutoROIForm, AutoROIForm);
  Application.CreateForm(TExtractForm, ExtractForm);
  //HighDPIfont(GetFontData(GLForm1.Font.Handle).Height);
  {$IFDEF FPC}{$IFDEF LINUX} HighDPILinux(GetFontData(GLForm1.Font.Reference.Handle).Height); {$ENDIF} {$ENDIF}
  //{$IFDEF FPC}{$IFNDEF UNIX}HighDPI(96);{$ENDIF}{$ENDIF}
  Application.Run;
end.


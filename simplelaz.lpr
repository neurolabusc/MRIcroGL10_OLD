program simplelaz;

{$mode objfpc}{$H+}
{$include opts.inc}
uses
{$IFDEF FPC}{$IFNDEF UNIX} uscaledpi, {$ENDIF}{$IFDEF LINUX} Graphics, uscaledpi, {$ENDIF}{$ENDIF}
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, Forms, lazopenglcontext, mainunit, autoroi, readint, scriptengine,
  nifti_dicom, clustering, savethreshold, reslice, drawu, dcm2nii, shaderui,
  clut, {$IFDEF COREGL} raycast_core, {$ELSE} raycast_legacy, {$ENDIF} raycast_common, pascalscript, extractui;

{$IFNDEF UNIX}{$R simplelaz.res}{$ENDIF}

begin
  Application.Title:='mricrogl';
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
  {$IFDEF FPC}{$IFNDEF UNIX}HighDPI(96);{$ENDIF}{$ENDIF}
  Application.Run;
end.


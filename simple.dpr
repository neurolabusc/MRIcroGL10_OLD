program simple;
{$include options.inc}
{$WARN SYMBOL_PLATFORM OFF}
{$D-,L-,O+,Q-,R-,Y-,S-}
uses
  FastMM4, //fastMM4 prevents memory fragmentation seen with large volumes
  Forms,mainunit,glpanel,
  scriptengine,reslice,readint, dcm2nii, autoroi,extractui;
{$R *.res}
begin
{$INCLUDE FastMM4Options.inc}

  Application.Initialize;
  Application.CreateForm(TGLForm1, GLForm1);
  Application.CreateForm(TResliceForm , ResliceForm );
  Application.CreateForm(TReadIntForm, ReadIntForm);
  Application.CreateForm(Tdcm2niiForm , dcm2niiForm );
  
  {$IFDEF ENABLESCRIPT} Application.CreateForm(TScriptForm, ScriptForm); {$ENDIF}
  Application.CreateForm(TAutoROIForm, AutoROIForm);
   Application.CreateForm(TExtractForm, ExtractForm);
  Application.Run;
end.

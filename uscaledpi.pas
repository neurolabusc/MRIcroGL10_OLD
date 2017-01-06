unit uscaledpi;
 //http://wiki.lazarus.freepascal.org/High_DPI
{$IFDEF FPC}{$mode delphi}  {$H+}{$ENDIF}

interface

uses
   {$IFDEF Linux} FileUtil, Process, Classes,SysUtils, {$ENDIF}
   Forms, Graphics, Controls, ComCtrls;

procedure HighDPI(FromDPI: integer);
procedure ScaleDPI(Control: TControl; FromDPI: integer);
procedure HighDPIfont(fontSize: integer);
function getFontScale: single;

implementation

procedure ScaleDPI(Control: TControl; FromDPI: integer);
var
  i: integer;
  WinControl: TWinControl;
begin
  with Control do
  begin
    Left := ScaleX(Left, FromDPI);

    {$IFDEF LINUX} //strange minimum size and height on Lazarus 1.6.2
    if Control is TTrackBar then begin
      i := 22;
      Height := ScaleY(i, FromDPI);
      i := (Height - i) div 2;
      Top := ScaleY(Top, FromDPI) - i ;

    end else begin
       Top :=ScaleY(Top, FromDPI);
       Height := ScaleY(Height, FromDPI);
    end;
    {$ELSE}
       Top :=ScaleY(Top, FromDPI);
       Height := ScaleY(Height, FromDPI);
    {$ENDIF}
    Width := ScaleX(Width, FromDPI);


  end;

  if Control is TWinControl then
  begin
    WinControl := TWinControl(Control);
    if WinControl.ControlCount = 0 then
      exit;
    for i := 0 to WinControl.ControlCount - 1 do
      ScaleDPI(WinControl.Controls[i], FromDPI);
  end;
end;

{$IFDEF LINUX}
function getFontScale: single;
var
  AProcess: TProcess;
  Exe: String;
  AStringList: TStringList;
begin
  result := 1.0;
  Exe := FindDefaultExecutablePath('gsettings');
  if length(Exe) < 1 then exit;
  if not FileExists(Exe) then exit;
  AProcess := TProcess.Create(nil);
  AProcess.Executable:=Exe;
  AProcess.Parameters.Add('get');
  AProcess.Parameters.Add('org.gnome.desktop.interface');
  AProcess.Parameters.Add('text-scaling-factor');
  AProcess.Options := AProcess.Options + [poWaitOnExit, poUsePipes];
  AProcess.Execute;
  if (AProcess.ExitCode = 0) then begin
     AStringList := TStringList.Create;
     AStringList.LoadFromStream(AProcess.Output);
     if AStringList.Count > 0 then
        result := strtofloatdef(AStringList.Strings[0], 1.0);
     AStringList.Free;
  end;
  AProcess.Free;
end;
{$ELSE}
function getFontScale: single;
begin
     result := 1.0;
end;
{$ENDIF}

procedure HighDPIfont(fontSize: integer);
var
  i, FromDPI: integer;
  scale: single;
begin
  //if (fontSize <= 13) then exit;
  //FromDPI :=  round(14/fontSize * 96);
  scale := getFontScale;
  if (scale = 1) or (scale = 0) then exit;
  FromDPI := round( 96/scale);
  for i := 0 to Screen.FormCount - 1 do
    ScaleDPI(Screen.Forms[i], FromDPI);
end;

procedure HighDPI(FromDPI: integer);
var
  i: integer;
begin
  if Screen.PixelsPerInch = FromDPI then
    exit;
  for i := 0 to Screen.FormCount - 1 do
    ScaleDPI(Screen.Forms[i], FromDPI);
end;

end.


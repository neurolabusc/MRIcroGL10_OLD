unit nsappkitext;

{$mode objfpc}{$H+}
{$modeswitch objectivec2}
{$DEFINE XMojave}

interface

uses
  CocoaAll, LCLType,Classes, SysUtils, Controls, LCLClasses, Forms;

type
  NSAppearance = objcclass external (NSObject, NSCodingProtocol)
  private
    _name : NSString;
    _bundle : NSBundle;
    _private : Pointer;
    _reserved : id;
    _auxilary : id;
    {$ifdef CPU32}
    _extra : array [0..1] of id;
    {$endif}

  public
    procedure encodeWithCoder(aCoder: NSCoder); message 'encodeWithCoder:';
    function initWithCoder(aDecoder: NSCoder): id; message 'initWithCoder:';

    function name: NSString; message 'name';

    // Setting and identifying the current appearance in the thread.
    class function currentAppearance: NSAppearance; message 'currentAppearance';
    // nil is valid and indicates the default appearance.
    class procedure setCurrentAppearance(appearance: NSAppearance); message 'setCurrentAppearance:';

    // Finds and returns an NSAppearance based on the name.
    // For standard appearances such as NSAppearanceNameAqua, a built-in appearance is returned.
    // For other names, the main bundle is searched.
    class function appearanceNamed(aname: NSString): NSAppearance; message 'appearanceNamed:';

   {/* Creates an NSAppearance by searching the specified bundle for a file with the specified name (without path extension).
    If bundle is nil, the main bundle is assumed.
    */
    #if NS_APPEARANCE_DECLARES_DESIGNATED_INITIALIZERS
    - (nullable instancetype)initWithAppearanceNamed:(NSString *)name bundle:(nullable NSBundle *)bundle NS_DESIGNATED_INITIALIZER;
    - (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
    #endif}

    // Query allowsVibrancy to see if the given appearance actually needs vibrant drawing.
    // You may want to draw differently if the current apperance is vibrant.
    function allowsVibrancy: Boolean; message 'allowsVibrancy';
  end;
  {$IFNDEF Mojave}
  //procedure setThemeMode(FormHandle: HWND; isDarkMode: boolean);
  procedure setThemeMode(aOwner: TComponent; isDarkMode: boolean);
  {$ENDIF}
{$IFDEF Mojave}
  procedure setThemeMode(aOwner: TComponent; isDarkMode: boolean);
const
  macOSNSAppearanceNameAqua = 'NSAppearanceNameAqua';
  DefaultAppearance = macOSNSAppearanceNameAqua;
  macOSNSAppearanceNameVibrantDark = 'NSAppearanceNameVibrantDark';
  macOSNSAppearanceNameVibrantLight = 'NSAppearanceNameVibrantLight';
{$ELSE}
var

  NSAppearanceNameAqua: NSString; cvar; external;
  // Light content should use the default Aqua apppearance.
  NSAppearanceNameLightContent: NSString; cvar; external; // deprecated

  // The following two Vibrant appearances should only be set on an NSVisualEffectView, or one of its container subviews.
  NSAppearanceNameVibrantDark : NSString; cvar; external;
  NSAppearanceNameVibrantLight: NSString; cvar; external;
{$ENDIF}

type
  //it's actually a protocol!
  NSAppearanceCustomization = objccategory external (NSObject)
    procedure setAppearance(aappearance: NSAppearance); message 'setAppearance:';
    function appearance: NSAppearance; message 'appearance';

    // This returns the appearance that would be used when drawing the receiver, taking inherited appearances into account.
    //
    function effectiveAppearance: NSAppearance; message 'effectiveAppearance';
  end;


implementation

{$IFDEF Mojave}


function ComponentToNSWindow(Owner: TComponent): NSWindow;
var
  obj : NSObject;
begin
  Result := nil;
  if not Assigned(Owner) or not (Owner is TWinControl) then Exit;

  obj := NSObject(TWinControl(Owner).Handle);
  if not Assigned(obj) then Exit;

  if obj.respondsToSelector(ObjCSelector('window')) then
    Result := objc_msgSend(obj, ObjCSelector('window'));
end;

function UpdateAppearance(Owner: TComponent; const AAppearance: String): Boolean;
var
  cls : id;
  ap  : string;
  apr : id;
  win : NSWindow;
begin
  Result := false;

  win := ComponentToNSWindow(Owner);
  if not Assigned(win) then Exit;

  if AAppearance = ''
    then ap := DefaultAppearance
    else ap := AAppearance;

  cls := NSClassFromString( NSSTR('NSAppearance'));
  if not Assigned(cls) then Exit; // not suppored in OSX version

  apr := objc_msgSend(cls, ObjCSelector('appearanceNamed:'), NSSTR(@ap[1]));
  if not Assigned(apr) then Exit;

  if win.respondsToSelector(ObjCSelector('setAppearance:')) then
  begin
    objc_msgSend(win, ObjCSelector('setAppearance:'), apr);
    Result := true;
  end;
end;

procedure setThemeMode(aOwner: TComponent; isDarkMode: boolean);
begin
   if isDarkMode then
    UpdateAppearance(aOwner, macOSNSAppearanceNameVibrantDark)
  else
    UpdateAppearance(aOwner, DefaultAppearance);
end;

{$ELSE}

//procedure setThemeMode(FormHandle: HWND; isDarkMode: boolean);
procedure setThemeMode(aOwner: TComponent; isDarkMode: boolean);
var
  theWindow : CocoaAll.NSWindow;
  FormHandle: HWND;
begin
  FormHandle := (aOwner as TForm).Handle;
  theWindow := NSView(FormHandle).window;
  if isDarkMode then
    theWindow.setAppearance (NSAppearance.appearanceNamed(NSAppearanceNameVibrantDark))
  else
    theWindow.setAppearance (NSAppearance.appearanceNamed(NSAppearanceNameAqua));
  theWindow.invalidateShadow;
  //window.invalidateShadow()

end;
{$ENDIF}


(*{$IFDEF LCLCocoa}
{$mode objfpc}{$H+}
{$modeswitch objectivec2}
{$ENDIF}  *)

end.


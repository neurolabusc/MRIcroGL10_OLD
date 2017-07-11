unit glpanel;

interface
{$D-,L-,O+,Q-,R-,Y-,S-}
uses
  dglOpenGL,Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, stdctrls;
type
  TGLPanel= class(TPanel)
  private
      DC: HDC;
      RC: HGLRC;
  protected

    procedure Paint; override;

  public
    procedure MakeCurrent; overload;
    procedure MakeCurrent(dummy: boolean); overload;
    procedure ReleaseContext;
  published

  end;

procedure rglSetupGL(lPanel: TGLPanel; lAntiAlias: GLint);

procedure Register;

implementation
uses mainunit;

procedure Register;
begin
  RegisterComponents('GLPanel', [TGLPanel]);
end;

procedure TGLPanel.Paint;
begin
    wglMakeCurrent(self.DC, self.RC);
    GLForm1.GLboxPaint(self);
    SwapBuffers(Self.DC);
end;

procedure TGLPanel.MakeCurrent; 
begin
  wglMakeCurrent(self.DC, self.RC);
end;

procedure TGLPanel.MakeCurrent(dummy: boolean);
begin
  MakeCurrent;
end;

procedure  TGLPanel.ReleaseContext;
begin
  wglMakeCurrent(0,0);
end;

procedure rglSetupGL(lPanel: TGLPanel; lAntiAlias: GLint);
var
//http://stackoverflow.com/questions/3444217/opengl-how-to-limit-to-an-image-component
  PixelFormat: integer;
const
  PFD: TPixelFormatDescriptor = (
         nSize: sizeOf(TPixelFormatDescriptor);
         nVersion: 1;
         dwFlags: PFD_SUPPORT_OPENGL or PFD_DRAW_TO_WINDOW or PFD_DOUBLEBUFFER;
         iPixelType: PFD_TYPE_RGBA;
         cColorBits: 24;
         cRedBits: 0;
         cRedShift: 0;
         cGreenBits: 0;
         cGreenShift: 0;
         cBlueBits: 0;
         cBlueShift: 0;
         cAlphaBits: 24;
         cAlphaShift: 0;
         cAccumBits: 0;
         cAccumRedBits: 0;
         cAccumGreenBits: 0;
         cAccumBlueBits: 0;
         cAccumAlphaBits: 0;
         cDepthBits: 16;
         cStencilBits: 0;
         cAuxBuffers: 0;
         iLayerType: PFD_MAIN_PLANE;
         bReserved: 0;
         dwLayerMask: 0;
         dwVisibleMask: 0;
         dwDamageMask: 0);
begin
  lPanel.DC := GetDC(lPanel.Handle);
  if lAntiAlias > 0 then
    PixelFormat := lAntiAlias
  else
    PixelFormat := ChoosePixelFormat(lPanel.DC, @PFD);
  SetPixelFormat(lPanel.DC, PixelFormat, @PFD);
  lPanel.RC := wglCreateContext(lPanel.DC);
  wglMakeCurrent(lPanel.DC, lPanel.RC);
end;

end.
 
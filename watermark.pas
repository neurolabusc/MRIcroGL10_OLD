unit watermark;
interface
uses
  {$IFNDEF FPC} jpeg, pngimage,{$ENDIF}
  sysutils,graphics,dglOpenGL,define_types, textfx;

Type
  TWatermark = record 
    X,Y,Ht,Wid: integer;
    Texture2D: TGLuint;
    Filename: string;
  end;
procedure LoadWatermark(var W: TWatermark);
procedure DrawWatermark ( lX,lY,lW,lH: single; var W: TWatermark);
var
  gWatermark: TWatermark;

implementation

procedure CreateTexture2D(Width, Height: integer; pData : bytep; var Texture: TGLuint);
begin
  glDeleteTextures(1,@Texture);
  glGenTextures(1, @Texture);
  glBindTexture(GL_TEXTURE_2D, Texture);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA8, Width, HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, PChar(pData));
end;

procedure jpeg2bmp (s: string; var bmp: TBitmap);
var
   jpg  : TJpegImage;
begin
  jpg := TJpegImage.Create;
  TRY
      jpg.LoadFromFile(s);
      bmp.Height := jpg.Height;
      bmp.Width  := jpg.width;
      bmp.PixelFormat := pf24bit;
      bmp.Canvas.Draw(0,0, jpg);  // convert JPEG to Bitmap
  FINALLY
      jpg.Free
  END;
end;

procedure png2bmp (s: string; var bmp: TBitmap);
var
{$IFDEF FPC}
   png  : TPortableNetworkGraphic;
{$ELSE}
  png: TPNGObject;
{$ENDIF}
begin
{$IFDEF FPC}
     png := TPortableNetworkGraphic.Create;
{$ELSE}
     png := TPNGObject.Create;
{$ENDIF}
     TRY
        png.LoadFromFile(s);
        bmp.Height := png.Height;
        bmp.Width  := png.width;
        bmp.PixelFormat := pf24bit;
        bmp.Canvas.Draw(0,0, png);  // convert PNG to Bitmap
     FINALLY
            png.Free
     END;
end;

procedure LoadWatermark(var W: TWatermark);
var
  bmp: TBitmap;
  clr: TColor;
  data: bytep;  
  i,x,y: integer;
begin
  if not fileexists(W.Filename) then begin
     W.filename := '';
     exit;
  end;
  bmp := TBitmap.Create;
  if (UpCaseExt(W.Filename) = '.JPG') or (UpCaseExt(W.Filename) = '.JPEG') then
    jpeg2bmp (W.Filename,bmp)
  else if (UpCaseExt(W.Filename) = '.BMP') then
    bmp.LoadFromFile(W.Filename)
  else
    png2bmp (W.Filename,bmp);
  W.Filename := '';
  getmem(data,bmp.Width*bmp.Height*4);
  i := 1;
  //FPC/Lazarus faster with update locking http://wiki.lazarus.freepascal.org/Fast_direct_pixel_access
  try
     {$IFDEF FPC} bmp.BeginUpdate(True); {$ENDIF}
     for y:=  (bmp.Height-1) downto 0 do begin
         for x := (bmp.Width-1) downto 0 do begin
             clr := bmp.Canvas.Pixels[x,y];// := data^[i+2]+(data^[i+1] shl 8)+(data^[i] shl 16);
             data^[i] := clr and 255;
             data^[i+1] := (clr shr 8) and 255;
             data^[i+2] := (clr shr 16) and 255;
             data^[i+3] := 255;
             i := i + 4;
         end;//for X
     end; //for Y
  finally
  {$IFDEF FPC} bmp.EndUpdate(False); {$ENDIF}
  end;
  W.Ht := bmp.Height ;
  W.Wid := bmp.Width;
  bmp.free;
  CreateTexture2D(W.Wid,W.Ht, Data, W.Texture2D);
  freemem(data);
end;

procedure DrawWatermark ( lX,lY,lW,lH: single; var W: TWatermark);
begin
  Enter2D;
  glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D,W.Texture2D);
  glBegin(GL_QUADS);
      glTexCoord2d (0,1);
      glVertex2f(lX+lW,lY+lH);
      glTexCoord2d (0, 0);
      glVertex2f(lX+lW,lY);
      glTexCoord2d ( 1, 0);
      glVertex2f(lX,lY);
      glTexCoord2d (1, 1);
      glVertex2f(lX,lY+lH);
  glend;
  glDisable(GL_TEXTURE_2D);
end;

initialization
  gWatermark.Ht := 0;
  gWatermark.Wid := 0;
  gWatermark.Texture2D := 0;
end.
 

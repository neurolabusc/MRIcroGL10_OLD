unit shaderu;
{$IFDEF FPC}{$mode objfpc}{$H+}{$ENDIF}
{$D-,L-,O+,Q-,R-,Y-,S-}
{$include options.inc}
interface
uses
 {$IFDEF DGL} dglOpenGL, {$ELSE} gl, glext, {$ENDIF} sysutils,dialogs;
const
  kMaxUniform = 10;
  kError = 666;
  kNote = 777;
  kBool = 0;
  kInt = 1;
  kFloat = 2;
  kSet = 3;
type
  TUniform = record
    Name: string;
    Widget: integer;
    Min,DefaultV,Max: single;
    Bool: boolean;
  end;
  TShader = record
         FragmentProgram,VertexProgram,Note, Vendor: String;
         OverlayVolume: integer;
         nUniform: integer;
         Uniform: array [1..kMaxUniform] of
          TUniform;
  end;
var
  gShader: TShader;

function LoadShader(lFilename: string): TShader;
procedure AdjustShaders (lShader: TShader);

implementation
uses raycastglsl;


procedure AdjustShaders (lShader: TShader);
//sends the uniform values to the GPU
var
  i: integer;
begin
  if (lShader.nUniform < 1) or (lShader.nUniform > kMaxUniform) then
    exit;
  for i := 1 to lShader.nUniform do begin
    case lShader.Uniform[i].Widget of
      kFloat: uniform1f(lShader.Uniform[i].name,lShader.Uniform[i].defaultV);
      kInt: uniform1i(lShader.Uniform[i].name,round(lShader.Uniform[i].defaultV));
      kBool: begin
          if lShader.Uniform[i].bool then
            uniform1i(lShader.Uniform[i].name,1)
          else
            uniform1i(lShader.Uniform[i].name,0);
        end;
    end;//case
  end; //for each uniform
end; //AdjustShaders

function strtofloat0 (lS:string): single;
begin
  result := 0;
  if length(lS) < 1 then exit;
  if (upcase (lS[1]) = 'T')  or (upcase (lS[1]) = 'F') then exit; //old unsupported 'SET' used true/false booleans
  try
     result :=  strtofloat(lS);
  except
      on Exception : EConvertError do
         result := 0;
  end;
end;

function StrToUniform(lS: string): TUniform;
var
  lV: string;
  lC: char;
  lLen,lP,lN: integer;
begin
  result.Name := '';
  result.Widget := kError;
  lLen := length(lS);
  //read values
  lV := '';
  lP := 1;
  lN := 0;
  while (lP <= lLen) do begin
    if lS[lP] = '/' then
      exit;
    if lS[lP] <> '|' then
      lV := lV + lS[lP];

    if (lS[lP] = '|') or (lP = lLen) then begin
        inc(lN);
        case lN of
          1: result.Name := lV;
          2: begin
              lC := upcase (lV[1]);
              case lC of
                'S' : result.Widget := kSet;
                'B' : result.Widget := kBool;
                'I' : result.Widget := kInt;
                'F' : result.Widget := kFloat;
                'N' : begin
                    result.Widget := kNote;
                    exit;
                  end;
                else
                  showmessage('Unkown uniform type :'+lV);
                  exit;
              end;
            end;
          3: begin
            if (result.Widget = kBool) {or (result.Widget = kSet)} then begin
              result.bool := upcase (lV[1]) = 'T';
            end else
              result.min := strtofloat0(lV);
            end;
          4: result.defaultv := strtofloat0(lV);
          5: result.max := strtofloat0(lV);
        end;
        lV := '';
    end;
    inc(lP);
  end;
end;

const  kDefaultVertex =  'void main() { gl_TexCoord[1] = gl_MultiTexCoord1; gl_Position = ftransform();}' ;
const  kDefaultFragment =  'uniform int loops;'
+'uniform float stepSize, sliceSize, viewWidth, viewHeight, clipPlaneDepth;'
+'uniform sampler3D intensityVol;'
+'uniform sampler2D backFace;'
+'uniform vec3 clearColor, clipPlane;'
+'void main() {'
+'	vec3 backPosition = texture2D(backFace,vec2(gl_FragCoord.x/viewWidth,gl_FragCoord.y/viewHeight)).xyz;'
+'	vec3 start = gl_TexCoord[1].xyz;'
+'	vec3 dir = backPosition - start;'
+'	float len = length(dir);'
+'	dir = normalize(dir);'
+'	if (clipPlaneDepth > -0.5) {'
+'		bool frontface = (dot(dir , clipPlane) > 0.0);'
+'		float dis = dot(dir,clipPlane);'
+'		if (dis != 0.0  )  dis = (-clipPlaneDepth - dot(clipPlane, start.xyz-0.5)) / dis;'
+'		if ((frontface) && (dis >= len)) len = 0.0;'
+'		if ((!frontface) && (dis <= 0.0)) len = 0.0;'
+'		if ((dis > 0.0) && (dis < len)) {'
+'			if (frontface) {'
+'				start = start + dir * dis;'
+'			} else {'
+'				backPosition =  start + dir * (dis); '
+'			}'
+'			dir = backPosition - start;'
+'			len = length(dir);'
+'			dir = normalize(dir);		'
+'		}'
+'	}'
+'	vec3 deltaDir = dir * stepSize;'
+'	vec4 colorSample,colAcc = vec4(0.0,0.0,0.0,0.0);'
+'	float lengthAcc = 0.0;'
+'	float opacityCorrection = stepSize/sliceSize;'
+'	vec3 samplePos = start.xyz;'
+'	for(int i = 0; i < loops; i++) {'
+'		colorSample = texture3D(intensityVol,samplePos);'
+'		colorSample.a = 1.0-pow((1.0 - colorSample.a), opacityCorrection);		'
+'		colorSample.rgb *= colorSample.a; '
+'		colAcc= (1.0 - colAcc.a) * colorSample + colAcc;'
+'		samplePos += deltaDir;'
+'		lengthAcc += stepSize;'
+'		if ( lengthAcc >= len || colAcc.a > 0.95 )'
+'			break;'
+'	}'
+'	colAcc.rgb = mix(clearColor,colAcc.rgb,colAcc.a);'
+'	gl_FragColor = colAcc;'
+'}';

function DefaultShader: TShader;
begin
  result.Note := 'Please reinstall this software: Unable to find the shader folder';
  result.VertexProgram := kDefaultVertex;
  result.nUniform := 0;
  result.OverlayVolume := 0;//false;
  result.FragmentProgram :=  kDefaultFragment;

  //

end;

function LoadShader(lFilename: string): TShader;
//modes
const
  //kCR = chr (13)+chr(10); //UNIX end of line
  //kCR = chr(10); //UNIX end of line
  knone=0;
  kpref=1;
  kvert = 2;
  kfrag = 3;
var
  mode: integer;
  F : TextFile;
  S: string;
  U: TUniform;
begin
  result.Note := '';
  result.VertexProgram := '';
  result.nUniform := 0;
  result.OverlayVolume := 0;//false;
  result.FragmentProgram := '';
  if not fileexists(lFilename) then  lFilename := lFilename +'.txt';
  if not fileexists(lFilename) then begin
  //if true  then begin
       result := DefaultShader;
      //showmessage('Can not find '+lFilename);
    exit;
  end;
  mode := knone;
  AssignFile(F,lFilename);
  Reset(F);
  while not Eof(F) do begin
    ReadLn(F, S);
    if S = '//pref' then
      mode := kpref
    else if S = '//frag' then
      mode := kfrag
    else if S = '//vert' then
      mode := kvert
    else if mode = kpref then begin
      U := StrToUniform(S);
      if U.Widget = kSet then begin
        if U.Name = 'overlayVolume' then
          result.OverlayVolume:= round(U.min) ; //U.Bool;
      end else if U.Widget = kNote then
        result.Note := U.Name
      else if U.Widget <> kError then begin
        if (result.nUniform < kMaxUniform) then begin
          inc(result.nUniform);
          result.Uniform[result.nUniform] := U;
        end else
          showmessage('Too many preferences');
      end ;
      //mode := kpref
    end else if mode = kfrag then
      result.FragmentProgram := result.FragmentProgram + S+#13#10 //kCR
    else if mode = kvert then
      result.VertexProgram := result.VertexProgram + S+#13#10;
  end;//EOF
  CloseFile(F);
  if result.VertexProgram = '' then
    result.VertexProgram := kDefaultVertex;
  if result.FragmentProgram = '' then begin
    result.nUniform := 0;
    result.OverlayVolume := 0;//false;
    result.FragmentProgram :=  kDefaultFragment;
  end;
end;



end.


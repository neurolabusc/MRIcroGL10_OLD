unit shaderu;
{$IFDEF FPC}{$mode objfpc}{$H+}{$ENDIF}
{$D-,L-,O+,Q-,R-,Y-,S-}
{$include opts.inc}
interface
uses
{$IFDEF DGL} dglOpenGL, {$ELSE DGL} {$IFDEF COREGL} glcorearb, {$ELSE} gl, glext, {$ENDIF}  {$ENDIF DGL}
sysutils,dialogs;
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
    id: GLint;
    Min,DefaultV,Max: single;
    Bool: boolean;
  end;
  TShader = record
         FragmentProgram,VertexProgram,Note, Vendor: String;
         OverlayVolume, SinglePass: integer;
         nUniform: integer;
         Uniform: array [1..kMaxUniform] of
         TUniform;
         {$IFDEF COREGL}
         nface, vao_point2d, vbo_face2d, program2d: GLuint;

         {$ENDIF}
  end;
var
  gShader: TShader;
  function LoadShader(lFilename: string; var lShader: TShader): boolean;
procedure AdjustShaders (lShader: TShader);

implementation
uses raycast_common, {$IFDEF COREGL} raycast_core, {$ENDIF} mainunit;


procedure AdjustShaders (lShader: TShader);
//sends the uniform values to the GPU
var
  i: integer;
begin
  if (lShader.nUniform < 1) or (lShader.nUniform > kMaxUniform) then
    exit;
{$IFDEF SLOWSHADER} //always request ShaderID from name = slow
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
{$ELSE} //store ShaderID from name = fase
for i := 1 to lShader.nUniform do begin
  if lShader.Uniform[i].id = 0 then
    lShader.Uniform[i].id := glGetUniformLocation(gRayCast.GLSLprogram, pAnsiChar(lShader.Uniform[i].name));
  case lShader.Uniform[i].Widget of
    kFloat: glUniform1f(lShader.Uniform[i].id,lShader.Uniform[i].defaultV);
    kInt: glUniform1i(lShader.Uniform[i].id,round(lShader.Uniform[i].defaultV));
    kBool: begin
        if lShader.Uniform[i].bool then
          glUniform1i(lShader.Uniform[i].id,1)
        else
          glUniform1i(lShader.Uniform[i].id,0);
      end;
  end;//case
end; //for each uniform
{$ENDIF}
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
  result.id:= 0;
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

{$IFDEF COREGL}
const  kDefaultVertex = '#version 330 core'
+#10'layout(location = 0) in vec3 vPos;'
+#10'out vec3 TexCoord1;'
+#10'uniform int zoom = 1;'
+#10'uniform mat4 modelViewProjectionMatrix;'
+#10'void main() {'
+#10'    TexCoord1 = vPos;'
+#10'    gl_Position = modelViewProjectionMatrix * vec4(vPos, 1.0);'
+#10'    gl_Position.xy *= zoom;'
+#10'}';

const  kDefaultFragment = '#version 330 core'
+#10'in vec3 TexCoord1;'
+#10'out vec4 FragColor;'
+#10'uniform mat4 modelViewMatrixInverse;'
+#10'uniform int loops;'
+#10'uniform float stepSize, sliceSize, viewWidth, viewHeight;'
+#10'uniform sampler3D intensityVol;'
+#10'uniform sampler3D gradientVol;'
+#10'uniform sampler2D backFace;'
+#10'uniform vec3 clearColor,lightPosition, clipPlane;'
+#10'uniform float clipPlaneDepth;'
+#10'uniform float ambient = 1.0;'
+#10'uniform float diffuse = 0.3;'
+#10'uniform float specular = 0.25;'
+#10'uniform float shininess = 10.0;'
+#10'uniform float edgeThresh = 0.01;'
+#10'uniform float edgeExp = 0.15;'
+#10'uniform float boundExp = 0.0;'
+#10'void main() {'
+#10'	vec3 backPosition = texture(backFace,vec2(gl_FragCoord.x/viewWidth,gl_FragCoord.y/viewHeight)).xyz;'
+#10'	vec3 start = TexCoord1.xyz;'
+#10'	if (backPosition == clearColor) discard;'
+#10'	vec3 dir = backPosition - start;'
+#10'	float len = length(dir);'
+#10'	dir = normalize(dir);'
+#10'	if (clipPlaneDepth > -0.5) {'
+#10'		FragColor.rgb = vec3(1.0,0.0,0.0);'
+#10'		bool frontface = (dot(dir , clipPlane) > 0.0);'
+#10'		float dis = dot(dir,clipPlane);'
+#10'		if (dis != 0.0  )  dis = (-clipPlaneDepth - dot(clipPlane, start.xyz-0.5)) / dis;'
+#10'		if ((frontface) && (dis >= len)) len = 0.0;'
+#10'		if ((!frontface) && (dis <= 0.0)) len = 0.0;'
+#10'		if ((dis > 0.0) && (dis < len)) {'
+#10'			if (frontface) {'
+#10'				start = start + dir * dis;'
+#10'			} else {'
+#10'				backPosition =  start + dir * (dis);'
+#10'			}'
+#10'			dir = backPosition - start;'
+#10'			len = length(dir);'
+#10'			dir = normalize(dir);'
+#10'		}'
+#10'	}'
+#10'	vec3 deltaDir = dir * stepSize;'
+#10'	vec4 colorSample,gradientSample,colAcc = vec4(0.0,0.0,0.0,0.0);'
+#10'	float lengthAcc = 0.0;'
+#10'	vec3 samplePos = start.xyz + deltaDir* (fract(sin(gl_FragCoord.x * 12.9898 + gl_FragCoord.y * 78.233) * 43758.5453));'
+#10'	vec4 prevNorm = vec4(0.0,0.0,0.0,0.0);'
+#10'	vec3 lightDirHeadOn =  normalize(modelViewMatrixInverse * vec4(0.0,0.0,1.0,0.0)).xyz ;'
+#10'	float stepSizex2 = sliceSize * 2.0;'
+#10'	for(int i = 0; i < loops; i++) {'
+#10'		//colorSample = texture(gradientVol, samplePos);'
+#10'		colorSample = texture(intensityVol,samplePos);'
+#10'		if ((lengthAcc <= stepSizex2) && (colorSample.a > 0.01) )  colorSample.a = sqrt(colorSample.a);'
+#10'		colorSample.a = 1.0-pow((1.0 - colorSample.a), stepSize/sliceSize);'
+#10'		if ((colorSample.a > 0.01) && (lengthAcc > stepSizex2)  ) {'
+#10'			gradientSample= texture(gradientVol,samplePos);'
+#10'			gradientSample.rgb = normalize(gradientSample.rgb*2.0 - 1.0);'
+#10'			if (gradientSample.a < prevNorm.a)'
+#10'				gradientSample.rgb = prevNorm.rgb;'
+#10'			prevNorm = gradientSample;'
+#10'			float lightNormDot = dot(gradientSample.rgb, lightDirHeadOn);'
+#10'			float edgeVal = pow(1.0-abs(lightNormDot),edgeExp);'
+#10'			edgeVal = edgeVal * pow(gradientSample.a,0.3);'
+#10'	    	if (edgeVal >= edgeThresh)'
+#10'				colorSample.rgb = mix(colorSample.rgb, vec3(0.0,0.0,0.0), pow((edgeVal-edgeThresh)/(1.0-edgeThresh),4.0));'
+#10'			if (boundExp > 0.0)'
+#10'				colorSample.a = colorSample.a * pow(gradientSample.a,boundExp)*pow(1.0-abs(lightNormDot),6.0);'
+#10'			lightNormDot = dot(gradientSample.rgb, lightPosition);'
+#10'			vec3 a = colorSample.rgb * ambient;'
+#10'			vec3 d = max(lightNormDot, 0.0) * colorSample.rgb * diffuse;'
+#10'			float s =   specular * pow(max(dot(reflect(lightPosition, gradientSample.rgb), dir), 0.0), shininess);'
+#10'			colorSample.rgb = a + d + s;'
+#10'		}'
+#10'		colorSample.rgb *= colorSample.a;'
+#10'		colAcc= (1.0 - colAcc.a) * colorSample + colAcc;'
+#10'		samplePos += deltaDir;'
+#10'		lengthAcc += stepSize;'
+#10'		if ( lengthAcc >= len || colAcc.a > 0.95 )'
+#10'			break;'
+#10'	}'
+#10'	colAcc.a = colAcc.a/0.95;'
+#10'	if ( colAcc.a < 1.0 )'
+#10'		colAcc.rgb = mix(clearColor,colAcc.rgb,colAcc.a);'
+#10'	if (len == 0.0) colAcc.rgb = clearColor;'
+#10'	FragColor = colAcc;'
+#10'}';
{$ELSE}
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
{$ENDIF}

function DefaultShader: TShader;
begin
  result.Note := 'Please reinstall this software: Unable to find the shader folder';
  result.VertexProgram := kDefaultVertex;
  result.nUniform := 0;
  result.OverlayVolume := 0;//false;
  result.SinglePass := 0;
  result.FragmentProgram :=  kDefaultFragment;
end;

function LoadShader(lFilename: string; var lShader: TShader): boolean;
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
  Result := false;
  lShader.Note := '';
  lShader.VertexProgram := '';
  lShader.nUniform := 0;
  lShader.OverlayVolume := 0;//false;
  lShader.SinglePass := 0;
  lShader.FragmentProgram := '';
  if not fileexists(lFilename) then  lFilename := lFilename +'.txt';
  if not fileexists(lFilename) then begin
      lShader := DefaultShader;
    exit;
  end;
  mode := knone;
  FileMode := fmOpenRead;
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
        if U.Name = 'singlePass' then
          lShader.SinglePass:= round(U.min) ;
        if U.Name = 'overlayVolume' then
          lShader.OverlayVolume:= round(U.min) ; //U.Bool;
      end else if U.Widget = kNote then
        lShader.Note := U.Name
      else if U.Widget <> kError then begin
        if (lShader.nUniform < kMaxUniform) then begin
          inc(lShader.nUniform);
          lShader.Uniform[lShader.nUniform] := U;
        end else
          showmessage('Too many preferences');
      end ;
      //mode := kpref
    end else if mode = kfrag then
      lShader.FragmentProgram := lShader.FragmentProgram + S+#13#10 //kCR
    else if mode = kvert then
      lShader.VertexProgram := lShader.VertexProgram + S+#13#10;
  end;//EOF
  CloseFile(F);
  if lShader.VertexProgram = '' then
    lShader.VertexProgram := kDefaultVertex;
  if lShader.FragmentProgram = '' then begin
    lShader.nUniform := 0;
    lShader.OverlayVolume := 0;//false;
    lShader.FragmentProgram :=  kDefaultFragment;
  end;
  result := true;
end;
end.


#version 120

/*
Modified Chocapic13 Shader Lite By AirLoocke42
*/

#define BLOOM
	const float b_intensity = 16.0;

#define WATER_REFLECTIONS

#define VIGNETTE
	#define VIGNETTE_STRENGTH 8.25
	#define VIGNETTE_START 0.25
	#define VIGNETTE_EXP 1.5   

#define GODRAYS
	const float exposure = 5.0;		
	const float density = 0.25;			
	const int NUM_SAMPLES = 8;	
	const float grnoise = 0.0;	

const int maxf = 5;				//number of refinements
const float stp = 1.0;			//size of one step for raytracing algorithm
const float ref = 0.12;			//refinement multiplier
const float inc = 1.6;			//increasement factor at each step

varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 ambient_color;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D gcolor;

uniform sampler2D composite;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform ivec2 eyeBrightness;

uniform int isEyeInWater;
uniform int worldTime;

uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;

vec3 sunPos = sunPosition;

uniform int fogMode;

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;
float wetx  = clamp(wetness, 0.0f, 1.0f);

float sky_lightmap = texture2D(gaux1,texcoord.xy).r;

vec3 fogclr = pow(mix(vec3(0.5,0.5,1.0),vec3(0.3,0.3,0.3),rainStrength)*ambient_color,vec3(2.2));

vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;

float iswet = wetness*pow(sky_lightmap,5.0)*sqrt(0.5+max(dot(normal,normalize(upPosition)),0.0));

float matflag = texture2D(gaux1,texcoord.xy).g;

float ld(float depth) { return (2.0 * near) / (far + near - depth * (far - near)); }

float A = 0.15, B = 0.25, C = 0.10, D = 0.20, E = 0.02, F = 0.30, W = 16.0;

vec3 Uncharted2Tonemap(vec3 x) { return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F; }

vec3 nvec3(vec4 pos) { return pos.xyz/pos.w; }

vec4 nvec4(vec3 pos) { return vec4(pos.xyz, 1.0); }

vec4 sunre = texture2D(composite,texcoord.xy)*16.0;

float getnoise(vec2 pos) { return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f)); }

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5), abs(coord.t-0.5))*2.0;
}

vec4 raytrace(vec3 fragpos, vec3 normal) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i = 0; i < 30 ; i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = distance(fragpos.xyz,spos.xyz);
       if(err < pow(length(vector)*1.1,1.1)*1.1){

                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 1.75), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=ref;
				
        
}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}

float pixeldepth = texture2D(depthtex0,texcoord.xy).x;

void main() {

	int iswater = int(matflag > 0.04 && matflag < 0.07);
	int land = int(matflag > 0.04);

	vec2 fake_refract = vec2(sin(worldTime/15.0 + texcoord.x*100.0 + texcoord.y*50.0),cos(worldTime/15.0 + texcoord.y*100.0 + texcoord.x*50.0)) * isEyeInWater;

	vec3 color = texture2D(composite, texcoord.st + fake_refract * 0.005).rgb*16.0;

	fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));

	float normalDotEye = dot(normal, normalize(fragpos));
	float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
	vec4 reflection = vec4(0.0), fpos = vec4(fragpos, 1.0);

	if (iswater > 0.9 && isEyeInWater == 0) {
	#ifdef WATER_REFLECTIONS
	reflection = raytrace(fragpos, normal)*16.0;
	#endif

	reflection.rgb = mix(gl_Fog.color.rgb, reflection.rgb, reflection.a/16.0);
	reflection.a = min(reflection.a/16.0 + sky_lightmap,1.0);

	color.rgb += reflection.rgb*fresnel*1.75*reflection.a;
	color.rgb += -log(1.0-sunre.a/16.0)*sunlight*(1.0-rainStrength)*16.0;
   	}

	if (land > 0.9 && iswater < 0.9) {
	reflection = raytrace(fragpos, normal)*16.0;
	color.rgb += ((reflection.rgb/16)*fresnel*0.5*reflection.a)*iswet;
   	}

	float fog = 0.0; 
	fog = 1.0-clamp(exp(-pow(ld(texture2D(depthtex0, texcoord.st).r),3.0)),0.0,1.0);
	
	#ifdef BLOOM
	color *= 0.8;

	float rad = 0.001, sc = 20.0, blm_amount = 0.02*b_intensity;
	int i = 0, samples = 1; vec4 clr = vec4(0.0);
	
	for (i = -8; i < 8; i++) {
	vec2 d = vec2(-i, i), e = vec2(0, i), f = texcoord.st;
	clr += texture2D(composite, f+(d.yy)*rad)*sc;
	clr += texture2D(composite, f+(d.yx)*rad)*sc;
	clr += texture2D(composite, f+(d.xy)*rad)*sc;
	clr += texture2D(composite, f+(d.xx)*rad)*sc;
	++samples;
	sc = sc - 1.0;
	}
	clr = (clr/8.0)/samples; color += clr.rgb*blm_amount;
	#endif

	float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));
	float night = clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-22800.0)/200.0,0.0,1.0);

	color.rgb += texture2D(gaux4,texcoord.xy).rgb*sqrt(texture2D(gaux4,texcoord.xy).a);

	float fogl = exp(-pow(length(fragpos)/160.0,4.0-(3.0*rainStrength))*8.0);
	float fogfactor =  clamp(fogl,0.0,1.0);
	float rain = rainStrength;

	fogclr = mix(color.rgb, ambient_color*0.5+(0.5*rain), 0.2+(0.3*rain));

	color.rgb = mix(fogclr, color.rgb, fogfactor);	

	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z, lightPos = pos1*0.5+0.5;
		
	vec3 lightVector;
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	} else {
		lightVector = normalize(moonPosition);
	}

	#ifdef VIGNETTE

	float dv = pow(clamp(distance(texcoord.st, vec2(0.5, 0.5))/sqrt(2.0)-VIGNETTE_START,0.0,1.0),VIGNETTE_EXP);

	dv *= VIGNETTE_STRENGTH;
	dv = clamp(1.0 - dv,0.0,1.0);

	color *= dv;
	#endif

	float truepos = pow(clamp(dot(-lightVector,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.25);

	#ifdef GODRAYS
	if (truepos > 0.05) {
    	vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
   	vec2 textCoord = texcoord.st;

    	deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
    	float illuminationDecay = 1.0;

	vec2 noise = vec2(getnoise(textCoord),getnoise(-textCoord.yx+0.05));
	float gr = 0.0, avgdecay = 0.0;
	float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
	float disty = abs(texcoord.y-lightPos.y);

        illuminationDecay = pow(max(1.0-sqrt(distx*distx+disty*disty),0.0),5.0);

    	for(int i=0; i < NUM_SAMPLES ; i++) {	
        	textCoord -= deltaTextCoord;
	float sample = texture2D(gdepth, textCoord + noise*grnoise).r;
		gr += sample;
    	}
	color.rgb += mix(sunlight,fogclr,rainStrength*0.6)*exposure*(gr/NUM_SAMPLES)*(1.0 - rainStrength*0.9)*illuminationDecay*truepos*transition_fading;
	}
	#endif

	float avglight = texture2D(gaux2,vec2(1.0)).a;
	float exposure = -log(clamp(avglight*48.0,0.01,0.5));
	exposure = 1.0;

	vec3 curr = Uncharted2Tonemap(color);

	vec3 whiteScale = 1.0f/Uncharted2Tonemap(vec3(W));
	color = curr*whiteScale;

	float saturation = 1.05, avg = (color.r + color.g + color.b);

        color = (((color - avg )*saturation)+avg) ;
	color /= saturation;	
	color = clamp(pow(color,vec3(1.1/2.2)),0.0,1.0);

	gl_FragColor = vec4(color,1.0);
	
}
#version 120
#define MAX_COLOR_RANGE 48.0
#extension GL_ARB_shader_texture_lod : enable
const bool compositeMipmapEnabled = true;

/*
                            _____ _____ ___________
                           /  ___|_   _|  _  | ___ \
                           \ `--.  | | | | | | |_/ /
                            `--. \ | | | | | |  __/
                           /\__/ / | | \ \_/ / |
                           \____/  \_/  \___/\_|

						Before editing anything here make sure you've
						read The agreement, which you accepted by downloading
						my shaderpack. The agreement can be found here:
			http://www.minecraftforum.net/topic/1953873-164-172-sildurs-shaders-pcmacintel/

				This code is from Chocapic13' shaders adapted, modified and tweaked by Sildur
		http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/1293898-chocapic13s-shaders
*/

/*--------------------
//ADJUSTABLE VARIABLES//
---------------------*/

#define Sun_Effects						//Has to be enabled in order to make use of Godrays, Lens flares and Raindrops.
	#define Rain_Drops					//Enables rain drops on screen during raining. Requires sun effects to be enabled. Low performance impact.
	#define Lens_Flares					//Emulates camera lens effects. Requires sun effects to be enabled. Low performance impact.
	#define Godrays						//Sun casts rays. Requires sun effects to be enabled. Low performance impact.

//#define Bloom							//Makes lightsources more glowy. Medium performance impact.

//#define Depth_of_Field				//Simulates eye focusing on objects. Low performance impact
	//#define Distance_Blur				//Requires Depth of Field to be enabled, replaces eye focusing effect with distance being blurred instead.

//#define Motionblur					//Blurres your view/camera during movemenent, low performance impact. Doesn't work well with Depth of Field.

/*---------------------------
//END OF ADJUSTABLE VARIABLES//
----------------------------*/

//Defined values for Optifine
#define DoF_Strength 90					//[60 70 80 90 100 110 120 130 140 150]
#define Lens_Flares_Strength 1.2		//[0.6 1.2 2.4 3.6 4.8]
#define Godrays_Density 5				//[2.5 5 7.5 10 12.5]
#define Godrays_Quality 4				//[2 4 6 8 10 12 14]


/*--------------------------------*/
varying vec4 texcoord;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;

varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D depthtex0;
uniform sampler2D gdepthtex;
uniform sampler2D gdepth;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform sampler2D composite;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float frameTimeCounter;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
uniform int worldTime;
float time = float(worldTime);
float night = clamp((time-13000.0)/300.0,0.0,1.0)-clamp((time-22800.0)/200.0,0.0,1.0);

uniform ivec2 eyeBrightness;

vec3 aux = texture2D(gaux1, texcoord.st).rgb;
vec3 color = vec3(0.0);
/*--------------------------------*/

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

float MotionDepth(in vec2 coord) {
	return texture2D(gdepthtex, coord).x;
}

#ifdef Depth_of_Field
	//Dof constant values
	const float focal = 0.024;
	float aperture = 0.008;
	const float sizemult = DoF_Strength;

	//hexagon pattern
	const vec2 hex_offsets[60] = vec2[60] (	vec2(  0.2165,  0.1250 ),
											vec2(  0.0000,  0.2500 ),
											vec2( -0.2165,  0.1250 ),
											vec2( -0.2165, -0.1250 ),
											vec2( -0.0000, -0.2500 ),
											vec2(  0.2165, -0.1250 ),
											vec2(  0.4330,  0.2500 ),
											vec2(  0.0000,  0.5000 ),
											vec2( -0.4330,  0.2500 ),
											vec2( -0.4330, -0.2500 ),
											vec2( -0.0000, -0.5000 ),
											vec2(  0.4330, -0.2500 ),
											vec2(  0.6495,  0.3750 ),
											vec2(  0.0000,  0.7500 ),
											vec2( -0.6495,  0.3750 ),
											vec2( -0.6495, -0.3750 ),
											vec2( -0.0000, -0.7500 ),
											vec2(  0.6495, -0.3750 ),
											vec2(  0.8660,  0.5000 ),
											vec2(  0.0000,  1.0000 ),
											vec2( -0.8660,  0.5000 ),
											vec2( -0.8660, -0.5000 ),
											vec2( -0.0000, -1.0000 ),
											vec2(  0.8660, -0.5000 ),
											vec2(  0.2163,  0.3754 ),
											vec2( -0.2170,  0.3750 ),
											vec2( -0.4333, -0.0004 ),
											vec2( -0.2163, -0.3754 ),
											vec2(  0.2170, -0.3750 ),
											vec2(  0.4333,  0.0004 ),
											vec2(  0.4328,  0.5004 ),
											vec2( -0.2170,  0.6250 ),
											vec2( -0.6498,  0.1246 ),
											vec2( -0.4328, -0.5004 ),
											vec2(  0.2170, -0.6250 ),
											vec2(  0.6498, -0.1246 ),
											vec2(  0.6493,  0.6254 ),
											vec2( -0.2170,  0.8750 ),
											vec2( -0.8663,  0.2496 ),
											vec2( -0.6493, -0.6254 ),
											vec2(  0.2170, -0.8750 ),
											vec2(  0.8663, -0.2496 ),
											vec2(  0.2160,  0.6259 ),
											vec2( -0.4340,  0.5000 ),
											vec2( -0.6500, -0.1259 ),
											vec2( -0.2160, -0.6259 ),
											vec2(  0.4340, -0.5000 ),
											vec2(  0.6500,  0.1259 ),
											vec2(  0.4325,  0.7509 ),
											vec2( -0.4340,  0.7500 ),
											vec2( -0.8665, -0.0009 ),
											vec2( -0.4325, -0.7509 ),
											vec2(  0.4340, -0.7500 ),
											vec2(  0.8665,  0.0009 ),
											vec2(  0.2158,  0.8763 ),
											vec2( -0.6510,  0.6250 ),
											vec2( -0.8668, -0.2513 ),
											vec2( -0.2158, -0.8763 ),
											vec2(  0.6510, -0.6250 ),
											vec2(  0.8668,  0.2513 ));
#endif

float distratio(vec2 pos, vec2 pos2, float ratio) {
	float xvect = pos.x*ratio-pos2.x*ratio;
	float yvect = pos.y-pos2.y;
	return sqrt(xvect*xvect + yvect*yvect);
}

#ifdef Sun_Effects
	float yDistAxis (in float degrees) {
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
			 tpos = vec4(tpos.xyz/tpos.w,1.0);
		vec2 lightPos = tpos.xy/tpos.z;
			 lightPos = (lightPos + 1.0f)/2.0f;

		return abs((lightPos.y-lightPos.x*(degrees))-(texcoord.y-texcoord.x*(degrees)));
	}

	float smoothCircleDist (in float lensDist) {
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
			 tpos = vec4(tpos.xyz/tpos.w,1.0);
		vec2 lightPos = tpos.xy/tpos.z*lensDist;
			 lightPos = (lightPos + 1.0f)/2.0f;
		return distratio(lightPos.xy, texcoord.xy, aspectRatio);
	}

	float cirlceDist (float lensDist, float size) {
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
			 tpos = vec4(tpos.xyz/tpos.w,1.0);
		vec2 lightPos = tpos.xy/tpos.z*lensDist;
			 lightPos = (lightPos + 1.0f)/2.0f;
		return pow(min(distratio(lightPos.xy, texcoord.xy, aspectRatio),size)/size,10.);
	}
#endif

//tonemapping constants
float A = 1.25;
float B = 0.4;
float C = 0.09;

vec3 Uncharted2Tonemap(vec3 x) {
	float D = 0.2;
	float E = 0.02;
	float F = 0.3;
	float W = MAX_COLOR_RANGE;
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float gen_circular_lens(vec2 center, float size) {
	float dist=distratio(center,texcoord.xy, aspectRatio)/size;
	return exp(-dist*dist);
}

vec2 noisepattern(vec2 pos) {
	vec2 all_values = vec2(18.9898f,28.633f) * 4378.5453f; //performs the computation all at once.
	return vec2(abs(fract(sin(dot(pos ,all_values)))),abs(fract(sin(dot(pos.yx ,all_values)))));
}

#ifdef Motionblur
float adjustBstrength = 0.0035;
#else
float adjustBstrength = 0.0;
#endif

#ifdef Bloom
vec3 Glow(float pos, float pos2, vec2 offpos){
	vec3 blur = pow(texture2D(composite,texcoord.xy/pos + offpos).rgb,vec3(2.2))*pos2;
	color += mix(color/10,(blur)*MAX_COLOR_RANGE,0.0025+adjustBstrength);
	return blur;
}
#endif

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/

void main() {

	//Unpack Materials
	float land = float(aux.g > 0.04);
	float hand = float(aux.g > 0.75 && aux.g < 0.85);
	/*--------------------------------*/
	//Texcoord, color, fog and more
	float rainlens = 0.0;
	vec2 fake_refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0)) ;
	vec2 newTC = texcoord.st + fake_refract * 0.01 * (rainlens+isEyeInWater*0.25);

	color = pow(texture2D(gaux2, newTC).rgb,vec3(2.2))*MAX_COLOR_RANGE;


	float fog = 1-(exp(-pow(ld(texture2D(depthtex0, newTC.st).r)/256.0*far,4.0-(2.7*rainStrength))*4.0));
	fog = mix(fog,1-exp(-ld(texture2D(depthtex0, newTC.st).r)*far/256.),isEyeInWater);
	/*--------------------------------*/

#ifdef Rain_Drops
float ftime = frameTimeCounter*2.0/4.0;
vec2 drop = vec2(0.0,fract(frameTimeCounter/20.0));
		if (rainStrength > 0.02) {
		/*--------------------------------*/
		float gen = 1.0-fract((ftime+0.5)*0.5);
		vec2 pos = (noisepattern(vec2(-0.94386347*floor(ftime*0.5+0.25),floor(ftime*0.5+0.25))))*0.8+0.1 - drop;
		rainlens += gen_circular_lens(fract(pos),0.04)*gen*rainStrength;
		/*--------------------------------*/
		gen = 1.0-fract((ftime+1.0)*0.5);
		pos = (noisepattern(vec2(0.9347*floor(ftime*0.5+0.5),-0.2533282*floor(ftime*0.5+0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.023)*gen*rainStrength;
		/*--------------------------------*/
		gen = 1.0-fract((ftime+1.5)*0.5);
		pos = (noisepattern(vec2(0.785282*floor(ftime*0.5+0.75),-0.285282*floor(ftime*0.5+0.75))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.03)*gen*rainStrength;
		/*--------------------------------*/
		gen =  1.0-fract(ftime*0.5);
		pos = (noisepattern(vec2(-0.347*floor(ftime*0.5),0.6847*floor(ftime*0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.05)*gen*rainStrength;
		/*--------------------------------*/
		rainlens *= clamp((eyeBrightnessSmooth.y-220)/15.0,0.0,1.0);
	}
#endif

#ifdef Depth_of_Field
if (hand < 0.9){
	float z = ld(texture2D(depthtex0, newTC.st).r)*far;
	float focus = ld(texture2D(depthtex0, vec2(0.5)).r)*far;
	float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*15.0);
	#ifdef Distance_Blur
	if(land > 0.1)pcoc = min(fog*pw*20.0,pw*20.0);
	#endif
	vec3 bcolor = color/MAX_COLOR_RANGE;
	vec2 bcoord = vec2(0.0);
		for ( int i = 0; i < 60; i++) {
			bcolor += pow(texture2D(gaux2, newTC.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio)).rgb,vec3(2.2));
		}
		color.rgb = bcolor/61.0*MAX_COLOR_RANGE;
}
#endif

#ifdef Bloom
	vec3 bloom = Glow(4, 10, vec2(0.0,0.0));
			bloom += Glow(8, 8, vec2(0.4,0.0));
			bloom += Glow(16, 6, vec2(0.0,0.4));
			bloom += Glow(32, 4, vec2(0.6,0.6));
			bloom += Glow(64, 2, vec2(0.8,0.8));
#endif

//draw rain
if(hand < 0.1){
vec4 rain = pow(texture2D(gaux4,texcoord.xy),vec4(vec3(2.2),1.));
if (length(rain) > 0.0001) {
rain.rgb = normalize(rain.rgb)*0.001*(0.5+length(rain.rgb)*0.25)*length(ambient_color);
color.rgb = ((1-(1-color.xyz/48.0)*(1-rain.xyz*rain.a))*48.0);
}
}
/*--------------------------------*/

#ifdef Rain_Drops
vec3 c_rain = rainlens*ambient_color*0.0008;
color = (((1-(1-color.xyz/48.0)*(1-c_rain.xyz))*48.0));
#endif

#ifdef Sun_Effects

	//Positioning
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		lightPos = (lightPos + 1.0f)/2.0f;

    float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
	float fading = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);

	//Sun visibility
    float sunvisibility = min(texture2D(gaux2,vec2(0.0)).a,1.0) * fading;

	//Fix, that the particles are visible on the moon position at daytime
	float truepos = sunPosition.z/abs(sunPosition.z);		//1 -> sun / -1 -> moon
	vec3 rainc = mix(vec3(1.),vec3(0.2,0.25,0.3),rainStrength);
	vec3 lightColor = mix(sunlight*sunVisibility*rainc,6*moonlight*moonVisibility*rainc,(truepos+1.0)/2.);

	#ifdef Godrays
	if(rainStrength < 0.1){
	float gr = 0.0;
	float tw = 0.0;
	const float density = Godrays_Density;
	const int nSteps = Godrays_Quality;	//increase this for better quality at the cost of performance
	const float blurScale = 0.002/nSteps*9.0;
	const int center = (nSteps-1)/2;
	vec2 deltaTextCoord = normalize(texcoord.st - lightPos.xy)*blurScale;
	vec2 textCoord = texcoord.st - deltaTextCoord*center;
	float distx = texcoord.x*aspectRatio-lightPos.x*aspectRatio;
	float disty = texcoord.y-lightPos.y;
	float illuminationDecay = pow(max(1.0-sqrt(distx*distx+disty*disty),0.0),4.0);
		for(int i=0; i < nSteps ; i++) {
			textCoord += deltaTextCoord;

			float dist = (i-float(center))/center;
			float weight = exp(-(dist*dist)/(2.0*0.5));

			float sample = texture2D(gdepth, textCoord).r*weight;
			tw += weight;
			gr += sample;
	}
	vec3 grC = mix(lightColor,vec3(0.2,0.25,0.3),rainStrength)*density*(gr/tw)*illuminationDecay * (1-isEyeInWater);
	color.xyz = (1-(1-color.xyz/48.0)*(1-grC.xyz/48.0))*48.0;
	}
	/*------------------------------------------------------*/
	#endif

	#ifdef Lens_Flares
	//Colors
	float lensBrightness = Lens_Flares_Strength;
	vec3 lenscolor = pow(normalize(lightColor),vec3(2.2))*length(lightColor);
	float lens_strength;

	//Anamorphic Lens
	if (sunvisibility > 0.01) {
		float visibility = max(pow(max(1.0 - smoothCircleDist(1.0)/1.5,0.1),1.0)-0.1,0.0);

		lenscolor = length(lightColor)*vec3(0.2, 0.8, 2.55);

		lens_strength = 0.8 * lensBrightness;
		lenscolor *= lens_strength;

		float anamorphic_lens = max(pow(max(1.0 - yDistAxis(0.0)/1.4,0.1),10.0)-0.5,0.0);
		color += anamorphic_lens * lenscolor * visibility  * sunvisibility * (1.0-rainStrength*1.0);
	}


	//Sunrays
	if (sunvisibility > 0.01) {
		float visibility = max(pow(max(1.0 - smoothCircleDist(1.0)/1.0,0.1),5.0)-0.1,0.0);

		lens_strength = 0.2 * lensBrightness;
		lenscolor *= lens_strength;

		float sunrays = max(pow(max(1.0 - yDistAxis(1.5)/0.7,0.1),10.0)-0.6,0.0)
		+ max(pow(max(1.0 - yDistAxis(-1.3)/0.7,0.1),10.0)-0.6,0.0)
		+ max(pow(max(1.0 - yDistAxis(5.0)/1.5,0.1),10.0)-0.6,0.0)
		+ max(pow(max(1.0 - yDistAxis(-4.8)/1.5,0.1),10.0)-0.6,0.0);

		color += lenscolor * sunrays * visibility * sunvisibility * (1.0-rainStrength*1.0)*2.0;
	}

	//Sun Glow
	if (sunvisibility > 0.01) {
	  if(night > 0.1)lenscolor = vec3(0.4, 1.2, 2.52) * length(lightColor);
	  else lenscolor = vec3(2.52, 1.2, 0.4) * length(lightColor);

		lens_strength = 0.28 * lensBrightness;
		lenscolor *= lens_strength;

		float lensFlare = max(pow(max(1.0 - smoothCircleDist(1.0)/2.4,0.1),5.0)-0.1,0.0);

		color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0);
	}

	//Circle Lens 1
	if (sunvisibility > 0.01) {
		lenscolor =  vec3(2.52, 1.2, 0.4) * lightColor;

		lens_strength = 0.2 * lensBrightness;
		lenscolor *= lens_strength;

		float lensFlare1 = max(pow(max(1.0 - cirlceDist(-0.15, 0.07)/1.0,0.1),5.0)-0.1,0.0);
		float lensFlare2 = max(pow(max(1.0 - cirlceDist(-0.2, 0.07)/1.0,0.1),5.0)-0.1,0.0);
		float lensFlare3 = max(pow(max(1.0 - cirlceDist(-0.25, 0.07)/1.0,0.1),5.0)-0.1,0.0);

		float lensFlare = clamp(lensFlare1 * lensFlare2 * lensFlare3, 0.0, 1.0);

		color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0)*0.7;
	}

	//Circle Lens 2
	if (sunvisibility > 0.01) {
		lenscolor =  vec3(1.6, 2.55, 0.4) * lightColor;

		lens_strength = 0.2 * lensBrightness;
		lenscolor *= lens_strength;

		float lensFlare1 = max(pow(max(1.0 - cirlceDist(-0.4, 0.13)/1.0,0.1),5.0)-0.1,0.0);
		float lensFlare2 = max(pow(max(1.0 - cirlceDist(-0.5, 0.13)/1.0,0.1),5.0)-0.1,0.0);
		float lensFlare3 = max(pow(max(1.0 - cirlceDist(-0.6, 0.13)/1.0,0.1),5.0)-0.1,0.0);

		float lensFlare = clamp(lensFlare1 * lensFlare2 * lensFlare3, 0.0, 1.0);

		color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0)*0.7;
	}

	//Circle Lens 3
	if (sunvisibility > 0.01) {
		lenscolor =  vec3(0.4, 2.55, 1.55) * lightColor;

		lens_strength = 0.1 * lensBrightness;
		lenscolor *= lens_strength;

		float lensFlare1 = max(pow(max(1.0 - cirlceDist(-0.75, 0.09)/1.0,0.1),5.0)-0.1,0.0);
		float lensFlare2 = max(pow(max(1.0 - cirlceDist(-0.8, 0.09)/1.0,0.1),5.0)-0.1,0.0);
		float lensFlare3 = max(pow(max(1.0 - cirlceDist(-0.85, 0.09)/1.0,0.1),5.0)-0.1,0.0);

		float lensFlare = clamp(lensFlare1 * lensFlare2 * lensFlare3, 0.0, 1.0);

		color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0)*0.7;
	}

	//Small point 1
	if (sunvisibility > 0.01) {
		lenscolor = vec3(2.55, 2.55, 0.0) * lightColor;

		lens_strength = 150.0 * lensBrightness;
		lenscolor *= lens_strength;

		float lensFlare1 = max(pow(max(1.0 - smoothCircleDist(-0.27)/1.0,0.1),5.0)-0.85,0.0);
		float lensFlare2 = max(pow(max(1.0 - smoothCircleDist(-0.3)/1.0,0.1),5.0)-0.85,0.0);
		float lensFlare3 = max(pow(max(1.0 - smoothCircleDist(-0.33)/1.0,0.1),5.0)-0.85,0.0);

		float lensFlare = clamp(lensFlare1 * lensFlare2 * lensFlare3, 0.0, 1.0);

		color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0);
	}

	//Small point 2
	if (sunvisibility > 0.01) {
		lenscolor = vec3(0.0, 1.55, 2.52) * lightColor;

		lens_strength = 150.0 * lensBrightness;
		lenscolor *= lens_strength;

		float lensFlare1 = max(pow(max(1.0 - smoothCircleDist(-0.82)/1.0,0.1),5.0)-0.85,0.0);
		float lensFlare2 = max(pow(max(1.0 - smoothCircleDist(-0.85)/1.0,0.1),5.0)-0.85,0.0);
		float lensFlare3 = max(pow(max(1.0 - smoothCircleDist(-0.88)/1.0,0.1),5.0)-0.85,0.0);

		float lensFlare = clamp(lensFlare1 * lensFlare2 * lensFlare3, 0.0, 1.0);

		color += lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0);
	}

	//Ring Lens
	if (sunvisibility > 0.01) {
		lenscolor = vec3(0.2, 0.8, 2.55) * length(lightColor);

		lens_strength = 0.3 * lensBrightness;
		lenscolor *= lens_strength;

		float lensFlare1 = max(pow(max(1.0 - cirlceDist(-0.7, 0.5)/1.0,0.1),5.0)-0.1,0.0);
		float lensFlare2 = max(pow(max(1.0 - cirlceDist(-0.9, 0.5)/1.0,0.1),5.0)-0.1,0.0);

		float lensFlare = clamp(lensFlare2 - lensFlare1, 0.0, 1.0);
		color += lensFlare*lensFlare * lenscolor * sunvisibility * (1.0-rainStrength*1.0)*1.3;
	}
	#endif
#endif

#ifdef Motionblur
if (hand < 0.1 && isEyeInWater < 0.1){
float depth = MotionDepth(texcoord.st);

vec4 currentPlayerPosition = vec4(texcoord.x * 2.0f - 1.0f, texcoord.y * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
vec4 fragposition = gbufferProjectionInverse * currentPlayerPosition;
	fragposition = gbufferModelViewInverse * fragposition;
	fragposition /= fragposition.w;
	fragposition.xyz += cameraPosition;

vec4 previousPlayerPosition = fragposition;
	previousPlayerPosition.xyz -= previousCameraPosition;
	previousPlayerPosition = gbufferPreviousModelView * previousPlayerPosition;
	previousPlayerPosition = gbufferPreviousProjection * previousPlayerPosition;
	previousPlayerPosition /= previousPlayerPosition.w;

vec2 Blurness = (currentPlayerPosition - previousPlayerPosition).st * 0.0065;
vec2 coord = texcoord.st + Blurness;
vec3 Mcolor = color;
vec3 NormalizeColor = vec3(2.2);

for (int i = 0; i < 60; ++i, coord += Blurness) {
        Mcolor += pow(texture2D(gaux2, coord).rgb, NormalizeColor);
	}
		color = Mcolor/NormalizeColor;
}
#endif

	//Tonemapping and colors
	vec3 curr = Uncharted2Tonemap(color);
	vec3 whiteScale = 1.0f/Uncharted2Tonemap(vec3(MAX_COLOR_RANGE));
	color = pow(curr*whiteScale,vec3(1.0/2.2));

	float avg = (color.r + color.g + color.b);
	color = (((color - avg )*0.98)+avg) ;

	if(land > 0.1){
	color.r = (color.r * 1.1)+(color.b+color.g)*(-0.1);
	color.g = (color.g * 1.1)+(color.r+color.b)*(-0.1);
	color.b = (color.b * 1.1)+(color.r+color.g)*(-0.1);
	}
	/*--------------------------------*/

	gl_FragColor = vec4(color,1.0);
}

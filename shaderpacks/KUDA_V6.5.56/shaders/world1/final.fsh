#version 120
#extension GL_ARB_shader_texture_lod : enable

/*



			███████ ███████ ███████ ███████ █
			█          █    █     █ █     █ █
			███████    █    █     █ ███████ █
			      █    █    █     █ █
			███████    █    ███████ █       █

	Before you change anything here, please keep in mind that
	you are allowed to modify my shaderpack ONLY for yourself!

	Please read my agreement for more informations!
		- http://dedelner.net/agreement/



*/

#define enableTonemapping		// Disable it, when you want to keep the originals colors.
	#define saturation 1.0		// [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
	#define exposure 1.0		// [0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
	#define contrast 1.0		// [1.0 1.1 1.2 1.3 1.4 1.5]
//#define cinematicMode
//#define depthOfField
	#define HQFocus						// A better transition in blurred areas by the cost of performance.
	#define underwaterBlur		// No focus underwater.
	#define blurFactor 1.0 // [0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
//#define distanceBlur			// Depth of field needs to be enabled!
#define bloom
//#define dirtyLens
//#define anamorphicLens
//#define cameraNoise
//#define chromaticAberration
//#define vignette
#define jitter						// A effect which is present only in the End.

#define maxColorRange 20.0

varying vec2 texcoord;

uniform sampler2D composite;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;

uniform float aspectRatio;
uniform float centerDepthSmooth;
uniform float frameTimeCounter;
uniform float blindness;
uniform float viewWidth;
uniform float viewHeight;

uniform int isEyeInWater;
uniform int worldTime;

float gaux3Material = texture2D(gaux3, texcoord.st).b;

bool hand = gaux3Material > 0.49 && gaux3Material < 0.51;

float luma(vec3 clr) {
	return dot(clr, vec3(0.3333));
}

const vec2 circlePattern[28] = vec2[28](vec2(1.0, 0.0),
										vec2(0.0, 1.0),

										vec2(-1.0, 0.0),
										vec2(0.0, -1.0),

										vec2(1.0, 0.5),
										vec2(0.5, 1.0),

										vec2(-1.0, 0.5),
										vec2(0.5, -1.0),

										vec2(1.0, -0.5),
										vec2(-0.5, 1.0),

										vec2(-1.0, -0.5),
										vec2(-0.5, -1.0),

										vec2(-0.8, 0.8),
										vec2(0.8, -0.8),

										vec2(0.8, 0.8),
										vec2(-0.8, -0.8),

										vec2(1.2, 0.0),
										vec2(0.0, 1.2),

										vec2(-1.2, 0.0),
										vec2(0.0, -1.2),

										vec2(0.5, 0.0),
										vec2(0.0, 0.5),

										vec2(-0.5, 0.0),
										vec2(0.0, -0.5),

										vec2(0.5, 0.5),
										vec2(-0.5, -0.5),

										vec2(0.5, -0.5),
										vec2(-0.5, 0.5));

vec2 rand(vec2 coord){
    return vec2(fract(sin(dot(coord.xy ,vec2(12.9898,78.233))) * 43758.5453), fract(cos(dot(coord.yx ,vec2(8.64947,45.097))) * 43758.5453)) * 2.0 -1.0;
}

float randomDots(vec2 coord) {

	// Source: https://gist.github.com/gerard-geer/4d0be4fbefabe209c9b5

	vec2 aspectcorrect = vec2(aspectRatio, 1.0);

	vec2 g = floor(coord * aspectcorrect);
	vec2 f = fract(coord * aspectcorrect) * 2.0 - 1.0;
	vec2 r = rand(g) * .5;

	return length(f + r);

}

float getDirtyLensTexture(vec2 coord) {

	float dirtylens = 0.0;

	dirtylens += 1.0 - smoothstep(0.1, 0.3, randomDots(coord * 2.0));
	dirtylens += 1.0 - smoothstep(0.1, 0.3, randomDots(coord * 2.5));
	dirtylens += 1.0 - smoothstep(0.1, 0.3, randomDots(coord * 3.0));
	dirtylens += 1.0 - smoothstep(0.1, 0.3, randomDots(coord * 4.0));
	dirtylens += 1.0 - smoothstep(0.1, 0.3, randomDots(coord * 6.0));

	return min(dirtylens, 1.0);

}

vec2 underwaterRefraction(vec2 coord) {

	float	refractionMultiplier = 0.003;
	float	refractionSpeed	= 4.0;
	float refractionSize = 1.0;

	vec2 refractCoord = vec2(sin(frameTimeCounter * refractionSpeed + coord.x * 25.0 * refractionSize + coord.y * 12.5 * refractionSize), 0.0);

	return bool(isEyeInWater)? coord + refractCoord * refractionMultiplier : coord;

}

vec3 blindnessEffect(vec3 clr) {

	const float blindnessAmount = 0.9;

	float dist  = min(pow(distance(texcoord.st, vec2(0.5)), 0.3) * 1.3, 1.0);

	return mix(clr, vec3(0.0), blindness * dist);

}

vec3 doTonemapping(vec3 clr) {

	// Thanks to robobo1221

	#ifdef enableTonemapping

		// Saturation
		clr = mix(clr, vec3(dot(clr, vec3(0.1111, 0.3333, 0.3333))), -saturation * 1.4 + 1.0);

		// Contrast
		clr = pow(clr, vec3(1.07 * contrast)) * contrast;

		clr = pow(clr, vec3(2.2));

		// Exposure
		clr *= 1.7 * exposure;

		clr = 1.0 - exp(-clr);
		clr = pow(clr, vec3(0.4545));

	#endif

	return clr;

}

vec3 doVignette(vec3 clr) {

	const float vignetteStrength	= 3.0;
	const float vignetteSharpness	= 5.0;

	#ifdef vignette

		float dist  = 1.0 - pow(distance(texcoord.st, vec2(0.5)), vignetteSharpness) * vignetteStrength;

		clr *= dist;

	#endif

	return clr;

}

vec3 doCinematicMode(vec3 clr) {

	#ifdef cinematicMode

		if (texcoord.t > 0.9 || texcoord.t < 0.1) clr.rgb = vec3(0.0);

	#endif

	return clr;

}

vec3 doCameraNoise(vec3 clr) {

	const float	noiseStrength	= 0.03;
	const float	noiseResoltion	= 3.5;

	#ifdef cameraNoise

		vec2 aspectcorrect = vec2(aspectRatio, 1.0);

		vec3 rgbNoise = texture2D(noisetex, texcoord.st * noiseResoltion * aspectcorrect + vec2(frameTimeCounter * 15.0, frameTimeCounter * 5.0)).rgb;

		clr = mix(clr, rgbNoise, luma(rgbNoise) * noiseStrength);

	#endif

	return clr;

}

vec3 doChromaticAberration(vec3 clr, vec2 coord) {

	const float offsetMultiplier	= 0.004;

	#ifdef chromaticAberration

		float dist = pow(distance(coord.st, vec2(0.5)), 2.5);

		float rChannel = texture2D(composite, coord.st + vec2(offsetMultiplier * dist, 0.0)).r;
		float gChannel = texture2D(composite, coord.st).g;
		float bChannel = texture2D(composite, coord.st - vec2(offsetMultiplier * dist, 0.0)).b;

		clr = vec3(rChannel, gChannel, bChannel) * maxColorRange;

	#endif

	return clr;

}

vec3 renderDOF(vec3 clr, vec2 coord, vec3 fragpos) {

	const float maxBlurFactor							= 0.6;		// To prevent weird results to very close objects.
	const float blurStartDistance					= 100.0;
	const float chromaticAberrationOffset	= 0.5;
	const float gaux2Mipmapping						= 5.0;

	vec3 blurSample = clr;

	#if defined depthOfField || defined distanceBlur

		vec2 aspectcorrect	= vec2(1.0, aspectRatio);

		float getDepth = texture2D(depthtex2, coord.st).x;

		#ifdef HQFocus

			getDepth = 0.0;
			for(int j = 0; j < 28; j++) getDepth += texture2D(depthtex2, coord.st + circlePattern[j] * aspectcorrect * 0.005).x;

			getDepth /= 28.0;

		#endif

		getDepth	= hand? 1.0 : getDepth;
		float focus			= getDepth - centerDepthSmooth;
		float factor		= 0.0;

		#ifdef depthOfField
			factor = focus * blurFactor * 7.5;
		#endif

		#ifdef distanceBlur

			factor += (1.0 - exp(-pow(length(fragpos) / blurStartDistance, 3.0))) * blurFactor * 0.07;

		#endif

		factor = clamp(factor, -maxBlurFactor, maxBlurFactor);

		#ifdef underwaterBlur
			if (float(isEyeInWater) > 0.9) factor = 0.75;
		#endif

		vec2 chromAberation = vec2((factor * chromaticAberrationOffset) / 100.0, 0.0);

		for(int i = 0; i < 28; i++) {

			#ifdef chromaticAberration

				blurSample.r += texture2DLod(composite, coord.st + circlePattern[i] * aspectcorrect * factor * 0.01 + chromAberation,	gaux2Mipmapping * abs(factor)).r * maxColorRange;
				blurSample.g += texture2DLod(composite, coord.st + circlePattern[i] * aspectcorrect * factor * 0.01,									gaux2Mipmapping * abs(factor)).g * maxColorRange;
				blurSample.b += texture2DLod(composite, coord.st + circlePattern[i] * aspectcorrect * factor * 0.01 - chromAberation,	gaux2Mipmapping * abs(factor)).b * maxColorRange;

			#else

				blurSample += texture2DLod(composite, coord.st + circlePattern[i] * aspectcorrect * factor * 0.01, gaux2Mipmapping * abs(factor)).rgb * maxColorRange;

			#endif

		}

		blurSample /= 28.0;

	#endif


	return blurSample;

}

vec3 calcBloom(vec3 clr, vec2 coord) {

	const float bloomStength = 0.1;

	#ifdef bloom

	vec3 blur  = pow(texture2D(gaux4, coord / pow(2.0, 2.0) + vec2(0.0, 0.0)).rgb, vec3(2.2)) * 7.0;
			 blur += pow(texture2D(gaux4, coord / pow(2.0, 3.0) + vec2(0.3, 0.0)).rgb, vec3(2.2)) * 6.0;
			 blur += pow(texture2D(gaux4, coord / pow(2.0, 4.0) + vec2(0.0, 0.3)).rgb, vec3(2.2)) * 5.0;
			 blur += pow(texture2D(gaux4, coord / pow(2.0, 5.0) + vec2(0.1, 0.3)).rgb, vec3(2.2)) * 4.0;
			 blur += pow(texture2D(gaux4, coord / pow(2.0, 6.0) + vec2(0.2, 0.3)).rgb, vec3(2.2)) * 3.0;
			 blur += pow(texture2D(gaux4, coord / pow(2.0, 7.0) + vec2(0.3, 0.3)).rgb, vec3(2.2)) * 2.0;

			 blur *= maxColorRange;

	clr.rgb = mix(clr.rgb, blur, bloomStength);

	#endif

	return clr;

}

vec3 calcBloomBasedAnamorphicLens(vec3 clr, vec2 coord) {

	const float	bloomIntensity	= 10.0;
	const float bloomMipmapping = 4.5;
	const int		bloomSamples			= 32;

	#ifdef anamorphicLens

		vec2 aspectcorrect		= vec2(1.0, aspectRatio);
		float bloomSample			= 0.0;

		for(int i = 0; i < bloomSamples; i++) {

			float offset = (pow(exp(float(i)), 0.07) - 1.0) * 0.05;

			bloomSample += pow(texture2D(gaux4, coord.st + vec2(offset, 0.0) * aspectcorrect, bloomMipmapping).a, 2.2);
			bloomSample += pow(texture2D(gaux4, coord.st - vec2(offset, 0.0) * aspectcorrect, bloomMipmapping).a, 2.2);

		}

		bloomSample /= float(bloomSamples) * 2.0;

		vec3 bloomColor = vec3(0.1, 0.4, 1.0);

		clr += bloomColor * bloomSample * bloomIntensity;

	#endif

	return clr;

}

vec3 drawDirtyLens(vec3 clr, vec2 coord) {

	const float	bloomIntensity	= 0.07;

	#ifdef dirtyLens

		vec3 blur  = pow(texture2D(gaux4, coord / pow(2.0, 2.0) + vec2(0.0, 0.0)).rgb, vec3(2.2)) * 7.0;
				 blur += pow(texture2D(gaux4, coord / pow(2.0, 3.0) + vec2(0.3, 0.0)).rgb, vec3(2.2)) * 6.0;
				 blur += pow(texture2D(gaux4, coord / pow(2.0, 4.0) + vec2(0.0, 0.3)).rgb, vec3(2.2)) * 5.0;
				 blur += pow(texture2D(gaux4, coord / pow(2.0, 5.0) + vec2(0.1, 0.3)).rgb, vec3(2.2)) * 4.0;
				 blur += pow(texture2D(gaux4, coord / pow(2.0, 6.0) + vec2(0.2, 0.3)).rgb, vec3(2.2)) * 3.0;
				 blur += pow(texture2D(gaux4, coord / pow(2.0, 7.0) + vec2(0.3, 0.3)).rgb, vec3(2.2)) * 2.0;

				 blur *= maxColorRange;

		clr = mix(clr, pow(blur, vec3(0.6)), clamp(getDirtyLensTexture(coord) * bloomIntensity, 0.0, 1.0));

	#endif

	return clr;

}

#define g(a) (-4.*a.x*a.y+3.*a.x+a.y*2.)

float bayer16x16(vec2 p){

    p *= vec2(viewWidth,viewHeight);

    vec2 m0 = vec2(mod(floor(p/8.), 2.));
    vec2 m1 = vec2(mod(floor(p/4.), 2.));
    vec2 m2 = vec2(mod(floor(p/2.), 2.));
    vec2 m3 = vec2(mod(floor(p)   , 2.));

    return (g(m0)+g(m1)*4.0+g(m2)*16.0+g(m3)*64.0)/255.;
}

#undef g

vec2 doJitter(vec2 coord) {

	float jitterAmount = 0.003;
	float jitterSpeed = 0.4;

	float jitterX = 0.0;

	#ifdef jitter

		float dist			= pow(distance(coord.st, vec2(0.5)), 1.5);
		float sinOffset		= 0.0;
		float cosOffset		= 0.0;
		float jitterFactor	= 0.0;

		float wave1 = sin(coord.y * 50.0	+ frameTimeCounter * 10.0 * jitterSpeed);
		float wave2	= cos(coord.y * 100.0	+ frameTimeCounter * 5.0 	* jitterSpeed);
		float wave3	= sin(coord.y * 20.0	+ frameTimeCounter * 25.0 * jitterSpeed) + cos(coord.y * 20.0 - frameTimeCounter * 50.0 * jitterSpeed);

		if (wave1 > 0.1)	sinOffset		= 1.0;
		if (wave1 > -0.1)	sinOffset		= -1.0;

		if (wave2 > 0.1)	cosOffset		= 1.0;
		if (wave2 > -0.1)	cosOffset		= -1.0;

		if (wave3 > 0.7)	jitterFactor	= 1.0;
		if (wave3 < -0.7)	jitterFactor	= 0.0;

		jitterX = (sinOffset * jitterFactor + cosOffset * jitterFactor) * dist * jitterAmount;

	#endif

	return vec2(coord.x + jitterX, coord.y);

}



void main() {

	const bool compositeMipmapEnabled = true;
	const bool gaux4MipmapEnabled = true;

	vec2 newTexcoord = doJitter(underwaterRefraction(texcoord.xy));

	// Get main color.
	vec4 color = texture2D(composite, newTexcoord.xy) * maxColorRange;

	// Set up positions.
	vec4 fragposition  = gbufferProjectionInverse * (vec4(newTexcoord.st, texture2D(depthtex1, newTexcoord.st).x, 1.0) * 2.0 - 1.0);
       fragposition /= fragposition.w;

	color.rgb = doChromaticAberration(color.rgb, newTexcoord);
	color.rgb = renderDOF(color.rgb, newTexcoord, fragposition.xyz);
	color.rgb = calcBloom(color.rgb, newTexcoord);
	color.rgb = calcBloomBasedAnamorphicLens(color.rgb, newTexcoord);
	color.rgb = drawDirtyLens(color.rgb, newTexcoord);
	color.rgb = blindnessEffect(color.rgb);
	color.rgb = doCameraNoise(color.rgb);
	color.rgb = doTonemapping(color.rgb);
	color.rgb = doVignette(color.rgb);
	color.rgb = doCinematicMode(color.rgb);

	color.rgb += bayer16x16(ivec2(gl_FragCoord.st)) / 255.0;

  gl_FragColor = color;

}

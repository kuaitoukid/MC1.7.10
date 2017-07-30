#version 120

/*
Paolo's Lagless Shaders was derived from Chocapic13's WIP Folder
Thank you CrapDeShoes for letting me use your code as a base file.
.
.
DO NOT EDIT BEYOND THIS POINT
*/

/* DRAWBUFFERS:0N2N4 */



//#define SMOOTH_WATER_TEXTURE
#define CUSTOM_WATER_TEXTURE


//water color and opacity
const float water_opacity = 0.4;

uniform sampler2D texture;
uniform float rainStrength;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;

varying vec3 normal;

varying float iswater;


const float MAX_OCCLUSION_DISTANCE = 100.0;

const int MAX_OCCLUSION_POINTS = 20;

uniform int worldTime;

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;

const float bump_distance = 80.0f;
const float fademult = 0.1f;





void main() {	
	

    vec4 tex = texture2D(texture, texcoord.st);
    
	//DEFAULT WATER 
	if (iswater > 0.9) {
		tex.a = 0.95f;
	}

	
	#ifdef SMOOTH_WATER_TEXTURE
 	if (iswater > 0.9) {
	 	tex = mix(tex, vec4(0.15f, 0.3f, 0.45f, 0.9f), 0.65f);
    	}
	#endif
	
	#ifdef CUSTOM_WATER_TEXTURE
 	if (iswater > 0.9) {
	 	tex = vec4(vec3(0.10f ,0.22f , 0.4f),  0.70f) * color;
    	}
	#endif

	
	vec3 indlmap = mix(lmcoord.t,1.0,lmcoord.s)*tex.rgb*color.rgb;
	gl_FragData[0] = vec4(indlmap,mix(tex.a,water_opacity,iswater));
	gl_FragDepth = gl_FragCoord.z;
	
	vec4 frag2;
	

			frag2 = vec4((normal) * 0.5f + 0.5f, 1.0f);			
	
	
	gl_FragData[2] = frag2;	
	//x = specularity / y = land(0.0/1.0)/shadow early exit(0.2)/water(0.05) / z = torch lightmap
	gl_FragData[4] = vec4(0.0, mix(1.0,0.05,iswater), lmcoord.s, 1.0);
	
}
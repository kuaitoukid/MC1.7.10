#version 120

/*
Modified Chocapic13 Shader Lite By Airloocke42
*/

const int RGBA16 = 3;
const int RGB16 = 2;
const int RGBA8 = 1;
const int R8 = 0;

const int gdepthFormat = R8;
const int gnormalFormat = RGB16;
const int compositeFormat = RGBA16;
const int gaux2Format = RGBA16;
const int gcolorFormat = RGBA8;

const int GL_EXP = 2048;
const int GL_LINEAR = 9729;

const float bump_distance = 64.0;
const float pom_distance = 32.0;
const float fademult = 0.1;

varying vec2 lmcoord;
varying vec4 color;
varying float mat;
varying vec2 texcoord;

varying vec3 normal;

uniform sampler2D texture;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int fogMode;
uniform int worldTime;
uniform float wetness;

void main() {
	vec2 adjustedTexCoord = texcoord;

	vec4 frag2 = vec4(normal*0.5+.5, 1.0f);
	
	vec4 c = mix(color,vec4(1.0),float(mat > 0.58 && mat < 0.62));

/* DRAWBUFFERS:024 */

	gl_FragData[0] = texture2D(texture, texcoord)*c;
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4((lmcoord.t), mat, lmcoord.s, 1.0);
}
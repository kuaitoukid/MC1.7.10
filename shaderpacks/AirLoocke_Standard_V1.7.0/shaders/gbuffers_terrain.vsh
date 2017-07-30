#version 120

/*
Modified Chocapic13 Shader Lite By Airloocke42
*/

/* Change Statement To “false” If You Want To Use WorldTime As Animation */

bool Frame_Animation = true;	

//---Waving Effects---//

#define WAVING_GRASS
#define WAVING_FLOWERS
#define WAVING_VEGETATION
#define WAVING_LEAVES
#define WAVING_LILIES
#define WAVING_VINES
#define WAVING_SAPLINGS
#define WAVING_SUGAR_CANES
#define WAVING_TALLPLANTS_AND_TALLGRASS

#define WAVING_FIRE
#define WAVING_LAVA
#define WAVING_WATER

//---Waving Effects---//

//---Do Not Edit---//

#define ENTITY_LEAVES        18.0
#define ENTITY_VINES        106.0
#define ENTITY_TALLGRASS     31.0
#define ENTITY_DANDELION     37.0
#define ENTITY_ROSE          38.0
#define ENTITY_WHEAT         59.0
#define ENTITY_LILYPAD      111.0
#define ENTITY_FIRE          51.0
#define ENTITY_LAVAFLOWING   10.0
#define ENTITY_LAVASTILL     11.0

//---Do Not Edit---//

const float PI = 3.1415927;

varying vec4 color;
varying vec2 lmcoord;
varying float mat;
varying vec2 texcoord;

varying vec3 normal;


attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;
uniform float rainStrength;

void main() {
	float istopv = 0.0, tick; mat = 1.0f;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;

	if (Frame_Animation) {
	tick = frameTimeCounter; } else {
	tick = float(worldTime/20.0); }

	if (gl_MultiTexCoord0.t < mc_midTexCoord.t) istopv = 1.0;
	/* un-rotate */
	vec4 position = gl_Vertex;
	vec3 worldpos = position.xyz + cameraPosition;
	
	float speed = 0.1;
        float magnitude = (sin((tick * 3.14159265358979323846264 / ((28.0) * speed))) * 0.05 + 0.15) * 0.27;
        float d2 = sin(tick * 3.14159265358979323846264 / (162.0 * speed)) * 3.0 - 1.5;
        float d3 = sin(tick * 3.14159265358979323846264 / (112.0 * speed)) * 3.0 - 1.5;

   #ifdef WAVING_LEAVES
	if (mc_Entity.x == 18.0) {
	position.x += sin(position.z+float(tick)/1.25)*0.1*(rainStrength+1)-0.05*(rainStrength+1);
	position.z += sin(position.x+float(tick)/1.25)*0.1*(rainStrength+1)-0.05*(rainStrength+1);

	}
#endif

    #ifdef WAVING_LILIES
    if (mc_Entity.x == 111.0) {
        position.x += sin(position.z+float(tick)/1.25)*0.1*(rainStrength+1)-0.05*(rainStrength+1);
	position.z += sin(position.x+float(tick)/1.25)*0.1*(rainStrength+1)-0.05*(rainStrength+1);

    }
    #endif
 
    #ifdef WAVING_VINES
    if (mc_Entity.x == 106.0) {
        position.x += sin(position.z+float(tick)/2.0)*0.1*(rainStrength+1)-0.05*(rainStrength+1);
	position.z += sin(position.x+float(tick)/2.0)*0.1*(rainStrength+1)-0.05*(rainStrength+1);
	
    }
    #endif

    #ifdef WAVING_SUGAR_CANES
    if (mc_Entity.x == 83.0 && texcoord.t < 1.90 && texcoord.t > -1.0) {
        position.x += sin(position.z+float(tick)/3.25)*0.1*(rainStrength+1)-0.05*(rainStrength+1);
	position.z += sin(position.x+float(tick)/3.25)*0.1*(rainStrength+1)-0.05*(rainStrength+1);

    }
    #endif

	if (istopv > 0.9) {

   #ifdef WAVING_GRASS
    if (mc_Entity.x == 31.0) {
        position.x += sin(position.z+tick*1.5)*0.1*(rainStrength+1)-0.05*(rainStrength+1);
	position.z += sin(position.x+tick*1.5)*0.1*(rainStrength+1)-0.05*(rainStrength+1);

    }
    #endif

   #ifdef WAVING_SAPLINGS
    if (mc_Entity.x == 6) {
        position.x += sin(position.z+tick*2.25)*0.1*(rainStrength+1)-.05*(rainStrength+1);
	position.z += sin(position.x+tick*2.25)*0.1*(rainStrength+1)-.05*(rainStrength+1);
	
    }
    #endif

   #ifdef WAVING_TALLPLANTS_AND_TALLGRASS
    if ( mc_Entity.x == 175.0 && texcoord.t < 0.23) {
        position.x += sin(position.z+tick*1.5)*0.1*(rainStrength+1)-0.05*(rainStrength+1);
	position.z += sin(position.x+tick*1.5)*0.1*(rainStrength+1)-0.05*(rainStrength+1);

    }
    #endif
    
    #ifdef WAVING_FLOWERS
    if (mc_Entity.x == 37.0 || mc_Entity.x == 38.0) {
        position.x += sin(position.z+tick*1.75)*0.1*(rainStrength+1)-.05*(rainStrength+1);
        position.z += sin(position.x+tick*1.75)*0.1*(rainStrength+1)-.05*(rainStrength+1);
	
    }
    #endif
    
    #ifdef WAVING_VEGETATION
    if (mc_Entity.x == 59.0 || mc_Entity.x == 141 || mc_Entity.x == 142) {
        position.x += sin(position.z+tick*2.0)*0.1*(rainStrength+1)-0.05*(rainStrength+1);
	position.z += sin(position.x+tick*2.0)*0.1*(rainStrength+1)-0.05*(rainStrength+1);

    }
    #endif
    
    #ifdef WAVING_FIRE
    if (mc_Entity.x == 51.0 && texcoord.t < 0.10) {
        position.x += sin(position.z+tick*2.0)*0.1*(rainStrength+1)-0.05*(rainStrength+1);
	position.z += sin(position.x+tick*2.0)*0.1*(rainStrength+1)-0.05*(rainStrength+1);
	
    }
    #endif
   
	}

	if (mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == ENTITY_VINES  || mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE || mc_Entity.x == ENTITY_WHEAT || mc_Entity.x == 30.0
	|| mc_Entity.x == 175.0	|| mc_Entity.x == 115.0 || mc_Entity.x == 32.0)
	mat = 0.4;
	
	if (mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == ENTITY_TALLGRASS) mat = 0.45;
	
	if (mc_Entity.x == 50.0 || mc_Entity.x == 62.0 || mc_Entity.x == 76.0 || mc_Entity.x == 91.0 || mc_Entity.x == 89.0 || mc_Entity.x == 124.0 || mc_Entity.x == 138.0) mat = 0.6;
	/* re-rotate */
	
	/* projectify */
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * position);
	
	color = gl_Color;
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	 normal = normalize(gl_NormalMatrix * gl_Normal);

}
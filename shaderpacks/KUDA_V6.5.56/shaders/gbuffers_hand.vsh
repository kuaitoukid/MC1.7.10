#version 120

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

#define	shakingHand
//#define animateUsingWorldTime

varying vec4 color;
varying vec3 normal;
varying vec2 texcoord;
varying vec2 lmcoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

attribute vec4 mc_Entity;

uniform float frameTimeCounter;
uniform int worldTime;

#ifdef animateUsingWorldTime
	#define frameTimeCounter worldTime * 0.0416
#endif


void main() {

  texcoord      = gl_MultiTexCoord0.st;
  lmcoord       = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  color         = gl_Color;
  normal        = normalize(gl_NormalMatrix * gl_Normal);

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

  #ifdef shakingHand
		position -= vec4(0.02 * sin(frameTimeCounter * 2.0), 0.005 * cos(frameTimeCounter * 3.0), 0.0, 0.0) * gbufferModelView;
	#endif

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

}

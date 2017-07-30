#version 120

/*
Chocapic13' shaders, read my terms of mofification/sharing before changing something below please!
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

varying vec4 color;


void main() {



	color = gl_Color;

	vec4 viewVertex = gl_ModelViewMatrix * gl_Vertex;

	gl_Position = gl_ProjectionMatrix * viewVertex;

	gl_FogFragCoord = gl_Position.z;

}
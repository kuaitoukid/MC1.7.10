#version 120

/*
Chocapic13' shaders, read my terms of mofification/sharing before changing something below please!
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

varying vec4 color;
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {

	gl_Position = ftransform();
	
	color = gl_Color;
	
	gl_FogFragCoord = gl_Position.z;
	
}
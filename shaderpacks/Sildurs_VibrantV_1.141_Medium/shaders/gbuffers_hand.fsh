#version 120
/* DRAWBUFFERS:024 */
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

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;

varying vec3 normal;

uniform sampler2D texture;


void main() {

	//Draw textures, colors
	gl_FragData[0] = texture2D(texture, texcoord)*color;
	//Keep lighting intact
	gl_FragData[1] = vec4(normal*0.5+0.5, 1.0f);
	gl_FragData[2] = vec4((lmcoord.t), 0.8, lmcoord.s, 1.0);

}
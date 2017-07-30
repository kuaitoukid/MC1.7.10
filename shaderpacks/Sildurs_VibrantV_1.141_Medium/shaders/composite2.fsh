#version 120
/* DRAWBUFFERS:3 */
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

//#define Bloom		//Makes lightsources more glowy, is only enabled during night-time or in dark areas. Medium performance impact.
#define blur_amount 1.25 //[1.0 1.25 1.5 2.0]

/*--------------------------------*/
const bool gaux2MipmapEnabled = true;
varying vec4 texcoord;
uniform sampler2D gaux2;
/*--------------------------------*/

#ifdef Bloom
vec3 Glow(float pos, vec2 offpos){
	vec3 blur = vec3(0.0);
	pos = pow(2, pos);
	vec2 bcoord = (texcoord.xy-offpos)*pos;

	if (bcoord.x > -0.1 && bcoord.y > -0.1 && bcoord.x < 1.1 && bcoord.y < 1.1)
	blur += pow(texture2D(gaux2, bcoord).rgb,vec3(2.2))*10.0;
	blur /= blur_amount;
	return blur;
}
#endif

void main() {

#ifdef Bloom
	vec3 bloom = Glow(2, vec2(0.0,0.0));
			bloom += Glow(3, vec2(0.4,0.0));
			bloom += Glow(4, vec2(0.0,0.4));
			bloom += Glow(5, vec2(0.6,0.6));
			bloom += Glow(6, vec2(0.8,0.8));
	bloom = pow(bloom,vec3(0.454));
#endif

#ifdef Bloom
	gl_FragData[0] = vec4(bloom,1.0);
#else
	gl_FragData[0] = vec4(0.0);
#endif
}

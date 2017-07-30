#version 120
/* DRAWBUFFERS:0246 */
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

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;
varying float mat;

varying vec3 normal;

uniform sampler2D texture;

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/

void main() {

	//Fix weird lightmap bug on emissive blocks
	vec4 c = mix(color,vec4(1.0),float(mat > 0.58 && mat < 0.62));

	//Draw textures, colors
	gl_FragData[0] = texture2D(texture, texcoord)*color;
	//Keep lighting intact
	gl_FragData[1] = vec4(normal*0.5+0.5, 1.0f);
	gl_FragData[2] = vec4((lmcoord.t), mat, lmcoord.s, 1.0);
}

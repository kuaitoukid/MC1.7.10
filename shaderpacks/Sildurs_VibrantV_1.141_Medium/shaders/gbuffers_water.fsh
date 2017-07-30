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
						   
						Sildur's shaders, derived from Chocapic's shaders */
						
						



vec4 watercolor = vec4(0.1,0.22,0.25,0.7);

const float PI = 3.1415927;
varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 worldpos;
varying float iswater;

uniform sampler2D texture;
uniform sampler2D noisetex;
uniform float frameTimeCounter;


float noiseW(vec3 pos) {
	vec3 coord = fract(pos / 1000);

	float noise = texture2D(noisetex,coord.xz*0.5 + frameTimeCounter*0.0010).x/0.5;
	noise -= texture2D(noisetex,coord.xz*0.5 - frameTimeCounter*0.0010).x/0.5;	
	noise += texture2D(noisetex,coord.xz*2.0 + frameTimeCounter*0.0015).x/2.0;
	noise -= texture2D(noisetex,coord.xz*2.0 - frameTimeCounter*0.0015).x/2.0;	
	noise += texture2D(noisetex,coord.xz*3.5 + frameTimeCounter*0.0020).x/3.5;
	noise -= texture2D(noisetex,coord.xz*3.5 - frameTimeCounter*0.0020).x/3.5;	
	noise += texture2D(noisetex,coord.xz*5.0 + frameTimeCounter*0.0025).x/5.0;	
	noise -= texture2D(noisetex,coord.xz*5.0 - frameTimeCounter*0.0025).x/5.0;		

	return noise;
}

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/ 

void main() {	
	
	vec4 tex = vec4((watercolor*length(texture2D(texture, texcoord.xy).rgb*0.5)*color).rgb,watercolor.a);
	if (iswater < 0.9)  tex = texture2D(texture, texcoord.xy)*color;
	
	vec3 waterpos = worldpos.xyz;
	waterpos.x -= (waterpos.x-frameTimeCounter*0.15)*7.0;
	waterpos.z -= (waterpos.z-frameTimeCounter*0.15)*7.0;
	
	float deltaPos = 0.4;
	float h0 = noiseW(waterpos);
	float h1 = noiseW(waterpos + vec3(deltaPos,0.0,0.0));
	float h2 = noiseW(waterpos + vec3(-deltaPos,0.0,0.0));
	float h3 = noiseW(waterpos + vec3(0.0,0.0,deltaPos));
	float h4 = noiseW(waterpos + vec3(0.0,0.0,-deltaPos));
	
	float xDelta = ((h1-h0)+(h0-h2))/deltaPos;
	float yDelta = ((h3-h0)+(h0-h4))/deltaPos;
	
	//Fix Iceblocks
	vec4 frag2 = vec4(normal*0.5+0.5, 1.0f);	
		
	if (iswater > 0.9) {
		float bumpmult = 0.03;	
		vec3 newnormal = normalize(vec3(xDelta,yDelta,1.0-xDelta*xDelta-yDelta*yDelta));
		newnormal = newnormal * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);
		
		frag2 = vec4(normalize(newnormal * tbnMatrix) * 0.5 + 0.5, 1.0);
	}
	gl_FragData[0] = tex;
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4(lmcoord.t, mix(1.0,0.05,iswater), lmcoord.s, 1.0);
}
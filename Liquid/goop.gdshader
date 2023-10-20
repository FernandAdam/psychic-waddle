shader_type canvas_item;
uniform float pixelFactor : hint_range(0,1) = 0.2;
uniform float volume = 500;
vec2 random(vec2 uv) {
	return vec2(fract(sin(dot(uv.xy,
		vec2(12.9898,78.233))) * 43758.5453123));
}

float worley(vec2 uv, float columns, float rows) {
	
	vec2 index_uv = floor(vec2(uv.x * columns, uv.y * rows));
	vec2 fract_uv = fract(vec2(uv.x * columns, uv.y * rows));
	
	float minimum_dist = 1.0;  
	
	for (int y= -1; y <= 1; y++) {
		for (int x= -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x),float(y));
			vec2 point = random(index_uv + neighbor);
			
			vec2 diff = neighbor + point - fract_uv;
			float dist = length(diff);
			minimum_dist = min(minimum_dist, dist);
		}
	}
	
	return minimum_dist;
}

void fragment() {
	//float width = float(textureSize(TEXTURE, 0).x)*2.5;
	vec2 middle_UV = UV - vec2(volume, volume);
	float len = length(middle_UV);
	//if (len < volume){
	if (COLOR.a >= 0.7) {
		vec2 pixelNumber = vec2(textureSize(TEXTURE, 0)) * pixelFactor;
		vec2 pixelatedUV = round(UV * pixelNumber) / pixelNumber;
		float worley = worley(pixelatedUV+vec2(TIME/64.0,TIME/64.0), 3.0, 5.0);
		COLOR = vec4(vec3(worley), 1.0);
		COLOR.r -= 0.1;
		COLOR.g -= 0.1;
		COLOR.b +=0.9;
	//} else {
	//	COLOR = vec4(1,1,1, 1.0 - COLOR.g);
	}
}

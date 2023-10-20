shader_type canvas_item;

uniform float volume = 0;
uniform float max_volume = 10;

void fragment() {
	// Place fragment code here.
	COLOR = texture(TEXTURE, UV);
	if (COLOR != vec4(0,0,0,1) && COLOR.r>0.5){
		COLOR.b += float(int(volume/max_volume*5.0))/5.0;
	}
}

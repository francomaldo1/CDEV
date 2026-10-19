shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Shader para paredes de pasillo estilo UTN FRC
// 1/3 inferior: revestimiento de madera barnizada
// Moldura oscura divisoria
// 2/3 superior: pared blanca institucional

uniform vec4 color_pared : source_color = vec4(0.72, 0.70, 0.65, 1.0);
uniform vec4 color_madera : source_color = vec4(0.64, 0.38, 0.18, 1.0);
uniform vec4 color_moldura : source_color = vec4(0.32, 0.18, 0.08, 1.0);

uniform float altura_piso = 4.5;
uniform float altura_madera = 1.35;
uniform float grosor_moldura = 0.04;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Altura relativa al piso actual (cada piso mide 4.5m)
	float y_rel = mod(world_pos.y, altura_piso);
	
	if (y_rel < (altura_madera - grosor_moldura * 0.5)) {
		// 1/3 INFERIOR: Madera de pasillo
		// Vetas muy sutiles para darle vida sin que se vea pixelado
		float veta = sin(world_pos.x * 35.0 + world_pos.z * 35.0) * 0.025;
		ALBEDO = color_madera.rgb + vec3(veta);
		ROUGHNESS = 0.45;
		METALLIC = 0.0;
	} else if (y_rel < (altura_madera + grosor_moldura * 0.5)) {
		// MOLDURA DIVISORIA
		ALBEDO = color_moldura.rgb;
		ROUGHNESS = 0.5;
		METALLIC = 0.0;
	} else {
		// 2/3 SUPERIOR: Pared blanca de la facultad
		ALBEDO = color_pared.rgb;
		ROUGHNESS = 0.85;
		METALLIC = 0.0;
	}
}

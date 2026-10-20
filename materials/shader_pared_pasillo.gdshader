shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Shader para paredes de pasillo estilo UTN FRC
// 1/3 inferior: revestimiento de machimbre de pino barnizado con nudos, vetas y zócalo
// Moldura de madera superior divisoria con relieve
// 2/3 superior: pared blanca institucional

uniform vec4 color_pared : source_color = vec4(0.85, 0.83, 0.80, 1.0);
uniform vec4 color_madera_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D tex_madera : source_color, filter_linear_mipmap, repeat_enable;

uniform float altura_piso = 4.5;
uniform float altura_madera = 1.34;
uniform float grosor_moldura = 0.06;
uniform float altura_zocalo = 0.08;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Altura relativa al piso actual (cada piso mide 4.5m)
	float y_rel = mod(world_pos.y, altura_piso);
	
	// Coordenadas triplanares proyectadas según orientación de la pared
	float u = abs(world_normal.x) > abs(world_normal.z) ? world_pos.z : world_pos.x;
	float v = y_rel;
	
	// Escala de mapeo: ~13 cm por tabla de machimbre
	vec2 uv_madera = vec2(u * 0.95, v * 0.95);
	
	float moldura_inicio = altura_madera - grosor_moldura * 0.5;
	float moldura_fin = altura_madera + grosor_moldura * 0.5;
	
	if (y_rel < altura_zocalo) {
		// ZÓCALO INFERIOR (perfil oscuro junto al piso como en la foto)
		ALBEDO = vec3(0.20, 0.20, 0.22);
		ROUGHNESS = 0.65;
		METALLIC = 0.0;
	} else if (y_rel < moldura_inicio) {
		// 1/3 INFERIOR: Machimbre de pino lustrado con nudos y vetas
		vec4 madera_sample = texture(tex_madera, uv_madera);
		ALBEDO = madera_sample.rgb * color_madera_tint.rgb;
		ROUGHNESS = 0.38; // Acabado semibrillante / satinado de barniz
		METALLIC = 0.0;
		SPECULAR = 0.45;
	} else if (y_rel < moldura_fin) {
		// MOLDURA SUPERIOR DE MADERA (guardasilla / perfil de remate con relieve)
		float p_moldura = (y_rel - moldura_inicio) / grosor_moldura;
		// Veta horizontal para la moldura
		vec4 madera_moldura = texture(tex_madera, vec2(v * 4.0, u * 0.2));
		vec3 base_moldura = madera_moldura.rgb * vec3(0.85, 0.60, 0.35);
		
		// Relieve: bisel superior brillante, ranura inferior sombreada
		if (p_moldura > 0.65) {
			ALBEDO = base_moldura * 1.25; // Brillo superior
		} else if (p_moldura < 0.25) {
			ALBEDO = base_moldura * 0.55; // Sombra de caída inferior
		} else {
			ALBEDO = base_moldura;
		}
		ROUGHNESS = 0.35;
		METALLIC = 0.0;
	} else {
		// 2/3 SUPERIOR: Pared blanca institucional de la facultad
		// Micro-grano muy sutil para textura de mampostería / yeso
		float micro_tex = sin(world_pos.x * 60.0) * sin(world_pos.y * 60.0 + world_pos.z * 60.0) * 0.015;
		ALBEDO = color_pared.rgb + vec3(micro_tex);
		ROUGHNESS = 0.82;
		METALLIC = 0.0;
	}
}

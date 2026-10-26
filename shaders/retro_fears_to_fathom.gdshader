shader_type canvas_item;
// Shader: 1990s Found-Footage Camcorder / VHS Degraded Video Camera
// Especificamente calibrado para estetica retro Fears to Fathom / terror liminal:
// - Buena iluminacion y exposicion (no oscurece el juego, levanta sombras lechosas de cinta analogica)
// - Distorsion de lente curvada (ojo de pez / angular sutil de camcorder de los 90s)
// - Destello tenue de lente en focos de luz (Lens Glare / Halation de linterna)
// - Grano de video analogico dinamico de sensor de camara
// - Scanlines suaves de entrelazado NTSC
// - Aberracion cromatica equilibrada (sutil en el centro estilo cinta VHS, visible en bordes estilo lente retro)
// - Dithering Bayer 8x8 fino en gradientes

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// Iluminacion / Exposicion (evita que sea oscuro, levanta las sombras como camara real)
// Modo Vision Nocturna estilo Outlast Camcorder (intensificador de luz infrarrojo / fosforico)
uniform float night_vision_active : hint_range(0.0, 1.0, 0.05) = 0.0;

uniform float exposure_boost : hint_range(1.0, 1.8, 0.05) = 1.15;
uniform float black_lift : hint_range(0.0, 0.15, 0.01) = 0.04;

// Lente y Distorsion de camara de los 90s
uniform float lens_distortion : hint_range(0.0, 0.25, 0.01) = 0.03;
uniform float lens_vignette : hint_range(0.0, 0.8, 0.05) = 0.22;

// Ruido y Grano analogico de sensor camcorder
uniform float video_noise : hint_range(0.0, 0.2, 0.005) = 0.03;

// Scanlines de video / entrelazado NTSC suaves
uniform float scanline_intensity : hint_range(0.0, 0.3, 0.01) = 0.04;

// Aberracion cromatica equilibrada
uniform float chromatic_aberration : hint_range(0.0, 0.006, 0.0002) = 0.0018;

// Destello / Resplandor tenue de lente en zonas iluminadas (linterna)
uniform float glare_strength : hint_range(0.0, 0.5, 0.02) = 0.12;

// Dithering Bayer 8x8 y cuantizacion
uniform float dither_strength : hint_range(0.0, 0.8, 0.02) = 0.22;
uniform float color_depth : hint_range(16.0, 64.0, 2.0) = 36.0;

// Matriz Bayer 8x8
const int bayer8[64] = int[](
     0, 32,  8, 40,  2, 34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,
    12, 44,  4, 36, 14, 46,  6, 38,
    60, 28, 52, 20, 62, 30, 54, 22,
     3, 35, 11, 43,  1, 33,  9, 41,
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21
);

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec2 distort_lens(vec2 uv) {
    vec2 centered = uv - 0.5;
    float r2 = dot(centered, centered);
    return uv + centered * (r2 * lens_distortion);
}

void fragment() {
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = distort_lens(SCREEN_UV);
    vec2 clamped_uv = clamp(uv, vec2(0.001), vec2(0.999));
    
    // Aberracion cromatica hibrida (radial de lente + leve desfase horizontal de cinta VHS):
    // Deja una franja de color retro claramente perceptible pero nitida y sin vision doble molesta
    vec2 from_center = clamped_uv - 0.5;
    float dist = length(from_center);
    vec2 chroma_offset = from_center * (dist * chromatic_aberration * 2.0) + vec2(chromatic_aberration * 0.4, 0.0);
    
    float r = texture(screen_texture, clamp(clamped_uv + chroma_offset, vec2(0.001), vec2(0.999))).r;
    float g = texture(screen_texture, clamped_uv).g;
    float b = texture(screen_texture, clamp(clamped_uv - chroma_offset, vec2(0.001), vec2(0.999))).b;
    vec3 color = vec3(r, g, b);
    
    // Destello de lente / Resplandor (Lens Glare / Halation) en zonas iluminadas (linterna)
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    if (glare_strength > 0.0) {
        float highlight = max(0.0, luma - 0.5) * 1.6;
        color += vec3(highlight * glare_strength * 0.7, highlight * glare_strength * 0.8, highlight * glare_strength * 0.6);
    }
    
    // Iluminacion clara y abierta (evita que el juego quede oscuro)
    color *= exposure_boost;
    color = max(color, vec3(black_lift)); // Levanta negros al tono lechoso analogico
    
    // Grano / Ruido de video de sensor de camcorder
    if (video_noise > 0.0) {
        float n = (random(clamped_uv + vec2(fract(TIME * 9.17), fract(TIME * 17.43))) - 0.5) * video_noise;
        color += n;
    }
    
    // Dithering Bayer 8x8 fino en gradientes
    ivec2 coord = ivec2(mod(floor(FRAGCOORD.xy), 8.0));
    int bayer_index = coord.y * 8 + coord.x;
    float dither = (float(bayer8[bayer_index]) / 64.0) - 0.5;
    color += (dither * dither_strength) / color_depth;
    color = floor(color * color_depth + 0.5) / color_depth;
    
    // Scanlines de entrelazado de video suaves
    if (scanline_intensity > 0.0) {
        float scanline = sin(clamped_uv.y * screen_size.y * PI * 0.5) * 0.5 + 0.5;
        color *= 1.0 - (scanline * scanline_intensity);
    }
    
    // Vineta tenue de lente
    if (lens_vignette > 0.0) {
        vec2 centered_uv = (uv - 0.5) * 2.0;
        float vig = clamp(1.0 - dot(centered_uv, centered_uv) * (lens_vignette * 0.35), 0.0, 1.0);
        color *= vig;
    }
    
    // Tinte levemente desaturado / autentico de camcorder
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(gray), 0.06);
    
    // Modo Vision Nocturna tipo Camcorder Outlast
    if (night_vision_active > 0.0) {
        float nv_luma = dot(color, vec3(0.299, 0.587, 0.114));
        float amplified = pow(nv_luma, 0.60) * 2.3;
        vec3 nv_palette = vec3(0.18, 0.98, 0.44) * amplified;
        float nv_grain = (random(clamped_uv + vec2(fract(TIME * 13.7), fract(TIME * 29.3))) - 0.5) * 0.08;
        nv_palette += vec3(nv_grain * 0.7, nv_grain * 1.2, nv_grain * 0.9);
        color = mix(color, nv_palette, night_vision_active);
    }

    COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}

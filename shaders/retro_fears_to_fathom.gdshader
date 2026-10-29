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

// Efecto de panico / distorsion analogica por proximidad al profesor (Efecto C)
uniform float panic_glitch : hint_range(0.0, 1.0, 0.02) = 0.0;

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
    
    // Distorsión y desgarro horizontal VHS por proximidad al profesor (Efecto pánico)
    if (panic_glitch > 0.0) {
        float tape_slice = floor(clamped_uv.y * 55.0);
        float tear_hash = random(vec2(tape_slice, floor(TIME * 24.0)));
        float tear_active = step(0.82 - panic_glitch * 0.35, tear_hash);
        float h_shift = (tear_hash - 0.5) * 0.038 * panic_glitch * tear_active;
        float tape_wobble = sin(clamped_uv.y * 95.0 + TIME * 36.0) * 0.003 * panic_glitch;
        clamped_uv.x = clamp(clamped_uv.x + h_shift + tape_wobble, 0.001, 0.999);
    }
    
    // Aberracion cromatica hibrida con incremento tembloroso en panico:
    vec2 from_center = clamped_uv - 0.5;
    float dist = length(from_center);
    float dynamic_chroma = chromatic_aberration + panic_glitch * 0.0038 * (0.8 + 0.35 * sin(TIME * 42.0));
    vec2 chroma_offset = from_center * (dist * dynamic_chroma * 2.0) + vec2(dynamic_chroma * 0.4, 0.0);
    
    float r = texture(screen_texture, clamp(clamped_uv + chroma_offset, vec2(0.001), vec2(0.999))).r;
    float g = texture(screen_texture, clamped_uv).g;
    float b = texture(screen_texture, clamp(clamped_uv - chroma_offset, vec2(0.001), vec2(0.999))).b;
    vec3 color = vec3(r, g, b);
    
    // Estática analógica VHS y barras de tracking en pánico
    if (panic_glitch > 0.0) {
        float static_noise = (random(clamped_uv * 2.5 + vec2(fract(TIME * 43.1), fract(TIME * 67.9))) - 0.5) * (0.22 * panic_glitch);
        float tracking_bar = smoothstep(0.92, 1.0, sin(clamped_uv.y * 3.5 - TIME * 5.0));
        color += static_noise + tracking_bar * 0.07 * panic_glitch;
    }
    
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
    
    // Modo Vision Nocturna estilo Outlast Camcorder exacta (menos brillante, sombras profundas, haz IR circular)
    if (night_vision_active > 0.0) {
        float luma = dot(color, vec3(0.299, 0.587, 0.114));
        vec2 centered_uv = uv - 0.5;
        centered_uv.x *= screen_size.x / screen_size.y;
        float r = length(centered_uv);
        float ir_beam = smoothstep(0.65, 0.18, r);
        float boosted = pow(luma * 1.45, 0.80) * (ir_beam * 0.94 + 0.06);
        vec3 c_dark  = vec3(0.00, 0.015, 0.008);
        vec3 c_edge  = vec3(0.059, 0.137, 0.094);
        vec3 c_mid   = vec3(0.388, 0.596, 0.475);
        vec3 c_high  = vec3(0.761, 0.961, 0.875);
        vec3 nv_outlast;
        if (boosted < 0.18) {
            nv_outlast = mix(c_dark, c_edge, boosted / 0.18);
        } else if (boosted < 0.65) {
            nv_outlast = mix(c_edge, c_mid, (boosted - 0.18) / 0.47);
        } else {
            nv_outlast = mix(c_mid, c_high, clamp((boosted - 0.65) / 0.35, 0.0, 1.0));
        }
        // Grano analógico y ruido de sensor CCD de alta ganancia Outlast
        float nv_grain = (random(clamped_uv + vec2(fract(TIME * 19.3), fract(TIME * 41.7))) - 0.5) * 0.115;
        float nv_sparkle = step(0.972, random(clamped_uv * 3.0 + vec2(fract(TIME * 53.7), fract(TIME * 17.9)))) * 0.15;
        nv_outlast += vec3(nv_grain * 0.5 + nv_sparkle * 0.35, nv_grain * 0.9 + nv_sparkle * 0.6, nv_grain * 0.6 + nv_sparkle * 0.45);
        color = mix(color, nv_outlast, night_vision_active);
    }

    COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}

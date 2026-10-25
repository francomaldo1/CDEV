shader_type canvas_item;
// Shader de Post-procesado estilo Retro / Fears to Fathom para Godot 4
// - Dithering espacial ordenado mediante Matriz Bayer 8x8 escalada
// - Cuantización a baja profundidad de color (Retro Color Depth)
// - Aberración cromática radial en bordes de lente
// - Grano analógico dinámico de cinta VHS
// - Líneas de escaneo horizontales CRT / VHS
// - Viñeta perimetral cinematográfica

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Cantidad de niveles por canal RGB (8 = muy retro 3-bit, 12-16 = Fears to Fathom / PSX, 24 = suave)
uniform float color_depth : hint_range(4.0, 32.0, 1.0) = 12.0;

// Intensidad del tramado de Dithering (0.0 = bandas lisas, 1.0 = tramado fuerte marcado)
uniform float dither_strength : hint_range(0.0, 1.5, 0.05) = 0.9;

// Tamaño del tramado de Dithering en píxeles de pantalla (1.0 = fino, 2.0-3.0 = bien visible y retro)
uniform float dither_size : hint_range(1.0, 4.0, 1.0) = 2.0;

// Pixelación general de la escena (1.0 = resolución nativa, 2.0 = estilo Fears to Fathom / 480p)
uniform float pixel_size : hint_range(1.0, 4.0, 1.0) = 2.0;

// Grano analógico / ruido fílmico dinámico
uniform float noise_amount : hint_range(0.0, 0.2, 0.005) = 0.045;

// Aberración cromática (desfase RGB en las esquinas de la lente)
uniform float chromatic_aberration : hint_range(0.0, 0.02, 0.001) = 0.005;

// Líneas de escaneo horizontales CRT / VHS
uniform float scanline_strength : hint_range(0.0, 0.4, 0.01) = 0.12;

// Viñeta perimetral oscura
uniform float vignette_intensity : hint_range(0.0, 1.0, 0.05) = 0.5;

// Matriz Bayer 8x8 estándar de ordered dithering (valores de 0 a 63)
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

void fragment() {
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = SCREEN_UV;
    
    // Pixelación retro general
    if (pixel_size > 1.0) {
        vec2 grid = screen_size / pixel_size;
        uv = floor(uv * grid) / grid;
    }
    
    // Aberración cromática radial en los bordes de la pantalla
    vec3 color;
    if (chromatic_aberration > 0.0) {
        vec2 dist_from_center = uv - 0.5;
        vec2 offset = dist_from_center * chromatic_aberration;
        float r = texture(screen_texture, uv - offset).r;
        float g = texture(screen_texture, uv).g;
        float b = texture(screen_texture, uv + offset).b;
        color = vec3(r, g, b);
    } else {
        color = texture(screen_texture, uv).rgb;
    }
    
    // Grano analógico dinámico de cámara VHS
    if (noise_amount > 0.0) {
        float n = (random(uv + vec2(fract(TIME * 7.13), fract(TIME * 13.37))) - 0.5) * noise_amount;
        color += n;
    }
    
    // Dithering Bayer 8x8 escalado con dither_size para que sea nítido y visible en alta resolución
    float d_scale = max(dither_size, pixel_size);
    ivec2 coord = ivec2(mod(floor(FRAGCOORD.xy / d_scale), 8.0));
    int bayer_index = coord.y * 8 + coord.x;
    float dither = (float(bayer8[bayer_index]) / 64.0) - 0.5;
    
    // Aplicación pronunciada del tramado
    color += (dither * dither_strength) / color_depth;
    
    // Cuantización a baja profundidad de color (pocas tonalidades retro)
    color = floor(color * color_depth + 0.5) / color_depth;
    
    // Líneas de escaneo CRT marcadas
    if (scanline_strength > 0.0) {
        float scanline = sin(uv.y * screen_size.y * PI * 0.5) * 0.5 + 0.5;
        color *= 1.0 - (scanline * scanline_strength);
    }
    
    // Viñeta perimetral oscura (efecto lente de cámara antigua)
    if (vignette_intensity > 0.0) {
        vec2 centered_uv = (uv - 0.5) * 2.0;
        float dist_sq = dot(centered_uv, centered_uv);
        float vig = clamp(1.0 - dist_sq * (vignette_intensity * 0.4), 0.0, 1.0);
        color *= vig;
    }
    
    COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}

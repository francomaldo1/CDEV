shader_type canvas_item;
// Shader de Post-procesado auténtico estilo Fears to Fathom para Godot 4
// - Resolución nativa nítida (sin pixelado tosco/mosaico)
// - Dithering Bayer 8x8 fino que texturiza sombras y gradientes de luz
// - Profundidad de color calibrada (32 niveles / 5-bit analógico)
// - Grano de película dinámico y sutil
// - Aberración cromática suave en extremos de la lente
// - Curva de contraste atmosférica con tinte analógico
// - Viñeta perimetral cinematográfica

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// Profundidad de color (32.0 = 5-bit estilo PSX/Fears to Fathom: sutil y orgánico)
uniform float color_depth : hint_range(8.0, 64.0, 1.0) = 32.0;

// Intensidad del Dithering fino en gradientes
uniform float dither_strength : hint_range(0.0, 1.0, 0.02) = 0.35;

// Pixelación (1.0 = resolución nativa nítida como en Fears to Fathom)
uniform float pixel_size : hint_range(1.0, 4.0, 1.0) = 1.0;

// Grano fílmico analógico tenue
uniform float film_grain : hint_range(0.0, 0.1, 0.005) = 0.022;

// Aberración cromática sutil en los bordes de la lente
uniform float chromatic_aberration : hint_range(0.0, 0.01, 0.0005) = 0.0018;

// Ajuste de contraste cinematográfico de terror
uniform float contrast : hint_range(0.8, 1.4, 0.02) = 1.08;
uniform float brightness : hint_range(-0.1, 0.1, 0.01) = -0.01;

// Tinte cálido tenue analógico
uniform vec3 tint_color : source_color = vec3(0.99, 0.97, 0.95);

// Viñeta perimetral suave
uniform float vignette_intensity : hint_range(0.0, 1.0, 0.05) = 0.28;

// Matriz Bayer 8x8 para dithering fino
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
    
    // Pixelación opcional (por defecto 1.0 = nítido, sin pérdida de definición)
    if (pixel_size > 1.0) {
        vec2 grid = screen_size / pixel_size;
        uv = floor(uv * grid) / grid;
    }
    
    // Aberración cromática sutil en los extremos de la pantalla
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
    
    // Grano de filmación orgánico dinámico
    if (film_grain > 0.0) {
        float n = (random(uv + vec2(fract(TIME * 5.17), fract(TIME * 11.23))) - 0.5) * film_grain;
        color += n;
    }
    
    // Dithering Bayer 8x8 fino alineado a los píxeles de pantalla
    ivec2 coord = ivec2(mod(floor(FRAGCOORD.xy), 8.0));
    int bayer_index = coord.y * 8 + coord.x;
    float dither = (float(bayer8[bayer_index]) / 64.0) - 0.5;
    
    // Aplicación del tramado de dither sobre los gradientes
    color += (dither * dither_strength) / color_depth;
    
    // Reducción suave de profundidad de color
    color = floor(color * color_depth + 0.5) / color_depth;
    
    // Curva de contraste y brillo cinematográfico
    color = (color - 0.5) * contrast + 0.5 + brightness;
    
    // Tinte cálido tenue analógico
    color *= tint_color;
    
    // Viñeta suave en las esquinas
    if (vignette_intensity > 0.0) {
        vec2 centered_uv = (uv - 0.5) * 2.0;
        float dist_sq = dot(centered_uv, centered_uv);
        float vig = clamp(1.0 - dist_sq * (vignette_intensity * 0.35), 0.0, 1.0);
        color *= vig;
    }
    
    COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}

@tool
extends SceneTree

# Generador de textura de machimbre de pino barnizado para revestimiento de pared
# Reproduce con precisión la foto de referencia: tablas verticales, nudos de pino,
# vetas onduladas, tono caramelo/miel cálido y biseles entre tablas.

func _init():
	print(">>> Generando textura de machimbre de pino (tex_wood_pine_panel.png)...")
	var size = 1024
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Ruido base para vetas finas y fibra de madera
	var noise_grain = FastNoiseLite.new()
	noise_grain.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_grain.seed = 305
	noise_grain.frequency = 0.015
	noise_grain.fractal_octaves = 4

	var noise_curl = FastNoiseLite.new()
	noise_curl.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_curl.seed = 991
	noise_curl.frequency = 0.02

	# Ancho de cada tabla vertical: 128 px (8 tablas en 1024 px)
	var plank_w = 128
	var num_planks = size / plank_w

	# Definición de nudos de pino (posición X, Y, radio, intensidad)
	# Ubicados estratégicamente para que parezcan naturales e irregulares
	var knots = [
		{"x": 190.0, "y": 280.0, "rx": 22.0, "ry": 32.0, "strength": 0.85},
		{"x": 310.0, "y": 720.0, "rx": 18.0, "ry": 26.0, "strength": 0.80},
		{"x": 580.0, "y": 210.0, "rx": 24.0, "ry": 36.0, "strength": 0.90},
		{"x": 710.0, "y": 640.0, "rx": 16.0, "ry": 24.0, "strength": 0.75},
		{"x": 920.0, "y": 380.0, "rx": 20.0, "ry": 30.0, "strength": 0.82},
		{"x": 80.0,  "y": 850.0, "rx": 19.0, "ry": 28.0, "strength": 0.78}
	]

	# Paleta de colores cálidos de pino barnizado / lustrado (extraída de la foto real)
	# Tono ámbar/miel brillante, vetas doradas y ranuras marrones oscuras
	var col_amber_light = Color(0.82, 0.54, 0.22)   # Luz en veta de pino
	var col_amber_base  = Color(0.70, 0.42, 0.16)   # Tono medio cálido de machimbre
	var col_amber_dark  = Color(0.52, 0.28, 0.09)   # Veta profunda
	var col_knot_core   = Color(0.24, 0.11, 0.04)   # Núcleo oscuro del nudo de pino
	var col_knot_ring   = Color(0.40, 0.19, 0.06)   # Anillo circundante del nudo
	var col_seam        = Color(0.22, 0.12, 0.05)   # Ranura / bisel entre tablas

	for y in range(size):
		var fy = float(y)
		for x in range(size):
			var fx = float(x)
			var plank_idx = x / plank_w
			var x_in_plank = x % plank_w

			# Tono base individual de cada tabla para evitar uniformidad artificial
			var plank_seed = float(plank_idx * 17 + 5)
			var plank_tone_offset = sin(plank_seed * 1.8) * 0.04
			var plank_hue_offset = cos(plank_seed * 2.3) * 0.03

			# Deformación de coordenadas por nudos cercanos (las vetas fluyen alrededor del nudo)
			var warp_x = 0.0
			var warp_y = 0.0
			var knot_influence = 0.0
			var min_knot_dist_norm = 999.0

			for k in knots:
				var dx = (fx - k.x) / k.rx
				var dy = (fy - k.y) / k.ry
				var d2 = dx * dx + dy * dy
				var d = sqrt(d2)
				if d < 4.0:
					var factor = exp(-d * 0.8) * k.strength
					# Distorsión tangencial / expansiva de la fibra alrededor del nudo
					var angle = atan2(dy, dx)
					warp_x += cos(angle) * factor * 28.0
					warp_y += sin(angle) * factor * 14.0
				if d < min_knot_dist_norm:
					min_knot_dist_norm = d
				if d < 1.2:
					knot_influence = maxf(knot_influence, (1.2 - d) / 1.2 * k.strength)

			# Coordenadas perturbadas para la fibra vertical
			var sample_x = fx + warp_x
			var sample_y = fy + warp_y

			# Simulación de vetas de madera estiradas fuertemente en Y (factor 9x)
			var curl = noise_curl.get_noise_2d(sample_x * 0.8, sample_y * 0.1) * 16.0
			var grain_noise = noise_grain.get_noise_2d((sample_x + curl) * 3.0, sample_y * 0.25)
			
			# Patrón de anillos / fibras finas
			var fiber_val = sin((sample_x * 0.18 + curl * 0.4) + grain_noise * 6.0) * 0.5 + 0.5
			# Modulación por crecimiento estacional (anillos anchos y delgados)
			var wide_ring = sin((sample_x * 0.05 + curl * 0.1) + grain_noise * 2.0) * 0.5 + 0.5

			# Mezcla de colores de madera de pino
			var wood_color = col_amber_base.lerp(col_amber_dark, grain_noise * 0.4 + 0.3)
			wood_color = wood_color.lerp(col_amber_light, fiber_val * 0.4 + wide_ring * 0.2)

			# Aplicar variación individual por tabla
			wood_color.r = clampf(wood_color.r + plank_tone_offset + plank_hue_offset, 0.0, 1.0)
			wood_color.g = clampf(wood_color.g + plank_tone_offset, 0.0, 1.0)
			wood_color.b = clampf(wood_color.b + plank_tone_offset - plank_hue_offset * 0.5, 0.0, 1.0)

			# Incorporar nudo de pino si corresponde
			if knot_influence > 0.0:
				var knot_blend = smoothstep(0.0, 1.0, knot_influence)
				var knot_col = col_knot_ring.lerp(col_knot_core, clampf((1.0 - min_knot_dist_norm) * 2.0, 0.0, 1.0))
				# Anillos oscuros dentro del nudo
				var knot_ring_osc = sin(min_knot_dist_norm * 18.0) * 0.15
				knot_col.r += knot_ring_osc
				wood_color = wood_color.lerp(knot_col, knot_blend)

			# Bisel / ranura entre tablas machihembradas
			# Bordes izquierdo y derecho de cada tabla
			var dist_to_edge = min(x_in_plank, plank_w - 1 - x_in_plank)
			if dist_to_edge == 0:
				# Ranura oscura central profunda
				wood_color = col_seam
			elif dist_to_edge <= 2:
				# Bisel inclinado (sombra en lado izquierdo, luz en lado derecho)
				if x_in_plank <= 2:
					# Sombra del bisel
					wood_color = wood_color.lerp(col_seam, 0.65)
				else:
					# Realce / brillo del bisel biselado hacia la luz
					wood_color = wood_color.lerp(col_amber_light, 0.35)

			img.set_pixel(x, y, wood_color)

	img.save_png("res://textures/tex_wood_pine_panel.png")
	print("✓ Textura generada con éxito: res://textures/tex_wood_pine_panel.png")
	quit()

extends SceneTree

func _init():
	print(">>> Generando texturas procedurales para UTN FRC...")
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("res://textures"):
		dir.make_dir("res://textures")

	_gen_wood_texture()
	_gen_granite_texture()
	_gen_stairs_texture()
	_gen_metal_texture()
	_gen_chair_texture()

	print(">>> ¡TODAS LAS TEXTURAS FUERON GENERADAS CON ÉXITO!")
	quit()

## 1. Textura de madera para pasillos y bancos
func _gen_wood_texture():
	var size = 512
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 42
	noise.frequency = 0.02
	noise.fractal_octaves = 4

	var plank_w = 64 # Ancho de cada tablón vertical

	var col_base = Color(0.60, 0.36, 0.18)
	var col_dark = Color(0.42, 0.24, 0.10)
	var col_light = Color(0.72, 0.46, 0.25)
	var col_seam = Color(0.20, 0.12, 0.05)

	for y in range(size):
		for x in range(size):
			var plank_idx = x / plank_w
			var x_in_plank = x % plank_w
			
			# Variación sutil de color entre tablones
			var plank_tint = sin(float(plank_idx) * 2.5) * 0.06
			
			# Vetas alargadas verticales (estiradas en Y factor x8)
			var grain = noise.get_noise_2d(float(x) * 3.5, float(y) * 0.4)
			var fine_grain = sin((float(x) + grain * 15.0) * 0.4) * 0.5 + 0.5
			
			var c = col_base.lerp(col_dark, grain * 0.5 + 0.5)
			c = c.lerp(col_light, fine_grain * 0.25)
			c.r += plank_tint
			c.g += plank_tint * 0.7
			c.b += plank_tint * 0.4

			# Ranura oscura entre tablones
			if x_in_plank == 0 or x_in_plank == 1 or x_in_plank == plank_w - 1:
				c = col_seam

			img.set_pixel(x, y, c)

	img.save_png("res://textures/tex_wood_panel.png")
	print("✓ tex_wood_panel.png guardada")

## 2. Textura de granito / mosaico para piso de la facultad
func _gen_granite_texture():
	var size = 512
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = 101
	noise.frequency = 0.15

	var col_bg = Color(0.68, 0.66, 0.62) # Fondo granítico gris claro
	var col_dark_speck = Color(0.18, 0.18, 0.18)
	var col_white_speck = Color(0.92, 0.92, 0.90)
	var col_brown_speck = Color(0.45, 0.38, 0.32)
	var col_grout = Color(0.35, 0.34, 0.32) # Junta de baldosa

	var tile_size = 128 # Baldosas de 50x50cm

	for y in range(size):
		for x in range(size):
			var n = noise.get_noise_2d(float(x), float(y))
			var c = col_bg

			# Motas salpicadas de piedra
			var rand_val = randf()
			if rand_val < 0.10:
				c = col_dark_speck.lerp(col_bg, randf() * 0.3)
			elif rand_val < 0.20:
				c = col_white_speck
			elif rand_val < 0.28:
				c = col_brown_speck
			else:
				c = col_bg.lerp(Color(0.74, 0.72, 0.68), (n + 1.0) * 0.5)

			# Juntas de baldosa
			var in_tile_x = x % tile_size
			var in_tile_y = y % tile_size
			if in_tile_x <= 1 or in_tile_y <= 1:
				c = col_grout

			img.set_pixel(x, y, c)

	img.save_png("res://textures/tex_granite_floor.png")
	print("✓ tex_granite_floor.png guardada")

## 3. Textura de pizarra / granito negro para escaleras
func _gen_stairs_texture():
	var size = 512
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.seed = 202
	noise.frequency = 0.08

	var col_base = Color(0.12, 0.13, 0.15)
	var col_speck = Color(0.22, 0.24, 0.28)
	var col_grout = Color(0.06, 0.06, 0.07)

	var tile_size = 256 # Baldosas grandes de descanso

	for y in range(size):
		for x in range(size):
			var n = (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			var c = col_base.lerp(col_speck, n * 0.6)

			# Rugosidad superficial
			if randf() < 0.08:
				c = c.lightened(0.12)
			elif randf() < 0.08:
				c = c.darkened(0.2)

			# Juntas
			if (x % tile_size) <= 2 or (y % tile_size) <= 2:
				c = col_grout

			img.set_pixel(x, y, c)

	img.save_png("res://textures/tex_stairs_slate.png")
	print("✓ tex_stairs_slate.png guardada")

## 4. Textura de metal cepillado para barandas y pasamanos
func _gen_metal_texture():
	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)

	var col_base = Color(0.45, 0.46, 0.48)

	for y in range(size):
		for x in range(size):
			# Micro rayado horizontal de cepillado
			var scratch = (randf() * 2.0 - 1.0) * 0.08
			var highlight = sin(float(y) * 0.05) * 0.05
			var c = col_base
			c.r = clampf(c.r + scratch + highlight, 0.0, 1.0)
			c.g = clampf(c.g + scratch + highlight, 0.0, 1.0)
			c.b = clampf(c.b + scratch + highlight, 0.0, 1.0)
			img.set_pixel(x, y, c)

	img.save_png("res://textures/tex_metal_brushed.png")
	print("✓ tex_metal_brushed.png guardada")

## 5. Textura de tapizado / plástico para sillas
func _gen_chair_texture():
	var size = 256
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)

	var col_base = Color(0.82, 0.16, 0.11)

	for y in range(size):
		for x in range(size):
			# Trama de tela / cuadrícula micro-texturada
			var weave = ((x % 4 == 0) != (y % 4 == 0))
			var factor = 0.06 if weave else -0.06
			var c = col_base
			c.r = clampf(c.r + factor, 0.0, 1.0)
			c.g = clampf(c.g + factor * 0.5, 0.0, 1.0)
			c.b = clampf(c.b + factor * 0.5, 0.0, 1.0)
			img.set_pixel(x, y, c)

	img.save_png("res://textures/tex_chair_red.png")
	print("✓ tex_chair_red.png guardada")

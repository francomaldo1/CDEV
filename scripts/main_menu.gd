extends Control

## =====================================================================
## MENÚ PRINCIPAL - UTN FRC: NOCHE DE FINALES
## Estética Outlast / Videocámara / Terror Institucional
## =====================================================================

var typewriter_font: Font = null
var typewriter_click_sfx = preload("res://audio/sfx/typewriter_click.wav")

var ambient_player: AudioStreamPlayer = null
var sfx_player: AudioStreamPlayer = null

# Elementos del camcorder
var rec_label: Label = null
var timecode_label: Label = null
var rec_timer: float = 0.0
var session_time: float = 0.0

# Modales
var active_modal: Control = null
var controls_modal: PanelContainer = null
var settings_modal: PanelContainer = null
var credits_modal: PanelContainer = null
var scanline_overlay: Control = null
var fade_overlay: ColorRect = null

# Sliders de ajustes
var volume_slider: HSlider = null
var volume_val_label: Label = null
var sens_slider: HSlider = null
var sens_val_label: Label = null
var fullscreen_chk: CheckBox = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if ResourceLoader.exists("res://fonts/typewriter.ttf"):
		typewriter_font = load("res://fonts/typewriter.ttf")
		
	_setup_audio()
	_setup_background_and_crt()
	_setup_camcorder_overlay()
	_setup_main_menu_content()
	_setup_modals()
	_setup_fade_overlay()

func _setup_audio() -> void:
	# Drone ambiental tenebroso
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "MenuAmbientAudio"
	if ResourceLoader.exists("res://audio/ambient/horror_ambience_atmos_11.wav"):
		ambient_player.stream = load("res://audio/ambient/horror_ambience_atmos_11.wav")
	ambient_player.volume_db = -18.0
	ambient_player.bus = &"Master"
	add_child(ambient_player)
	ambient_player.play()
	
	# SFX de clics / botones
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "MenuSFX"
	sfx_player.stream = typewriter_click_sfx
	sfx_player.volume_db = -10.0
	sfx_player.bus = &"Master"
	add_child(sfx_player)

func _setup_background_and_crt() -> void:
	# Fondo oscuro base
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.015, 0.018, 0.025, 1.0)
	add_child(bg)
	
	# Imagen de fondo: vista exterior desde el estacionamiento hacia la entrada
	if ResourceLoader.exists("res://textures/bg_menu_estacionamiento.png"):
		var bg_tex = load("res://textures/bg_menu_estacionamiento.png")
		var bg_rect = TextureRect.new()
		bg_rect.name = "BackgroundExteriorEstacionamiento"
		bg_rect.texture = bg_tex
		bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_rect.modulate = Color(0.72, 0.78, 0.88, 0.82)
		add_child(bg_rect)
		
		# Gradiente oscuro sutil sobre el lado izquierdo para dar máxima legibilidad a los textos y botones
		var left_scrim = ColorRect.new()
		left_scrim.name = "LeftMenuScrim"
		left_scrim.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		left_scrim.offset_right = 580.0
		left_scrim.color = Color(0.01, 0.015, 0.025, 0.65)
		add_child(left_scrim)
		
		# Viñeta oscura sutil de videocámara
		var vignette = ColorRect.new()
		vignette.name = "VignetteBorder"
		vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
		vignette.color = Color(0.0, 0.0, 0.0, 0.22)
		add_child(vignette)
	
	# Overlay sutil de líneas de escaneo (Scanlines CRT)
	scanline_overlay = Control.new()
	scanline_overlay.name = "ScanlineOverlay"
	scanline_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanline_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanline_overlay.draw.connect(_on_scanlines_draw)
	add_child(scanline_overlay)

func _on_scanlines_draw() -> void:
	var sz = get_viewport_rect().size
	var line_spacing = 4.0
	var col = Color(0.0, 0.0, 0.0, 0.18)
	var y = 0.0
	while y < sz.y:
		scanline_overlay.draw_line(Vector2(0, y), Vector2(sz.x, y), col, 1.0)
		y += line_spacing

func _setup_camcorder_overlay() -> void:
	var cam_hud = Control.new()
	cam_hud.name = "CamcorderHUD"
	cam_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	cam_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cam_hud)
	
	# Top-Left: REC
	rec_label = Label.new()
	rec_label.text = "● REC   SP"
	rec_label.position = Vector2(35, 25)
	rec_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 0.95))
	rec_label.add_theme_font_size_override("font_size", 16)
	if typewriter_font:
		rec_label.add_theme_font_override("font", typewriter_font)
	cam_hud.add_child(rec_label)
	
	# Top-Center: Ubicación y Fecha
	var header_meta = Label.new()
	header_meta.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header_meta.offset_top = 26.0
	header_meta.offset_bottom = 50.0
	header_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_meta.text = "UTN FRC - SEDE CENTRAL | CÓRDOBA, ARG | 23:58:40"
	header_meta.add_theme_color_override("font_color", Color(0.75, 0.82, 0.88, 0.65))
	header_meta.add_theme_font_size_override("font_size", 13)
	if typewriter_font:
		header_meta.add_theme_font_override("font", typewriter_font)
	cam_hud.add_child(header_meta)
	
	# Top-Right: Batería
	var bat_label = Label.new()
	bat_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bat_label.position = Vector2(-125, 25)
	bat_label.text = "[▮▮▮▯] 78%"
	bat_label.add_theme_color_override("font_color", Color(0.55, 0.92, 0.72, 0.9))
	bat_label.add_theme_font_size_override("font_size", 14)
	if typewriter_font:
		bat_label.add_theme_font_override("font", typewriter_font)
	cam_hud.add_child(bat_label)
	
	# Bottom-Left: Cámara NTSC
	var cam_name = Label.new()
	cam_name.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	cam_name.position = Vector2(35, -45)
	cam_name.text = "CAM 00 - HALL DE INGRESO"
	cam_name.add_theme_color_override("font_color", Color(0.75, 0.82, 0.88, 0.55))
	cam_name.add_theme_font_size_override("font_size", 13)
	if typewriter_font:
		cam_name.add_theme_font_override("font", typewriter_font)
	cam_hud.add_child(cam_name)
	
	# Bottom-Right: Timecode
	timecode_label = Label.new()
	timecode_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	timecode_label.position = Vector2(-170, -45)
	timecode_label.text = "00:00:00:00"
	timecode_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.75))
	timecode_label.add_theme_font_size_override("font_size", 14)
	if typewriter_font:
		timecode_label.add_theme_font_override("font", typewriter_font)
	cam_hud.add_child(timecode_label)

func _setup_main_menu_content() -> void:
	# Centrado exacto respecto a la banda negra izquierda (scrim ancho 580px, centro en X = 290px)
	var scrim_w = 580.0
	var box_w = 440.0
	var box_x = (scrim_w - box_w) / 2.0 # 70.0 px de margen simétrico
	
	var main_box = VBoxContainer.new()
	main_box.name = "MainMenuContent"
	main_box.position = Vector2(box_x, 100.0)
	main_box.custom_minimum_size = Vector2(box_w, 520.0)
	main_box.add_theme_constant_override("separation", 20)
	add_child(main_box)
	
	# Encabezado con Logo y Título
	var title_box = VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 8)
	main_box.add_child(title_box)
	
	# Logo UTN
	if ResourceLoader.exists("res://textures/tex_utn_frc_glass_logo.png"):
		var logo_tex = load("res://textures/tex_utn_frc_glass_logo.png")
		var logo_rect = TextureRect.new()
		logo_rect.texture = logo_tex
		logo_rect.custom_minimum_size = Vector2(74, 74)
		logo_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		logo_rect.modulate = Color(0.9, 0.95, 1.0, 0.85)
		title_box.add_child(logo_rect)
		
	var main_title = Label.new()
	main_title.text = "UTN FRC: NOCHE DE FINALES"
	main_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_title.add_theme_font_size_override("font_size", 28)
	main_title.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 0.95))
	main_title.add_theme_constant_override("outline_size", 4)
	main_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	if typewriter_font:
		main_title.add_theme_font_override("font", typewriter_font)
	title_box.add_child(main_title)
	
	# Separador estilizado
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(360, 10)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.3, 0.35, 0.45, 0.4)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	main_box.add_child(sep)
	
	# Lista de Botones del Menú
	var btn_box = VBoxContainer.new()
	btn_box.name = "MenuButtons"
	btn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_box.add_theme_constant_override("separation", 14)
	main_box.add_child(btn_box)
	
	var btn_play = _create_menu_button("▶  INICIAR PARTIDA")
	btn_play.pressed.connect(_on_play_pressed)
	btn_box.add_child(btn_play)
	
	var btn_controls = _create_menu_button("📋  CONTROLES Y GUÍA")
	btn_controls.pressed.connect(func(): _open_modal(controls_modal))
	btn_box.add_child(btn_controls)
	
	var btn_settings = _create_menu_button("⚙  AJUSTES Y AUDIO")
	btn_settings.pressed.connect(func(): _open_modal(settings_modal))
	btn_box.add_child(btn_settings)
	
	var btn_credits = _create_menu_button("🎓  CRÉDITOS")
	btn_credits.pressed.connect(func(): _open_modal(credits_modal))
	btn_box.add_child(btn_credits)
	
	var btn_quit = _create_menu_button("✖  SALIR AL ESCRITORIO")
	btn_quit.pressed.connect(func(): get_tree().quit())
	btn_box.add_child(btn_quit)

func _create_menu_button(label_text: String) -> Button:
	var btn = Button.new()
	btn.text = label_text
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.custom_minimum_size = Vector2(380, 46)
	
	if typewriter_font:
		btn.add_theme_font_override("font", typewriter_font)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(0.96, 0.93, 0.68, 1.0)) # Amarillo pálido al hover
	btn.add_theme_color_override("font_focus_color", Color(0.96, 0.93, 0.68, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	
	# Estilo normal
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.04, 0.05, 0.08, 0.70)
	normal_style.border_color = Color(0.25, 0.30, 0.42, 0.6)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(3)
	normal_style.content_margin_left = 14
	normal_style.content_margin_right = 14
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal_style)
	
	# Estilo hover
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.08, 0.12, 0.18, 0.90)
	hover_style.border_color = Color(0.96, 0.93, 0.68, 0.85) # Borde sutil amarillo pálido
	hover_style.set_border_width_all(1)
	hover_style.set_corner_radius_all(3)
	hover_style.content_margin_left = 14
	hover_style.content_margin_right = 14
	hover_style.content_margin_top = 8
	hover_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("focus", hover_style)
	
	# Estilo presionado
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.14, 0.16, 0.24, 0.98)
	pressed_style.border_color = Color(1.0, 1.0, 1.0, 0.9)
	pressed_style.set_border_width_all(1)
	pressed_style.set_corner_radius_all(3)
	pressed_style.content_margin_left = 14
	pressed_style.content_margin_right = 14
	pressed_style.content_margin_top = 8
	pressed_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.mouse_entered.connect(_play_hover_sound)
	btn.pressed.connect(_play_click_sound)
	
	return btn

func _play_hover_sound() -> void:
	if sfx_player and typewriter_click_sfx:
		sfx_player.pitch_scale = randf_range(1.2, 1.35)
		sfx_player.play()

func _play_click_sound() -> void:
	if sfx_player and typewriter_click_sfx:
		sfx_player.pitch_scale = 0.95
		sfx_player.play()

func _setup_modals() -> void:
	controls_modal = _create_modal_container("CONTROLES Y GUÍA DE SUPERVIVENCIA")
	_populate_controls_modal(controls_modal)
	add_child(controls_modal)
	
	settings_modal = _create_modal_container("AJUSTES Y OPCIONES")
	_populate_settings_modal(settings_modal)
	add_child(settings_modal)
	
	credits_modal = _create_modal_container("CRÉDITOS Y AGRADECIMIENTOS")
	_populate_credits_modal(credits_modal)
	add_child(credits_modal)

func _create_modal_container(title: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 520)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	panel.modulate.a = 0.0
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.05, 0.96)
	style.border_color = Color(0.96, 0.93, 0.68, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.name = "ModalVBox"
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "[ " + title + " ]"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.95))
	if typewriter_font:
		title_lbl.add_theme_font_override("font", typewriter_font)
	vbox.add_child(title_lbl)
	
	return panel

func _populate_controls_modal(panel: PanelContainer) -> void:
	var vbox = panel.get_node("ModalVBox") as VBoxContainer
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 365)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(620, 0)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	
	# Encabezado 1: Controles
	var sec1 = Label.new()
	sec1.text = "▶  TECLAS DE ACCIÓN Y MECÁNICAS"
	sec1.add_theme_font_size_override("font_size", 15)
	sec1.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.95))
	if typewriter_font:
		sec1.add_theme_font_override("font", typewriter_font)
	content.add_child(sec1)
	
	_add_control_row(content, " • [ W / A / S / D ]", "Desplazarse por los pasillos y aulas de la facultad.")
	_add_control_row(content, " • [ Shift ]", "Correr a máxima velocidad (consume estamina).")
	_add_control_row(content, " • [ Click Der / F ]", "Visión Nocturna en la Videocámara (consume batería).")
	_add_control_row(content, " • [ E ]", "Interactuar / Rendir parciales / Reparar tablero eléctrico.")
	_add_control_row(content, " • [ Q ]", "Consumir Peronachos (recupera 100% de estamina al instante).")
	_add_control_row(content, " • [ R ]", "Insertar pilas AA en la videocámara para recargar batería.")
	_add_control_row(content, " • [ Espacio ]", "Ocultarse o salir de los tachos de basura.")
	_add_control_row(content, " • [ F1 ]", "Abrir el menú de objetivos y guía de supervivencia.")
	
	# Separador
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(600, 14)
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.3, 0.35, 0.45, 0.4)
	sep.add_theme_stylebox_override("separator", sep_style)
	content.add_child(sep)
	
	# Encabezado 2: Guía
	var sec2 = Label.new()
	sec2.text = "▶  GUÍA Y REGLAS DE SUPERVIVENCIA"
	sec2.add_theme_font_size_override("font_size", 15)
	sec2.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.95))
	if typewriter_font:
		sec2.add_theme_font_override("font", typewriter_font)
	content.add_child(sec2)
	
	_add_step_row(content, "1.", "Rendí los 4 parciales matemáticos en los cuadernos de Planta Baja.")
	_add_step_row(content, "2.", "Al terminar el 4to examen, saltarán los disyuntores y se cortará la luz.")
	_add_step_row(content, "3.", "Subí al Piso 1 (P1) hacia Bedelía a recuperar el Fusible de Alta Tensión.")
	_add_step_row(content, "4.", "Bajá al Depto. de Electrónica (PB Oeste) y colocá el fusible en el tablero.")
	_add_step_row(content, "5.", "¡Esquivá al Profesor! Escapá del laboratorio y buscá la Llave del Auditorio en el 2do Piso.")
	_add_step_row(content, "6.", "Abrí el Auditorio, retirá tu Título Universitario del estrado y escapá por la Salida Principal.")
	
	var btn_close = _create_menu_button("◀  VOLVER AL MENÚ")
	btn_close.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_close.pressed.connect(_close_active_modal)
	vbox.add_child(btn_close)

func _add_control_row(container: VBoxContainer, key_text: String, desc_text: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	
	var key_lbl = Label.new()
	key_lbl.text = key_text
	key_lbl.custom_minimum_size = Vector2(180, 0)
	key_lbl.add_theme_font_size_override("font_size", 14)
	key_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.95))
	if typewriter_font:
		key_lbl.add_theme_font_override("font", typewriter_font)
	hbox.add_child(key_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = desc_text
	desc_lbl.custom_minimum_size = Vector2(430, 0)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.96, 0.9))
	if typewriter_font:
		desc_lbl.add_theme_font_override("font", typewriter_font)
	hbox.add_child(desc_lbl)
	
	container.add_child(hbox)

func _add_step_row(container: VBoxContainer, step_num: String, step_text: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var num_lbl = Label.new()
	num_lbl.text = step_num
	num_lbl.custom_minimum_size = Vector2(25, 0)
	num_lbl.add_theme_font_size_override("font_size", 14)
	num_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.95))
	if typewriter_font:
		num_lbl.add_theme_font_override("font", typewriter_font)
	hbox.add_child(num_lbl)
	
	var text_lbl = Label.new()
	text_lbl.text = step_text
	text_lbl.custom_minimum_size = Vector2(585, 0)
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.add_theme_font_size_override("font_size", 14)
	text_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.96, 0.9))
	if typewriter_font:
		text_lbl.add_theme_font_override("font", typewriter_font)
	hbox.add_child(text_lbl)
	
	container.add_child(hbox)

func _populate_settings_modal(panel: PanelContainer) -> void:
	var vbox = panel.get_node("ModalVBox") as VBoxContainer
	
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	vbox.add_child(content)
	
	# 1. Volumen General
	var vol_box = VBoxContainer.new()
	vol_box.add_theme_constant_override("separation", 6)
	
	var vol_lbl_box = HBoxContainer.new()
	var vol_title = Label.new()
	vol_title.text = "VOLUMEN GENERAL (MASTER):"
	vol_title.add_theme_font_size_override("font_size", 14)
	vol_title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.9))
	if typewriter_font:
		vol_title.add_theme_font_override("font", typewriter_font)
	vol_lbl_box.add_child(vol_title)
	
	volume_val_label = Label.new()
	volume_val_label.text = " 100%"
	volume_val_label.add_theme_font_size_override("font_size", 14)
	volume_val_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	if typewriter_font:
		volume_val_label.add_theme_font_override("font", typewriter_font)
	vol_lbl_box.add_child(volume_val_label)
	vol_box.add_child(vol_lbl_box)
	
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	volume_slider.value_changed.connect(_on_volume_changed)
	vol_box.add_child(volume_slider)
	content.add_child(vol_box)
	
	# 2. Pantalla Completa
	fullscreen_chk = CheckBox.new()
	fullscreen_chk.text = " Modo Pantalla Completa (Fullscreen)"
	fullscreen_chk.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	fullscreen_chk.toggled.connect(_on_fullscreen_toggled)
	if typewriter_font:
		fullscreen_chk.add_theme_font_override("font", typewriter_font)
	fullscreen_chk.add_theme_font_size_override("font_size", 14)
	fullscreen_chk.add_theme_color_override("font_color", Color(0.88, 0.92, 0.96))
	content.add_child(fullscreen_chk)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)
	
	var btn_close = _create_menu_button("◀  VOLVER AL MENÚ")
	btn_close.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_close.pressed.connect(_close_active_modal)
	vbox.add_child(btn_close)

func _populate_credits_modal(panel: PanelContainer) -> void:
	var vbox = panel.get_node("ModalVBox") as VBoxContainer
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 365)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(620, 0)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	
	var title_lbl = Label.new()
	title_lbl.text = "PROYECTO: UTN FRC: NOCHE DE FINALES"
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.95))
	if typewriter_font:
		title_lbl.add_theme_font_override("font", typewriter_font)
	content.add_child(title_lbl)
	
	var team_lbl = Label.new()
	team_lbl.text = "▶  EQUIPO DE DESARROLLO:"
	team_lbl.add_theme_font_size_override("font_size", 14)
	team_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.95))
	if typewriter_font:
		team_lbl.add_theme_font_override("font", typewriter_font)
	content.add_child(team_lbl)
	
	var members = [
		"Schurrer, Gabriel Nicolas",
		"Maldonado, Franco Gabriel",
		"Nobile, Bruno Nicolas",
		"Imwinkelried, Ivan",
		"Ranieri, Valentina",
		"Ramirez, Carlos David",
		"Grosso Gaspar",
		"Mottura Mateo"
	]
	
	for m in members:
		var m_lbl = Label.new()
		m_lbl.text = " • " + m
		m_lbl.custom_minimum_size = Vector2(600, 0)
		m_lbl.add_theme_font_size_override("font_size", 14)
		m_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 0.96, 0.95))
		if typewriter_font:
			m_lbl.add_theme_font_override("font", typewriter_font)
		content.add_child(m_lbl)
		
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(600, 10)
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.3, 0.35, 0.45, 0.4)
	sep.add_theme_stylebox_override("separator", sep_style)
	content.add_child(sep)
	
	var inst_lbl = Label.new()
	inst_lbl.text = "INSTITUCIÓN:\n • Universidad Tecnológica Nacional - Facultad Regional Córdoba (UTN FRC)"
	inst_lbl.custom_minimum_size = Vector2(600, 0)
	inst_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inst_lbl.add_theme_font_size_override("font_size", 13)
	inst_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90, 0.8))
	if typewriter_font:
		inst_lbl.add_theme_font_override("font", typewriter_font)
	content.add_child(inst_lbl)
	
	var tech_lbl = Label.new()
	tech_lbl.text = "MOTOR Y TECNOLOGÍA:\n • Godot Engine 4.7\n • Modelos 3D y Sonidos de la Comunidad de Código Abierto (Freesound / CC-BY)"
	tech_lbl.custom_minimum_size = Vector2(600, 0)
	tech_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tech_lbl.add_theme_font_size_override("font_size", 13)
	tech_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90, 0.8))
	if typewriter_font:
		tech_lbl.add_theme_font_override("font", typewriter_font)
	content.add_child(tech_lbl)
	
	var btn_close = _create_menu_button("◀  VOLVER AL MENÚ")
	btn_close.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_close.pressed.connect(_close_active_modal)
	vbox.add_child(btn_close)

func _setup_fade_overlay() -> void:
	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.color = Color(0, 0, 0, 1)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.modulate.a = 1.0
	add_child(fade_overlay)
	
	# Fundido de entrada al abrir el menú
	var tw = create_tween()
	tw.tween_property(fade_overlay, "modulate:a", 0.0, 0.8)

func _process(delta: float) -> void:
	session_time += delta
	rec_timer += delta
	
	# Parpadeo del indicador REC
	if rec_label:
		rec_label.visible = fmod(rec_timer, 1.2) < 0.7
		
	# Timecode dinámico
	if timecode_label:
		var mins = int(session_time / 60.0)
		var secs = int(fmod(session_time, 60.0))
		var frames = int(fmod(session_time * 30.0, 30.0))
		timecode_label.text = "00:%02d:%02d:%02d" % [mins, secs, frames]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if active_modal:
			_close_active_modal()
			get_viewport().set_input_as_handled()

func _open_modal(modal: Control) -> void:
	if active_modal:
		_close_active_modal()
	active_modal = modal
	modal.visible = true
	var tw = create_tween()
	tw.tween_property(modal, "modulate:a", 1.0, 0.25)

func _close_active_modal() -> void:
	if not active_modal:
		return
	var m = active_modal
	active_modal = null
	var tw = create_tween()
	tw.tween_property(m, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		if is_instance_valid(m):
			m.visible = false
	)

func _on_play_pressed() -> void:
	if fade_overlay:
		var tw = create_tween()
		tw.tween_property(fade_overlay, "modulate:a", 1.0, 0.7)
		tw.tween_callback(func():
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_volume_changed(val: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(maxf(val, 0.001)))
	if volume_val_label:
		volume_val_label.text = " %d%%" % int(val * 100.0)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

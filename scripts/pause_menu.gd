extends CanvasLayer
class_name PauseMenu

## Menú de Pausa in-game con estética de videocámara Outlast / UTN Terror

var is_paused: bool = false
var typewriter_font: Font = null

# Referencias UI
var background_rect: ColorRect = null
var main_container: VBoxContainer = null
var settings_modal: PanelContainer = null
var guide_modal: PanelContainer = null
var active_modal: PanelContainer = null

# Controles de configuración
var master_vol_slider: HSlider = null
var master_vol_label: Label = null
var mouse_sens_slider: HSlider = null
var mouse_sens_label: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 125
	visible = false
	
	if ResourceLoader.exists("res://fonts/veteran_typewriter.ttf"):
		typewriter_font = load("res://fonts/veteran_typewriter.ttf")
		
	_build_ui()
	_build_modals()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		# Si hay un modal secundario abierto, cerrarlo primero
		if active_modal and active_modal.visible:
			_close_modal()
			get_viewport().set_input_as_handled()
			return
			
		# Verificar si el jugador está vivo o si el juego no terminó
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			# Si el panel de victoria está visible, ignorar
			var vic = hud.get_node_or_null("VictoryPanel")
			if vic and vic.visible:
				return
		
		toggle_pause(!is_paused)
		get_viewport().set_input_as_handled()

func toggle_pause(enable: bool) -> void:
	is_paused = enable
	visible = is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if active_modal:
			_close_modal()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _build_ui() -> void:
	# Fondo oscurecido con viñeta
	background_rect = ColorRect.new()
	background_rect.name = "BackgroundOverlay"
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.color = Color(0.02, 0.03, 0.05, 0.85)
	add_child(background_rect)
	
	# Indicadores de videocámara superior
	var top_hud = Control.new()
	top_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_hud)
	
	# Ícono de pausa superior izquierdo (dos barras grises grandes)
	var pause_icon_box = HBoxContainer.new()
	pause_icon_box.name = "PauseIcon"
	pause_icon_box.position = Vector2(40, 26)
	pause_icon_box.add_theme_constant_override("separation", 10)
	top_hud.add_child(pause_icon_box)
	
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.72, 0.75, 0.80, 0.90)
	bar_style.set_corner_radius_all(2)
	
	var bar1 = Panel.new()
	bar1.custom_minimum_size = Vector2(10, 32)
	bar1.add_theme_stylebox_override("panel", bar_style)
	pause_icon_box.add_child(bar1)
	
	var bar2 = Panel.new()
	bar2.custom_minimum_size = Vector2(10, 32)
	bar2.add_theme_stylebox_override("panel", bar_style)
	pause_icon_box.add_child(bar2)
	
	# Contenedor Central
	main_container = VBoxContainer.new()
	main_container.name = "MainBox"
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.custom_minimum_size = Vector2(440, 480)
	main_container.offset_left = -220.0
	main_container.offset_right = 220.0
	main_container.offset_top = -220.0
	main_container.offset_bottom = 260.0
	main_container.add_theme_constant_override("separation", 18)
	add_child(main_container)
	
	# Título de Pausa
	var title_lbl = Label.new()
	title_lbl.text = "PARTIDA EN PAUSA"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.95))
	title_lbl.add_theme_constant_override("outline_size", 3)
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	if typewriter_font:
		title_lbl.add_theme_font_override("font", typewriter_font)
	main_container.add_child(title_lbl)
	
	# Separador
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(380, 8)
	sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.3, 0.35, 0.45, 0.4)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	main_container.add_child(sep)
	
	# Botones
	var btn_box = VBoxContainer.new()
	btn_box.name = "PauseButtons"
	btn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_box.add_theme_constant_override("separation", 12)
	main_container.add_child(btn_box)
	
	var btn_resume = _create_pause_button("▶  REANUDAR PARTIDA")
	btn_resume.pressed.connect(func(): toggle_pause(false))
	btn_box.add_child(btn_resume)
	
	var btn_settings = _create_pause_button("⚙  AJUSTES Y AUDIO")
	btn_settings.pressed.connect(func(): _open_modal(settings_modal))
	btn_box.add_child(btn_settings)
	
	var btn_guide = _create_pause_button("📋  OBJETIVOS Y CONTROLES")
	btn_guide.pressed.connect(func(): _open_modal(guide_modal))
	btn_box.add_child(btn_guide)
	
	var btn_menu = _create_pause_button("🏛  VOLVER AL MENÚ PRINCIPAL")
	btn_menu.pressed.connect(_on_return_to_main_menu)
	btn_box.add_child(btn_menu)
	
	var btn_quit = _create_pause_button("✖  SALIR AL ESCRITORIO")
	btn_quit.pressed.connect(func(): get_tree().quit())
	btn_box.add_child(btn_quit)

func _create_pause_button(label_text: String) -> Button:
	var btn = Button.new()
	btn.text = label_text
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.custom_minimum_size = Vector2(360, 44)
	
	if typewriter_font:
		btn.add_theme_font_override("font", typewriter_font)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98, 0.88))
	btn.add_theme_color_override("font_hover_color", Color(0.96, 0.93, 0.68, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(0.96, 0.93, 0.68, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.05, 0.07, 0.11, 0.75)
	normal_style.border_color = Color(0.25, 0.32, 0.44, 0.65)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(3)
	normal_style.content_margin_left = 12
	normal_style.content_margin_right = 12
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.10, 0.14, 0.22, 0.92)
	hover_style.border_color = Color(0.96, 0.93, 0.68, 0.9)
	hover_style.set_border_width_all(1)
	hover_style.set_corner_radius_all(3)
	hover_style.content_margin_left = 12
	hover_style.content_margin_right = 12
	hover_style.content_margin_top = 8
	hover_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("focus", hover_style)
	
	return btn

func _build_modals() -> void:
	settings_modal = _create_modal_frame("AJUSTES Y SONIDO", Vector2(560, 420))
	_populate_settings_modal(settings_modal)
	add_child(settings_modal)
	
	guide_modal = _create_modal_frame("OBJETIVOS Y GUÍA", Vector2(660, 480))
	_populate_guide_modal(guide_modal)
	add_child(guide_modal)

func _create_modal_frame(title_text: String, size: Vector2) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = size
	panel.offset_left = -size.x / 2.0
	panel.offset_right = size.x / 2.0
	panel.offset_top = -size.y / 2.0
	panel.offset_bottom = size.y / 2.0
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.96)
	style.border_color = Color(0.35, 0.42, 0.55, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.name = "ModalVBox"
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	# Header del modal
	var header = HBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = ":: " + title_text
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 1.0))
	if typewriter_font:
		title_lbl.add_theme_font_override("font", typewriter_font)
	header.add_child(title_lbl)
	
	var btn_close = Button.new()
	btn_close.text = "✕ CERRAR"
	btn_close.custom_minimum_size = Vector2(90, 30)
	if typewriter_font:
		btn_close.add_theme_font_override("font", typewriter_font)
	btn_close.pressed.connect(_close_modal)
	header.add_child(btn_close)
	vbox.add_child(header)
	
	var sep = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.35, 0.4, 0.5, 0.5)
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)
	
	return panel

func _populate_settings_modal(panel: PanelContainer) -> void:
	var vbox = panel.get_node("ModalVBox") as VBoxContainer
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	vbox.add_child(content)
	
	# Volumen Master
	var vol_box = VBoxContainer.new()
	vol_box.add_theme_constant_override("separation", 6)
	var vol_header = HBoxContainer.new()
	var vol_title = Label.new()
	vol_title.text = "VOLUMEN PRINCIPAL (AUDIO):"
	vol_title.add_theme_font_size_override("font_size", 14)
	vol_title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.9))
	if typewriter_font:
		vol_title.add_theme_font_override("font", typewriter_font)
	vol_header.add_child(vol_title)
	
	master_vol_label = Label.new()
	master_vol_label.text = " 100%"
	master_vol_label.add_theme_font_size_override("font_size", 14)
	if typewriter_font:
		master_vol_label.add_theme_font_override("font", typewriter_font)
	vol_header.add_child(master_vol_label)
	vol_box.add_child(vol_header)
	
	master_vol_slider = HSlider.new()
	master_vol_slider.min_value = 0.0
	master_vol_slider.max_value = 1.0
	master_vol_slider.step = 0.05
	var master_bus = AudioServer.get_bus_index("Master")
	master_vol_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	master_vol_label.text = " %d%%" % int(master_vol_slider.value * 100)
	master_vol_slider.value_changed.connect(_on_master_volume_changed)
	vol_box.add_child(master_vol_slider)
	content.add_child(vol_box)
	
	# Sensibilidad del Mouse
	var sens_box = VBoxContainer.new()
	sens_box.add_theme_constant_override("separation", 6)
	var sens_header = HBoxContainer.new()
	var sens_title = Label.new()
	sens_title.text = "SENSIBILIDAD DEL RATÓN:"
	sens_title.add_theme_font_size_override("font_size", 14)
	sens_title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.9))
	if typewriter_font:
		sens_title.add_theme_font_override("font", typewriter_font)
	sens_header.add_child(sens_title)
	
	mouse_sens_label = Label.new()
	mouse_sens_label.text = " 100%"
	mouse_sens_label.add_theme_font_size_override("font_size", 14)
	if typewriter_font:
		mouse_sens_label.add_theme_font_override("font", typewriter_font)
	sens_header.add_child(mouse_sens_label)
	sens_box.add_child(sens_header)
	
	mouse_sens_slider = HSlider.new()
	mouse_sens_slider.min_value = 0.2
	mouse_sens_slider.max_value = 2.5
	mouse_sens_slider.step = 0.1
	mouse_sens_slider.value = 1.0
	mouse_sens_slider.value_changed.connect(_on_mouse_sens_changed)
	sens_box.add_child(mouse_sens_slider)
	content.add_child(sens_box)

func _populate_guide_modal(panel: PanelContainer) -> void:
	var vbox = panel.get_node("ModalVBox") as VBoxContainer
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	vbox.add_child(scroll)
	
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	
	var obj_title = Label.new()
	obj_title.text = "OBJETIVOS DE LA NOCHE DE FINALES:"
	obj_title.add_theme_font_size_override("font_size", 15)
	obj_title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 1.0))
	if typewriter_font:
		obj_title.add_theme_font_override("font", typewriter_font)
	content.add_child(obj_title)
	
	var steps = [
		"1. Rendí los 4 parciales matemáticos en los cuadernos de Planta Baja.",
		"2. Al completar los parciales ocurre un corte total de energía.",
		"3. Subí al Piso 1 (Bedelía General) a buscar el Fusible de Alta Tensión.",
		"4. Volvé al Laboratorio de Electrónica (PB) e insertá el fusible para restaurar la luz.",
		"5. ¡Esquivá al Profesor! Salí del laboratorio y buscá la Llave del Auditorio en el 2do Piso.",
		"6. Abrí el Auditorio en PB, retirá tu Título Universitario del estrado y escapá por la salida principal."
	]
	for s in steps:
		var lbl = Label.new()
		lbl.text = s
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.85))
		if typewriter_font:
			lbl.add_theme_font_override("font", typewriter_font)
		content.add_child(lbl)
		
	var ctrl_title = Label.new()
	ctrl_title.text = "\nCONTROLES DE SUPERVIVENCIA:"
	ctrl_title.add_theme_font_size_override("font_size", 15)
	ctrl_title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 1.0))
	if typewriter_font:
		ctrl_title.add_theme_font_override("font", typewriter_font)
	content.add_child(ctrl_title)
	
	var key_rows = [
		["WASD", "Moverse por la facultad"],
		["SHIFT", "Correr (consume estamina)"],
		["C / CTRL", "Agacharse / Esconderse en tachos"],
		["F / CLICK DER", "Visión Nocturna de la videocámara"],
		["E", "Interactuar / Recoger / Abrir"],
		["R", "Recargar batería de la videocámara (pilas AA)"],
		["Q", "Comer Peronachos (recupera estamina)"],
		["M", "Ver mapa institucional de pisos"],
		["ESC", "Menú de pausa / reanudar"]
	]
	for kr in key_rows:
		var h = HBoxContainer.new()
		var k_lbl = Label.new()
		k_lbl.text = kr[0]
		k_lbl.custom_minimum_size = Vector2(140, 0)
		k_lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.68, 0.9))
		k_lbl.add_theme_font_size_override("font_size", 13)
		if typewriter_font:
			k_lbl.add_theme_font_override("font", typewriter_font)
		h.add_child(k_lbl)
		
		var d_lbl = Label.new()
		d_lbl.text = kr[1]
		d_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.85))
		d_lbl.add_theme_font_size_override("font_size", 13)
		if typewriter_font:
			d_lbl.add_theme_font_override("font", typewriter_font)
		h.add_child(d_lbl)
		content.add_child(h)

func _open_modal(modal: PanelContainer) -> void:
	if active_modal:
		active_modal.visible = false
	active_modal = modal
	active_modal.visible = true
	main_container.visible = false

func _close_modal() -> void:
	if active_modal:
		active_modal.visible = false
		active_modal = null
	main_container.visible = true

func _on_master_volume_changed(val: float) -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	if val <= 0.01:
		AudioServer.set_bus_mute(master_bus, true)
	else:
		AudioServer.set_bus_mute(master_bus, false)
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(val))
	if master_vol_label:
		master_vol_label.text = " %d%%" % int(val * 100)

func _on_mouse_sens_changed(val: float) -> void:
	if mouse_sens_label:
		mouse_sens_label.text = " %d%%" % int(val * 100)
	var player = get_tree().root.find_child("Player", true, false)
	if player and "mouse_sensitivity" in player:
		player.mouse_sensitivity = 0.0025 * val

func _on_return_to_main_menu() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

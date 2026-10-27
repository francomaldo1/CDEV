extends CanvasLayer

@onready var mic_progress_bar: ProgressBar = $MicContainer/ProgressBar
@onready var mic_container: Control = $MicContainer
@onready var mic_icon: TextureRect = $MicContainer.get_node_or_null("MicIcon")
var current_mic_volume: float = 0.0
var is_mic_alert: bool = false
var is_mic_active_visible: bool = false
@onready var alert_label: Label = $AlertLabel
@onready var instruction_label: Label = $InstructionLabel
@onready var key_status_label: Label = $KeyStatusLabel
@onready var notification_banner: Label = $NotificationBanner
@onready var interact_prompt: Label = $InteractPrompt

@onready var math_panel: PanelContainer = $MathPanel
@onready var formula_label: Label = $MathPanel/Margin/VBox/FormulaLabel
@onready var btn_opt0: Button = $MathPanel/Margin/VBox/OptionsGrid/BtnOpt0
@onready var btn_opt1: Button = $MathPanel/Margin/VBox/OptionsGrid/BtnOpt1
@onready var btn_opt2: Button = $MathPanel/Margin/VBox/OptionsGrid/BtnOpt2
@onready var btn_opt3: Button = $MathPanel/Margin/VBox/OptionsGrid/BtnOpt3
@onready var btn_cancel: Button = $MathPanel/Margin/VBox/BtnCancel

@onready var victory_panel: ColorRect = $VictoryPanel
@onready var btn_restart: Button = $VictoryPanel/VBox/BtnRestart

var has_exit_key: bool = false
var has_fuse: bool = false
var has_auditorium_key: bool = false

var active_cuaderno: Node = null
var current_correct_answer: int = 0
var option_buttons: Array[Button] = []

var debug_coords_panel: PanelContainer = null
var debug_coords_label: Label = null
var show_debug_coords: bool = true
var last_coords_string: String = ""
var player_cached: CharacterBody3D = null

var inventory_container: HBoxContainer = null
var inventory_slots: Dictionary = {}
var exams_approved_count: int = 0
var exams_total_count: int = 4

## Interfaz de Videocámara Outlast
var camcorder_container: Control = null
var camcorder_rec_label: Label = null
var camcorder_nv_label: Label = null
var camcorder_battery_label: Label = null
var camcorder_battery_icon: Control = null
var camcorder_battery_container: Control = null
var camcorder_timecode_label: Label = null
var camcorder_rec_blink_timer: float = 0.0
var camcorder_time_elapsed: float = 0.0
var is_nv_active: bool = false
var nv_battery_pct: float = 100.0

func _ready() -> void:
	if alert_label:
		alert_label.visible = false
		alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if notification_banner:
		notification_banner.text = ""
		notification_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if interact_prompt:
		interact_prompt.text = ""
		interact_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if key_status_label:
		key_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if math_panel:
		math_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
		
	var crosshair = find_child("Crosshair", true, false) as Control
	if crosshair:
		crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if instruction_label:
		instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		instruction_label.visible = false
		instruction_label.text = ""
	if mic_container:
		mic_container.visible = is_mic_active_visible

	option_buttons = [btn_opt0, btn_opt1, btn_opt2, btn_opt3]
	for i in range(option_buttons.size()):
		if option_buttons[i]:
			option_buttons[i].mouse_filter = Control.MOUSE_FILTER_STOP
			# Desconectar si ya estaba conectado
			for conn in option_buttons[i].pressed.get_connections():
				option_buttons[i].pressed.disconnect(conn.callable)
			# Conexión directa y confiable
			option_buttons[i].pressed.connect(_on_option_selected.bind(i))

	if btn_cancel:
		btn_cancel.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_cancel.pressed.connect(_close_math_exam)
		
	if btn_restart:
		btn_restart.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_restart.pressed.connect(func(): get_tree().reload_current_scene())

	update_inventory_display()
	_setup_debug_coords()
	_setup_trash_overlay()
	_setup_stamina_bar()
	_setup_inventory_slots()
	_setup_camcorder_ui()
	_style_mic_bar()

func _style_mic_bar() -> void:
	if mic_icon:
		var img: Image = null
		if FileAccess.file_exists("res://textures/mic_icon.png"):
			img = Image.load_from_file("res://textures/mic_icon.png")
		elif FileAccess.file_exists("res://textures/mic_icon.svg"):
			img = Image.load_from_file("res://textures/mic_icon.svg")
		if img and not img.is_empty():
			mic_icon.texture = ImageTexture.create_from_image(img)
	
	if mic_progress_bar:
		# Fondo oscuro con marco blanco nítido tipo juego de terror
		var bg_box = StyleBoxFlat.new()
		bg_box.bg_color = Color(0.06, 0.06, 0.08, 0.8)
		bg_box.border_color = Color(1.0, 1.0, 1.0, 0.95)
		bg_box.set_border_width_all(1)
		bg_box.set_corner_radius_all(2)
		mic_progress_bar.add_theme_stylebox_override("background", bg_box)
		
		# Relleno blanco sólido
		var fill_box = StyleBoxFlat.new()
		fill_box.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		fill_box.set_corner_radius_all(1)
		mic_progress_bar.add_theme_stylebox_override("fill", fill_box)

func is_modal_active() -> bool:
	return (math_panel and math_panel.visible) or (victory_panel and victory_panel.visible)

func set_exams_progress(count: int, total: int = 4) -> void:
	exams_approved_count = count
	exams_total_count = total
	update_inventory_display()

func update_inventory_display() -> void:
	if key_status_label:
		var key_str = "CONSEGUIDO ✓" if has_exit_key else "Buscando..."
		var fuse_str = "EN MOCHILA ✓" if has_fuse else "No"
		var aud_str = "EN MOCHILA ✓" if has_auditorium_key else "No"
		var peronachos_str = "0"
		if is_instance_valid(player_cached) and player_cached.get("peronachos_count") != null:
			peronachos_str = str(player_cached.peronachos_count)
		else:
			var players = get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				player_cached = players[0] as CharacterBody3D
				if player_cached.get("peronachos_count") != null:
					peronachos_str = str(player_cached.peronachos_count)
		key_status_label.text = "🎓 TÍTULO: %s   |   ⚡ FUSIBLE: %s   |   🏛 LLAVE AUDITORIO: %s   |   🍟 PERONACHOS: %s [Q]" % [key_str, fuse_str, aud_str, peronachos_str]
		if has_exit_key:
			key_status_label.modulate = Color(0.3, 1.0, 0.5)
		else:
			key_status_label.modulate = Color(0.85, 0.85, 0.85)

	_update_inventory_slots()

func _setup_inventory_slots() -> void:
	if key_status_label:
		key_status_label.visible = false
		
	inventory_container = HBoxContainer.new()
	inventory_container.name = "InventorySlotsContainer"
	inventory_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	inventory_container.anchor_left = 0.5
	inventory_container.anchor_right = 0.5
	inventory_container.anchor_top = 1.0
	inventory_container.anchor_bottom = 1.0
	inventory_container.offset_left = -180.0
	inventory_container.offset_right = 180.0
	inventory_container.offset_top = -152.0
	inventory_container.offset_bottom = -102.0
	inventory_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inventory_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	inventory_container.alignment = BoxContainer.ALIGNMENT_CENTER
	inventory_container.add_theme_constant_override("separation", 8)
	add_child(inventory_container)
	
	var slot_defs = [
		{"key": "exams", "icon": "📝", "title": "PARCIALES", "default_val": "0/4"},
		{"key": "fuse", "icon": "⚡", "title": "FUSIBLE", "default_val": "VACÍO"},
		{"key": "key", "icon": "🏛", "title": "AUDITORIO", "default_val": "VACÍO"},
		{"key": "title", "icon": "🎓", "title": "TÍTULO", "default_val": "VACÍO"},
		{"key": "chips", "icon": "🍟", "title": "PERONACHOS", "default_val": "0 [Q]"}
	]
	
	for def in slot_defs:
		var slot_panel = PanelContainer.new()
		slot_panel.name = "Slot_" + def["key"]
		slot_panel.custom_minimum_size = Vector2(64, 62)
		slot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var margin = MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		slot_panel.add_child(margin)
		
		var vbox = VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 1)
		margin.add_child(vbox)
		
		var icon_lbl = Label.new()
		icon_lbl.name = "Icon"
		icon_lbl.text = def["icon"]
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 20)
		icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon_lbl)
		
		var title_lbl = Label.new()
		title_lbl.name = "Title"
		title_lbl.text = def["title"]
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_font_size_override("font_size", 8)
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(title_lbl)
		
		var val_lbl = Label.new()
		val_lbl.name = "Value"
		val_lbl.text = def["default_val"]
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_lbl.add_theme_font_size_override("font_size", 9)
		val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(val_lbl)
		
		inventory_container.add_child(slot_panel)
		inventory_slots[def["key"]] = {
			"panel": slot_panel,
			"icon": icon_lbl,
			"title": title_lbl,
			"value": val_lbl
		}
		
	_update_inventory_slots()

func _update_inventory_slots() -> void:
	if inventory_slots.is_empty():
		return
		
	# 1. Parciales
	var s_exams = inventory_slots["exams"]
	var exams_done = (exams_approved_count >= exams_total_count)
	s_exams["value"].text = "%d/%d ✓" % [exams_approved_count, exams_total_count] if exams_done else "%d/%d" % [exams_approved_count, exams_total_count]
	_apply_slot_style(s_exams, exams_approved_count > 0, exams_done, Color(0.2, 1.0, 0.5) if exams_done else Color(0.3, 0.85, 1.0))

	# 2. Fusible
	var s_fuse = inventory_slots["fuse"]
	_apply_slot_style(s_fuse, has_fuse, has_fuse, Color(1.0, 0.9, 0.2))
	s_fuse["value"].text = "30A ✓" if has_fuse else "VACÍO"

	# 3. Llave Auditorio
	var s_key = inventory_slots["key"]
	_apply_slot_style(s_key, has_auditorium_key, has_auditorium_key, Color(1.0, 0.85, 0.35))
	s_key["value"].text = "LLAVE ✓" if has_auditorium_key else "VACÍO"

	# 4. Título Universitario
	var s_title = inventory_slots["title"]
	_apply_slot_style(s_title, has_exit_key, has_exit_key, Color(0.3, 1.0, 0.55))
	s_title["value"].text = "SALIDA ✓" if has_exit_key else "VACÍO"

	# 5. Peronachos
	var s_chips = inventory_slots["chips"]
	var count = 0
	if is_instance_valid(player_cached) and player_cached.get("peronachos_count") != null:
		count = player_cached.peronachos_count
	else:
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_cached = players[0] as CharacterBody3D
			if player_cached.get("peronachos_count") != null:
				count = player_cached.peronachos_count
				
	var has_chips = (count > 0)
	_apply_slot_style(s_chips, has_chips, has_chips, Color(1.0, 0.75, 0.2))
	s_chips["value"].text = "x%d [Q]" % count if has_chips else "0 [Q]"

func _apply_slot_style(slot_data: Dictionary, is_active: bool, is_highlighted: bool, accent_color: Color) -> void:
	var panel: PanelContainer = slot_data["panel"]
	var icon: Label = slot_data["icon"]
	var title: Label = slot_data["title"]
	var val: Label = slot_data["value"]
	
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(5)
	
	if is_active:
		style.bg_color = Color(0.08, 0.11, 0.16, 0.92)
		style.border_color = accent_color if is_highlighted else Color(0.95, 0.95, 1.0, 0.9)
		style.set_border_width_all(2)
		icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
		title.modulate = Color(1.0, 1.0, 1.0, 0.9)
		val.modulate = accent_color
	else:
		style.bg_color = Color(0.04, 0.05, 0.07, 0.65)
		style.border_color = Color(0.28, 0.32, 0.40, 0.40)
		style.set_border_width_all(1)
		icon.modulate = Color(0.5, 0.55, 0.65, 0.30)
		title.modulate = Color(0.5, 0.55, 0.65, 0.40)
		val.modulate = Color(0.45, 0.5, 0.6, 0.45)
		
	panel.add_theme_stylebox_override("panel", style)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if math_panel and math_panel.visible:
			_close_math_exam()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			toggle_debug_cheats_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F3:
			show_debug_coords = not show_debug_coords
			if debug_coords_panel:
				debug_coords_panel.visible = show_debug_coords
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F2:
			if last_coords_string != "":
				DisplayServer.clipboard_set(last_coords_string)
				show_temporary_alert("📋 ¡Copiado al portapapeles! " + last_coords_string, Color(0.3, 1.0, 0.6))
				get_viewport().set_input_as_handled()

func set_interact_prompt(text_msg: String) -> void:
	if interact_prompt:
		interact_prompt.text = text_msg

func show_temporary_alert(text_msg: String, color: Color = Color(1.0, 0.3, 0.3)) -> void:
	if notification_banner:
		notification_banner.text = text_msg
		notification_banner.modulate = color
		get_tree().create_timer(4.5).timeout.connect(func():
			if is_instance_valid(notification_banner) and notification_banner.text == text_msg:
				notification_banner.text = ""
		)

func set_mic_visible(vis: bool) -> void:
	is_mic_active_visible = vis
	if mic_container:
		mic_container.visible = vis
	if not vis:
		current_mic_volume = 0.0
		is_mic_alert = false

func on_mic_volume_updated(volume: float, is_alert: bool) -> void:
	current_mic_volume = volume
	is_mic_alert = is_alert

## =====================================================================
## DESAFÍO MATEMÁTICO
## =====================================================================
func open_math_exam(cuaderno: Node) -> void:
	active_cuaderno = cuaderno
	
	# Generar problema matemático al azar
	var op_type = randi() % 3
	var a = randi_range(6, 12)
	var b = randi_range(4, 9)
	var c = randi_range(5, 25)
	
	var formula_str = ""
	match op_type:
		0:
			current_correct_answer = (a * b) - c
			formula_str = "%d × %d - %d = ?" % [a, b, c]
		1:
			current_correct_answer = a + (b * 5)
			formula_str = "%d + (%d × 5) = ?" % [a, b]
		2:
			current_correct_answer = (a * 4) + c
			formula_str = "(%d × 4) + %d = ?" % [a, c]

	if formula_label:
		formula_label.text = formula_str

	# Generar 3 opciones incorrectas distintas
	var choices: Array[int] = [current_correct_answer]
	var offsets = [-10, -5, -3, 3, 5, 8, 12, 15]
	offsets.shuffle()
	
	for off in offsets:
		var false_val = current_correct_answer + off
		if false_val != current_correct_answer and not false_val in choices:
			choices.append(false_val)
			if choices.size() >= 4:
				break
				
	choices.shuffle()
	
	for i in range(option_buttons.size()):
		if i < choices.size() and option_buttons[i]:
			var val = choices[i]
			option_buttons[i].text = "%s)   %d" % [["A", "B", "C", "D"][i], val]
			option_buttons[i].set_meta("value", val)

	if math_panel:
		math_panel.visible = true
		
	# Liberar el mouse para hacer clic en las opciones
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_option_selected(btn_index: int) -> void:
	if not option_buttons[btn_index]:
		return
		
	var chosen_val: int = option_buttons[btn_index].get_meta("value", -9999)
	var is_correct = (chosen_val == current_correct_answer)
	
	_close_math_exam()
	
	if is_correct:
		show_temporary_alert("✅ ¡PARCIAL APROBADO!", Color(0.2, 1.0, 0.4))
		
		if active_cuaderno and active_cuaderno.has_method("on_exam_result"):
			active_cuaderno.on_exam_result(true)
	else:
		show_temporary_alert("❌ ¡PARCIAL DESAPROBADO! El profesor se enfureció y aumentó su velocidad.", Color(1.0, 0.2, 0.2))
		
		if active_cuaderno and active_cuaderno.has_method("on_exam_result"):
			active_cuaderno.on_exam_result(false)
			
		var prof = get_tree().root.find_child("Profesor", true, false)
		if prof and prof.has_method("boost_speed"):
			prof.boost_speed()

func _close_math_exam() -> void:
	if math_panel:
		math_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func trigger_victory_screen() -> void:
	if victory_panel:
		victory_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


var stamina_container: HBoxContainer = null
var stamina_progress_bar: ProgressBar = null
var stamina_fill_box: StyleBoxFlat = null
var stamina_alpha: float = 0.0
var stamina_full_timer: float = 0.0

func _process(delta: float) -> void:
	_process_mic_bar(delta)
	_process_camcorder_ui(delta)
	_process_stamina_bar(delta)
	_process_debug_coords(delta)

func _setup_stamina_bar() -> void:
	stamina_container = HBoxContainer.new()
	stamina_container.name = "StaminaContainer"
	stamina_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamina_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	# Ubicado justo arriba de la barra de micrófono
	# MicContainer está en offset_top = -68, offset_bottom = -46
	# Colocamos StaminaContainer en offset_top = -94, offset_bottom = -76
	stamina_container.anchor_left = 0.5
	stamina_container.anchor_right = 0.5
	stamina_container.anchor_top = 1.0
	stamina_container.anchor_bottom = 1.0
	stamina_container.offset_left = -140.0
	stamina_container.offset_right = 140.0
	stamina_container.offset_top = -94.0
	stamina_container.offset_bottom = -76.0
	stamina_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	stamina_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	stamina_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stamina_container.add_theme_constant_override("separation", 8)
	stamina_container.modulate = Color(1.0, 1.0, 1.0, 0.0) # Empieza invisible
	
	# Barra de progreso
	stamina_progress_bar = ProgressBar.new()
	stamina_progress_bar.name = "StaminaProgressBar"
	stamina_progress_bar.custom_minimum_size = Vector2(230, 12)
	stamina_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stamina_progress_bar.show_percentage = false
	stamina_progress_bar.max_value = 100.0
	stamina_progress_bar.value = 100.0
	stamina_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var bg_box = StyleBoxFlat.new()
	bg_box.bg_color = Color(0.06, 0.06, 0.08, 0.8)
	bg_box.border_color = Color(1.0, 1.0, 1.0, 0.9)
	bg_box.set_border_width_all(1)
	bg_box.set_corner_radius_all(2)
	stamina_progress_bar.add_theme_stylebox_override("background", bg_box)
	
	stamina_fill_box = StyleBoxFlat.new()
	stamina_fill_box.bg_color = Color(1.0, 1.0, 1.0)
	stamina_fill_box.set_corner_radius_all(1)
	stamina_progress_bar.add_theme_stylebox_override("fill", stamina_fill_box)
	
	stamina_container.add_child(stamina_progress_bar)
	add_child(stamina_container)

func _process_stamina_bar(delta: float) -> void:
	if not stamina_container or not stamina_progress_bar:
		return
		
	if not is_instance_valid(player_cached):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_cached = players[0] as CharacterBody3D
			
	if not is_instance_valid(player_cached):
		return
		
	var cur_stamina = player_cached.get("current_stamina")
	var max_stamina = player_cached.get("max_stamina")
	var is_sprint = player_cached.get("is_sprinting")
	var is_exhausted = player_cached.get("stamina_exhausted")
	
	if cur_stamina == null or max_stamina == null:
		return
		
	var pct = clampf((cur_stamina / max_stamina) * 100.0, 0.0, 100.0)
	stamina_progress_bar.value = pct
	
	# Mostrar si está corriendo o si no tiene la estamina al 100%
	var should_show = is_sprint or (cur_stamina < max_stamina - 0.5)
	if should_show:
		stamina_full_timer = 0.0
		stamina_alpha = lerpf(stamina_alpha, 1.0, delta * 7.0)
	else:
		stamina_full_timer += delta
		if stamina_full_timer > 0.8: # Tras 0.8s de estar llena, desvanecer suavemente
			stamina_alpha = lerpf(stamina_alpha, 0.0, delta * 3.0)
			
	stamina_container.modulate.a = stamina_alpha
	
	# Modulación de color según nivel de estamina (Blanco por defecto)
	if is_exhausted:
		# Pulso de agotamiento en rojo parpadeante
		var pulse = (sin(Time.get_ticks_msec() * 0.015) * 0.5 + 0.5)
		stamina_fill_box.bg_color = lerp(Color(0.9, 0.1, 0.1), Color(1.0, 0.4, 0.4), pulse)
	elif pct < 20.0:
		stamina_fill_box.bg_color = Color(1.0, 0.85, 0.85) # Sutil alerta
	else:
		stamina_fill_box.bg_color = Color(1.0, 1.0, 1.0) # Blanco puro

func _process_mic_bar(_delta: float) -> void:
	if not mic_container or not mic_container.visible:
		return
		
	# Sube y baja constante y sutil (idle breathing) para que el jugador sepa que el mic está activo
	var idle_wave: float = (sin(Time.get_ticks_msec() * 0.0035) * 0.5 + 0.5) * 0.045 + 0.015
	var display_vol: float = maxf(current_mic_volume, idle_wave)
	
	if mic_progress_bar:
		mic_progress_bar.value = display_vol * 100.0
		
		if is_mic_alert:
			mic_progress_bar.modulate = Color(1.0, 0.2, 0.2)
			if mic_icon:
				mic_icon.modulate = Color(1.0, 0.2, 0.2)
		elif display_vol > 0.45:
			mic_progress_bar.modulate = Color(1.0, 0.75, 0.2)
			if mic_icon:
				mic_icon.modulate = Color(1.0, 0.75, 0.2)
		else:
			mic_progress_bar.modulate = Color(1.0, 1.0, 1.0)
			if mic_icon:
				mic_icon.modulate = Color(1.0, 1.0, 1.0)

func _process_debug_coords(_delta: float) -> void:
	if not show_debug_coords or not debug_coords_label:
		return
		
	if not is_instance_valid(player_cached):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_cached = players[0] as CharacterBody3D
			
	if not is_instance_valid(player_cached):
		return
		
	var p = player_cached.global_position
	
	var piso = "PB"
	if p.y >= 7.0:
		piso = "Segundo Piso (P2)"
	elif p.y >= 2.5:
		piso = "Primer Piso (P1)"
	else:
		piso = "Planta Baja (PB)"
		
	var cam = player_cached.find_child("Camera3D", true, false) as Camera3D
	var heading = "Norte"
	if cam:
		var fwd = -cam.global_transform.basis.z
		if absf(fwd.z) > absf(fwd.x):
			heading = "Sur (+Z)" if fwd.z > 0 else "Norte (-Z)"
		else:
			heading = "Este (+X)" if fwd.x > 0 else "Oeste (-X)"
			
	last_coords_string = "X: %.1f, Y: %.1f, Z: %.1f (%s)" % [p.x, p.y, p.z, piso]
	
	debug_coords_label.text = "📍 Pos: X: %.1f  Y: %.1f  Z: %.1f\n🏢 %s | Mirando: %s\n⌨️ [F1] Cheats | [F2] Copiar | [F3] Ocultar" % [
		p.x, p.y, p.z, piso, heading
	]

var debug_cheats_panel: PanelContainer = null

func toggle_debug_cheats_panel() -> void:
	if not debug_cheats_panel:
		_setup_debug_cheats_panel()
	debug_cheats_panel.visible = not debug_cheats_panel.visible

func _setup_debug_cheats_panel() -> void:
	debug_cheats_panel = PanelContainer.new()
	debug_cheats_panel.name = "DebugCheatsPanel"
	debug_cheats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.10, 0.94)
	style.border_color = Color(0.2, 0.75, 1.0, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	debug_cheats_panel.add_theme_stylebox_override("panel", style)
	
	debug_cheats_panel.set_anchors_preset(Control.PRESET_CENTER)
	debug_cheats_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	debug_cheats_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var lbl = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.text = "🛠️ ATAJOS DE TESTING RÁPIDO (MODO DEBUG)\n\n" + \
		"  [F4]  📍 Teleport a Primer Piso (P1) frente a Bedelía\n" + \
		"  [F5]  ⚡ Activar Apagón inmediato y Obtener Fusible de 10A\n" + \
		"  [F6]  💡 Teleport a Tablero Eléctrico (con Fusible listo para colocar [E])\n" + \
		"  [F7]  🍟 Teleport a Cafetería PB (Estantes de Peronachos)\n" + \
		"  [F8]  🎓 Aprobar todos los Parciales y Desbloquear Accesos\n" + \
		"  [F9]  🧊 Congelar / Descongelar al Profesor (para probar sin peligro)\n" + \
		"  [F10] 📼 Alternar Filtro Retro Fears to Fathom (Dithering + Color Cuantizado)\n" + \
		"  [F2]  📋 Copiar coordenadas exactas al portapapeles\n" + \
		"  [F3]  👁️ Ocultar / Mostrar visor de coordenadas\n" + \
		"  [F1]  ❌ Cerrar esta ventana de ayuda"
	lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	
	debug_cheats_panel.add_child(lbl)
	add_child(debug_cheats_panel)

func _setup_debug_coords() -> void:
	debug_coords_panel = PanelContainer.new()
	debug_coords_panel.name = "DebugCoordsPanel"
	debug_coords_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.8)
	style.border_color = Color(0.25, 0.45, 0.75, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	debug_coords_panel.add_theme_stylebox_override("panel", style)
	
	debug_coords_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	debug_coords_panel.offset_left = -300.0
	debug_coords_panel.offset_right = -20.0
	debug_coords_panel.offset_top = 68.0
	debug_coords_panel.offset_bottom = 133.0
	debug_coords_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	
	debug_coords_label = Label.new()
	debug_coords_label.name = "CoordsLabel"
	debug_coords_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_coords_label.add_theme_font_size_override("font_size", 13)
	debug_coords_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	debug_coords_label.text = "📍 Coordenadas: cargando..."
	
	debug_coords_panel.add_child(debug_coords_label)
	add_child(debug_coords_panel)


var trash_overlay: Control = null
var is_trash_overlay_active: bool = false

func set_trash_overlay_visible(_is_vis: bool) -> void:
	# La vista de espiar ahora se hace 100% a través del modelo 3D real del tacho
	pass

func _setup_trash_overlay() -> void:
	# No se dibuja ninguna interfaz 2D artificial para espiar
	pass

func update_trash_overlay_parallax(_yaw_ratio: float, _pitch_ratio: float) -> void:
	pass


func _setup_camcorder_ui() -> void:
	camcorder_container = Control.new()
	camcorder_container.name = "CamcorderUI"
	camcorder_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	camcorder_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(camcorder_container)
	
	# Top Left: REC
	camcorder_rec_label = Label.new()
	camcorder_rec_label.text = "● REC   SP"
	camcorder_rec_label.position = Vector2(30, 25)
	camcorder_rec_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 0.9))
	camcorder_rec_label.add_theme_font_size_override("font_size", 16)
	camcorder_container.add_child(camcorder_rec_label)
	
	# Top Right: NIGHT VISION + BATERIA (Icono gráfico según referencia)
	camcorder_nv_label = Label.new()
	camcorder_nv_label.text = "[Click Der / F] VISIÓN NOCTURNA: OFF"
	camcorder_nv_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	camcorder_nv_label.position = Vector2(-390, 24)
	camcorder_nv_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 0.75))
	camcorder_nv_label.add_theme_font_size_override("font_size", 13)
	camcorder_container.add_child(camcorder_nv_label)
	
	var battery_box = HBoxContainer.new()
	battery_box.name = "BatteryBox"
	battery_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	battery_box.position = Vector2(-125, 20)
	battery_box.add_theme_constant_override("separation", 8)
	
	camcorder_battery_icon = Control.new()
	camcorder_battery_icon.custom_minimum_size = Vector2(46, 22)
	camcorder_battery_icon.draw.connect(_on_battery_icon_draw)
	battery_box.add_child(camcorder_battery_icon)
	
	camcorder_battery_label = Label.new()
	camcorder_battery_label.text = "100%"
	camcorder_battery_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.85))
	camcorder_battery_label.add_theme_font_size_override("font_size", 13)
	battery_box.add_child(camcorder_battery_label)
	
	camcorder_container.add_child(battery_box)
	
	# Bottom Left: Timecode y cámara
	camcorder_timecode_label = Label.new()
	camcorder_timecode_label.text = "CAM 01 - UTN FRC | 00:00:00"
	camcorder_timecode_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	camcorder_timecode_label.position = Vector2(30, -45)
	camcorder_timecode_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.6))
	camcorder_timecode_label.add_theme_font_size_override("font_size", 13)
	camcorder_container.add_child(camcorder_timecode_label)

func set_night_vision_active(active: bool) -> void:
	is_nv_active = active
	if camcorder_nv_label:
		if is_nv_active:
			camcorder_nv_label.text = "NIGHT VISION [ ACTIVE ]"
			camcorder_nv_label.add_theme_color_override("font_color", Color(0.55, 0.92, 0.72, 0.95))
		else:
			camcorder_nv_label.text = "[Click Der / F] VISIÓN NOCTURNA: OFF"
			camcorder_nv_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 0.65))
	if camcorder_battery_icon:
		camcorder_battery_icon.queue_redraw()

func set_night_vision_battery(pct: float) -> void:
	nv_battery_pct = pct
	if camcorder_battery_label:
		camcorder_battery_label.text = "%d%%" % int(pct)
		if pct <= 20.0:
			camcorder_battery_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2, 0.95))
		elif is_nv_active:
			camcorder_battery_label.add_theme_color_override("font_color", Color(0.55, 0.92, 0.72, 0.95))
		else:
			camcorder_battery_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 0.7))
	if camcorder_battery_icon:
		camcorder_battery_icon.queue_redraw()

func _on_battery_icon_draw() -> void:
	if not camcorder_battery_icon:
		return
		
	var col = Color(0.85, 0.92, 0.96, 0.88)
	if nv_battery_pct <= 20.0:
		var blink = int(camcorder_rec_blink_timer * 3.5) % 2 == 0
		col = Color(1.0, 0.25, 0.2, 0.95) if blink else Color(0.55, 0.15, 0.15, 0.45)
	elif is_nv_active:
		col = Color(0.35, 1.0, 0.55, 0.95)
		
	# 1. Contorno principal rectangular de la batería
	var border_w = 2.5
	camcorder_battery_icon.draw_rect(Rect2(0, 1, 40, 20), col, false, border_w)
	
	# 2. Terminal positivo sobresaliente en el lateral derecho
	camcorder_battery_icon.draw_rect(Rect2(40, 6, 4, 10), col, true)
	
	# 3. Barras de carga internas (3 barras proporcionales según imagen de referencia)
	var bars = 0
	if nv_battery_pct > 66.0:
		bars = 3
	elif nv_battery_pct > 33.0:
		bars = 2
	elif nv_battery_pct > 1.0:
		bars = 1
	else:
		bars = 0
		
	var bar_w = 8.5
	var bar_h = 13.0
	var bar_y = 4.5
	var start_x = 4.0
	var gap = 3.5
	
	for i in range(bars):
		var bx = start_x + i * (bar_w + gap)
		camcorder_battery_icon.draw_rect(Rect2(bx, bar_y, bar_w, bar_h), col, true)

func _process_camcorder_ui(delta: float) -> void:
	if not camcorder_container:
		return
	camcorder_time_elapsed += delta
	camcorder_rec_blink_timer += delta
	
	if camcorder_rec_label:
		var is_rec_vis = fmod(camcorder_rec_blink_timer, 1.2) < 0.75
		camcorder_rec_label.visible = is_rec_vis
		
	if nv_battery_pct <= 20.0 and camcorder_battery_icon:
		camcorder_battery_icon.queue_redraw()
	
	if camcorder_timecode_label:
		var s = int(camcorder_time_elapsed) % 60
		var m = int(camcorder_time_elapsed / 60.0) % 60
		var h = int(camcorder_time_elapsed / 3600.0)
		camcorder_timecode_label.text = "CAM 01 - UTN FRC | %02d:%02d:%02d" % [h, m, s]

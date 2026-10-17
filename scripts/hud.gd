extends CanvasLayer

@onready var mic_progress_bar: ProgressBar = $MicContainer/ProgressBar
@onready var mic_label: Label = $MicContainer/MicLabel
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

var active_cuaderno: Node = null
var current_correct_answer: int = 0
var option_buttons: Array[Button] = []

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
		instruction_label.text = "[W,A,S,D] Caminar | [Shift] Correr | [F] Linterna | [E] Interactuar | [ESC] Cursor"

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

func is_modal_active() -> bool:
	return (math_panel and math_panel.visible) or (victory_panel and victory_panel.visible)

func update_inventory_display() -> void:
	if key_status_label:
		var key_str = "CONSEGUIDA ✓" if has_exit_key else "Buscando..."
		var fuse_str = "EN MOCHILA ✓" if has_fuse else "No"
		key_status_label.text = "🔑 LLAVE: %s   |   ⚡ FUSIBLE: %s" % [key_str, fuse_str]
		if has_exit_key:
			key_status_label.modulate = Color(0.3, 1.0, 0.5)
		else:
			key_status_label.modulate = Color(0.85, 0.85, 0.85)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if math_panel and math_panel.visible:
			_close_math_exam()
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

func on_mic_volume_updated(volume: float, is_alert: bool) -> void:
	if mic_progress_bar:
		mic_progress_bar.value = volume * 100.0
		
		if is_alert:
			mic_progress_bar.modulate = Color(1.0, 0.2, 0.2)
			if alert_label:
				alert_label.visible = true
				alert_label.text = "¡PELIGRO: HACES DEMASIADO RUIDO!"
		elif volume > 0.4:
			mic_progress_bar.modulate = Color(1.0, 0.8, 0.2)
			if alert_label:
				alert_label.visible = false
		else:
			mic_progress_bar.modulate = Color(0.2, 1.0, 0.4)
			if alert_label:
				alert_label.visible = false

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
		has_exit_key = true
		update_inventory_display()
		show_temporary_alert("✅ ¡PARCIAL APROBADO! Obtuviste la LLAVE DE SALIDA. Corre a la puerta principal.", Color(0.2, 1.0, 0.4))
		
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

extends CanvasLayer
class_name UICandado

signal code_entered(success: bool)
signal ui_closed

@onready var digit_labels: Array[Label] = [
	$Backdrop/MainPanel/Margin/VBox/DialsContainer/Col0/DigitPanel0/DigitLabel0,
	$Backdrop/MainPanel/Margin/VBox/DialsContainer/Col1/DigitPanel1/DigitLabel1,
	$Backdrop/MainPanel/Margin/VBox/DialsContainer/Col2/DigitPanel2/DigitLabel2
]

@onready var btn_up_list: Array[Button] = [
	$Backdrop/MainPanel/Margin/VBox/DialsContainer/Col0/BtnUp0,
	$Backdrop/MainPanel/Margin/VBox/DialsContainer/Col1/BtnUp1,
	$Backdrop/MainPanel/Margin/VBox/DialsContainer/Col2/BtnUp2
]

@onready var btn_down_list: Array[Button] = [
	$Backdrop/MainPanel/Margin/VBox/DialsContainer/Col0/BtnDown0,
	$Backdrop/MainPanel/Margin/VBox/DialsContainer/Col1/BtnDown1,
	$Backdrop/MainPanel/Margin/VBox/DialsContainer/Col2/BtnDown2
]

@onready var feedback_label: Label = $Backdrop/MainPanel/Margin/VBox/FeedbackLabel
@onready var btn_unlock: Button = $Backdrop/MainPanel/Margin/VBox/ButtonsBox/BtnUnlock
@onready var btn_close: Button = $Backdrop/MainPanel/Margin/VBox/ButtonsBox/BtnClose
@onready var main_panel: PanelContainer = $Backdrop/MainPanel

var target_code: String = "742"
var current_digits: Array[int] = [0, 0, 0]
var is_busy: bool = false
var audio_player: AudioStreamPlayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = &"Master"
	add_child(audio_player)
	
	for i in range(3):
		var idx = i
		btn_up_list[idx].pressed.connect(func(): _change_digit(idx, 1))
		btn_down_list[idx].pressed.connect(func(): _change_digit(idx, -1))
		
	btn_unlock.pressed.connect(_on_unlock_pressed)
	btn_close.pressed.connect(_close_ui)
	
	_update_display()

func open_lock(code: String) -> void:
	target_code = code
	current_digits = [0, 0, 0]
	is_busy = false
	visible = true
	_update_display()
	feedback_label.text = "INGRESE EL CÓDIGO DE 3 DÍGITOS"
	feedback_label.modulate = Color(0.7, 0.8, 0.9)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _change_digit(col_idx: int, delta: int) -> void:
	if is_busy:
		return
	current_digits[col_idx] = (current_digits[col_idx] + delta + 10) % 10
	_play_click_sfx()
	_update_display()

func _update_display() -> void:
	for i in range(3):
		if i < digit_labels.size() and digit_labels[i]:
			digit_labels[i].text = str(current_digits[i])

func _unhandled_input(event: InputEvent) -> void:
	if not visible or is_busy:
		return
		
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_close_ui()
		get_viewport().set_input_as_handled()
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_0 and event.keycode <= KEY_9:
			var num = event.keycode - KEY_0
			# Desplazar dígitos a la izquierda e insertar a la derecha
			current_digits[0] = current_digits[1]
			current_digits[1] = current_digits[2]
			current_digits[2] = num
			_play_click_sfx()
			_update_display()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_unlock_pressed()
			get_viewport().set_input_as_handled()

func _on_unlock_pressed() -> void:
	if is_busy:
		return
		
	var entered = "%d%d%d" % [current_digits[0], current_digits[1], current_digits[2]]
	if entered == target_code:
		_handle_success()
	else:
		_handle_error()

func _handle_success() -> void:
	is_busy = true
	feedback_label.text = "✓ ACCESO CONCEDIDO - DESBLOQUEANDO..."
	feedback_label.modulate = Color(0.2, 1.0, 0.4)
	
	_play_unlock_sfx()
	code_entered.emit(true)
	
	get_tree().create_timer(0.9).timeout.connect(func():
		_close_ui()
	)

func _handle_error() -> void:
	feedback_label.text = "❌ CÓDIGO INCORRECTO"
	feedback_label.modulate = Color(1.0, 0.25, 0.25)
	
	_play_error_sfx()
	_shake_panel()
	code_entered.emit(false)

func _shake_panel() -> void:
	if not main_panel:
		return
	var orig_x = main_panel.position.x
	var tw = create_tween()
	tw.tween_property(main_panel, "position:x", orig_x - 12.0, 0.05)
	tw.tween_property(main_panel, "position:x", orig_x + 12.0, 0.05)
	tw.tween_property(main_panel, "position:x", orig_x - 6.0, 0.04)
	tw.tween_property(main_panel, "position:x", orig_x + 6.0, 0.04)
	tw.tween_property(main_panel, "position:x", orig_x, 0.04)

func _close_ui() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("set_frozen"):
		player.set_frozen(false)
	ui_closed.emit()

func _play_click_sfx() -> void:
	if not audio_player:
		return
	var sfx_path = "res://audio/sfx/typewriter_click.wav"
	if ResourceLoader.exists(sfx_path):
		audio_player.stream = load(sfx_path)
		audio_player.pitch_scale = randf_range(1.1, 1.3)
		audio_player.volume_db = -2.0
		audio_player.play()

func _play_error_sfx() -> void:
	if not audio_player:
		return
	var horror_audio = load("res://scripts/horror_audio.gd")
	if horror_audio and horror_audio.has_method("get_door_rattle_sound"):
		audio_player.stream = horror_audio.get_door_rattle_sound()
		audio_player.pitch_scale = 0.95
		audio_player.volume_db = 2.0
		audio_player.play()

func _play_unlock_sfx() -> void:
	if not audio_player:
		return
	var horror_audio = load("res://scripts/horror_audio.gd")
	if horror_audio and horror_audio.has_method("get_door_unlock_sound"):
		audio_player.stream = horror_audio.get_door_unlock_sound()
		audio_player.pitch_scale = 1.05
		audio_player.volume_db = 3.0
		audio_player.play()

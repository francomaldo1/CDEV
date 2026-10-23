extends Area3D
class_name TachoBasura

signal player_entered_hiding
signal player_exited_hiding

@export var is_occupied: bool = false

@onready var hide_pos: Marker3D = $HidePoint
@onready var exit_pos: Marker3D = $ExitPoint
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var is_player_nearby: bool = false
var player_ref: CharacterBody3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if audio_player:
		audio_player.unit_size = 3.0
		audio_player.max_distance = 25.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E and not event.echo):
		if is_occupied:
			exit_trashcan()
			get_viewport().set_input_as_handled()
		elif is_player_nearby and is_instance_valid(player_ref) and not player_ref.get("is_hidden"):
			enter_trashcan()
			get_viewport().set_input_as_handled()

func enter_trashcan() -> void:
	if is_occupied or not is_instance_valid(player_ref):
		return
	is_occupied = true
	
	# Reproducir sonido de contenedor metálico
	if audio_player:
		audio_player.stream = HorrorAudio.get_trashcan_sound(true)
		audio_player.play()
		
	var target_pos = hide_pos.global_position if hide_pos else global_position + Vector3(0, 0.05, 0)
	var forward_dir = -global_transform.basis.z # hacia donde mira el frente del tacho
	
	if player_ref.has_method("enter_hiding"):
		player_ref.enter_hiding(self, target_pos, forward_dir)
	
	# Activar micrófono y UI
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud:
		hud.set_interact_prompt("[E] Salir del tacho de basura")
		if hud.has_method("set_mic_visible"):
			hud.set_mic_visible(true)
		
	var mic = get_tree().root.find_child("MicDetector", true, false)
	if mic and mic.has_method("set_mic_active"):
		mic.set_mic_active(true)
		
	player_entered_hiding.emit()

func exit_trashcan() -> void:
	if not is_occupied or not is_instance_valid(player_ref):
		return
	is_occupied = false
	
	if audio_player:
		audio_player.stream = HorrorAudio.get_trashcan_sound(false)
		audio_player.play()
		
	var out_pos = exit_pos.global_position if exit_pos else global_position + global_transform.basis.z * 1.1
	if player_ref.has_method("exit_hiding"):
		player_ref.exit_hiding(out_pos)
	
	# Desactivar micrófono y UI
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud:
		if hud.has_method("set_mic_visible"):
			hud.set_mic_visible(false)
		if is_player_nearby:
			hud.set_interact_prompt("[E] Esconderse en el tacho de basura")
		else:
			hud.set_interact_prompt("")
			
	var mic = get_tree().root.find_child("MicDetector", true, false)
	if mic and mic.has_method("set_mic_active"):
		mic.set_mic_active(false)
		
	player_exited_hiding.emit()

func force_eject() -> void:
	if is_occupied:
		exit_trashcan()

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and (body.is_in_group("player") or body.name == "Player"):
		is_player_nearby = true
		player_ref = body
		if not is_occupied:
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud:
				hud.set_interact_prompt("[E] Esconderse en el tacho de basura")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		if not is_occupied:
			player_ref = null
			var hud = get_tree().root.find_child("HUD", true, false)
			if hud:
				hud.set_interact_prompt("")

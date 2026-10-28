extends Area3D
class_name PuertaSalida

signal player_escaped

@onready var prompt_label: Label3D = get_node_or_null("PromptLabel")
@onready var candado: Node3D = $Candado
@onready var collision_blocker: CollisionShape3D = $BloqueoFisico/CollisionShape3D
@onready var hoja_izq: Node3D = $Visuals/HojaIzq
@onready var hoja_der: Node3D = $Visuals/HojaDer

var is_player_nearby: bool = false
var has_escaped: bool = false
var player_ref: CharacterBody3D = null
var audio_player: AudioStreamPlayer3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	audio_player = AudioStreamPlayer3D.new()
	audio_player.unit_size = 5.0
	audio_player.max_distance = 25.0
	add_child(audio_player)
	
	if collision_blocker:
		collision_blocker.set_deferred("disabled", false)

func _process(delta: float) -> void:
	if has_escaped:
		return

	if is_player_nearby and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
		_try_open_door()

func _try_open_door() -> void:
	if has_escaped:
		return
		
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		return
		
	if hud.has_exit_key:
		has_escaped = true
		player_escaped.emit()
		
		# Desactivar bloqueo físico para permitir pasar
		if collision_blocker:
			collision_blocker.set_deferred("disabled", true)
			
		# Ocultar candado y cadenas
		if candado:
			candado.visible = false
			
		# Sonido de destrabe
		if audio_player:
			audio_player.stream = HorrorAudio.get_door_unlock_sound()
			audio_player.play()
			
		# Animación de apertura hacia el interior del auditorio (+Z)
		var tw = create_tween().set_parallel(true)
		if hoja_izq:
			tw.tween_property(hoja_izq, "rotation:y", deg_to_rad(-78.0), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if hoja_der:
			tw.tween_property(hoja_der, "rotation:y", deg_to_rad(78.0), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
		if prompt_label:
			prompt_label.text = "¡PUERTA DESBLOQUEADA!"
			prompt_label.modulate = Color(0.2, 1.0, 0.4)
			
		hud.show_temporary_alert("🎓 ¡HAS ESCAPADO DE LA UTN FRC! Aprobaste la materia.", Color(0.2, 1.0, 0.4))
		hud.trigger_victory_screen()
	else:
		if audio_player:
			audio_player.stream = HorrorAudio.get_door_rattle_sound()
			audio_player.play()
			
		if prompt_label:
			prompt_label.text = "¡BLOQUEADA! Necesitás tu Título"
			prompt_label.modulate = Color(1.0, 0.2, 0.2)
			
		if hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("🔒 ¡PUERTA BLOQUEADA! Sin el TÍTULO no salís. Buscalo en el atril del AUDITORIO.", Color(1.0, 0.3, 0.3))

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			if hud.has_exit_key:
				hud.set_interact_prompt("[E] Mostrar tu Título y Escapar de la UTN")
				if prompt_label:
					prompt_label.text = "[E] Escapar con tu Título"
					prompt_label.modulate = Color(0.2, 1.0, 0.4)
			else:
				hud.set_interact_prompt("[E] Puerta Bloqueada (Requiere Título)")
				if prompt_label:
					prompt_label.text = "[E] Puerta Bloqueada (Requiere Título)"
					prompt_label.modulate = Color(1.0, 0.4, 0.4)

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

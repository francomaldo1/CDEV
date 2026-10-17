extends Area3D
class_name PuertaSalida

signal player_escaped

@onready var prompt_label: Label3D = $PromptLabel
@onready var cartel_luz: SpotLight3D = $CartelLuz
@onready var candado: Node3D = $Candado

var is_player_nearby: bool = false
var has_escaped: bool = false
var player_ref: CharacterBody3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if has_escaped:
		return

	if is_player_nearby and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
		_try_open_door()

func _try_open_door() -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		return
		
	if hud.has_exit_key:
		has_escaped = true
		player_escaped.emit()
		
		if candado:
			candado.visible = false
			
		if prompt_label:
			prompt_label.text = "¡PUERTA DESBLOQUEADA!"
			prompt_label.modulate = Color(0.2, 1.0, 0.4)
			
		hud.trigger_victory_screen()
	else:
		if prompt_label:
			prompt_label.text = "¡BLOQUEADA! Necesitas la Llave de Salida"
			prompt_label.modulate = Color(1.0, 0.2, 0.2)
			
		if hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("🔒 ¡PUERTA BLOQUEADA! Busca el parcial en las aulas para conseguir la llave.", Color(1.0, 0.3, 0.3))

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			if hud.has_exit_key:
				hud.set_interact_prompt("[E] Usar Llave para Escapar de la UTN")
				if prompt_label:
					prompt_label.text = "[E] Usar Llave para Escapar"
					prompt_label.modulate = Color(0.2, 1.0, 0.4)
			else:
				hud.set_interact_prompt("[E] Puerta Bloqueada (Requiere Llave)")
				if prompt_label:
					prompt_label.text = "[E] Puerta Bloqueada (Requiere Llave)"
					prompt_label.modulate = Color(1.0, 0.4, 0.4)

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

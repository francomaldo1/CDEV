extends Area3D
class_name TituloUniversitario

## Título universitario apoyado en el atril del auditorio.
## Al recogerlo se habilita la puerta de salida (usa hud.has_exit_key).

signal title_collected

@onready var prompt_label: Label3D = $PromptLabel
@onready var light: OmniLight3D = $OmniLight3D

var is_player_nearby: bool = false
var player_ref: CharacterBody3D = null
var collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if light:
		light.light_energy = 1.0 + sin(Time.get_ticks_msec() * 0.003) * 0.35

	if is_player_nearby and not collected and Input.is_action_just_pressed("interact"):
		_collect()

func _collect() -> void:
	collected = true
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud:
		hud.has_exit_key = true
		hud.update_inventory_display()
		hud.set_interact_prompt("")
		if hud.has_method("set_objective_text"):
			hud.set_objective_text("NUEVO OBJETIVO: ¡Escapá de la facultad por la Puerta de Salida Principal!", Color(0.3, 1.0, 0.5))

	var prof = get_tree().root.find_child("Profesor", true, false)
	if prof and prof.visible and prof.has_method("_say"):
		prof._say("¡¿QUIÉN TE DIO ESE TÍTULO?! ¡DEVOLVELO!", Color(1.0, 0.2, 0.2))

	title_collected.emit()
	print(">>> ¡TÍTULO RECOGIDO! Puerta de salida habilitada")
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("[E] Recoger tu Título Universitario")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

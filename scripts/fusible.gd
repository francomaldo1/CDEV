extends Area3D
class_name Fusible

signal fuse_collected

@onready var prompt_label: Label3D = $PromptLabel
@onready var light: OmniLight3D = $OmniLight3D

var is_player_nearby: bool = false
var player_ref: CharacterBody3D = null

func _ready() -> void:
	add_to_group("fusibles")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if light:
		# Efecto de chispa / pulsación eléctrica
		light.light_energy = 0.7 + sin(Time.get_ticks_msec() * 0.008) * 0.35

	if is_player_nearby and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
		_collect()

func _collect() -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud:
		hud.has_fuse = true
		hud.update_inventory_display()
		hud.show_temporary_alert("⚡ ¡FUSIBLE RECOGIDO! Llévalo al Departamento de Ingeniería Electrónica.", Color(1.0, 0.85, 0.2))
		hud.set_interact_prompt("")
		
	fuse_collected.emit()
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("[E] Recoger Fusible de Alta Tensión (30A)")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

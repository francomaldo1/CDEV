extends Area3D
class_name LlaveAuditorio

## Llave que se recoge en la cafetería del 2do piso y abre la puerta del auditorio

signal key_collected

@onready var prompt_label: Label3D = $PromptLabel
@onready var light: OmniLight3D = $OmniLight3D
@onready var modelo: Node3D = $Pivote

var is_player_nearby: bool = false
var player_ref: CharacterBody3D = null
var base_y: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if modelo:
		base_y = modelo.position.y

func _process(_delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	# Brillo pulsante para que se note (la llave queda quieta, apoyada)
	if light:
		light.light_energy = 0.9 + sin(t * 4.0) * 0.4

	if is_player_nearby and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
		_collect()

func _collect() -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud:
		hud.has_auditorium_key = true
		hud.update_inventory_display()
		hud.show_temporary_alert("🔑 ¡LLAVE DEL AUDITORIO RECOGIDA! Bajá a planta baja y abrí el auditorio.", Color(1.0, 0.85, 0.2))
		if hud.has_method("set_objective_text"):
			hud.set_objective_text("NUEVO OBJETIVO: ¡Llave del Auditorio obtenida! Abrí la puerta del Auditorio en PB", Color(0.2, 1.0, 0.7))
		hud.set_interact_prompt("")

	key_collected.emit()
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("[E] Recoger Llave del Auditorio")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

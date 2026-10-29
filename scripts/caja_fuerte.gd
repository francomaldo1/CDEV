extends Area3D
class_name CajaFuerte

signal safe_opened

@export var safe_code: String = "742"

@onready var prompt_label: Label3D = get_node_or_null("PromptLabel")
@onready var luz_led: OmniLight3D = get_node_or_null("Visuals/LuzLED")
@onready var puerta: Node3D = get_node_or_null("Visuals/PuertaPivot")
@onready var key_mesh: Node3D = get_node_or_null("Visuals/LlaveInterior")

var is_player_nearby: bool = false
var is_unlocked: bool = false
var player_ref: CharacterBody3D = null
var ui_candado_instance: CanvasLayer = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if luz_led:
		luz_led.light_color = Color(1.0, 0.1, 0.1) # Rojo cerrado
		luz_led.light_energy = 0.6
		
	if prompt_label:
		prompt_label.text = "[E] Caja Fuerte (Código de 3 Dígitos)"

func _process(_delta: float) -> void:
	if is_unlocked:
		return
		
	if luz_led:
		luz_led.light_energy = 0.5 + sin(Time.get_ticks_msec() * 0.005) * 0.25
		
	if is_player_nearby and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
		_interact()

func _interact() -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if is_unlocked:
		if hud and hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("ℹ La caja fuerte ya está abierta y vacía.", Color(0.5, 0.8, 1.0))
		return
		
	_open_keypad_ui()

func _open_keypad_ui() -> void:
	if not ui_candado_instance:
		ui_candado_instance = get_tree().root.find_child("UICandado", true, false) as CanvasLayer
		if not ui_candado_instance:
			var scene = load("res://scenes/ui_candado.tscn")
			if scene:
				ui_candado_instance = scene.instantiate() as CanvasLayer
				get_tree().root.add_child(ui_candado_instance)
				
	if ui_candado_instance:
		for conn in ui_candado_instance.code_entered.get_connections():
			ui_candado_instance.code_entered.disconnect(conn.callable)
		ui_candado_instance.code_entered.connect(_on_code_result)
		
		for conn in ui_candado_instance.ui_closed.get_connections():
			ui_candado_instance.ui_closed.disconnect(conn.callable)
		ui_candado_instance.ui_closed.connect(_on_ui_closed)
		
		var pl = player_ref if is_instance_valid(player_ref) else get_tree().get_first_node_in_group("player")
		if is_instance_valid(pl) and pl.has_method("set_frozen"):
			pl.set_frozen(true)
			
		if ui_candado_instance.has_method("open_lock"):
			ui_candado_instance.open_lock(safe_code)

func _on_ui_closed() -> void:
	var pl = player_ref if is_instance_valid(player_ref) else get_tree().get_first_node_in_group("player")
	if is_instance_valid(pl) and pl.has_method("set_frozen"):
		pl.set_frozen(false)

func _on_code_result(success: bool) -> void:
	if success and not is_unlocked:
		_unlock_safe()

func _unlock_safe() -> void:
	is_unlocked = true
	
	if luz_led:
		luz_led.light_color = Color(0.2, 1.0, 0.4) # Verde abierto
		luz_led.light_energy = 1.0
		
	if puerta:
		var tw = create_tween()
		tw.tween_property(puerta, "rotation:y", deg_to_rad(80.0), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if key_mesh:
		var tw2 = create_tween()
		tw2.tween_interval(0.4)
		tw2.tween_property(key_mesh, "scale", Vector3.ZERO, 0.3)
		tw2.tween_callback(func(): key_mesh.visible = false)
		
	if prompt_label:
		prompt_label.text = "Caja Fuerte (Abierta - Vacía)"
		prompt_label.modulate = Color(0.3, 1.0, 0.5)
		
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud:
		hud.has_auditorium_key = true
		hud.update_inventory_display()
		if hud.has_method("set_objective_text"):
			hud.set_objective_text("NUEVO OBJETIVO: ¡Llave del Auditorio obtenida! Abrí la puerta del Auditorio en PB", Color(0.2, 1.0, 0.7))
		if hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("🔑 ¡LLAVE DEL AUDITORIO OBTENIDA! Desbloqueá las cadenas del Auditorio en PB.", Color(0.3, 1.0, 0.6))
		hud.set_interact_prompt("")
		
	safe_opened.emit()
	print(">>> ¡Caja Fuerte abierta exitosamente! Llave del Auditorio entregada al jugador.")

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			if is_unlocked:
				hud.set_interact_prompt("Caja Fuerte (Abierta)")
			else:
				hud.set_interact_prompt("[E] Abrir Caja Fuerte del Bufet")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

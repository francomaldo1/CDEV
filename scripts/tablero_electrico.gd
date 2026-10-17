extends Area3D
class_name TableroElectrico

signal power_restored

@onready var prompt_label: Label3D = $PromptLabel
@onready var estado_label: Label3D = $Visuals/EstadoLabel
@onready var luz_indicador: OmniLight3D = $Visuals/LuzIndicador
@onready var fusible_insertado: Node3D = $Visuals/FusibleInsertado

var is_player_nearby: bool = false
var is_blackout_active: bool = false
var is_restored: bool = false
var player_ref: CharacterBody3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if fusible_insertado:
		fusible_insertado.visible = false
		
	_set_normal_state()

func _process(delta: float) -> void:
	if is_blackout_active and not is_restored:
		# Parpadeo de emergencia en el tablero
		if luz_indicador:
			luz_indicador.light_energy = 0.8 + sin(Time.get_ticks_msec() * 0.015) * 0.7
			
		if is_player_nearby and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
			_try_insert_fuse()

func trigger_blackout() -> void:
	is_blackout_active = true
	is_restored = false
	
	if luz_indicador:
		luz_indicador.light_color = Color(1.0, 0.1, 0.1) # Rojo alarma
		luz_indicador.light_energy = 1.2
		
	if estado_label:
		estado_label.text = "⚠️ DISYUNTOR QUEMADO\nFALTA FUSIBLE 30A"
		estado_label.modulate = Color(1.0, 0.2, 0.2)
		
	if prompt_label:
		prompt_label.text = "[E] Tablero Principal (Fusible Fundido)"
		prompt_label.modulate = Color(1.0, 0.2, 0.2)

func _set_normal_state() -> void:
	if luz_indicador:
		luz_indicador.light_color = Color(0.2, 1.0, 0.4) # Verde normal
		luz_indicador.light_energy = 0.5
		
	if estado_label:
		estado_label.text = "TABLERO GENERAL 220V\nING. ELECTRÓNICA\nESTADO: NORMAL"
		estado_label.modulate = Color(0.3, 1.0, 0.5)
		
	if prompt_label:
		prompt_label.text = "Tablero Eléctrico: Operando"
		prompt_label.modulate = Color(0.5, 0.9, 0.6)

func _try_insert_fuse() -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		return
		
	if hud.has_fuse:
		is_restored = true
		is_blackout_active = false
		hud.has_fuse = false
		hud.update_inventory_display()
		
		if fusible_insertado:
			fusible_insertado.visible = true
			
		if luz_indicador:
			luz_indicador.light_color = Color(0.2, 1.0, 0.4)
			luz_indicador.light_energy = 1.0
			
		if estado_label:
			estado_label.text = "FUSIBLE REEMPLAZADO\nENERGÍA RESTABLECIDA ✓"
			estado_label.modulate = Color(0.2, 1.0, 0.4)
			
		if prompt_label:
			prompt_label.text = "✓ ¡ENERGÍA RESTABLECIDA!"
			prompt_label.modulate = Color(0.2, 1.0, 0.4)
			
		hud.show_temporary_alert("💡 ¡ENERGÍA RESTABLECIDA! La luz del edificio volvió a encenderse.", Color(0.2, 1.0, 0.4))
		
		# Avisar a la escena principal para encender las luces
		power_restored.emit()
		
		# Profesor reacciona
		var prof = get_tree().root.find_child("Profesor", true, false)
		if prof and prof.has_method("_say"):
			prof._say("¡Por fin alguien levantó la térmica de Electrónica!", Color(1.0, 0.85, 0.4))
	else:
		if hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("⚡ ¡FALTA EL FUSIBLE! Búscalo en las aulas o cafetería para reparar el tablero.", Color(1.0, 0.3, 0.3))

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			if is_blackout_active and not is_restored:
				if hud.has_fuse:
					hud.set_interact_prompt("[E] Colocar Fusible y Restablecer Luz")
				else:
					hud.set_interact_prompt("[E] Tablero Dañado (Necesitas un Fusible)")
			else:
				hud.set_interact_prompt("Tablero de Energía: Operando")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

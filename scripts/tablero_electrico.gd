extends Area3D
class_name TableroElectrico

const HorrorAudio = preload("res://scripts/horror_audio.gd")

signal power_restored

@onready var prompt_label: Label3D = $PromptLabel
@onready var estado_label: Label3D = $Visuals/EstadoLabel
@onready var luz_indicador: OmniLight3D = $Visuals/LuzIndicador
@onready var fusible_insertado: Node3D = $Visuals/FusibleInsertado

var is_player_nearby: bool = false
var is_blackout_active: bool = false
var is_restored: bool = false
var is_screamer_running: bool = false
var player_ref: CharacterBody3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if fusible_insertado:
		fusible_insertado.visible = false
		
	_set_normal_state()

func _process(delta: float) -> void:
	if is_blackout_active and not is_restored and not is_screamer_running:
		# Parpadeo de emergencia en el tablero
		if luz_indicador:
			luz_indicador.light_energy = 0.8 + sin(Time.get_ticks_msec() * 0.015) * 0.7
			
		if is_player_nearby:
			if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
				_try_insert_fuse()

func trigger_blackout() -> void:
	is_blackout_active = true
	is_restored = false
	is_screamer_running = false
	
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
	if is_restored or is_screamer_running:
		return
		
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		return
		
	if not hud.has_fuse:
		if hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("⚡ ¡FALTA EL FUSIBLE! Búscalo en las aulas o cafetería para reparar el tablero.", Color(1.0, 0.3, 0.3))
		return
		
	# Iniciar la secuencia de terror / screamer
	_execute_fuse_screamer_sequence(hud)

func _execute_fuse_screamer_sequence(hud: Node) -> void:
	is_screamer_running = true
	is_restored = true
	is_blackout_active = false
	
	# 1. Consumir fusible del inventario
	hud.has_fuse = false
	hud.update_inventory_display()
	hud.set_interact_prompt("")
	
	if fusible_insertado:
		fusible_insertado.visible = true
		
	# Obtener referencias al jugador y al profesor
	var player = player_ref
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			
	var prof = get_tree().root.find_child("Profesor", true, false)
	if not prof:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0:
			prof = enemies[0]
			
	# Congelar movimiento del jugador durante la cinemática de sobresalto (puede rotar cámara)
	if is_instance_valid(player) and player.has_method("set_frozen"):
		player.set_frozen(true)
		
	# 2. CHISPAZO ELÉCTRICO Y DESCARGA INICIAL (T = 0.0s)
	var spark_light = OmniLight3D.new()
	spark_light.position = Vector3(0.0, 1.25, 0.3)
	spark_light.light_color = Color(0.65, 0.85, 1.0)
	spark_light.light_energy = 6.0
	spark_light.omni_range = 7.0
	spark_light.shadow_enabled = false
	add_child(spark_light)
	
	var spark_player = AudioStreamPlayer3D.new()
	spark_player.stream = HorrorAudio.get_spark_sound()
	spark_player.position = Vector3(0.0, 1.2, 0.0)
	spark_player.volume_db = 4.0
	spark_player.unit_size = 9.0
	add_child(spark_player)
	spark_player.play()
	
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(0.75, 0.45)
		
	var spark_tw = create_tween()
	spark_tw.tween_property(spark_light, "light_energy", 1.2, 0.08)
	spark_tw.tween_property(spark_light, "light_energy", 5.0, 0.05)
	spark_tw.tween_property(spark_light, "light_energy", 0.0, 0.08)
	spark_tw.tween_callback(spark_light.queue_free)
	spark_player.finished.connect(spark_player.queue_free)
	
	# 3. CORTE DE LINTERNA Y OSCURIDAD TOTAL (T = 0.18s)
	await get_tree().create_timer(0.18).timeout
	if is_instance_valid(player) and player.has_method("force_flashlight"):
		player.force_flashlight(false)
		
	# 4. TELETRANSPORTAR AL PROFESOR EN SILENCIO TRAS EL JUGADOR
	if is_instance_valid(prof):
		var p_pos = player.global_position if is_instance_valid(player) else Vector3(-18.5, 0.0, 0.0)
		var ambush_x = p_pos.x - 2.6
		var ambush_z = clampf(p_pos.z, -0.1, 1.6)
		var ambush_pos = Vector3(ambush_x, 0.2, ambush_z)
		var look_target = Vector3(p_pos.x, 1.2, p_pos.z)
		prof.trigger_screamer_ambush(ambush_pos, look_target)
		
	# 5. GOLPE SECO DE MADERA CONTRA LA MESADA EN LA OSCURIDAD (T = 0.85s)
	await get_tree().create_timer(0.67).timeout
	
	var slam_player = AudioStreamPlayer3D.new()
	slam_player.stream = HorrorAudio.get_wood_slam_sound()
	slam_player.position = Vector3(-21.0, 1.0, 0.0)
	slam_player.volume_db = 7.0
	slam_player.unit_size = 12.0
	get_tree().root.add_child(slam_player)
	slam_player.play()
	slam_player.finished.connect(slam_player.queue_free)
	
	if is_instance_valid(prof):
		prof.play_ruler_slam_animation()
		
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(0.65, 0.3)
		
	# 6. ENERGÍA RESTABLECIDA, STINGER Y PERSECUCIÓN (T = 1.22s)
	await get_tree().create_timer(0.37).timeout
	
	if is_instance_valid(player) and player.has_method("force_flashlight"):
		player.force_flashlight(true)
		
	if luz_indicador:
		luz_indicador.light_color = Color(0.2, 1.0, 0.4)
		luz_indicador.light_energy = 1.0
		
	if estado_label:
		estado_label.text = "FUSIBLE REEMPLAZADO\nENERGÍA RESTABLECIDA ✓"
		estado_label.modulate = Color(0.2, 1.0, 0.4)
		
	if prompt_label:
		prompt_label.text = "✓ ¡ENERGÍA RESTABLECIDA!"
		prompt_label.modulate = Color(0.2, 1.0, 0.4)
		
	# Encender las 95 luces del edificio (proyecta la sombra del profesor)
	power_restored.emit()
	
	# Screamer stinger orquestal
	var stinger = AudioStreamPlayer.new()
	stinger.stream = HorrorAudio.get_screamer_stinger()
	stinger.volume_db = 2.5
	get_tree().root.add_child(stinger)
	stinger.play()
	stinger.finished.connect(stinger.queue_free)
	
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(0.9, 0.7)
		
	if is_instance_valid(prof):
		prof._say("¡¡HORARIO DE CONSULTA FINALIZADO, ALUMNO!! ¡¡A MARZO DIRECTO!!", Color(1.0, 0.0, 0.0))
		prof.release_screamer_ambush()
		
	hud.show_temporary_alert("⚡ ¡¡CUIDADO!! ¡¡EL PROFESOR ESTÁ JUSTO DETRÁS TUYO!!", Color(1.0, 0.1, 0.1))
	
	# Liberar el movimiento del jugador para escapar
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(player) and player.has_method("set_frozen"):
		player.set_frozen(false)
		
	is_screamer_running = false

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			if is_screamer_running:
				hud.set_interact_prompt("")
			elif is_blackout_active and not is_restored:
				if hud.has_fuse:
					hud.set_interact_prompt("[E] Colocar Fusible y Restablecer Luz")
				else:
					hud.set_interact_prompt("[E] Tablero Dañado (Necesitas un Fusible)")
			else:
				hud.set_interact_prompt("Tablero de Energía: Operando")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		if not is_screamer_running:
			player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and not is_screamer_running:
			hud.set_interact_prompt("")

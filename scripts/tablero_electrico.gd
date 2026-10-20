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
		
	# 4. TELETRANSPORTAR AL PROFESOR A LA PUERTA DEL LABORATORIO (bloqueando la única salida)
	# La puerta del lab hacia el pasillo oeste está exactamente en X = -36.2, Z = 0.5
	var door_ambush_pos = Vector3(-36.2, 0.2, 0.5)
	if is_instance_valid(prof):
		var p_pos = player.global_position if is_instance_valid(player) else Vector3(-18.5, 0.0, 0.0)
		var look_target = p_pos + Vector3(0, 1.4, 0)
		prof.trigger_screamer_ambush(door_ambush_pos, look_target)
		
	# 5. GOLPE SECO DE MADERA CONTRA EL MARCO DE LA PUERTA EN LA OSCURIDAD (T = 0.60s)
	await get_tree().create_timer(0.42).timeout
	
	var slam_player = AudioStreamPlayer3D.new()
	slam_player.stream = HorrorAudio.get_wood_slam_sound()
	slam_player.position = door_ambush_pos + Vector3(0, 1.2, 0)
	slam_player.volume_db = 8.0
	slam_player.unit_size = 14.0
	get_tree().root.add_child(slam_player)
	slam_player.play()
	slam_player.finished.connect(slam_player.queue_free)
	
	if is_instance_valid(prof):
		prof.play_ruler_slam_animation()
		
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(0.55, 0.25)
		
	# 6. GIRO DRAMÁTICO DE CÁMARA HACIA LA PUERTA (T = 0.75s)
	# La cámara del jugador gira 180° hacia el pasillo central apuntando directamente a la puerta
	if is_instance_valid(player) and player.has_method("force_look_at"):
		player.force_look_at(door_ambush_pos + Vector3(0, 1.6, 0), 0.40)
		
	# 7. ENERGÍA RESTABLECIDA, JUMPSCARE EN LA PUERTA Y PERSECUCIÓN (T = 1.18s)
	await get_tree().create_timer(0.43).timeout
	
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
		
	# Encender las luces del edificio (la luz del pasillo recorta al profesor parado en la puerta)
	power_restored.emit()
	
	# Screamer stinger orquestal
	var stinger = AudioStreamPlayer.new()
	stinger.stream = HorrorAudio.get_screamer_stinger()
	stinger.volume_db = 3.0
	get_tree().root.add_child(stinger)
	stinger.play()
	stinger.finished.connect(stinger.queue_free)
	
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(0.95, 0.7)
		
	if is_instance_valid(prof):
		prof._say("¡¡HORARIO DE CONSULTA FINALIZADO, ALUMNO!!", Color(1.0, 0.0, 0.0))
		
	hud.show_temporary_alert("⚡ ¡¡EL PROFESOR ESTÁ EN LA PUERTA!!", Color(1.0, 0.1, 0.1))
	
	# Bloqueo de cámara fijo en el profesor durante 1.4 segundos de tensión pura
	await get_tree().create_timer(1.4).timeout
	
	# Sonido screamer mp3 cuando el profesor se acerca corriendo a nosotros
	var jumpscare = AudioStreamPlayer.new()
	jumpscare.name = "ScreamerJumpscareAudio"
	jumpscare.stream = HorrorAudio.get_screamer_jumpscare_sound()
	jumpscare.volume_db = 5.0
	jumpscare.bus = &"Master"
	jumpscare.add_to_group("screamer_audio")
	get_tree().root.add_child(jumpscare)
	jumpscare.play()
	
	var tw_sc = get_tree().create_tween()
	tw_sc.tween_interval(4.5)
	tw_sc.tween_property(jumpscare, "volume_db", -40.0, 1.5)
	tw_sc.tween_callback(jumpscare.queue_free)
	
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(1.3, 0.9)
	
	# El profesor sale corriendo rapidísimo hacia nosotros (casi instantáneo)
	if is_instance_valid(prof):
		if prof.has_method("start_screamer_charge"):
			prof.start_screamer_charge()
		else:
			prof.release_screamer_ambush()
		
	hud.show_temporary_alert("⚡ ¡¡CORRE!! ¡¡ESQUÍVALO POR LAS MESADAS!!", Color(1.0, 0.1, 0.1))
	
	# Liberar el movimiento del jugador justo en el instante que arranca la embestida
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

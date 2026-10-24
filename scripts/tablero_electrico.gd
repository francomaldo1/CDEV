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
var ghostly_audio_player: AudioStreamPlayer = null

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
		
	# Reproducir sonido de fusible eléctrico conectado
	_play_fuse_insert_sound()
		
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
		
	# 2. CHISPAZO ELÉCTRICO Y DESCARGA INICIAL (T = 0.0s a 0.85s)
	var spark_light = OmniLight3D.new()
	spark_light.position = Vector3(0.0, 1.25, 0.3)
	spark_light.light_color = Color(0.65, 0.85, 1.0)
	spark_light.light_energy = 7.0
	spark_light.omni_range = 8.0
	spark_light.shadow_enabled = false
	add_child(spark_light)
	
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(0.85, 0.6)
		
	var spark_tw = create_tween()
	spark_tw.tween_property(spark_light, "light_energy", 2.0, 0.15)
	spark_tw.tween_property(spark_light, "light_energy", 6.5, 0.12)
	spark_tw.tween_property(spark_light, "light_energy", 2.5, 0.18)
	spark_tw.tween_property(spark_light, "light_energy", 0.0, 0.25)
	spark_tw.tween_callback(spark_light.queue_free)
	
	# Dejar que el sonido y los chispazos de conexión se aprecien con claridad
	await get_tree().create_timer(0.85).timeout
	
	# 3. MANTENER LINTERNA PRENDIDA Y ENCENDER HILERA DE LUCES DEL LABORATORIO
	if is_instance_valid(player) and player.has_method("force_flashlight"):
		player.force_flashlight(true)
	_turn_on_hilera_luces()
		
	# 4. TELETRANSPORTAR AL PROFESOR A LA PUERTA DEL LABORATORIO (X = -36.2, Z = 0.9)
	# La puerta del lab hacia el pasillo oeste está en X = -36.5, Z = 0.9.
	# Colocamos al profesor justo bajo la lámpara de la puerta, bloqueando la salida.
	var door_ambush_pos = Vector3(-36.0, 0.05, 0.9)
	if is_instance_valid(prof):
		var p_pos = player.global_position if is_instance_valid(player) else Vector3(-18.5, 0.05, 0.0)
		var look_target = p_pos + Vector3(0, 1.4, 0)
		prof.trigger_screamer_ambush(door_ambush_pos, look_target)
		
	await get_tree().create_timer(0.85).timeout
	
	# 5. GOLPE DE REGLA DEL PROFESOR EN LA PENUMBRA (T = 1.8s a 2.7s)
	if is_instance_valid(prof):
		prof.play_ruler_slam_animation()
		
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(0.55, 0.3)
		
	await get_tree().create_timer(0.75).timeout
	
	# 6. GIRO DRAMÁTICO DE CÁMARA, AUDIO FANTASMAL Y APAGÓN EN CASCADA DE LUCES HACIA LA PUERTA
	_play_ghostly_sound()
	
	# Iniciar el apagón progresivo de la hilera de luces desde el tablero hacia la puerta
	_animate_hilera_lights_cascade()
	
	# Giro suave y cinematográfico de cámara de 180° hacia la puerta
	if is_instance_valid(player) and player.has_method("force_look_at"):
		player.force_look_at(door_ambush_pos + Vector3(0, 1.5, 0), 0.95)
		
	# Dejar contemplar al profesor perfectamente iluminado bajo la única luz de la puerta
	await get_tree().create_timer(1.3).timeout
		
	# 7. ENERGÍA RESTABLECIDA, JUMPSCARE EN LA PUERTA Y PERSECUCIÓN (T = 4.1s a 6.8s)
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
	
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(1.1, 0.9)
		
	if is_instance_valid(prof):
		prof._say("¡¡HORARIO DE CONSULTA FINALIZADO, ALUMNO!!", Color(1.0, 0.0, 0.0))
		
	hud.show_temporary_alert("⚡ ¡¡EL PROFESOR ESTÁ EN LA PUERTA!!", Color(1.0, 0.1, 0.1))
	
	# Bloqueo de cámara fijo en el profesor durante 2.4 segundos de tensión pura
	await get_tree().create_timer(2.4).timeout
	
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(1.4, 0.9)
	
	# Desvanecer ghostly sound al desatarse la embestida
	if is_instance_valid(ghostly_audio_player) and ghostly_audio_player.playing:
		var tw = create_tween()
		tw.tween_property(ghostly_audio_player, "volume_db", -35.0, 0.35)
		tw.tween_callback(ghostly_audio_player.queue_free)

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

func _play_fuse_insert_sound() -> void:
	var sfx_paths = [
		"res://audio/sfx/Firefly_audio_sonido_de_fusible_electrico_conectado_variation3.wav",
		"res://Firefly_audio_sonido_de_fusible_electrico_conectado_variation3.wav"
	]
	var stream: AudioStream = null
	for p in sfx_paths:
		if ResourceLoader.exists(p):
			stream = load(p)
			break
	if stream:
		var asp = AudioStreamPlayer.new()
		asp.name = "FuseConnectedSFX"
		asp.stream = stream
		asp.bus = &"Master"
		asp.volume_db = 2.0
		add_child(asp)
		asp.play()
		asp.finished.connect(asp.queue_free)

func _play_ghostly_sound() -> void:
	var sfx_paths = [
		"res://audio/sfx/ghostly-sound.mp3",
		"res://ghostly-sound.mp3"
	]
	var stream: AudioStream = null
	for p in sfx_paths:
		if ResourceLoader.exists(p):
			stream = load(p)
			break
	if stream:
		ghostly_audio_player = AudioStreamPlayer.new()
		ghostly_audio_player.name = "GhostlySoundSFX"
		ghostly_audio_player.stream = stream
		ghostly_audio_player.bus = &"Master"
		ghostly_audio_player.volume_db = 2.5
		add_child(ghostly_audio_player)
		ghostly_audio_player.play()
		ghostly_audio_player.finished.connect(func():
			if is_instance_valid(ghostly_audio_player):
				ghostly_audio_player.queue_free()
				ghostly_audio_player = null
		)

func _turn_on_hilera_luces() -> void:
	var hilera = get_tree().root.find_child("HileraLucesLabElectronica", true, false)
	if not hilera:
		return
	for child in hilera.get_children():
		if child is SpotLight3D:
			child.visible = true
		elif child is CSGBox3D and child.name.begins_with("Tube_"):
			if child.material is StandardMaterial3D:
				var mat = (child.material as StandardMaterial3D).duplicate()
				mat.emission_enabled = true
				child.material = mat

func _animate_hilera_lights_cascade() -> void:
	var hilera = get_tree().root.find_child("HileraLucesLabElectronica", true, false)
	if not hilera:
		return
	var spots: Array[SpotLight3D] = []
	for child in hilera.get_children():
		if child is SpotLight3D:
			spots.append(child)
	# Ordenar de mayor a menor X (desde tablero en X = -19.5 hacia la puerta en X = -36.5)
	spots.sort_custom(func(a, b): return a.global_position.x > b.global_position.x)
	if spots.is_empty():
		return
		
	var snap_audio = AudioStreamPlayer3D.new()
	snap_audio.unit_size = 5.0
	snap_audio.max_distance = 35.0
	snap_audio.bus = &"Master"
	add_child(snap_audio)
	
	# Apagar en cascada todas las luces menos la última (la de la puerta en X = -36.5)
	for i in range(spots.size() - 1):
		await get_tree().create_timer(0.22).timeout
		var s = spots[i]
		if is_instance_valid(s):
			s.visible = false
			snap_audio.global_position = s.global_position
			snap_audio.stream = HorrorAudio.get_spark_sound()
			snap_audio.volume_db = 2.0
			snap_audio.pitch_scale = randf_range(1.15, 1.35)
			snap_audio.play()
			
			for child in hilera.get_children():
				if child is CSGBox3D and child.name.begins_with("Tube_"):
					if absf(child.global_position.x - s.global_position.x) < 0.6:
						if child.material is StandardMaterial3D:
							var mat = (child.material as StandardMaterial3D).duplicate()
							mat.emission_enabled = false
							child.material = mat

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

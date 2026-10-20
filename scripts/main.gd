extends Node3D

@onready var mic_detector = $MicDetector
@onready var hud = $HUD
@onready var profesor = $Profesor
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var moon_light: DirectionalLight3D = $MoonLight

var cuaderno_scene = preload("res://scenes/cuaderno_matematica.tscn")
var puerta_salida_scene = preload("res://scenes/puerta_salida.tscn")
var tablero_scene = preload("res://scenes/tablero_electrico.tscn")
var fusible_scene = preload("res://scenes/fusible.tscn")

## Retraso en segundos hasta que se corte la luz
@export var blackout_delay: float = 45.0

var tablero_electrico: Area3D = null
var is_blackout: bool = false
var original_ambient_energy: float = 0.4
var original_moon_energy: float = 0.35

var ambient_drone_player: AudioStreamPlayer = null
var spook_audio_3d: AudioStreamPlayer3D = null
var spook_interval_timer: float = 0.0
var next_spook_delay: float = 12.0

## Ubicaciones de pupitres en todas las aulas de Planta Baja
var classroom_spots = [
	{"pos": Vector3(-52.5, 0.82, -39.0), "name": "Aula 101 (Norte)"},
	{"pos": Vector3(-27.5, 0.82, -39.0), "name": "Aula 102 (Norte)"},
	{"pos": Vector3(-2.5, 0.82, -39.0),  "name": "Aula 103 (Norte)"},
	{"pos": Vector3(23.5, 0.82, -39.0),  "name": "Aula 104 (Norte)"},
	{"pos": Vector3(-56.5, 0.82, -25.8), "name": "Laboratorio W1 (Oeste)"},
	{"pos": Vector3(-56.5, 0.82, -11.8), "name": "Aula W2 (Oeste)"},
	{"pos": Vector3(-56.5, 0.82, 2.2),   "name": "Aula W3 (Oeste)"},
	{"pos": Vector3(-56.5, 0.82, 17.2),  "name": "Aula W4 (Oeste)"}
]

func _ready() -> void:
	randomize()
	
	_setup_ambient_audio()
	
	if mic_detector and hud:
		mic_detector.volume_updated.connect(hud.on_mic_volume_updated)
		
	if world_env and world_env.environment:
		original_ambient_energy = world_env.environment.ambient_light_energy
	if moon_light:
		original_moon_energy = moon_light.light_energy
		
	_spawn_exit_door()
	_spawn_tablero_electronica()
	_spawn_fusible()
	_spawn_multiple_cuadernos()
	
	# Programar el corte de luz
	_start_blackout_timer()
	_init_building_lights()

func _setup_ambient_audio() -> void:
	ambient_drone_player = AudioStreamPlayer.new()
	ambient_drone_player.name = "AmbientDronePlayer"
	ambient_drone_player.stream = HorrorAudio.get_ambient_drone(false)
	ambient_drone_player.volume_db = 0.0
	ambient_drone_player.bus = &"Master"
	ambient_drone_player.finished.connect(func(): if ambient_drone_player and is_instance_valid(ambient_drone_player): ambient_drone_player.play())
	add_child(ambient_drone_player)
	ambient_drone_player.play()
	
	spook_audio_3d = AudioStreamPlayer3D.new()
	spook_audio_3d.name = "SpookAudio3D"
	spook_audio_3d.unit_size = 4.0
	spook_audio_3d.max_distance = 45.0
	spook_audio_3d.volume_db = -4.0
	spook_audio_3d.bus = &"Master"
	add_child(spook_audio_3d)
	
	next_spook_delay = randf_range(10.0, 20.0)

var turned_off_lights: Array[Light3D] = []
var building_lights_base_energy: Dictionary = {}
var active_light_flickers: Dictionary = {}
var next_light_flicker_delay: float = 2.5
var light_flicker_timer: float = 0.0

func _spawn_exit_door() -> void:
	var puerta = puerta_salida_scene.instantiate()
	puerta.position = Vector3(-60.0, 0.0, 45.0)
	puerta.rotation_degrees = Vector3.ZERO
	add_child(puerta)

func _spawn_tablero_electronica() -> void:
	# Ubicado en el Departamento de Ingeniería Electrónica (Planta Baja Oeste), montado en la pared este bajo la luz
	tablero_electrico = tablero_scene.instantiate() as Area3D
	tablero_electrico.position = Vector3(-17.22, 0.0, 0.0)
	tablero_electrico.rotation_degrees = Vector3(0, -90, 0)
	tablero_electrico.power_restored.connect(_on_power_restored)
	add_child(tablero_electrico)
	
	# Luz puntual en la pared justo sobre el tablero
	var luz_tablero = OmniLight3D.new()
	luz_tablero.name = "LuzParedTablero"
	luz_tablero.position = Vector3(-17.4, 2.5, 0.0)
	luz_tablero.light_color = Color(1.0, 0.95, 0.8)
	luz_tablero.light_energy = 0.45
	luz_tablero.omni_range = 5.0
	luz_tablero.shadow_enabled = true
	luz_tablero.add_to_group("building_lights")
	add_child(luz_tablero)

	# Luz de techo central del laboratorio (ilumina desde atrás y proyecta la sombra del profesor)
	var luz_techo_lab = OmniLight3D.new()
	luz_techo_lab.name = "LuzTechoLabElectronica"
	luz_techo_lab.position = Vector3(-25.0, 3.6, 0.0)
	luz_techo_lab.light_color = Color(0.9, 0.95, 1.0)
	luz_techo_lab.light_energy = 0.50
	luz_techo_lab.omni_range = 11.0
	luz_techo_lab.shadow_enabled = true
	luz_techo_lab.add_to_group("building_lights")
	add_child(luz_techo_lab)
	
	print(">>> Tablero Eléctrico instalado en Depto. de Electrónica (con iluminación y sombras de laboratorio)")

func _spawn_fusible() -> void:
	# El fusible está guardado en la Cafetería o Bedelía (ala este)
	var fusible = fusible_scene.instantiate()
	fusible.position = Vector3(45.0, 0.85, 28.0)
	add_child(fusible)
	print(">>> Fusible de alta tensión colocado en Cafetería (45, 0.85, 28)")

func _spawn_multiple_cuadernos() -> void:
	classroom_spots.shuffle()
	
	# Colocar exámenes en 6 de las 8 aulas disponibles para que sea fácil encontrarlos
	var count = min(6, classroom_spots.size())
	for i in range(count):
		var spot = classroom_spots[i]
		var cuaderno = cuaderno_scene.instantiate()
		cuaderno.position = spot["pos"]
		cuaderno.classroom_name = spot["name"]
		add_child(cuaderno)
		print(">>> Cuaderno matemático colocado en: %s" % spot["name"])

func _start_blackout_timer() -> void:
	get_tree().create_timer(blackout_delay).timeout.connect(_trigger_blackout)

func _collect_all_building_lights() -> Array[Light3D]:
	var result: Array[Light3D] = []
	
	# 1. Grupo explícito "building_lights"
	for l in get_tree().get_nodes_in_group("building_lights"):
		if l is Light3D and not result.has(l):
			result.append(l)
			
	# 2. Todas las luces de EdificioCentral
	var edificio = find_child("EdificioCentral", true, false)
	if edificio:
		for child in edificio.find_children("*", "Light3D", true, false):
			if child is Light3D and not result.has(child):
				result.append(child)
				
	# 3. Cualquier otra luz en la escena que no sea linterna, ojos del profesor o tablero
	for light in get_tree().root.find_children("*", "Light3D", true, false):
		if light is Light3D and not result.has(light) and light != moon_light:
			var is_exempt = false
			var curr: Node = light
			while curr != null and curr != get_tree().root:
				if curr.name == "Player" or curr.name == "Profesor" or curr.name == "TableroElectrico" or curr.name.begins_with("Fusible"):
					is_exempt = true
					break
				curr = curr.get_parent()
			if not is_exempt:
				result.append(light)
				
	return result

func _trigger_blackout() -> void:
	if is_blackout:
		return
	is_blackout = true
	
	# Recolectar todas las luces del edificio
	var all_building_lights = _collect_all_building_lights()
	turned_off_lights.clear()
	for l in all_building_lights:
		if is_instance_valid(l) and l.visible:
			turned_off_lights.append(l)
			
	# Efecto de parpadeo realista antes del corte total
	for flicker in range(2):
		for l in turned_off_lights:
			if is_instance_valid(l): l.visible = false
		await get_tree().create_timer(0.09).timeout
		for l in turned_off_lights:
			if is_instance_valid(l): l.visible = true
		await get_tree().create_timer(0.06).timeout
		
	# Apagón total en toda la facultad
	for l in turned_off_lights:
		if is_instance_valid(l):
			l.visible = false
			
	# Oscuridad casi total (solo tenue luz de luna en patio)
	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = 0.01
	if moon_light:
		moon_light.light_energy = 0.04
		
	# Transicionar a dron oscuro de apagón
	if ambient_drone_player:
		ambient_drone_player.volume_db = 3.0
		if not ambient_drone_player.playing:
			ambient_drone_player.play()
		
	if tablero_electrico:
		tablero_electrico.trigger_blackout()
		
	if hud and hud.has_method("show_temporary_alert"):
		hud.show_temporary_alert("⚡ ¡CORTE GENERAL DE LUZ! Los disyuntores saltaron. Busca el FUSIBLE y llévalo al Depto. de Electrónica.", Color(1.0, 0.25, 0.25))
		
	if profesor and profesor.has_method("_say"):
		profesor._say("¡¿Quién tocó los disyuntores?! ¡Quedaron todos a oscuras!", Color(1.0, 0.3, 0.3))
		
	print(">>> ¡CORTE DE LUZ ACTIVADO! (%d luces apagadas en toda la facultad)" % turned_off_lights.size())

func _on_power_restored() -> void:
	is_blackout = false
	
	# Restaurar dron ambiental normal
	if ambient_drone_player:
		ambient_drone_player.volume_db = 0.0
		if not ambient_drone_player.playing:
			ambient_drone_player.play()
	
	# Restaurar iluminación ambiental y lunar
	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = original_ambient_energy
	if moon_light:
		moon_light.light_energy = original_moon_energy
		
	# Reencender todas las luces restaurando su energía tenue
	for l in turned_off_lights:
		if is_instance_valid(l):
			l.visible = true
			if building_lights_base_energy.has(l):
				l.light_energy = building_lights_base_energy[l]
	turned_off_lights.clear()
			
	if hud and hud.has_method("show_temporary_alert"):
		hud.show_temporary_alert("💡 ¡Energía restablecida! Las luces volvieron a encenderse.", Color(0.3, 1.0, 0.5))
		
	print(">>> ¡ENERGÍA RESTABLECIDA EN TODA LA FACULTAD!")

func _process(delta: float) -> void:
	_process_light_flicker(delta)
	
	# Crujidos y sonidos espeluznantes periódicos a lo lejos en el edificio
	spook_interval_timer += delta
	if spook_interval_timer >= next_spook_delay:
		spook_interval_timer = 0.0
		next_spook_delay = randf_range(14.0, 28.0)
		_play_distant_spook()

func _play_distant_spook() -> void:
	if not spook_audio_3d:
		return
	# Elegir un punto aleatorio del edificio lejos del centro
	var spook_spots = [
		Vector3(0.0, 2.0, 0.0),    # Auditorio central
		Vector3(-45.0, 1.0, -30.0), # Pasillos noroeste
		Vector3(45.0, 1.0, 30.0),  # Cafetería este
		Vector3(0.0, 4.5, -20.0),  # Galería alta piso 1
		Vector3(-20.0, 0.5, 25.0)  # Cerca de las escaleras
	]
	var spot = spook_spots[randi() % spook_spots.size()]
	spook_audio_3d.global_position = spot
	spook_audio_3d.stream = HorrorAudio.get_spooky_creak()
	spook_audio_3d.pitch_scale = randf_range(0.85, 1.15)
	spook_audio_3d.volume_db = randf_range(-6.0, -1.0)
	spook_audio_3d.play()



func _init_building_lights() -> void:
	building_lights_base_energy.clear()
	for l in _collect_all_building_lights():
		if is_instance_valid(l):
			building_lights_base_energy[l] = l.light_energy

func _process_light_flicker(delta: float) -> void:
	if is_blackout:
		active_light_flickers.clear()
		return
		
	# 1. Programar nuevo evento de parpadeo aleatorio
	light_flicker_timer += delta
	if light_flicker_timer >= next_light_flicker_delay:
		light_flicker_timer = 0.0
		next_light_flicker_delay = randf_range(2.0, 4.5)
		_trigger_random_light_flicker()
		
	# 2. Animar las luces parpadeando activamente
	var finished_lights: Array = []
	for l in active_light_flickers.keys():
		if not is_instance_valid(l) or not l.visible:
			finished_lights.append(l)
			continue
			
		var data = active_light_flickers[l]
		data["elapsed"] += delta
		var base_e: float = data["base"]
		
		if data["elapsed"] >= data["duration"]:
			l.light_energy = base_e
			finished_lights.append(l)
		else:
			# Efecto de titileo con micro-caídas y destellos
			var r = randf()
			if r < 0.35:
				l.light_energy = base_e * randf_range(0.0, 0.15)
			elif r < 0.70:
				l.light_energy = base_e * randf_range(0.3, 0.6)
			elif r < 0.88:
				l.light_energy = base_e * randf_range(0.9, 1.3)
			else:
				l.light_energy = 0.0
				
	for l in finished_lights:
		active_light_flickers.erase(l)

func _trigger_random_light_flicker() -> void:
	if building_lights_base_energy.is_empty():
		return
		
	var player_node = find_child("Player", true, false)
	var player_pos = player_node.global_position if is_instance_valid(player_node) else Vector3.ZERO
	
	var near_lights: Array = []
	var other_lights: Array = []
	
	for l in building_lights_base_energy.keys():
		if is_instance_valid(l) and l.visible and not active_light_flickers.has(l):
			if is_instance_valid(player_node) and l.global_position.distance_to(player_pos) < 32.0:
				near_lights.append(l)
			else:
				other_lights.append(l)
				
	# 75% probabilidad de titilar cerca del jugador para máxima inmersión
	var pool = near_lights if (not near_lights.is_empty() and randf() < 0.75) else other_lights
	if pool.is_empty():
		pool = near_lights if not near_lights.is_empty() else other_lights
		
	if pool.is_empty():
		return
		
	pool.shuffle()
	var count = 1 if randf() < 0.65 else 2
	for i in range(min(count, pool.size())):
		var light_to_flicker = pool[i]
		var base_e = building_lights_base_energy.get(light_to_flicker, light_to_flicker.light_energy)
		active_light_flickers[light_to_flicker] = {
			"elapsed": 0.0,
			"duration": randf_range(0.35, 1.25),
			"base": base_e
		}

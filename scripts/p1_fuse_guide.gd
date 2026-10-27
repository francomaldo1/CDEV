extends Node3D
## Sistema de ambientación de terror y guía intuitiva del fusible en Primer Piso (P1)
## - Portazos espectrales en las puertas incorrectas a medida que el jugador avanza
## - Silueta del Alumno Fantasma que guía hacia Bedelía General
## - Única habitación abierta: Bedelía con el fusible iluminado

const HorrorAudio = preload("res://scripts/horror_audio.gd")

var player: CharacterBody3D = null
var hud: CanvasLayer = null

# Configuración de las puertas que se azotarán
var doors_data: Array[Dictionary] = [
	{
		"id": "sistemas",
		"name": "Depto. Sistemas",
		"hinge_pos": Vector3(-47.0, 4.6, -20.4),
		"rot_open": deg_to_rad(-85.0),
		"rot_closed": 0.0,
		"trigger_pos": Vector3(-42.0, 4.6, -19.0),
		"is_slammed": false,
		"door_node": null,
		"axis": "z"
	},
	{
		"id": "electronica",
		"name": "Depto. Electrónica P1",
		"hinge_pos": Vector3(-47.0, 4.6, 8.6),
		"rot_open": deg_to_rad(-85.0),
		"rot_closed": 0.0,
		"trigger_pos": Vector3(-42.0, 4.6, 10.0),
		"is_slammed": false,
		"door_node": null,
		"axis": "z"
	},
	{
		"id": "direccion",
		"name": "Dirección Departamental",
		"hinge_pos": Vector3(8.6, 4.6, -33.0),
		"rot_open": deg_to_rad(85.0),
		"rot_closed": 0.0,
		"trigger_pos": Vector3(10.0, 4.6, -28.5),
		"is_slammed": false,
		"door_node": null,
		"axis": "x"
	},
	{
		"id": "cetra",
		"name": "CETRA",
		"hinge_pos": Vector3(47.0, 4.6, -28.9),
		"rot_open": deg_to_rad(85.0),
		"rot_closed": 0.0,
		"trigger_pos": Vector3(42.0, 4.6, -27.5),
		"is_slammed": false,
		"door_node": null,
		"axis": "z"
	},
	{
		"id": "biblioteca",
		"name": "Biblioteca",
		"hinge_pos": Vector3(47.0, 4.6, 6.1),
		"rot_open": deg_to_rad(85.0),
		"rot_closed": 0.0,
		"trigger_pos": Vector3(42.0, 4.6, 7.5),
		"is_slammed": false,
		"door_node": null,
		"axis": "z"
	}
]

# Referencia a la criatura del primer piso
var phantom_node: Node3D = null
var creature_col_shape: CollisionShape3D = null
var scp_spawned: bool = false
var is_waiting_for_turnaround: bool = false
var scp_stinger_played: bool = false

# Materiales reutilizables
var mat_door: StandardMaterial3D = null
var mat_handle: StandardMaterial3D = null
var mat_phantom: StandardMaterial3D = null

func _ready() -> void:
	_init_materials()
	_create_doors()
	_create_phantom()
	call_deferred("_connect_fuse_signal")

func _init_materials() -> void:
	mat_door = StandardMaterial3D.new()
	mat_door.albedo_color = Color(0.22, 0.16, 0.12)
	mat_door.roughness = 0.65
	mat_door.metallic = 0.1
	
	mat_handle = StandardMaterial3D.new()
	mat_handle.albedo_color = Color(0.7, 0.65, 0.5)
	mat_handle.metallic = 0.8
	mat_handle.roughness = 0.3
	
	mat_phantom = StandardMaterial3D.new()
	mat_phantom.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_phantom.albedo_color = Color(0.04, 0.05, 0.08, 0.82)
	mat_phantom.roughness = 0.9
	mat_phantom.emission_enabled = true
	mat_phantom.emission = Color(0.15, 0.25, 0.45)
	mat_phantom.emission_energy_multiplier = 0.35

func _create_doors() -> void:
	for d in doors_data:
		var hinge = Node3D.new()
		hinge.name = "Hinge_" + d["id"]
		hinge.position = d["hinge_pos"]
		hinge.rotation.y = d["rot_open"]
		add_child(hinge)
		
		# Hoja de la puerta
		var leaf = CSGBox3D.new()
		leaf.name = "DoorLeaf"
		leaf.use_collision = false # Se activa con el portazo
		leaf.material = mat_door
		
		var handle = CSGBox3D.new()
		handle.name = "Handle"
		handle.size = Vector3(0.08, 0.22, 0.08)
		handle.material = mat_handle
		
		if d["axis"] == "z":
			# Puerta orientada a lo largo del eje Z
			leaf.size = Vector3(0.08, 3.1, 2.75)
			leaf.position = Vector3(0.0, 1.55, 1.375)
			handle.position = Vector3(0.06, 1.4, 2.5)
		else:
			# Puerta orientada a lo largo del eje X
			leaf.size = Vector3(2.75, 3.1, 0.08)
			leaf.position = Vector3(1.375, 1.55, 0.0)
			handle.position = Vector3(2.5, 1.4, 0.06)
			
		hinge.add_child(leaf)
		hinge.add_child(handle)
		d["door_node"] = hinge

func _create_phantom() -> void:
	phantom_node = Node3D.new()
	phantom_node.name = "CriaturaGuiaP1"
	# Posición del jumpscare al darse vuelta: X: -40.0, Y: 4.7, Z: -33.2 (puerta de Bedelía P1)
	phantom_node.position = Vector3(-40.0, 4.7, -33.2)
	
	# Mirando directamente hacia nosotros/interior de Bedelía (giro de 180°)
	phantom_node.rotation_degrees = Vector3(0, 180, 0)
	
	var is_custom_tscn = ResourceLoader.exists("res://scenes/scp_096_guia.tscn")
	var scp_scene = _load_scp_scene()
	if scp_scene:
		var scp_inst = scp_scene.instantiate()
		scp_inst.name = "SCP096Model"
		
		# Si se carga desde el FBX crudo (no desde la escena editable .tscn), aplicamos la postura inicial por código
		if not is_custom_tscn:
			# El FBX importado en Godot ya viene en orientación Y-up con escala natural
			scp_inst.rotation_degrees = Vector3(0, 0, 0)
			# Escala ~0.82x que le otorga una altura masiva y proporcionada
			scp_inst.scale = Vector3(0.82, 0.82, 0.82)
			# Elevado a Y = 1.02 para que las plantas de los pies apoyen limpiamente arriba del suelo
			scp_inst.position = Vector3(0.0, 1.02, 0.0)
			
			# Asignar textura del cuerpo
			var mesh = scp_inst.find_child("scp096", true, false) as MeshInstance3D
			if mesh:
				var tex = load("res://scpcb-future-horror-mod-scp-096/textures/SCP096_fh_fix.jpg")
				if tex:
					var mat0 = mesh.get_active_material(0)
					if mat0 is StandardMaterial3D:
						var m_dup = mat0.duplicate() as StandardMaterial3D
						m_dup.albedo_texture = tex
						mesh.set_surface_override_material(0, m_dup)
			
		var anim = scp_inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim:
			anim.play("scp096_skeleton|idle2")
			
		phantom_node.add_child(scp_inst)
	else:
		# Respaldo si no se encuentra el modelo 3D
		_create_fallback_phantom(phantom_node)
	
	# Colisión sólida física en el vano de la puerta (deja espacio a los lados para pasar)
	var col_body = StaticBody3D.new()
	col_body.name = "CreatureCollision"
	creature_col_shape = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.55
	cap.height = 3.20
	creature_col_shape.shape = cap
	creature_col_shape.position = Vector3(0.0, 1.60, 0.0)
	creature_col_shape.disabled = true
	col_body.add_child(creature_col_shape)
	phantom_node.add_child(col_body)
	
	# Permanece invisible e inactivo hasta que se recoja el fusible
	phantom_node.visible = false
	add_child(phantom_node)

func _load_scp_scene() -> PackedScene:
	var path_tscn = "res://scenes/scp_096_guia.tscn"
	if ResourceLoader.exists(path_tscn):
		return load(path_tscn)
	var path_fbx = "res://scpcb-future-horror-mod-scp-096/source/SCP-096.fbx"
	if ResourceLoader.exists(path_fbx):
		return load(path_fbx)
	return null

func _create_fallback_phantom(parent: Node3D) -> void:
	var body = CSGCylinder3D.new()
	body.radius = 0.38
	body.height = 1.75
	body.position = Vector3(0, 0.88, 0)
	body.material = mat_phantom
	parent.add_child(body)
	
	var head = CSGSphere3D.new()
	head.radius = 0.24
	head.position = Vector3(0, 1.82, 0)
	head.material = mat_phantom
	parent.add_child(head)

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		_find_player()
		if not is_instance_valid(player):
			return
			
	# Solo actuar si el jugador está en el Primer Piso (Y entre 3.6 y 7.5)
	if player.global_position.y < 3.6 or player.global_position.y > 7.5:
		return
		
	var p_pos = player.global_position
	
	# 1. Chequeo de portazos en puertas cercanas
	for d in doors_data:
		if not d["is_slammed"]:
			var dist = p_pos.distance_to(d["trigger_pos"])
			if dist <= 4.0:
				_slam_door(d)
				
	# 2. Verificar recolección del fusible para hacer aparecer a SCP-096 esperando en la puerta
	if not scp_spawned:
		var hud_node = get_tree().root.find_child("HUD", true, false)
		if hud_node and "has_fuse" in hud_node and hud_node.has_fuse:
			_spawn_scp_waiting()
			
	# 3. Detectar cuando el jugador se da vuelta para salir y mira hacia SCP-096
	if is_waiting_for_turnaround and is_instance_valid(phantom_node):
		var cam: Camera3D = null
		if player.has_node("CameraPivot/Camera3D"):
			cam = player.get_node("CameraPivot/Camera3D") as Camera3D
		elif player.has_node("Camera3D"):
			cam = player.get_node("Camera3D") as Camera3D
		else:
			cam = player.find_child("Camera3D", true, false) as Camera3D
			
		if cam:
			var cam_fwd = -cam.global_transform.basis.z
			var to_scp = (phantom_node.global_position + Vector3(0, 1.8, 0) - cam.global_position).normalized()
			var dot = cam_fwd.dot(to_scp)
			var dist_to_scp = player.global_position.distance_to(phantom_node.global_position)
			
			# Cuando el jugador gira su cámara y mira hacia la criatura (cono de ~65°), o si se aproxima a la puerta:
			if dot > 0.40 or dist_to_scp < 2.8:
				_trigger_scp_turnaround_scare()

func _connect_fuse_signal() -> void:
	var fuses = get_tree().get_nodes_in_group("fusibles")
	for f in fuses:
		if f.has_signal("fuse_collected") and not f.fuse_collected.is_connected(_on_fuse_collected):
			f.fuse_collected.connect(_on_fuse_collected)

func _on_fuse_collected() -> void:
	_spawn_scp_waiting()

func _spawn_scp_waiting() -> void:
	if scp_spawned or not is_instance_valid(phantom_node):
		return
	scp_spawned = true
	is_waiting_for_turnaround = true
	
	# Parado en X: -40.0, Y: 4.7, Z: -33.2 viendo hacia nosotros/interior de Bedelía (+Z)
	phantom_node.position = Vector3(-40.0, 4.7, -33.2)
	phantom_node.rotation_degrees = Vector3(0, 180, 0)
	phantom_node.visible = true
	
	if creature_col_shape:
		creature_col_shape.disabled = false
		
	var anim = phantom_node.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		anim.play("scp096_skeleton|idle2")
		
	print(">>> SCP-096 aguardando en la salida de Bedelía (-40.0, 4.7, -33.2) mirando hacia el fusible.")

func _trigger_scp_turnaround_scare() -> void:
	is_waiting_for_turnaround = false
	if scp_stinger_played:
		return
	scp_stinger_played = true
	
	# Sonido espectral/stinger que tiene asignado, reproducido recién al darse vuelta
	var whisper = AudioStreamPlayer3D.new()
	whisper.name = "SCP096Stinger3D"
	whisper.stream = HorrorAudio.get_screamer_stinger()
	whisper.position = phantom_node.global_position + Vector3(0, 1.8, 0)
	whisper.volume_db = 6.0
	whisper.pitch_scale = 0.55
	whisper.unit_size = 10.0
	whisper.max_distance = 45.0
	whisper.bus = &"Master"
	add_child(whisper)
	whisper.play()
	whisper.finished.connect(whisper.queue_free)
	
	var stinger_2d = AudioStreamPlayer.new()
	stinger_2d.stream = HorrorAudio.get_screamer_stinger()
	stinger_2d.volume_db = 1.0
	stinger_2d.pitch_scale = 0.55
	stinger_2d.bus = &"Master"
	add_child(stinger_2d)
	stinger_2d.play()
	stinger_2d.finished.connect(stinger_2d.queue_free)
	
	if player.has_method("shake_camera"):
		player.shake_camera(0.65, 0.45)
	if player.has_method("trigger_post_screamer_heartbeat"):
		player.trigger_post_screamer_heartbeat(18.0)
		
	print(">>> ¡SCP-096 REVELADO AL DARSE VUELTA! Sonido espectral ejecutado.")

func _slam_door(d: Dictionary) -> void:
	d["is_slammed"] = true
	var hinge: Node3D = d["door_node"]
	if not is_instance_valid(hinge):
		return
		
	# Portazo violento con aceleración hacia el marco
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(hinge, "rotation:y", d["rot_closed"], 0.12)
	
	# Activar colisión al iniciar el cierre
	var leaf: CSGBox3D = hinge.get_node_or_null("DoorLeaf")
	if leaf:
		leaf.use_collision = true
	
	# Disparar el BANG en el instante exacto en que la puerta choca contra el marco
	tw.tween_callback(func():
		_play_loud_slam_sound(d["hinge_pos"])
		
		# Sacudida de cámara en el instante del impacto
		var dist = player.global_position.distance_to(d["trigger_pos"])
		if dist < 12.0 and player.has_method("shake_camera"):
			var intensity = clampf(1.0 - (dist / 12.0), 0.55, 1.25)
			player.shake_camera(intensity, 0.45)
	)

func _play_loud_slam_sound(hinge_pos: Vector3) -> void:
	var slam_stream: AudioStream = null
	var candidates = [
		"res://audio/sfx/door_slam_loud.mp3",
		"res://Door Slam - (Loud) Sound.mp3",
		"res://door_slam_loud.mp3"
	]
	for c in candidates:
		if ResourceLoader.exists(c):
			slam_stream = load(c)
			break
	if not slam_stream:
		slam_stream = HorrorAudio.get_wood_slam_sound()
		
	# 1. Reproductor 3D posicional a muy alto volumen
	var slam_player_3d = AudioStreamPlayer3D.new()
	slam_player_3d.stream = slam_stream
	slam_player_3d.position = hinge_pos
	slam_player_3d.volume_db = 27.0 # Decibeles incrementados para un golpe potente y resonante
	slam_player_3d.unit_size = 7.0
	slam_player_3d.max_distance = 60.0
	slam_player_3d.bus = &"Master"
	add_child(slam_player_3d)
	# Iniciar directamente en 1.54s donde estalla el golpe, omitiendo el silencio inicial del archivo
	slam_player_3d.play(1.54)
	slam_player_3d.finished.connect(slam_player_3d.queue_free)
	
	# 2. Capa de refuerzo estéreo directa para impacto de jumpscare
	var slam_boost = AudioStreamPlayer.new()
	slam_boost.stream = slam_stream
	slam_boost.volume_db = 13.0 # Refuerzo aumentado para susto inmediato
	slam_boost.bus = &"Master"
	add_child(slam_boost)
	slam_boost.play(1.54)
	slam_boost.finished.connect(slam_boost.queue_free)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		player = get_tree().root.find_child("Player", true, false) as CharacterBody3D

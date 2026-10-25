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
		"rot_open": deg_to_rad(-55.0),
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
		"rot_open": deg_to_rad(-55.0),
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
		"rot_open": deg_to_rad(55.0),
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
		"rot_open": deg_to_rad(55.0),
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
		"rot_open": deg_to_rad(55.0),
		"rot_closed": 0.0,
		"trigger_pos": Vector3(42.0, 4.6, 7.5),
		"is_slammed": false,
		"door_node": null,
		"axis": "z"
	}
]

# Referencia a la criatura del primer piso
var phantom_node: Node3D = null
var phantom_triggered: bool = false

# Materiales reutilizables
var mat_door: StandardMaterial3D = null
var mat_handle: StandardMaterial3D = null
var mat_phantom: StandardMaterial3D = null

func _ready() -> void:
	_init_materials()
	_create_doors()
	_create_phantom()

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
	# Parado estático en la ubicación exacta solicitada: X: -45.4, Y: 4.6 (apoyado en piso), Z: -31.3
	phantom_node.position = Vector3(-45.4, 4.6, -31.3)
	
	# Rotado a ~48° (apuntando a +X y +Z) para que quede mirando fijo de frente al jugador en el pasillo
	phantom_node.rotation.y = deg_to_rad(48.0)
	
	var scp_scene = _load_scp_scene()
	if scp_scene:
		var scp_inst = scp_scene.instantiate()
		scp_inst.name = "SCP096Model"
		# El FBX importado en Godot ya viene en orientación Y-up con escala natural
		scp_inst.rotation_degrees = Vector3(0, 0, 0)
		# Escala 0.90x que le otorga una altura colosal de ~3.82 metros (el doble de un humano, llenando hasta el techo de 4.4m)
		scp_inst.scale = Vector3(0.9, 0.9, 0.9)
		# Con escala 0.9, los pies en espacio local quedan en Y = -0.93; elevamos +0.93 para que apoye perfecto en el piso
		scp_inst.position = Vector3(0.0, 0.93, 0.0)
		
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
		
		# Animar un instante para adoptar postura y luego pausar
		var anim = scp_inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim:
			anim.play("scp096_skeleton|idle2")
			anim.advance(0.5)
			anim.pause()
		
		# Articular los huesos del brazo derecho (Bone_009 hombro, Bone_012 codo) para que señale directo a Bedelía
		var skel = scp_inst.find_child("Skeleton3D", true, false) as Skeleton3D
		if skel:
			var b_sh = skel.find_bone("Bone_009")
			var b_el = skel.find_bone("Bone_012")
			if b_sh >= 0:
				var cur_sh = skel.get_bone_pose_rotation(b_sh)
				var q_sh = Quaternion(Vector3(0, 0, 1), deg_to_rad(75.0))
				skel.set_bone_pose_rotation(b_sh, cur_sh * q_sh)
			if b_el >= 0:
				var cur_el = skel.get_bone_pose_rotation(b_el)
				var q_el = Quaternion(Vector3(0, 0, 1), deg_to_rad(-15.0))
				skel.set_bone_pose_rotation(b_el, cur_el * q_el)
				
		phantom_node.add_child(scp_inst)
	else:
		# Respaldo si no se encuentra el modelo 3D
		_create_fallback_phantom(phantom_node)
	
	# Colisión sólida física adaptada al doble de tamaño
	var col_body = StaticBody3D.new()
	col_body.name = "CreatureCollision"
	var col_shape = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.70
	cap.height = 3.80
	col_shape.shape = cap
	col_shape.position = Vector3(0.0, 1.90, 0.0)
	col_body.add_child(col_shape)
	phantom_node.add_child(col_body)
	
	add_child(phantom_node)

func _load_scp_scene() -> PackedScene:
	var path = "res://scpcb-future-horror-mod-scp-096/source/SCP-096.fbx"
	if ResourceLoader.exists(path):
		return load(path)
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
			if dist <= 7.0:
				_slam_door(d)
				
	# 2. Sonido espectral ambiental sutil la primera vez que el jugador se aproxima a la esquina
	if not phantom_triggered and is_instance_valid(phantom_node):
		if p_pos.distance_to(phantom_node.global_position) <= 12.0:
			phantom_triggered = true
			var whisper = AudioStreamPlayer3D.new()
			whisper.stream = HorrorAudio.get_screamer_stinger()
			whisper.position = phantom_node.position
			whisper.volume_db = -8.0
			whisper.pitch_scale = 0.55
			whisper.max_distance = 25.0
			add_child(whisper)
			whisper.play()
			whisper.finished.connect(whisper.queue_free)

func _slam_door(d: Dictionary) -> void:
	d["is_slammed"] = true
	var hinge: Node3D = d["door_node"]
	if not is_instance_valid(hinge):
		return
		
	# Portazo violento con aceleración hacia el marco
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(hinge, "rotation:y", d["rot_closed"], 0.16)
	
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
	slam_player_3d.volume_db = 22.0 # Decibeles notablemente aumentados para un susto potente
	slam_player_3d.unit_size = 6.0
	slam_player_3d.max_distance = 55.0
	slam_player_3d.bus = &"Master"
	add_child(slam_player_3d)
	# Iniciar directamente en 1.54s donde estalla el golpe, omitiendo el silencio inicial del archivo
	slam_player_3d.play(1.54)
	slam_player_3d.finished.connect(slam_player_3d.queue_free)
	
	# 2. Capa de refuerzo estéreo directa para impacto de jumpscare
	var slam_boost = AudioStreamPlayer.new()
	slam_boost.stream = slam_stream
	slam_boost.volume_db = 8.0
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

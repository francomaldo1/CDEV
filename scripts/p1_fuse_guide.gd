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
var creature_mesh_inst: MeshInstance3D = null
var creature_material: ShaderMaterial = null

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
	# Parado estático en la esquina X: -39.0, Y: 4.6 (apoyado en piso), Z: -25.6
	phantom_node.position = Vector3(-39.0, 4.6, -25.6)
	
	# Orientación apuntando con exactitud hacia la entrada de Bedelía General (X = -40.0, Z = -33.0)
	var bedelia_door_pos = Vector3(-40.0, 4.6, -33.0)
	var dir_to_door = bedelia_door_pos - phantom_node.position
	phantom_node.rotation.y = atan2(dir_to_door.x, dir_to_door.z)
	
	var creature_scene = _load_creature_scene()
	if creature_scene:
		var creature_inst = creature_scene.instantiate()
		creature_inst.name = "CreatureModel"
		# El modelo tiene los pies en Y = -0.997, por lo que compensamos +0.997 para apoyarlo justo en el piso de P1
		creature_inst.position = Vector3(0.0, 0.997, 0.0)
		
		# Buscar el MeshInstance3D y configurar el sombreador opaco original con cinemática de brazo y dedo
		creature_mesh_inst = _find_mesh_instance(creature_inst)
		if creature_mesh_inst:
			_setup_creature_shader(creature_mesh_inst)
			
		phantom_node.add_child(creature_inst)
	else:
		# Respaldo si no se encuentra el modelo 3D
		_create_fallback_phantom(phantom_node)
	
	# Colisión sólida física para que el jugador no atraviese el modelo
	var col_body = StaticBody3D.new()
	col_body.name = "CreatureCollision"
	var col_shape = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.95
	col_shape.shape = cap
	col_shape.position = Vector3(0.0, 0.98, 0.0)
	col_body.add_child(col_shape)
	phantom_node.add_child(col_body)
	
	add_child(phantom_node)

func _load_creature_scene() -> PackedScene:
	var path = "res://gaunt-horror-creature-free-creepy-3d-model/source/человек_у_ко_0828200815_texture.glb"
	if ResourceLoader.exists(path):
		return load(path)
	var dir = DirAccess.open("res://gaunt-horror-creature-free-creepy-3d-model/source")
	if dir:
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if fname.ends_with(".glb"):
				return load("res://gaunt-horror-creature-free-creepy-3d-model/source/" + fname)
			fname = dir.get_next()
	return null

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_mesh_instance(child)
		if found:
			return found
	return null

func _setup_creature_shader(mesh_inst: MeshInstance3D) -> void:
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled; // Renderizar ambas caras igual que el modelo original (evita huecos)

uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform sampler2D roughness_texture;
uniform sampler2D metallic_texture;

uniform float point_blend : hint_range(0.0, 1.0) = 0.0;
uniform float tremor_intensity : hint_range(0.0, 1.0) = 1.0;
uniform float finger_stretch : hint_range(0.0, 2.0) = 1.25;

void vertex() {
	// Brazo derecho de la criatura en espacio de modelo (X > 0.22, Y < 0.52, Y > -0.65)
	if (VERTEX.x > 0.22 && VERTEX.y < 0.52 && VERTEX.y > -0.65) {
		float weight = clamp((0.50 - VERTEX.y) / 0.15, 0.0, 1.0) * point_blend;
		vec3 shoulder = vec3(0.28, 0.45, 0.0);
		vec3 rel = VERTEX - shoulder;
		
		// Temblor tenso en el brazo y dedo al señalar
		float jitter = sin(TIME * 24.0 + VERTEX.y * 12.0) * 0.008 * tremor_intensity * point_blend;
		
		// Rotación hacia arriba y adelante (hacia +Z)
		float ang_x = -1.48 * weight + jitter;
		float cos_x = cos(ang_x);
		float sin_x = sin(ang_x);
		
		vec3 rot = vec3(
			rel.x,
			rel.y * cos_x - rel.z * sin_x,
			rel.y * sin_x + rel.z * cos_x
		);
		
		// El dedo índice frontal se alarga señalando de punta hacia la habitación
		if (VERTEX.y < -0.52 && VERTEX.z > 0.25) {
			rot.z += (0.35 * finger_stretch * weight);
		}
		
		VERTEX = shoulder + rot;
		
		NORMAL = vec3(
			NORMAL.x,
			NORMAL.y * cos_x - NORMAL.z * sin_x,
			NORMAL.y * sin_x + NORMAL.z * cos_x
		);
	}
}

void fragment() {
	// Texturas y materiales exactamente idénticos al modelo 3D original, 100% opaco
	vec4 alb = texture(albedo_texture, UV);
	ALBEDO = alb.rgb;
	NORMAL_MAP = texture(normal_texture, UV).rgb;
	NORMAL_MAP_DEPTH = 1.0;
	ROUGHNESS = texture(roughness_texture, UV).g; // Canal verde (G) estándar glTF
	METALLIC = texture(metallic_texture, UV).b;  // Canal azul (B) estándar glTF
}
"""
	creature_material = ShaderMaterial.new()
	creature_material.shader = shader
	
	var alb_paths = [
		"res://gaunt-horror-creature-free-creepy-3d-model/source/человек_у_ко_0828200815_texture_0.jpg",
		"res://gaunt-horror-creature-free-creepy-3d-model/textures/gltf_embedded_0.jpeg"
	]
	for p in alb_paths:
		if ResourceLoader.exists(p):
			creature_material.set_shader_parameter("albedo_texture", load(p))
			break
			
	var norm_paths = [
		"res://gaunt-horror-creature-free-creepy-3d-model/source/человек_у_ко_0828200815_texture_2.jpg",
		"res://gaunt-horror-creature-free-creepy-3d-model/textures/gltf_embedded_2.jpeg"
	]
	for p in norm_paths:
		if ResourceLoader.exists(p):
			creature_material.set_shader_parameter("normal_texture", load(p))
			break
			
	var rough_paths = [
		"res://gaunt-horror-creature-free-creepy-3d-model/source/человек_у_ко_0828200815_texture_1.jpg",
		"res://gaunt-horror-creature-free-creepy-3d-model/textures/gltf_embedded_1@channels=B.jpeg"
	]
	for p in rough_paths:
		if ResourceLoader.exists(p):
			var tex = load(p)
			creature_material.set_shader_parameter("roughness_texture", tex)
			creature_material.set_shader_parameter("metallic_texture", tex)
			break
			
	creature_material.set_shader_parameter("point_blend", 1.0) # Apuntando estático desde el inicio
	creature_material.set_shader_parameter("tremor_intensity", 0.75)
	creature_material.set_shader_parameter("finger_stretch", 1.25)
	
	mesh_inst.material_override = creature_material

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

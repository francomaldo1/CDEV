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

# Referencia a la silueta del fantasma
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
	phantom_node.name = "AlumnoFantasma"
	# Parado al final del pasillo oeste antes de doblar hacia Bedelía
	phantom_node.position = Vector3(-42.0, 4.6, -24.0)
	phantom_node.rotation.y = deg_to_rad(180.0) # Mirando hacia el jugador que sube por el pasillo oeste
	
	# Cuerpo del fantasma
	var body = CSGCylinder3D.new()
	body.radius = 0.38
	body.height = 1.75
	body.position = Vector3(0, 0.88, 0)
	body.material = mat_phantom
	phantom_node.add_child(body)
	
	# Cabeza / capucha
	var head = CSGSphere3D.new()
	head.radius = 0.24
	head.position = Vector3(0, 1.82, 0)
	head.material = mat_phantom
	phantom_node.add_child(head)
	
	# Ojos pálidos espectrales
	var eye_mat = StandardMaterial3D.new()
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(0.8, 0.9, 1.0)
	eye_mat.emission_energy_multiplier = 2.5
	eye_mat.albedo_color = Color(1, 1, 1, 1)
	
	var eye_l = CSGSphere3D.new()
	eye_l.radius = 0.04
	eye_l.position = Vector3(-0.08, 1.85, 0.21)
	eye_l.material = eye_mat
	phantom_node.add_child(eye_l)
	
	var eye_r = CSGSphere3D.new()
	eye_r.radius = 0.04
	eye_r.position = Vector3(0.08, 1.85, 0.21)
	eye_r.material = eye_mat
	phantom_node.add_child(eye_r)
	
	# Luz muy tenue alrededor de la figura
	var aura = OmniLight3D.new()
	aura.light_color = Color(0.3, 0.5, 0.9)
	aura.light_energy = 0.3
	aura.omni_range = 3.5
	aura.shadow_enabled = false
	phantom_node.add_child(aura)
	
	add_child(phantom_node)

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
				
	# 2. Chequeo de la aparición y escape del fantasma hacia Bedelía
	if not phantom_triggered and is_instance_valid(phantom_node):
		# Cuando el jugador avanza por el pasillo oeste hacia el norte (Z <= 2.0):
		if p_pos.x <= -35.0 and p_pos.z <= 2.0:
			phantom_triggered = true
			_trigger_phantom_guide()

func _slam_door(d: Dictionary) -> void:
	d["is_slammed"] = true
	var hinge: Node3D = d["door_node"]
	if not is_instance_valid(hinge):
		return
		
	# Portazo violento con rotación rápida
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(hinge, "rotation:y", d["rot_closed"], 0.12)
	
	# Sonido estruendoso del portazo
	var slam_player = AudioStreamPlayer3D.new()
	slam_player.stream = HorrorAudio.get_wood_slam_sound()
	slam_player.position = d["hinge_pos"]
	slam_player.volume_db = 8.0
	slam_player.max_distance = 35.0
	add_child(slam_player)
	slam_player.play()
	slam_player.finished.connect(slam_player.queue_free)
	
	# Sacudida de cámara si el jugador está cerca
	var dist = player.global_position.distance_to(d["trigger_pos"])
	if dist < 8.0 and player.has_method("shake_camera"):
		var intensity = clampf(1.0 - (dist / 8.0), 0.35, 0.85)
		player.shake_camera(intensity, 0.35)
		
	# Activar colisión para que no se pueda ingresar
	var leaf: CSGBox3D = hinge.get_node_or_null("DoorLeaf")
	if leaf:
		leaf.use_collision = true
		
	# Sonido posterior de picaporte trabado / traba metálica
	var timer = get_tree().create_timer(0.22)
	timer.timeout.connect(func():
		var rattle = AudioStreamPlayer3D.new()
		rattle.stream = HorrorAudio.get_door_rattle_sound()
		rattle.position = d["hinge_pos"]
		rattle.volume_db = 2.0
		rattle.max_distance = 25.0
		add_child(rattle)
		rattle.play()
		rattle.finished.connect(rattle.queue_free)
	)

func _trigger_phantom_guide() -> void:
	if not is_instance_valid(phantom_node):
		return
		
	# Sonido sutil espectral / suspiro frío
	var whisper = AudioStreamPlayer3D.new()
	whisper.stream = HorrorAudio.get_screamer_stinger()
	whisper.position = phantom_node.position
	whisper.volume_db = -8.0
	whisper.pitch_scale = 0.65
	whisper.max_distance = 30.0
	add_child(whisper)
	whisper.play()
	whisper.finished.connect(whisper.queue_free)
	
	# Animación: El fantasma gira hacia Bedelía y se desliza velozmente hacia la puerta
	var tw = create_tween()
	# Gira hacia la entrada de Bedelía en X = -40, Z = -33
	tw.tween_property(phantom_node, "rotation:y", deg_to_rad(90.0), 0.20)
	# Se desliza flotando hacia la puerta de Bedelía
	tw.tween_property(phantom_node, "position", Vector3(-40.0, 4.6, -33.0), 0.95)
	# Al llegar a la puerta, se desvanece entrando al aula
	tw.tween_callback(func():
		if is_instance_valid(phantom_node):
			var fade_tw = create_tween()
			for child in phantom_node.get_children():
				if child is GeometryInstance3D and child.material:
					fade_tw.parallel().tween_property(child.material, "albedo_color:a", 0.0, 0.4)
				elif child is Light3D:
					fade_tw.parallel().tween_property(child, "light_energy", 0.0, 0.4)
			fade_tw.tween_callback(phantom_node.queue_free)
	)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		player = get_tree().root.find_child("Player", true, false) as CharacterBody3D

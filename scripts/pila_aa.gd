extends Area3D
class_name PilaAA

signal battery_collected(amount: int)

@export var battery_amount: int = 1

var is_player_nearby: bool = false
var player_ref: CharacterBody3D = null
var light: OmniLight3D = null
var mesh_container: Node3D = null

func _ready() -> void:
	add_to_group("baterias")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Colisión para interacción por cercanía
	var col = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 1.8
	col.shape = sphere
	col.position = Vector3(0, 0.2, 0)
	add_child(col)
	
	_build_visuals()

func _build_visuals() -> void:
	mesh_container = Node3D.new()
	mesh_container.name = "BatteryVisual"
	mesh_container.position = Vector3(0.0, 0.02, 0.0)
	add_child(mesh_container)
	
	var fbx_path = "res://models/aa-battery/source/AA_Battery.fbx"
	if ResourceLoader.exists(fbx_path):
		var fbx_scene = load(fbx_path) as PackedScene
		if fbx_scene:
			var inst = fbx_scene.instantiate()
			# Escala visible del pack de 5 pilas (~24 cm de ancho, ~16 cm de alto)
			inst.scale = Vector3(3.6, 3.6, 3.6)
			# Centrar el conjunto de 5 pilas sobre la posición de interacción
			inst.position = Vector3(-0.10, 0.015, -0.05)
			inst.rotation_degrees = Vector3(0.0, -25.0, 0.0)
			
			# Material PBR fiel al modelo original sin emisión que lave el color
			var mat = StandardMaterial3D.new()
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			if ResourceLoader.exists("res://models/aa-battery/textures/AA_Battery_BaseColor.png"):
				mat.albedo_texture = load("res://models/aa-battery/textures/AA_Battery_BaseColor.png")
			if ResourceLoader.exists("res://models/aa-battery/textures/AA_Battery_Metallic.png"):
				mat.metallic = 0.85
				mat.metallic_texture = load("res://models/aa-battery/textures/AA_Battery_Metallic.png")
			if ResourceLoader.exists("res://models/aa-battery/textures/AA_Battery_Roughness.png"):
				mat.roughness = 0.35
				mat.roughness_texture = load("res://models/aa-battery/textures/AA_Battery_Roughness.png")
			if ResourceLoader.exists("res://models/aa-battery/textures/AA_Battery_Normal.png"):
				mat.normal_enabled = true
				mat.normal_texture = load("res://models/aa-battery/textures/AA_Battery_Normal.png")
			if ResourceLoader.exists("res://models/aa-battery/textures/AA_Battery_AO.png"):
				mat.ao_enabled = true
				mat.ao_texture = load("res://models/aa-battery/textures/AA_Battery_AO.png")
			
			# Aplicar el material a las 5 pilas del pack (3 paradas y 2 acostadas adelante)
			for c in inst.get_children():
				if c is MeshInstance3D:
					c.material_override = mat
				
			mesh_container.add_child(inst)
	else:
		# Fallback geométrico
		var cyl = CSGCylinder3D.new()
		cyl.radius = 0.035
		cyl.height = 0.16
		cyl.position = Vector3(0, 0.08, 0)
		var fb_mat = StandardMaterial3D.new()
		fb_mat.albedo_color = Color(0.3, 0.45, 0.7)
		fb_mat.metallic = 0.8
		cyl.material = fb_mat
		mesh_container.add_child(cyl)
		
	# Luz tenue neutra/cálida cenital que ilumina el pack y destaca el metal plateado y las etiquetas
	light = OmniLight3D.new()
	light.name = "BatteryGlow"
	light.position = Vector3(0.0, 0.35, 0.0)
	light.light_color = Color(1.0, 0.96, 0.88)
	light.light_energy = 0.7
	light.omni_range = 2.0
	light.shadow_enabled = false
	add_child(light)

func _process(_delta: float) -> void:
	if light:
		light.light_energy = 0.65 + sin(Time.get_ticks_msec() * 0.003) * 0.1
		
	if is_player_nearby and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
		_collect()

func _collect() -> void:
	if is_instance_valid(player_ref) and player_ref.has_method("add_battery"):
		player_ref.add_battery(battery_amount)
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")
			var total_b = player_ref.get("battery_count")
			var b_txt = " (Total en mochila: %d)" % total_b if total_b != null else ""
			hud.show_temporary_alert("🔋 ¡Pilas AA recogidas! Presioná [R] para recargar la cámara.%s" % b_txt, Color(0.3, 1.0, 0.55))
			if hud.has_method("update_inventory_display"):
				hud.update_inventory_display()
				
		_play_pickup_sound()
			
	battery_collected.emit(battery_amount)
	queue_free()

func _play_pickup_sound() -> void:
	var p = AudioStreamPlayer.new()
	p.bus = &"Master"
	p.volume_db = -3.0
	get_tree().root.add_child(p)
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 44100
	gen.buffer_length = 0.15
	p.stream = gen
	p.play()
	var pb = p.get_stream_playback()
	if pb:
		var frames = int(44100 * 0.10)
		for i in range(frames):
			var t = float(i) / 44100.0
			var f = 900.0 + t * 2500.0
			var env = exp(-t * 28.0)
			var s = sin(TAU * f * t) * env * 0.35
			pb.push_frame(Vector2(s, s))
	p.finished.connect(p.queue_free)

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("[E] Agarrar Pilas AA (Inventario)")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

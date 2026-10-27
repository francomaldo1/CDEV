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
	col.position = Vector3(0, 0.25, 0)
	add_child(col)
	
	_build_visuals()

func _build_visuals() -> void:
	mesh_container = Node3D.new()
	mesh_container.name = "BatteryVisual"
	mesh_container.position = Vector3(0.0, 0.06, 0.0)
	add_child(mesh_container)
	
	var fbx_path = "res://aa-battery/source/AA_Battery.fbx"
	if ResourceLoader.exists(fbx_path):
		var fbx_scene = load(fbx_path) as PackedScene
		if fbx_scene:
			var inst = fbx_scene.instantiate()
			# Eliminar las 4 mallas duplicadas del paquete original y conservar solo una pila limpia
			for c in inst.get_children():
				if c.name != "AA_Battery_low":
					c.queue_free()
			
			# Escala visible y nítida (~23 cm de largo y 6 cm de diámetro para destacar en el piso)
			inst.scale = Vector3(5.5, 5.5, 5.5)
			# Acostada sobre el piso con leve ángulo estético
			inst.rotation_degrees = Vector3(90.0, 30.0, 0.0)
			inst.position = Vector3(0.0, 0.03, 0.0)
			
			# Material PBR realista con texturas originales y sutil resplandor dorado
			var mat = StandardMaterial3D.new()
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			if ResourceLoader.exists("res://aa-battery/textures/AA_Battery_BaseColor.png"):
				mat.albedo_texture = load("res://aa-battery/textures/AA_Battery_BaseColor.png")
			if ResourceLoader.exists("res://aa-battery/textures/AA_Battery_Metallic.png"):
				mat.metallic = 0.95
				mat.metallic_texture = load("res://aa-battery/textures/AA_Battery_Metallic.png")
			if ResourceLoader.exists("res://aa-battery/textures/AA_Battery_Roughness.png"):
				mat.roughness = 0.35
				mat.roughness_texture = load("res://aa-battery/textures/AA_Battery_Roughness.png")
			if ResourceLoader.exists("res://aa-battery/textures/AA_Battery_Normal.png"):
				mat.normal_enabled = true
				mat.normal_texture = load("res://aa-battery/textures/AA_Battery_Normal.png")
			if ResourceLoader.exists("res://aa-battery/textures/AA_Battery_AO.png"):
				mat.ao_enabled = true
				mat.ao_texture = load("res://aa-battery/textures/AA_Battery_AO.png")
			
			# Sutil resplandor ámbar/dorado para que sea fácilmente distinguible en la oscuridad
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.85, 0.45)
			mat.emission_energy_multiplier = 0.35
			
			var low_mesh = inst.get_node_or_null("AA_Battery_low") as MeshInstance3D
			if low_mesh:
				low_mesh.material_override = mat
				
			mesh_container.add_child(inst)
	else:
		# Fallback geométrico cilíndrico
		var cyl = CSGCylinder3D.new()
		cyl.radius = 0.03
		cyl.height = 0.16
		cyl.rotation_degrees = Vector3(90, 0, 0)
		cyl.position = Vector3(0, 0.04, 0)
		var fb_mat = StandardMaterial3D.new()
		fb_mat.albedo_color = Color(1.0, 0.75, 0.2)
		fb_mat.metallic = 0.8
		fb_mat.emission_enabled = true
		fb_mat.emission = Color(1.0, 0.8, 0.3)
		fb_mat.emission_energy_multiplier = 0.5
		cyl.material = fb_mat
		mesh_container.add_child(cyl)
		
	# Luz tenue cálida que resalta el objeto en la oscuridad
	light = OmniLight3D.new()
	light.name = "BatteryGlow"
	light.position = Vector3(0.0, 0.25, 0.0)
	light.light_color = Color(1.0, 0.92, 0.75)
	light.light_energy = 0.65
	light.omni_range = 1.8
	light.shadow_enabled = false
	add_child(light)

func _process(_delta: float) -> void:
	if light:
		light.light_energy = 0.55 + sin(Time.get_ticks_msec() * 0.004) * 0.15
		
	# Leve flotación sutil de 2cm para garantizar que siempre esté por encima del piso
	if mesh_container:
		mesh_container.position.y = 0.06 + sin(Time.get_ticks_msec() * 0.003) * 0.02
		
	if is_player_nearby and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
		_collect()

func _collect() -> void:
	if is_instance_valid(player_ref) and player_ref.has_method("add_battery"):
		player_ref.add_battery(battery_amount)
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")
			var total_b = player_ref.get("battery_count")
			var b_txt = " (Total: %d)" % total_b if total_b != null else ""
			hud.show_temporary_alert("🔋 ¡Pila AA guardada en el inventario! Presioná [R] para recargar la cámara.%s" % b_txt, Color(0.3, 1.0, 0.55))
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
			hud.set_interact_prompt("[E] Agarrar Pila AA (Inventario)")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

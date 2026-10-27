extends Area3D
class_name PilaAA

signal battery_collected(amount: float)

@export var recharge_amount: float = 50.0

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
	sphere.radius = 1.6
	col.shape = sphere
	col.position = Vector3(0, 0.25, 0)
	add_child(col)
	
	_build_visuals()

func _build_visuals() -> void:
	mesh_container = Node3D.new()
	mesh_container.name = "BatteryVisual"
	add_child(mesh_container)
	
	var fbx_path = "res://aa-battery/source/AA_Battery.fbx"
	if ResourceLoader.exists(fbx_path):
		var fbx_scene = load(fbx_path) as PackedScene
		if fbx_scene:
			var inst = fbx_scene.instantiate()
			# Escala visible (~15 cm de largo)
			inst.scale = Vector3(380.0, 380.0, 380.0)
			# Apoyada horizontalmente sobre el suelo con ligera inclinación estética
			inst.rotation_degrees = Vector3(90.0, 35.0, 0.0)
			inst.position = Vector3(0.0, 0.06, 0.0)
			
			# Aplicar materiales PBR originales
			var mat = StandardMaterial3D.new()
			if ResourceLoader.exists("res://aa-battery/textures/AA_Battery_BaseColor.png"):
				mat.albedo_texture = load("res://aa-battery/textures/AA_Battery_BaseColor.png")
			if ResourceLoader.exists("res://aa-battery/textures/AA_Battery_Metallic.png"):
				mat.metallic = 0.9
				mat.metallic_texture = load("res://aa-battery/textures/AA_Battery_Metallic.png")
			if ResourceLoader.exists("res://aa-battery/textures/AA_Battery_Roughness.png"):
				mat.roughness_texture = load("res://aa-battery/textures/AA_Battery_Roughness.png")
			if ResourceLoader.exists("res://aa-battery/textures/AA_Battery_Normal.png"):
				mat.normal_enabled = true
				mat.normal_texture = load("res://aa-battery/textures/AA_Battery_Normal.png")
			if ResourceLoader.exists("res://aa-battery/textures/AA_Battery_AO.png"):
				mat.ao_enabled = true
				mat.ao_texture = load("res://aa-battery/textures/AA_Battery_AO.png")
				
			# Sutil emisión verde/cálida para que se vea claramente a oscuras
			mat.emission_enabled = true
			mat.emission = Color(0.25, 0.9, 0.45)
			mat.emission_energy_multiplier = 0.35
			
			for c in inst.get_children():
				if c is MeshInstance3D:
					c.set_surface_override_material(0, mat)
					
			mesh_container.add_child(inst)
	else:
		# Fallback geométrico si no cargase el FBX
		var cyl = CSGCylinder3D.new()
		cyl.radius = 0.04
		cyl.height = 0.14
		cyl.rotation_degrees = Vector3(90, 0, 0)
		cyl.position = Vector3(0, 0.05, 0)
		var fb_mat = StandardMaterial3D.new()
		fb_mat.albedo_color = Color(0.15, 0.75, 0.35)
		fb_mat.metallic = 0.8
		fb_mat.emission_enabled = true
		fb_mat.emission = Color(0.2, 0.8, 0.4)
		fb_mat.emission_energy_multiplier = 0.5
		cyl.material = fb_mat
		mesh_container.add_child(cyl)
		
	# Luz tenue localizada que resalta su posición sobre el piso
	light = OmniLight3D.new()
	light.name = "BatteryGlow"
	light.position = Vector3(0.0, 0.25, 0.0)
	light.light_color = Color(0.35, 1.0, 0.6)
	light.light_energy = 0.45
	light.omni_range = 2.2
	light.shadow_enabled = false
	add_child(light)

func _process(_delta: float) -> void:
	if light:
		# Pulsación sutil y suave de faro guía
		light.light_energy = 0.35 + sin(Time.get_ticks_msec() * 0.005) * 0.15
		
	if is_player_nearby and (Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E)):
		_collect()

func _collect() -> void:
	if is_instance_valid(player_ref) and player_ref.has_method("recharge_night_vision"):
		var gained = player_ref.recharge_night_vision(recharge_amount)
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")
			var pct_txt = "+%d%%" % int(gained)
			hud.show_temporary_alert("🔋 ¡Pila AA recogida! %s de batería para la cámara." % pct_txt, Color(0.3, 1.0, 0.55))
			
	battery_collected.emit(recharge_amount)
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("[E] Recoger Pila AA (+50% Batería Videocámara)")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

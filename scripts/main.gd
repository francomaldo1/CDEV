extends Node3D

@onready var mic_detector = $MicDetector
@onready var hud = $HUD
@onready var profesor = $Profesor
@onready var player = $Player
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var moon_light: DirectionalLight3D = $MoonLight

var cuaderno_scene = preload("res://scenes/cuaderno_matematica.tscn")
var puerta_salida_scene = preload("res://scenes/puerta_salida.tscn")
var tablero_scene = preload("res://scenes/tablero_electrico.tscn")
var fusible_scene = preload("res://scenes/fusible.tscn")
var tacho_scene = preload("res://scenes/tacho_basura.tscn")

## Cantidad total de exámenes (cuadernos) que aparecen en las aulas
@export var total_exams: int = 4
## Exámenes aprobados necesarios para el corte de luz (y la aparición del profesor)
@export var exams_for_blackout: int = 2
## Exámenes aprobados necesarios para habilitar el piso de arriba
@export var exams_for_upper_floor: int = 4

## Cuadernos aprobados (cada uno cuenta una sola vez)
var exams_approved: Array = []
## Posición original del profesor (la que tiene en main.tscn)
var profesor_spawn_transform: Transform3D
## Barreras que bloquean las escaleras hasta aprobar todos los exámenes
var upper_floor_blockers: Array[Node3D] = []

## Susto cinemático del 4to examen (corrida por el pasillo al darse vuelta)
var is_waiting_for_turnaround_scare: bool = false
var scare_cuaderno_pos: Vector3 = Vector3.ZERO
var scare_cuaderno_name: String = ""
var scare_initial_player_yaw: float = 0.0
var scare_initial_player_pos: Vector3 = Vector3.ZERO
var scare_wait_timer: float = 0.0

## Espera de salida del Laboratorio de Electrónica tras restaurar la luz
var is_waiting_for_lab_exit: bool = false
var lab_exit_wait_timer: float = 0.0

var tablero_electrico: Area3D = null
var is_blackout: bool = false
var original_ambient_energy: float = 0.4
var original_moon_energy: float = 0.38

var ambient_drone_player: AudioStreamPlayer = null
var spook_audio_3d: AudioStreamPlayer3D = null
var spook_interval_timer: float = 0.0
var next_spook_delay: float = 12.0

## Ubicaciones de cuadernos en todas las aulas de Planta Baja
var classroom_spots = [
	{"pos": Vector3(-17.8, 0.15, 41.3), "name": "Fotocopiadora 1 (Examen #1)"},
	{"pos": Vector3(-56.5, 0.82, -11.8), "name": "Aula 106 (Examen #4)"},
	{"pos": Vector3(0.0, 0.62, 1.6), "name": "Patio del Estudiante (Examen #3)"},
	{"pos": Vector3(50.5, 0.78, -8.5), "name": "Cafeteria PB (Examen #2)"},
]

func _ready() -> void:
	randomize()
	
	_setup_ambient_audio()
	
	if mic_detector and hud:
		mic_detector.volume_updated.connect(hud.on_mic_volume_updated)
		mic_detector.set_mic_active(false)
	add_child(preload("res://scripts/hoja_pisos.gd").new())
		
	if world_env and world_env.environment:
		original_ambient_energy = world_env.environment.ambient_light_energy
	if moon_light:
		original_moon_energy = moon_light.light_energy
		
	_spawn_exit_door()
	_spawn_tablero_electronica()
	_spawn_fusible()
	_spawn_multiple_cuadernos()
	_spawn_upper_floor_blockers()
	_spawn_tachos_basura()
	_spawn_p1_fuse_guide()
	_setup_peronachos_shelves()
	_spawn_pilas_aa()
	if hud and hud.has_method("set_objective_text"):
		hud.set_objective_text("OBJETIVO: Rendir los 4 parciales en Planta Baja (0/4)")
	
	# El profesor no está al principio: aparece con el corte de luz
	if profesor:
		profesor_spawn_transform = profesor.global_transform
		profesor.set_active(false)
	
	# El corte de luz ahora se dispara al realizar exams_for_blackout exámenes (ver _on_exam_solved)
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
	luz_tablero.light_energy = 0.25
	luz_tablero.omni_range = 5.0
	luz_tablero.shadow_enabled = true
	luz_tablero.add_to_group("building_lights")
	add_child(luz_tablero)

	# Luz de techo central del laboratorio (ilumina desde atrás y proyecta la sombra del profesor)
	var luz_techo_lab = OmniLight3D.new()
	luz_techo_lab.name = "LuzTechoLabElectronica"
	luz_techo_lab.position = Vector3(-25.0, 3.6, 0.0)
	luz_techo_lab.light_color = Color(0.9, 0.95, 1.0)
	luz_techo_lab.light_energy = 0.28
	luz_techo_lab.omni_range = 11.0
	luz_techo_lab.shadow_enabled = true
	luz_techo_lab.add_to_group("building_lights")
	add_child(luz_techo_lab)
	
	_spawn_hilera_luces_lab()
	
	print(">>> Tablero Eléctrico instalado en Depto. de Electrónica (con iluminación y sombras de laboratorio)")

func _spawn_hilera_luces_lab() -> void:
	var root_hilera = Node3D.new()
	root_hilera.name = "HileraLucesLabElectronica"
	add_child(root_hilera)
	
	# 6 posiciones desde cerca del tablero (X = -19.5) hasta la puerta (X = -36.5) a lo largo de Z = 0.9
	var light_x_positions = [-19.5, -23.0, -26.5, -30.0, -33.5, -36.5]
	var mat_fixture = StandardMaterial3D.new()
	mat_fixture.albedo_color = Color(0.12, 0.14, 0.16)
	
	for i in range(light_x_positions.size()):
		var x_pos = light_x_positions[i]
		var lamp_pos = Vector3(x_pos, 3.65, 0.9)
		var is_door_lamp = (i == light_x_positions.size() - 1)
		
		var fixture = CSGBox3D.new()
		fixture.name = "Fixture_%d" % i
		fixture.position = lamp_pos + Vector3(0, 0.04, 0)
		fixture.size = Vector3(1.1, 0.08, 0.28)
		fixture.material = mat_fixture
		root_hilera.add_child(fixture)
		
		var tube = CSGBox3D.new()
		tube.name = "Tube_%d" % i
		tube.position = lamp_pos
		tube.size = Vector3(0.95, 0.04, 0.18)
		var mat_tube = StandardMaterial3D.new()
		mat_tube.albedo_color = Color(0.9, 0.95, 1.0)
		mat_tube.emission_enabled = false
		mat_tube.emission = Color(0.85, 0.94, 1.0)
		mat_tube.emission_energy_multiplier = 1.0
		tube.material = mat_tube
		root_hilera.add_child(tube)
		
		var spot = SpotLight3D.new()
		spot.name = "LuzLab_%d" % i
		spot.position = lamp_pos - Vector3(0, 0.05, 0)
		spot.rotation_degrees = Vector3(-90, 0, 0)
		spot.light_color = Color(0.85, 0.94, 1.0)
		spot.spot_angle = 68.0
		spot.spot_attenuation = 1.0
		if is_door_lamp:
			spot.light_energy = 2.4 # Foco intenso en la puerta sobre el profesor
			spot.spot_range = 8.0
		else:
			spot.light_energy = 1.3
			spot.spot_range = 6.5
		spot.shadow_enabled = true
		spot.visible = false
		spot.add_to_group("hilera_luces_lab")
		root_hilera.add_child(spot)

func _spawn_fusible() -> void:
	# El fusible está guardado en Bedelía General (Primer Piso, entrada en X = -40, Z = -33)
	# Se monta un mostrador/escritorio iluminado con luz cálida en el centro de Bedelía
	var desk = CSGBox3D.new()
	desk.name = "EscritorioBedelia"
	desk.position = Vector3(-40.0, 4.95, -39.0)
	desk.size = Vector3(2.4, 0.75, 1.2)
	desk.use_collision = true
	var mat_desk = StandardMaterial3D.new()
	mat_desk.albedo_color = Color(0.28, 0.20, 0.15)
	desk.material = mat_desk
	add_child(desk)
	
	var desk_light = OmniLight3D.new()
	desk_light.name = "LuzEscritorioBedelia"
	desk_light.position = Vector3(-40.0, 5.8, -39.0)
	desk_light.light_color = Color(1.0, 0.8, 0.45)
	desk_light.light_energy = 0.85
	desk_light.omni_range = 5.0
	desk_light.shadow_enabled = false
	add_child(desk_light)
	
	var fusible = fusible_scene.instantiate()
	fusible.position = Vector3(-40.0, 5.4, -39.0)
	add_child(fusible)
	print(">>> Fusible de alta tensión colocado sobre escritorio en Bedelía General P1 (-40.0, 5.4, -39.0)")

func _spawn_p1_fuse_guide() -> void:
	var p1_guide_script = preload("res://scripts/p1_fuse_guide.gd")
	var p1_guide = Node3D.new()
	p1_guide.name = "P1FuseGuide"
	p1_guide.set_script(p1_guide_script)
	add_child(p1_guide)

func _spawn_multiple_cuadernos() -> void:
	classroom_spots.shuffle()
	
	# Colocar los exámenes en aulas al azar
	var count = min(total_exams, classroom_spots.size())
	for i in range(count):
		var spot = classroom_spots[i]
		var cuaderno = cuaderno_scene.instantiate()
		cuaderno.position = spot["pos"]
		cuaderno.classroom_name = spot["name"]
		cuaderno.exam_solved.connect(_on_exam_solved.bind(cuaderno))
		add_child(cuaderno)
		print(">>> Cuaderno matemático colocado en: %s" % spot["name"])

func _on_exam_solved(success: bool, cuaderno: Node) -> void:
	# Solo cuentan los exámenes aprobados, y cada cuaderno una sola vez
	if not success or exams_approved.has(cuaderno):
		return
	exams_approved.append(cuaderno)
	var n = exams_approved.size()
	print(">>> Exámenes aprobados: %d / %d" % [n, total_exams])
	
	if hud and hud.has_method("set_exams_progress"):
		hud.set_exams_progress(n, total_exams)
	
	# Actualizar objetivo segun cantidad de parciales aprobados
	if n < total_exams:
		if hud and hud.has_method("set_objective_text"):
			hud.set_objective_text("OBJETIVO: Rendir los 4 parciales en Planta Baja (%d/%d)" % [n, total_exams])
	
	# Al 2do examen aprobado: el profesor comienza a patrullar la Planta Baja
	if n == 2 and is_instance_valid(profesor) and not profesor.is_active:
		_spawn_profesor()
		if hud and hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("👁️ ¡El profesor escucho las hojas! Salio a patrullar la Planta Baja...", Color(1.0, 0.4, 0.4))
	
	# Al 4to examen aprobado: todos listos -> Apagon general, furor del profesor y desbloqueo de escaleras
	if n >= total_exams:
		_unlock_upper_floor()
		if is_instance_valid(profesor) and not profesor.is_active:
			_spawn_profesor()
		_trigger_blackout()
		_prepare_fourth_exam_turnaround_scare(cuaderno)
		if is_instance_valid(profesor) and profesor.has_method("activate_enraged_final_phase"):
			profesor.activate_enraged_final_phase()
		if hud and hud.has_method("set_objective_text"):
			hud.set_objective_text("NUEVO OBJETIVO: ¡Corte de luz! Buscá el fusible en Bedelía (P1) para recuperar la luz", Color(1.0, 0.85, 0.2))

func _spawn_profesor() -> void:
	if not profesor:
		return
	profesor.global_transform = profesor_spawn_transform
	profesor.set_active(true)
	print(">>> ¡El profesor apareció!")

func _spawn_upper_floor_blockers() -> void:
	# Bloquea la entrada de planta baja a las 3 torres de escaleras
	var bloqueos = [
		{"name": "BloqueoEscaleraOeste", "pos": Vector3(-65.0, 2.25, 30.0), "size": Vector3(0.5, 4.5, 10.4)},
		{"name": "BloqueoEscaleraEste",  "pos": Vector3(65.0, 2.25, 30.0),  "size": Vector3(0.5, 4.5, 10.4)},
		{"name": "BloqueoEscaleraNorte", "pos": Vector3(42.0, 2.25, -45.0), "size": Vector3(10.4, 4.5, 0.5)}
	]
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.75, 0.0, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	for b in bloqueos:
		var body = StaticBody3D.new()
		body.name = b["name"]
		body.position = b["pos"]
		
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = b["size"]
		shape.shape = box
		body.add_child(shape)
		
		var mesh_inst = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = b["size"]
		mesh_inst.mesh = mesh
		mesh_inst.material_override = mat
		body.add_child(mesh_inst)
		
		var label = Label3D.new()
		label.text = "PISO SUPERIOR CERRADO\nAprobá los %d parciales" % exams_for_upper_floor
		label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		label.font_size = 48
		label.outline_size = 10
		label.modulate = Color(1.0, 0.8, 0.2)
		label.position = Vector3(0, 0.3, 0)
		body.add_child(label)
		
		add_child(body)
		upper_floor_blockers.append(body)
		
		# El profesor puede atravesar las barreras (para que no se trabe)
		if profesor:
			profesor.add_collision_exception_with(body)

func _unlock_upper_floor() -> void:
	for b in upper_floor_blockers:
		if is_instance_valid(b):
			b.queue_free()
	upper_floor_blockers.clear()
	print(">>> ¡PISO SUPERIOR HABILITADO!")

func _spawn_tachos_basura() -> void:
	var spots = [
		# PLANTA BAJA (PB) - Ubicados contra paños ciegos de pared, lejos de puertas de aulas
		{"pos": Vector3(-46.05, 0.0, -19.0), "rot": Vector3(0, 90, 0),   "desc": "Pasillo Oeste Norte PB"},
		{"pos": Vector3(-46.05, 0.0, -5.0),  "rot": Vector3(0, 90, 0),   "desc": "Pasillo Oeste Centro PB"},
		{"pos": Vector3(-46.05, 0.0, 10.0),  "rot": Vector3(0, 90, 0),   "desc": "Pasillo Oeste Sur PB"},
		{"pos": Vector3(46.05, 0.0, -23.0),  "rot": Vector3(0, -90, 0),  "desc": "Pasillo Este Norte PB"},
		{"pos": Vector3(46.05, 0.0, 8.0),    "rot": Vector3(0, -90, 0),  "desc": "Pasillo Este Sur PB"},
		# Pasillo Norte PB: ubicados al ras de la pared norte (Z = -32.45), reemplazando los lockers anteriores
		{"pos": Vector3(12.04, 0.0, -32.45), "rot": Vector3(0, 0, 0),    "desc": "Pasillo Norte Este PB"},
		{"pos": Vector3(-14.95, 0.0, -32.45), "rot": Vector3(0, 0, 0),   "desc": "Pasillo Norte Centro PB"},
		{"pos": Vector3(-37.6, 0.0, -32.45), "rot": Vector3(0, 0, 0),    "desc": "Pasillo Norte Extremo Oeste PB"},
		{"pos": Vector3(-37.55, 0.0, -8.0),  "rot": Vector3(0, -90, 0),  "desc": "Lab Electronica Entrada PB"},
		{"pos": Vector3(-18.0, 0.0, 21.85),  "rot": Vector3(0, 180, 0),  "desc": "Galeria Patio Oeste PB"},
		{"pos": Vector3(18.0, 0.0, 21.85),   "rot": Vector3(0, 180, 0),  "desc": "Galeria Patio Este PB"},
		{"pos": Vector3(-20.0, 0.0, 33.85),  "rot": Vector3(0, 180, 0),  "desc": "Pasillo Fotocopiadora PB"},

		# PRIMER PISO (P1)
		{"pos": Vector3(-46.05, 4.5, -9.0),  "rot": Vector3(0, 90, 0),   "desc": "Pasillo Sistemas P1"},
		{"pos": Vector3(-46.05, 4.5, 20.0),  "rot": Vector3(0, 90, 0),   "desc": "Pasillo Electronica P1"},
		{"pos": Vector3(-22.0, 4.5, -32.45), "rot": Vector3(0, 0, 0),    "desc": "Pasillo Bedelia P1"},
		{"pos": Vector3(46.05, 4.5, -18.0),  "rot": Vector3(0, -90, 0),  "desc": "Pasillo CETRA P1"},
		{"pos": Vector3(46.05, 4.5, 18.0),   "rot": Vector3(0, -90, 0),  "desc": "Pasillo Biblioteca P1"},

		# SEGUNDO PISO (P2)
		{"pos": Vector3(-46.05, 9.0, -5.0),  "rot": Vector3(0, 90, 0),   "desc": "Pasillo Aulas Oeste P2"},
		{"pos": Vector3(46.05, 9.0, -8.0),   "rot": Vector3(0, -90, 0),  "desc": "Pasillo Aulas Este P2"},
		{"pos": Vector3(0.0, 9.0, -32.45),   "rot": Vector3(0, 0, 0),    "desc": "Pasillo Norte Aula Magna P2"},
		{"pos": Vector3(12.04, 9.0, -32.45), "rot": Vector3(0, 0, 0),    "desc": "Pasillo Norte Este P2"},
		{"pos": Vector3(-12.31, 9.0, -32.45), "rot": Vector3(0, 0, 0),   "desc": "Pasillo Norte Centro P2"},
		{"pos": Vector3(-36.66, 9.0, -32.45), "rot": Vector3(0, 0, 0),   "desc": "Pasillo Norte Oeste P2"},
		{"pos": Vector3(-14.0, 9.0, 33.85),  "rot": Vector3(0, 180, 0),  "desc": "Cafeteria Entrada Oeste P2"},
		{"pos": Vector3(14.0, 9.0, 33.85),   "rot": Vector3(0, 180, 0),  "desc": "Cafeteria Entrada Este P2"}
	]
	for s in spots:
		var tacho = tacho_scene.instantiate()
		tacho.position = s["pos"]
		tacho.rotation_degrees = s["rot"]
		tacho.name = "Tacho_" + s["desc"].replace(" ", "_").replace("(", "").replace(")", "")
		add_child(tacho)
		print(">>> Tacho de basura instalado en: %s %s" % [s["desc"], s["pos"]])

func _setup_peronachos_shelves() -> void:
	# 1. Configurar estante original en X=51.10 como interactivo
	var original_shelf_area = Area3D.new()
	original_shelf_area.name = "EstantePeronachos_Original"
	original_shelf_area.set_script(preload("res://scripts/peronachos_shelf.gd"))
	original_shelf_area.position = Vector3(51.10, 0.0, 4.0)
	
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.48, 1.8, 1.3)
	col.shape = box
	col.position = Vector3(0.0, 0.9, -0.2)
	original_shelf_area.add_child(col)
	
	add_child(original_shelf_area)
	
	# Recolectar las bolsas originales existentes en edificio_central
	var habit_pb = find_child("HabitacionesPB", true, false)
	var existing_bags: Array = []
	if habit_pb:
		for child in habit_pb.get_children():
			if child is MeshInstance3D and child.name.begins_with("Peronachos_T"):
				existing_bags.append(child)
				
	if original_shelf_area.has_method("register_external_bags"):
		original_shelf_area.register_external_bags(existing_bags)
	
	# 2. Instanciar el nuevo segundo estante al lado en X=51.65
	var estante_scene = preload("res://scenes/estante_peronachos.tscn")
	var second_shelf = estante_scene.instantiate()
	second_shelf.name = "EstantePeronachos_Segundo"
	second_shelf.position = Vector3(51.65, 0.0, 4.0)
	add_child(second_shelf)
	print(">>> Estantes de Peronachos configurados e interactivos en Cafetería PB (X: 51.10 y X: 51.65)")

func _spawn_pilas_aa() -> void:
	var pila_script = preload("res://scripts/pila_aa.gd")
	var battery_spots = [
		{"pos": Vector3(-58.5, 4.75, 27.5), "desc": "P1 Escalera Oeste"},
		{"pos": Vector3(39.0, 4.75, -34.0), "desc": "P1 Escalera Norte"},
		{"pos": Vector3(57.0, 4.75, 27.5), "desc": "P1 Escalera Este"},
		{"pos": Vector3(-45.0, 4.75, 12.0), "desc": "P1 Pasillo Oeste"},
	]
	for spot in battery_spots:
		var pila = Area3D.new()
		pila.set_script(pila_script)
		pila.name = "PilaAA_" + spot["desc"].replace(" ", "_")
		pila.position = spot["pos"]
		add_child(pila)
		print(">>> Pila AA instalada en: %s (%s)" % [spot["desc"], str(spot["pos"])])

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
				if curr.name == "Player" or curr.name == "Profesor" or curr.name == "TableroElectrico" or curr.name.begins_with("Fusible") or curr.name.begins_with("PilaAA"):
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
			
	# Oscuridad con visibilidad atmosférica tenue (siluetas de pasillos y puertas)
	if world_env and world_env.environment:
		world_env.environment.ambient_light_color = Color(0.18, 0.22, 0.32, 1.0)
		world_env.environment.ambient_light_color = Color(0.22, 0.28, 0.40, 1.0)
		world_env.environment.ambient_light_energy = 0.11
	if moon_light:
		moon_light.light_energy = 0.48
		moon_light.light_color = Color(0.50, 0.65, 0.90, 1.0)
		
	# Transicionar a dron oscuro de apagón
	if ambient_drone_player:
		ambient_drone_player.volume_db = 3.0
		if not ambient_drone_player.playing:
			ambient_drone_player.play()
		
	if tablero_electrico:
		tablero_electrico.trigger_blackout()
		
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
		world_env.environment.ambient_light_color = Color(0.04, 0.04, 0.06, 1.0)
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
			
	is_waiting_for_lab_exit = true
	lab_exit_wait_timer = 0.0
	print(">>> ¡ENERGÍA RESTABLECIDA EN TODA LA FACULTAD! Esperando que el jugador salga del Laboratorio para mostrar objetivo...")

func _process(delta: float) -> void:
	_process_light_flicker(delta)
	
	if is_waiting_for_turnaround_scare:
		_check_turnaround_scare(delta)
		
	if is_waiting_for_lab_exit:
		_check_lab_exit(delta)
	
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

## =====================================================================
## SUSTO DEL 4TO EXAMEN: CORRIDA POR EL PASILLO AL DARSE VUELTA
## =====================================================================
func _prepare_fourth_exam_turnaround_scare(cuaderno: Node) -> void:
	if not is_instance_valid(player) or not is_instance_valid(profesor):
		return
	is_waiting_for_turnaround_scare = true
	scare_cuaderno_pos = cuaderno.global_position if (cuaderno is Node3D) else (player.global_position if is_instance_valid(player) else Vector3.ZERO)
	var c_name = cuaderno.get("classroom_name")
	scare_cuaderno_name = str(c_name) if c_name != null else ""
	scare_initial_player_yaw = player.rotation.y
	scare_initial_player_pos = player.global_position
	scare_wait_timer = 0.0
	print(">>> 4to examen aprobado en: %s. Esperando giro de 180° para susto en el pasillo..." % scare_cuaderno_name)

func _check_turnaround_scare(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(profesor):
		is_waiting_for_turnaround_scare = false
		return

	scare_wait_timer += delta
	
	# Detectar giro de ~180° (mínimo 105°) respecto a la orientación al terminar el parcial
	var yaw_diff = absf(wrapf(player.rotation.y - scare_initial_player_yaw, -PI, PI))
	var moved_dist = player.global_position.distance_to(scare_initial_player_pos)
	
	var turned_around = yaw_diff >= deg_to_rad(105.0)
	var walked_away = moved_dist >= 2.0
	var timeout = scare_wait_timer >= 4.5
	
	if turned_around or walked_away or timeout:
		is_waiting_for_turnaround_scare = false
		_trigger_hallway_dash_scare()

func _check_lab_exit(delta: float) -> void:
	if not is_instance_valid(player):
		return
	lab_exit_wait_timer += delta
	var p_pos = player.global_position
	# Salir por la puerta del laboratorio hacia el pasillo oeste (X <= -37.0) o alejarse de la zona del tablero
	var has_exited = p_pos.x <= -37.0 or p_pos.distance_to(Vector3(-17.22, 0.0, 0.0)) > 21.0 or lab_exit_wait_timer >= 25.0
	if has_exited:
		is_waiting_for_lab_exit = false
		if hud and hud.has_method("set_objective_text"):
			hud.set_objective_text("NUEVO OBJETIVO: ¡Luz restablecida! Buscá la Llave del Auditorio en Planta Baja")
		print(">>> Jugador salió del Laboratorio de Electrónica -> Objetivo de la Llave del Auditorio mostrado")

func _trigger_hallway_dash_scare() -> void:
	if not is_instance_valid(profesor) or not is_instance_valid(player):
		return
		
	var points = _get_scare_dash_points(scare_cuaderno_pos, scare_cuaderno_name)
	var start_pos: Vector3 = points[0]
	var end_pos: Vector3 = points[1]
	
	# Efectos audiovisuales de terror (Stinger estridente del 4to examen)
	if player.has_method("play_horror_stinger"):
		player.play_horror_stinger()
	if player.has_method("shake_camera"):
		player.shake_camera(0.4, 0.6)
	if player.has_method("trigger_post_screamer_heartbeat"):
		player.trigger_post_screamer_heartbeat(15.0)
		
	var phrases = [
		"¡¡EL RECREO SE TERMINÓ!!",
		"¡¡PROHIBIDO CORRER POR EL PASILLO!!",
		"¡¡A MARZO DIRECTO SIN DERECHO A FINAL!!",
		"¡¡NO VAN A ESCAPAR DE LA FACULTAD!!"
	]
	profesor._say(phrases[randi() % phrases.size()], Color(1.0, 0.1, 0.1))
	
	profesor.start_hallway_dash(start_pos, end_pos)
	print(">>> ¡Susto del 4to examen ejecutado! Profesor corriendo de %s a %s" % [start_pos, end_pos])

func _get_scare_dash_points(exam_pos: Vector3, exam_name: String) -> Array[Vector3]:
	if exam_name.contains("Aula") or exam_pos.x < -30.0:
		# Aula 106: Pasillo Oeste (X = -42.0), cruza frente a la puerta en Z = -12.0
		return [Vector3(-42.0, 0.05, -28.0), Vector3(-42.0, 0.05, 5.0)]
	elif exam_name.contains("Cafeteria") or exam_pos.x > 30.0:
		# Cafetería PB: Pasillo Este (X = 42.0), cruza frente a la entrada en Z = -2.5
		return [Vector3(42.0, 0.05, -22.0), Vector3(42.0, 0.05, 8.0)]
	elif exam_name.contains("Fotocopiadora") or exam_pos.z > 25.0:
		# Fotocopiadora 1: Pasillo Sur (Z = 33.5), cruza frente a la puerta en X = -35.0
		return [Vector3(-48.0, 0.05, 33.5), Vector3(-12.0, 0.05, 33.5)]
	else:
		# Patio del Estudiante: Corre cruzando perpendicularmente en el campo de visión del jugador
		var p_pos = player.global_position if is_instance_valid(player) else exam_pos
		var p_fwd = -player.global_transform.basis.z if is_instance_valid(player) else Vector3.FORWARD
		p_fwd.y = 0.0
		if p_fwd.length() < 0.1:
			p_fwd = Vector3.FORWARD
		else:
			p_fwd = p_fwd.normalized()
		var p_right = Vector3(-p_fwd.z, 0.0, p_fwd.x).normalized()
		var center = p_pos + p_fwd * 6.5
		center.y = 0.05
		# Mantener el centro dentro del patio abierto (-14 < x < 14, -12 < z < 14)
		center.x = clampf(center.x, -14.0, 14.0)
		center.z = clampf(center.z, -12.0, 14.0)
		var start_pos = center - p_right * 16.0
		var end_pos = center + p_right * 16.0
		start_pos.x = clampf(start_pos.x, -16.5, 16.5)
		start_pos.z = clampf(start_pos.z, -16.0, 16.5)
		end_pos.x = clampf(end_pos.x, -16.5, 16.5)
		end_pos.z = clampf(end_pos.z, -16.0, 16.5)
		return [start_pos, end_pos]



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
		
	# 1b. Titileo por proximidad al profesor al patrullar con la luz restablecida
	if is_instance_valid(profesor) and profesor.visible:
		var prof_pos = profesor.global_position
		for l in building_lights_base_energy.keys():
			if is_instance_valid(l) and l.visible and not active_light_flickers.has(l):
				var d_prof = l.global_position.distance_to(prof_pos)
				if d_prof < 14.0:
					if randf() < 0.08:
						var base_e = building_lights_base_energy.get(l, l.light_energy)
						active_light_flickers[l] = {
							"elapsed": 0.0,
							"duration": randf_range(0.25, 0.70),
							"base": base_e
						}
		
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

## =====================================================================
## ATAJOS DE TESTING RÁPIDO Y MODO DEBUG
## =====================================================================
var is_profesor_frozen: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
		
	match event.keycode:
		KEY_F1:
			if hud and hud.has_method("toggle_debug_cheats_panel"):
				hud.toggle_debug_cheats_panel()
				get_viewport().set_input_as_handled()
		KEY_F4:
			_debug_teleport_to_p1()
			get_viewport().set_input_as_handled()
		KEY_F5:
			_debug_trigger_blackout_and_fuse()
			get_viewport().set_input_as_handled()
		KEY_F6:
			_debug_teleport_to_tablero()
			get_viewport().set_input_as_handled()
		KEY_F7:
			_debug_teleport_to_cafeteria()
			get_viewport().set_input_as_handled()
		KEY_F8:
			_debug_approve_all_exams()
			get_viewport().set_input_as_handled()
		KEY_F9:
			_debug_toggle_freeze_profesor()
			get_viewport().set_input_as_handled()
		KEY_F10:
			_debug_toggle_retro_filter()
			get_viewport().set_input_as_handled()

func _debug_teleport_to_p1() -> void:
	_unlock_upper_floor()
	if is_instance_valid(player):
		player.velocity = Vector3.ZERO
		# Ubicar al jugador en el punto de vista con ángulo hacia la esquina y Bedelía
		player.global_position = Vector3(-39.0, 4.7, -26.5)
		player.rotation.y = deg_to_rad(-135.0)
	if hud and hud.has_method("show_temporary_alert"):
		hud.show_temporary_alert("📍 [F4] Teletransporte a P1 (Frente a Bedelía)", Color(0.3, 1.0, 0.6))

func _debug_trigger_blackout_and_fuse() -> void:
	if not is_blackout:
		_trigger_blackout()
	if hud:
		hud.has_fuse = true
		if hud.has_method("update_inventory_display"):
			hud.update_inventory_display()
		if hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("⚡ [F5] Apagón activado y Fusible listo en el inventario", Color(1.0, 0.85, 0.2))

func _debug_teleport_to_tablero() -> void:
	if not is_blackout:
		_trigger_blackout()
	if hud:
		hud.has_fuse = true
		if hud.has_method("update_inventory_display"):
			hud.update_inventory_display()
	if is_instance_valid(player):
		player.velocity = Vector3.ZERO
		# Frente al tablero eléctrico en Depto. de Electrónica (X = -18.5, Z = 0.0) mirando al tablero
		player.global_position = Vector3(-18.5, 0.05, 0.0)
		player.rotation.y = deg_to_rad(90.0)
	if hud and hud.has_method("show_temporary_alert"):
		hud.show_temporary_alert("💡 [F6] En Tablero Eléctrico con Fusible listo. ¡Apreta [E]!", Color(0.3, 1.0, 0.6))

func _debug_teleport_to_cafeteria() -> void:
	if is_instance_valid(player):
		player.velocity = Vector3.ZERO
		# Cafetería PB frente a los estantes de Peronachos (X = 48.5, Z = -8.0)
		player.global_position = Vector3(48.5, 0.05, -8.0)
		player.rotation.y = deg_to_rad(-90.0)
	if hud:
		hud.peronachos_count = 3
		if hud.has_method("update_inventory_display"):
			hud.update_inventory_display()
		if hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("🍟 [F7] Cafetería PB: Estantes listos [E] y 3 Peronachos en inventario [Q]", Color(1.0, 0.6, 0.2))

func _debug_approve_all_exams() -> void:
	for spot in classroom_spots:
		if not exams_approved.has(spot["name"]):
			exams_approved.append(spot["name"])
	_unlock_upper_floor()
	if hud and hud.has_method("update_exams"):
		hud.update_exams(exams_approved.size(), total_exams)
	if hud and hud.has_method("show_temporary_alert"):
		hud.show_temporary_alert("🎓 [F8] ¡Todos los parciales aprobados y accesos desbloqueados!", Color(0.3, 0.8, 1.0))

func _debug_toggle_freeze_profesor() -> void:
	is_profesor_frozen = not is_profesor_frozen
	if is_instance_valid(profesor):
		profesor.set_physics_process(not is_profesor_frozen)
		profesor.set_process(not is_profesor_frozen)
		profesor.velocity = Vector3.ZERO
	if hud and hud.has_method("show_temporary_alert"):
		if is_profesor_frozen:
			hud.show_temporary_alert("🧊 [F9] Profesor CONGELADO (Inmóvil para pruebas tranquilas)", Color(0.4, 0.85, 1.0))
		else:
			hud.show_temporary_alert("🏃 [F9] Profesor DESCONGELADO (Patrullando normalmente)", Color(1.0, 0.4, 0.4))

func _debug_toggle_retro_filter() -> void:
	if is_instance_valid(player) and player.has_method("toggle_retro_shader"):
		var is_on = player.toggle_retro_shader()
		if hud and hud.has_method("show_temporary_alert"):
			var msg = "📼 [F10] Filtro Retro Fears to Fathom: " + ("ACTIVADO" if is_on else "DESACTIVADO")
			var col = Color(0.9, 0.7, 1.0) if is_on else Color(0.7, 0.7, 0.7)
			hud.show_temporary_alert(msg, col)

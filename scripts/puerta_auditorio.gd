extends Area3D
class_name PuertaAuditorio

## Puerta central del auditorio (planta baja). Se abre solo con la llave del auditorio.

signal auditorium_opened

## Nodos de EdificioCentral que forman la hoja de la puerta y se quitan al abrir
@export var door_nodes: Array[String] = [
	"Aud_Puerta2_VidrioIzq",
	"Aud_Puerta2_VidrioDer",
	"Aud_Puerta2_Centro",
	"Aud_Puerta2_Franja",
	"Aud_Puerta2_ManijonL",
	"Aud_Puerta2_ManijonR",
]

@onready var cadenas: Node3D = get_node_or_null("CadenasAuditorio")
@onready var audio_unlock: AudioStreamPlayer3D = get_node_or_null("AudioUnlock")
@onready var audio_locked: AudioStreamPlayer3D = get_node_or_null("AudioLocked")

var is_player_nearby: bool = false
var player_ref: CharacterBody3D = null
var is_open: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_3d_chains()
	
	if audio_locked and not audio_locked.stream:
		var path1 = "res://audio/sfx/forzando_puerta.mp3"
		var path2 = "res://Forzando puerta 🔊- Efecto de Sonido 🚪.mp3"
		if ResourceLoader.exists(path1):
			audio_locked.stream = load(path1)
		elif ResourceLoader.exists(path2):
			audio_locked.stream = load(path2)

func _build_3d_chains() -> void:
	if not cadenas:
		return
	
	var mm_instance = MultiMeshInstance3D.new()
	mm_instance.name = "EslabonesCadenas"
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	
	var mat: Material = null
	if ResourceLoader.exists("res://materials/mat_chain_metal.tres"):
		mat = load("res://materials/mat_chain_metal.tres")
	elif ResourceLoader.exists("res://materials/mat_bench_metal.tres"):
		mat = load("res://materials/mat_bench_metal.tres")
		
	mm.mesh = _create_oval_chain_link_mesh(mat)
	
	var transforms: Array[Transform3D] = []
	
	# Segmentos de cadenas estilo Silent Hill 4 con eslabones ovalados interconectados
	# Horizontales
	_add_chain_segment(transforms, Vector3(-1.62, 0.45, 0.93), Vector3(1.62, 0.45, 0.93), 0.035)
	_add_chain_segment(transforms, Vector3(-1.62, 0.0, 0.93), Vector3(1.62, 0.0, 0.93), 0.045)
	_add_chain_segment(transforms, Vector3(-1.62, -0.45, 0.93), Vector3(1.62, -0.45, 0.93), 0.035)
	
	# Diagonales cruzadas en X
	_add_chain_segment(transforms, Vector3(-1.62, 0.70, 0.91), Vector3(1.62, -0.70, 0.91), 0.05)
	_add_chain_segment(transforms, Vector3(-1.62, -0.70, 0.90), Vector3(1.62, 0.70, 0.90), 0.05)
	
	# Diagonales desde anclaje superior
	_add_chain_segment(transforms, Vector3(0.0, 1.05, 0.89), Vector3(-1.62, -0.25, 0.89), 0.03)
	_add_chain_segment(transforms, Vector3(0.0, 1.05, 0.89), Vector3(1.62, -0.25, 0.89), 0.03)
	
	# Cadenas colgantes sueltas
	_add_chain_segment(transforms, Vector3(0.04, -0.05, 0.87), Vector3(0.04, -0.55, 0.87), 0.0)
	_add_chain_segment(transforms, Vector3(-0.65, 0.28, 0.87), Vector3(-0.65, -0.20, 0.87), 0.0)
	_add_chain_segment(transforms, Vector3(0.65, -0.22, 0.87), Vector3(0.65, -0.68, 0.87), 0.0)
	
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		
	mm_instance.multimesh = mm
	cadenas.add_child(mm_instance)

## Genera un eslabón ovalado auténtico (forma stadium: lados rectos paralelos y extremos semicirculares)
func _create_oval_chain_link_mesh(material: Material) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var l_straight: float = 0.038
	var r_curve: float = 0.022
	var r_wire: float = 0.0075
	
	var spine_points: Array[Vector3] = []
	var spine_tangents: Array[Vector3] = []
	var spine_normals: Array[Vector3] = []
	
	var n_straight: int = 4
	var n_curve: int = 10
	
	# 1. Tramo recto lateral 1 (+X, recorriendo de -l/2 a +l/2)
	for i in range(n_straight):
		var t = float(i) / float(n_straight)
		var z = -l_straight * 0.5 + t * l_straight
		spine_points.append(Vector3(r_curve, 0.0, z))
		spine_tangents.append(Vector3(0.0, 0.0, 1.0))
		spine_normals.append(Vector3(1.0, 0.0, 0.0))
		
	# 2. Semicírculo frontal (+Z, theta de 0 a PI)
	for i in range(n_curve):
		var theta = float(i) / float(n_curve) * PI
		var x = r_curve * cos(theta)
		var z = l_straight * 0.5 + r_curve * sin(theta)
		spine_points.append(Vector3(x, 0.0, z))
		spine_tangents.append(Vector3(-sin(theta), 0.0, cos(theta)).normalized())
		spine_normals.append(Vector3(cos(theta), 0.0, sin(theta)).normalized())
		
	# 3. Tramo recto lateral 2 (-X, recorriendo de +l/2 a -l/2)
	for i in range(n_straight):
		var t = float(i) / float(n_straight)
		var z = l_straight * 0.5 - t * l_straight
		spine_points.append(Vector3(-r_curve, 0.0, z))
		spine_tangents.append(Vector3(0.0, 0.0, -1.0))
		spine_normals.append(Vector3(-1.0, 0.0, 0.0))
		
	# 4. Semicírculo posterior (-Z, theta de PI a 2*PI)
	for i in range(n_curve):
		var theta = PI + float(i) / float(n_curve) * PI
		var x = r_curve * cos(theta)
		var z = -l_straight * 0.5 + r_curve * sin(theta)
		spine_points.append(Vector3(x, 0.0, z))
		spine_tangents.append(Vector3(-sin(theta), 0.0, cos(theta)).normalized())
		spine_normals.append(Vector3(cos(theta), 0.0, sin(theta)).normalized())
		
	var n_spine = spine_points.size()
	var n_ring: int = 8
	
	for k in range(n_spine):
		var pos = spine_points[k]
		var tang = spine_tangents[k]
		var norm = spine_normals[k]
		var binorm = tang.cross(norm).normalized()
		
		for j in range(n_ring):
			var phi = float(j) / float(n_ring) * TAU
			var dir_out = (norm * cos(phi) + binorm * sin(phi)).normalized()
			var vpos = pos + dir_out * r_wire
			var uv = Vector2(float(k) / float(n_spine) * 4.0, float(j) / float(n_ring))
			st.set_normal(dir_out)
			st.set_uv(uv)
			st.add_vertex(vpos)
			
	for k in range(n_spine):
		var next_k = (k + 1) % n_spine
		for j in range(n_ring):
			var next_j = (j + 1) % n_ring
			var v0 = k * n_ring + j
			var v1 = k * n_ring + next_j
			var v2 = next_k * n_ring + next_j
			var v3 = next_k * n_ring + j
			st.add_index(v0)
			st.add_index(v1)
			st.add_index(v2)
			st.add_index(v0)
			st.add_index(v2)
			st.add_index(v3)
			
	if material:
		st.set_material(material)
	return st.commit()

func _add_chain_segment(transforms: Array[Transform3D], p_start: Vector3, p_end: Vector3, max_sag: float = 0.04, step: float = 0.052) -> void:
	var total_dist = p_start.distance_to(p_end)
	if total_dist < step:
		return
	var dir = (p_end - p_start).normalized()
	var num_links = int(ceil(total_dist / step))
	
	var ref_up = Vector3.UP
	if abs(dir.dot(ref_up)) > 0.92:
		ref_up = Vector3.FORWARD
	var right = dir.cross(ref_up).normalized()
	var up = right.cross(dir).normalized()
	
	for i in range(num_links + 1):
		var t = float(i) / float(num_links)
		var pos = p_start.lerp(p_end, t)
		if max_sag > 0.0:
			pos.y -= sin(t * PI) * max_sag
			
		var twist_angle = 0.0 if (i % 2 == 0) else (PI * 0.5)
		var rot_basis = Basis(dir, twist_angle) * Basis(right, up, dir)
		transforms.append(Transform3D(rot_basis, pos))

func _process(_delta: float) -> void:
	if is_open or not is_player_nearby:
		return
	if Input.is_action_just_pressed("interact"):
		_try_open()

func _try_open() -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		return
	if not hud.has_auditorium_key:
		if audio_locked and not audio_locked.playing:
			audio_locked.play()
		hud.show_temporary_alert("🔒 El auditorio está cerrado con cadenas y candados. Necesitás la LLAVE DEL AUDITORIO.", Color(1.0, 0.3, 0.3))
		return
	_open()
	if hud.has_method("set_objective_text"):
		hud.set_objective_text("NUEVO OBJETIVO: Entrá al Auditorio y agarrá tu Título Universitario del estrado", Color(0.2, 1.0, 0.5))
	hud.set_interact_prompt("")

func _open() -> void:
	is_open = true
	var edificio = get_tree().root.find_child("EdificioCentral", true, false)
	if edificio:
		for n in door_nodes:
			var node = edificio.find_child(n, true, false)
			if node:
				node.queue_free()
			else:
				push_warning("PuertaAuditorio: no se encontró el nodo " + n)
	if audio_unlock:
		audio_unlock.play()
	if cadenas:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(cadenas, "position:y", cadenas.position.y - 0.5, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(cadenas, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
		tween.chain().tween_callback(cadenas.queue_free)
	auditorium_opened.emit()
	print(">>> ¡AUDITORIO ABIERTO! Cadenas retiradas.")

func _on_body_entered(body: Node3D) -> void:
	if is_open:
		return
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			if hud.has_auditorium_key:
				hud.set_interact_prompt("[E] Abrir Auditorio con la llave")
			else:
				hud.set_interact_prompt("Auditorio cerrado con cadenas y candados")

func _on_body_exited(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

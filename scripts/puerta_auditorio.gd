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

var is_player_nearby: bool = false
var player_ref: CharacterBody3D = null
var is_open: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_3d_chains()

func _build_3d_chains() -> void:
	if not cadenas:
		return
	
	var mm_instance = MultiMeshInstance3D.new()
	mm_instance.name = "EslabonesCadenas"
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	
	var torus = TorusMesh.new()
	torus.inner_radius = 0.024
	torus.outer_radius = 0.052
	torus.rings = 14
	torus.ring_segments = 8
	if ResourceLoader.exists("res://materials/mat_bench_metal.tres"):
		torus.material = load("res://materials/mat_bench_metal.tres")
	mm.mesh = torus
	
	var transforms: Array[Transform3D] = []
	
	# Segmentos de cadenas estilo Silent Hill 4
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

func _add_chain_segment(transforms: Array[Transform3D], p_start: Vector3, p_end: Vector3, max_sag: float = 0.04, step: float = 0.062) -> void:
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
		var link_basis = rot_basis.scaled(Vector3(1.0, 1.0, 1.4))
		
		transforms.append(Transform3D(link_basis, pos))

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
		hud.show_temporary_alert("🔒 El auditorio está cerrado. Necesitás la LLAVE DEL AUDITORIO.", Color(1.0, 0.3, 0.3))
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
				hud.set_interact_prompt("[E] Auditorio cerrado (requiere llave)")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

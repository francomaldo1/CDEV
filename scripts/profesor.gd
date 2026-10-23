extends CharacterBody3D
class_name Profesor

enum State {
	PATROL,
	CHASE,
	SEARCH,
	ATTACK
}

## Velocidades ajustables
@export var base_patrol_speed: float = 2.0 ## Velocidad de patrullaje calmada y metódica
@export var base_chase_speed: float = 2.8 ## Velocidad de persecución aterradora pero controlada
@export var vision_range: float = 18.0 ## Metros de visión en cono
@export var vision_angle_deg: float = 105.0 ## Apertura del cono de visión (ampliada de 80 a 105 para no perder al jugador)
@export var proximity_range: float = 3.5 ## Detecta si el jugador está muy cerca en la espalda o costados
@export var hearing_range: float = 35.0 ## Rango para escuchar ruidos del micrófono
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.3
@export var lost_sight_timeout: float = 5.5 ## Tiempo de memoria tras perder de vista (ampliado de 3.5 a 5.5s)

## Estado actual
var current_state: State = State.PATROL
var current_speed: float = 2.0
var chase_speed: float = 2.8
var patrol_speed: float = 2.0
var speed_boost_count: int = 0

## Referencias al modelo
@onready var visual_root: Node3D = $Visuals
@onready var pierna_izq: Node3D = $Visuals/PiernaIzq
@onready var pierna_der: Node3D = $Visuals/PiernaDer
@onready var brazo_izq: Node3D = $Visuals/BrazoIzq
@onready var brazo_der: Node3D = $Visuals/BrazoDer
@onready var regla: Node3D = $Visuals/BrazoDer/ManoDer/ReglaPivot
@onready var cabeza: Node3D = $Visuals/Torso/Cabeza
@onready var cartel_dialogo: Label3D = $Visuals/DialogoLabel
@onready var ojos_luz: SpotLight3D = $Visuals/Torso/Cabeza/OjosLuz

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var player: CharacterBody3D = null

var walk_anim_time: float = 0.0
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_anim_time: float = 0.0

var time_without_sight: float = 0.0
var search_timer: float = 0.0
var last_known_player_pos: Vector3 = Vector3.ZERO

var stuck_timer: float = 0.0
var prev_pos: Vector3 = Vector3.ZERO
var pos_sample_timer: float = 0.0
var is_screamer_ambush: bool = false
var is_screamer_charging: bool = false
var screamer_charge_timer: float = 0.0

## Sistema de flanqueo inteligente de obstáculos (mesas, bancos, esquinas)
var is_flanking: bool = false
var flank_dir: Vector3 = Vector3.ZERO
var flank_pass_dir: Vector3 = Vector3.ZERO
var flank_timer: float = 0.0
var flank_phase: int = 0

## Puntos de patrullaje por toda la facultad organizados por piso
## PB = Y ~0.2 | P1 = Y ~4.7 | P2 = Y ~9.2
const WAYPOINTS_PB: Array[Vector3] = [
	Vector3(0.0, 0.2, -18.0),     # PB: Patio Norte
	Vector3(0.0, 0.2, -28.5),     # PB: Pasillo Norte centro
	Vector3(-25.0, 0.2, -28.5),   # PB: Pasillo Norte frente a Aula 102
	Vector3(-42.0, 0.2, -28.5),   # PB: Esquina Noroeste (frente a Aula 105)
	Vector3(-42.0, 0.2, -12.0),   # PB: Pasillo Oeste (frente a Aula 106)
	Vector3(-42.0, 0.2, 5.0),     # PB: Pasillo Oeste (frente a Aula 107)
	Vector3(-42.0, 0.2, 20.0),    # PB: Pasillo Oeste (frente a Aula 108)
	Vector3(-42.0, 0.2, 30.0),    # PB: Esquina Suroeste
	Vector3(-25.0, 0.2, 30.0),    # PB: Pasillo Sur oeste
	Vector3(0.0, 0.2, 30.0),      # PB: Pasillo Sur centro (frente a auditorio)
	Vector3(0.0, 0.2, 22.0),      # PB: Entrada Sur al Patio
	Vector3(0.0, 0.2, 4.0),       # PB: Patio interior frente a la fuente
	Vector3(0.0, 0.2, -4.0),      # PB: Patio interior norte
	Vector3(0.0, 0.2, 22.0),      # PB: Salida Patio Sur
	Vector3(25.0, 0.2, 30.0),     # PB: Pasillo Sur este
	Vector3(42.0, 0.2, 30.0),     # PB: Esquina Sureste
	Vector3(42.0, 0.2, 17.0),     # PB: Pasillo Este sur (frente a Aula 115)
	Vector3(42.0, 0.2, 0.0),      # PB: Pasillo Este centro (Cafetería PB)
	Vector3(42.0, 0.2, -15.0),    # PB: Pasillo Este norte (frente a Aula 114)
	Vector3(42.0, 0.2, -28.5),    # PB: Esquina Noreste
	Vector3(25.0, 0.2, -28.5)     # PB: Pasillo Norte este (frente a Aula 104)
]

const WAYPOINTS_P1: Array[Vector3] = [
	Vector3(-42.0, 4.7, 30.0),    # P1: Pasillo Oeste sur
	Vector3(-42.0, 4.7, 15.0),    # P1: Pasillo Oeste centro
	Vector3(-42.0, 4.7, 0.0),     # P1: Pasillo Oeste norte
	Vector3(-42.0, 4.7, -15.0),   # P1: Pasillo Oeste (oficinas dept.)
	Vector3(-42.0, 4.7, -28.5),   # P1: Esquina Noroeste
	Vector3(-20.0, 4.7, -28.5),   # P1: Pasillo Norte oeste
	Vector3(0.0, 4.7, -28.5),     # P1: Pasillo Norte centro
	Vector3(20.0, 4.7, -28.5),    # P1: Pasillo Norte este
	Vector3(42.0, 4.7, -28.5),    # P1: Esquina Noreste
	Vector3(42.0, 4.7, -15.0),    # P1: Pasillo Este norte
	Vector3(42.0, 4.7, 0.0),      # P1: Pasillo Este centro
	Vector3(42.0, 4.7, 15.0),     # P1: Pasillo Este sur
	Vector3(42.0, 4.7, 30.0),     # P1: Esquina Sureste
	Vector3(20.0, 4.7, 30.0),     # P1: Pasillo Sur este
	Vector3(0.0, 4.7, 30.0),      # P1: Pasillo Sur centro
	Vector3(-20.0, 4.7, 30.0)     # P1: Pasillo Sur oeste
]

const WAYPOINTS_P2: Array[Vector3] = [
	Vector3(42.0, 9.2, 30.0),     # P2: Esquina Sureste
	Vector3(42.0, 9.2, 15.0),     # P2: Pasillo Este sur
	Vector3(42.0, 9.2, 0.0),      # P2: Pasillo Este centro (Cafetería P2)
	Vector3(42.0, 9.2, -15.0),    # P2: Pasillo Este norte
	Vector3(42.0, 9.2, -28.5),    # P2: Esquina Noreste
	Vector3(20.0, 9.2, -28.5),    # P2: Pasillo Norte este (Aula 215)
	Vector3(0.0, 9.2, -28.5),     # P2: Pasillo Norte centro (Aula 210)
	Vector3(-20.0, 9.2, -28.5),   # P2: Pasillo Norte oeste (Aula 205)
	Vector3(-42.0, 9.2, -28.5),   # P2: Esquina Noroeste (Aula 201)
	Vector3(-42.0, 9.2, -15.0),   # P2: Pasillo Oeste norte
	Vector3(-42.0, 9.2, 0.0),     # P2: Pasillo Oeste centro
	Vector3(-42.0, 9.2, 15.0),    # P2: Pasillo Oeste sur
	Vector3(-42.0, 9.2, 30.0),    # P2: Esquina Suroeste
	Vector3(-20.0, 9.2, 30.0),    # P2: Pasillo Sur oeste
	Vector3(0.0, 9.2, 30.0),      # P2: Pasillo Sur centro
	Vector3(20.0, 9.2, 30.0)      # P2: Pasillo Sur este
]

## Nodos secuenciales de escaleras para no trabarse con la pared divisoria (WallDiv)
## Cada descanso tiene dos puntos: entrada (despeja WallDiv) y salida (alineado al siguiente tramo)
const STAIR_WEST_PATH: Array[Vector3] = [
	Vector3(-64.5, 0.2, 27.5),    # 0: PB Entrada pasillo
	Vector3(-66.0, 0.4, 27.5),    # 1: PB-P1 Tramo 1 inicio
	Vector3(-71.0, 2.1, 27.5),    # 2: PB-P1 Tramo 1 fin
	Vector3(-72.8, 2.25, 27.5),   # 3: PB-P1 Descanso Entrada (despeja WallDiv)
	Vector3(-72.8, 2.25, 32.5),   # 4: PB-P1 Descanso Salida (alineado con Tramo 2)
	Vector3(-71.0, 2.4, 32.5),    # 5: PB-P1 Tramo 2 inicio
	Vector3(-66.0, 4.3, 32.5),    # 6: PB-P1 Tramo 2 fin
	Vector3(-64.5, 4.7, 32.5),    # 7: P1 Salida/Hall
	Vector3(-64.5, 4.7, 27.5),    # 8: P1 Entrada a P2
	Vector3(-66.0, 4.9, 27.5),    # 9: P1-P2 Tramo 1 inicio
	Vector3(-71.0, 6.6, 27.5),    # 10: P1-P2 Tramo 1 fin
	Vector3(-72.8, 6.75, 27.5),   # 11: P1-P2 Descanso Entrada
	Vector3(-72.8, 6.75, 32.5),   # 12: P1-P2 Descanso Salida
	Vector3(-71.0, 6.9, 32.5),    # 13: P1-P2 Tramo 2 inicio
	Vector3(-66.0, 8.8, 32.5),    # 14: P1-P2 Tramo 2 fin
	Vector3(-64.5, 9.2, 32.5)     # 15: P2 Salida/Hall
]

const STAIR_EAST_PATH: Array[Vector3] = [
	Vector3(64.5, 0.2, 27.5),     # 0: PB Entrada pasillo
	Vector3(66.0, 0.4, 27.5),     # 1: PB-P1 Tramo 1 inicio
	Vector3(71.0, 2.1, 27.5),     # 2: PB-P1 Tramo 1 fin
	Vector3(72.8, 2.25, 27.5),    # 3: PB-P1 Descanso Entrada (despeja WallDiv)
	Vector3(72.8, 2.25, 32.5),    # 4: PB-P1 Descanso Salida (alineado con Tramo 2)
	Vector3(71.0, 2.4, 32.5),     # 5: PB-P1 Tramo 2 inicio
	Vector3(66.0, 4.3, 32.5),     # 6: PB-P1 Tramo 2 fin
	Vector3(64.5, 4.7, 32.5),     # 7: P1 Salida/Hall
	Vector3(64.5, 4.7, 27.5),     # 8: P1 Entrada a P2
	Vector3(66.0, 4.9, 27.5),     # 9: P1-P2 Tramo 1 inicio
	Vector3(71.0, 6.6, 27.5),     # 10: P1-P2 Tramo 1 fin
	Vector3(72.8, 6.75, 27.5),    # 11: P1-P2 Descanso Entrada
	Vector3(72.8, 6.75, 32.5),    # 12: P1-P2 Descanso Salida
	Vector3(71.0, 6.9, 32.5),     # 13: P1-P2 Tramo 2 inicio
	Vector3(66.0, 8.8, 32.5),     # 14: P1-P2 Tramo 2 fin
	Vector3(64.5, 9.2, 32.5)      # 15: P2 Salida/Hall
]

const STAIR_NORTH_PATH: Array[Vector3] = [
	Vector3(39.5, 0.2, -44.0),    # 0: PB Entrada pasillo (T1)
	Vector3(39.5, 0.4, -45.5),    # 1: PB-P1 Tramo 1 inicio
	Vector3(39.5, 2.1, -51.0),    # 2: PB-P1 Tramo 1 fin
	Vector3(39.5, 2.25, -52.8),   # 3: PB-P1 Descanso Entrada
	Vector3(44.5, 2.25, -52.8),   # 4: PB-P1 Descanso Salida
	Vector3(44.5, 2.4, -51.0),    # 5: PB-P1 Tramo 2 inicio
	Vector3(44.5, 4.3, -45.5),    # 6: PB-P1 Tramo 2 fin
	Vector3(44.5, 4.7, -44.0),    # 7: P1 Salida/Hall
	Vector3(39.5, 4.7, -44.0),    # 8: P1 Entrada a P2
	Vector3(39.5, 4.9, -45.5),    # 9: P1-P2 Tramo 1 inicio
	Vector3(39.5, 6.6, -51.0),    # 10: P1-P2 Tramo 1 fin
	Vector3(39.5, 6.75, -52.8),   # 11: P1-P2 Descanso Entrada
	Vector3(44.5, 6.75, -52.8),   # 12: P1-P2 Descanso Salida
	Vector3(44.5, 6.9, -51.0),    # 13: P1-P2 Tramo 2 inicio
	Vector3(44.5, 8.8, -45.5),    # 14: P1-P2 Tramo 2 fin
	Vector3(44.5, 9.2, -44.0)     # 15: P2 Salida/Hall
]

var current_patrol_floor: int = 0
var current_floor_waypoints: Array[Vector3] = WAYPOINTS_PB
var patrol_waypoints: Array[Vector3] = WAYPOINTS_PB
var current_waypoint_idx: int = 0

## Seguimiento secuencial en escaleras
var active_stair_idx: int = -1
var active_stair_tower: String = ""

## Investigación entre pisos
var floor_investigate_timer: float = 50.0
var is_investigating_floor: bool = false
var target_investigate_floor: int = 0
var target_floor_entry_pos: Vector3 = Vector3.ZERO

func get_floor(y: float) -> int:
	if y < 2.5: return 0
	elif y < 7.0: return 1
	else: return 2

func get_floor_waypoints(floor_idx: int) -> Array[Vector3]:
	match floor_idx:
		0: return WAYPOINTS_PB
		1: return WAYPOINTS_P1
		2: return WAYPOINTS_P2
		_: return WAYPOINTS_PB

func get_stair_tower_name(pos: Vector3) -> String:
	if pos.x <= -63.0 and pos.x >= -75.0 and pos.z >= 24.0 and pos.z <= 36.0:
		return "Oeste"
	if pos.x >= 63.0 and pos.x <= 75.0 and pos.z >= 24.0 and pos.z <= 36.0:
		return "Este"
	if pos.x >= 37.0 and pos.x <= 47.0 and pos.z >= -55.0 and pos.z <= -43.0:
		return "Norte"
	return ""

func get_stair_path(tower_name: String) -> Array[Vector3]:
	match tower_name:
		"Oeste": return STAIR_WEST_PATH
		"Este": return STAIR_EAST_PATH
		"Norte": return STAIR_NORTH_PATH
		_: return STAIR_WEST_PATH

func get_closest_stair_tower(pos: Vector3) -> String:
	var d_west = Vector2(pos.x - (-64.5), pos.z - 27.5).length_squared()
	var d_east = Vector2(pos.x - 64.5, pos.z - 27.5).length_squared()
	var d_north = Vector2(pos.x - 39.5, pos.z - (-44.0)).length_squared()
	if d_west <= d_east and d_west <= d_north:
		return "Oeste"
	elif d_east <= d_north:
		return "Este"
	else:
		return "Norte"

func _get_nav_target_to(destination_pos: Vector3) -> Vector3:
	var my_floor = get_floor(global_position.y)
	var tgt_floor = get_floor(destination_pos.y)
	var my_tower = get_stair_tower_name(global_position)
	var tgt_tower = get_stair_tower_name(destination_pos)

	# Si ambos están en el mismo piso y ninguno dentro de una caja de escalera:
	if my_floor == tgt_floor and my_tower == "" and tgt_tower == "":
		active_stair_idx = -1
		active_stair_tower = ""

		# En el Laboratorio Central de Electrónica (PB, X de -37 a -17, Z de -10 a 11):
		# Las 3 mesadas de 14m bloquean el paso directo entre pasillos.
		if my_floor == 0 and (global_position.x >= -37.0 and global_position.x <= -17.0 and global_position.z >= -10.0 and global_position.z <= 11.0):
			if not _is_walk_path_clear(global_position, destination_pos):
				var dist_west = absf(global_position.x - (-35.5))
				var dist_east = absf(global_position.x - (-18.5))
				var corridor_x = -35.5 if dist_west <= dist_east else -18.5
				
				var in_corridor = (corridor_x == -35.5 and global_position.x <= -34.5) or (corridor_x == -18.5 and global_position.x >= -19.5)
				if not in_corridor:
					return Vector3(corridor_x, global_position.y, global_position.z)
				elif absf(global_position.z - destination_pos.z) > 0.3:
					return Vector3(corridor_x, global_position.y, destination_pos.z)
				else:
					return destination_pos

		return destination_pos

	# Elegir la torre de escaleras adecuada
	var chosen_tower = ""
	if my_tower != "":
		chosen_tower = my_tower
	elif tgt_tower != "":
		chosen_tower = tgt_tower
	else:
		chosen_tower = get_closest_stair_tower(global_position)

	var path = get_stair_path(chosen_tower)

	# Determinar el nodo objetivo final en la escalera (goal_idx)
	var goal_idx = 0
	if tgt_tower == chosen_tower:
		# El jugador está dentro de esta misma escalera: buscar el nodo más cercano al jugador
		var min_td = 99999.0
		for i in range(path.size()):
			var td = destination_pos.distance_to(path[i])
			if td < min_td:
				min_td = td
				goal_idx = i
	else:
		# Jugador en otro piso fuera de la torre: salir en el piso objetivo
		if tgt_floor == 0:
			goal_idx = 0
		elif tgt_floor == 1:
			goal_idx = 7 if my_floor == 0 else 8
		else:
			goal_idx = 15

	# Si el profesor aún está fuera de la torre: dirigirse a la entrada del piso actual
	if my_tower == "":
		var entry_idx = 0
		if my_floor == 0:
			entry_idx = 0
		elif my_floor == 1:
			entry_idx = 8 if tgt_floor > 1 else 7
		else:
			entry_idx = 15
		active_stair_idx = entry_idx
		active_stair_tower = chosen_tower
		return path[entry_idx]

	# El profesor está dentro de la torre: actualizar el seguimiento secuencial
	if active_stair_idx < 0 or active_stair_idx >= path.size() or active_stair_tower != chosen_tower or global_position.distance_to(path[active_stair_idx]) > 3.0:
		active_stair_tower = chosen_tower
		var best_idx = 0
		var best_d = 99999.0
		for i in range(path.size()):
			var d = global_position.distance_to(path[i])
			if d < best_d:
				best_d = d
				best_idx = i
		if best_idx < goal_idx:
			active_stair_idx = best_idx + 1
		elif best_idx > goal_idx:
			active_stair_idx = best_idx - 1
		else:
			active_stair_idx = goal_idx

	# Si ya llegó cerca del nodo objetivo activo (< 0.85m), avanzar al siguiente nodo
	var cur_target = path[active_stair_idx]
	var d_to_cur = global_position.distance_to(cur_target)
	if d_to_cur < 0.85:
		if active_stair_idx < goal_idx:
			active_stair_idx += 1
		elif active_stair_idx > goal_idx:
			active_stair_idx -= 1

	# Si ya llegó al nodo meta
	if active_stair_idx == goal_idx:
		var d_goal = global_position.distance_to(path[goal_idx])
		if d_goal < 1.4 or (my_floor == tgt_floor and tgt_tower == ""):
			return destination_pos
		return path[goal_idx]

	return path[active_stair_idx]

func are_upper_floors_unlocked() -> bool:
	var main = get_tree().root.find_child("Main", true, false)
	if main and "upper_floor_blockers" in main:
		return main.upper_floor_blockers.size() == 0
	var blocker = get_tree().root.find_child("BloqueoEscaleraOeste", true, false)
	if blocker and is_instance_valid(blocker):
		return false
	return true

func _start_floor_investigation() -> void:
	var my_floor = get_floor(global_position.y)
	var available_floors: Array[int] = []
	for f in [0, 1, 2]:
		if f != my_floor:
			available_floors.append(f)
	
	if available_floors.is_empty():
		floor_investigate_timer = randf_range(40.0, 60.0)
		return

	target_investigate_floor = available_floors[randi() % available_floors.size()]
	is_investigating_floor = true

	var wps = get_floor_waypoints(target_investigate_floor)
	if wps.size() > 0:
		target_floor_entry_pos = wps[0]

	if target_investigate_floor > my_floor:
		var up_phrases = [
			"Voy a subir a revisar el piso " + str(target_investigate_floor) + "...",
			"Me pareció escuchar pasos arriba...",
			"Tengo que ir a buscar unos exámenes arriba...",
			"A ver si hay alumnos en las aulas de arriba..."
		]
		_say(up_phrases[randi() % up_phrases.size()], Color(1.0, 0.85, 0.5))
	else:
		var down_phrases = [
			"Todo en orden por aquí. Voy a bajar a revisar la planta baja...",
			"Voy a pegar una vuelta por planta baja...",
			"Volvamos a la ronda de abajo..."
		]
		_say(down_phrases[randi() % down_phrases.size()], Color(1.0, 0.85, 0.5))

## Frases del profesor
var phrases_patrol: Array[String] = [
	"Mmm... ¿quién anda por los pasillos?",
	"Horario de consulta finalizado...",
	"El que no entregó el TP va a final...",
	"Silencio absoluto en las aulas...",
	"Tengo que corregir 80 parciales todavía..."
]
var phrases_chase: Array[String] = [
	"¡¡DETÉNGASE AHÍ, ALUMNO!!",
	"¡¡ENTREGUE ESE PARCIAL AHORA!!",
	"¡¡A MARZO DIRECTO SIN DERECHO A RECUPERATORIO!!",
	"¡¡PROHIBIDO CORRER POR EL PATIO!!"
]
var phrases_enraged: Array[String] = [
	"¡¡DESAPROBADO!! ¡¡EL PARCIAL ESTÁ LLENO DE ERRORES!!",
	"¡¡COPIARSE ES CAUSAL DE EXPULSIÓN INMEDIATA!!",
	"¡¡NO TIENEN NIVEL PARA LA FACULTAD!!"
]
var phrase_timer: float = 0.0
var step_audio: AudioStreamPlayer3D = null
var step_phase: float = 0.0
var last_chase_screamer_time: float = -999.0

func _ready() -> void:
	add_to_group("enemies")
	
	# Audio 3D espacial de pasos
	_setup_step_audio()
	
	# Configuración de física para caminar suave y sin saltos ni flotar
	floor_snap_length = 0.5
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	floor_block_on_wall = false
	active_stair_idx = -1
	active_stair_tower = ""
	
	patrol_speed = base_patrol_speed
	chase_speed = base_chase_speed
	current_speed = patrol_speed
	
	prev_pos = global_position
	current_patrol_floor = get_floor(global_position.y)
	current_floor_waypoints = get_floor_waypoints(current_patrol_floor)
	patrol_waypoints = current_floor_waypoints
	
	_find_player()
	
	var mic = get_tree().root.find_child("MicDetector", true, false)
	if mic and mic.has_signal("noise_triggered"):
		mic.noise_triggered.connect(_on_player_noise)
	
	phrase_timer = randf_range(3.0, 7.0)
	floor_investigate_timer = randf_range(40.0, 65.0)
	_pick_closest_waypoint()

## Activa o desactiva al profesor (invisible, sin moverse ni colisionar)
var is_active: bool = true

func set_active(active: bool) -> void:
	is_active = active
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if active:
		velocity = Vector3.ZERO
		current_state = State.PATROL
		current_speed = patrol_speed
		time_without_sight = 0.0
		prev_pos = global_position
		current_patrol_floor = get_floor(global_position.y)
		current_floor_waypoints = get_floor_waypoints(current_patrol_floor)
		patrol_waypoints = current_floor_waypoints
		is_investigating_floor = false
		active_stair_idx = -1
		active_stair_tower = ""
		_pick_closest_waypoint()

func _pick_closest_waypoint() -> void:
	current_floor_waypoints = get_floor_waypoints(current_patrol_floor)
	patrol_waypoints = current_floor_waypoints
	var best_dist = 99999.0
	for i in range(current_floor_waypoints.size()):
		var d = global_position.distance_to(current_floor_waypoints[i])
		if d < best_dist:
			best_dist = d
			current_waypoint_idx = i

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		player = get_tree().root.find_child("Player", true, false) as CharacterBody3D

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		_find_player()
		if not is_instance_valid(player):
			return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5

	# Seguridad anti-caídas al vacío
	if global_position.y < -0.8:
		global_position.y = 0.05
		velocity.y = 0.0

	if attack_timer > 0.0:
		attack_timer -= delta

	# Comprobar visión hacia el jugador
	var can_see = _can_see_player()
	
	match current_state:
		State.PATROL:
			_process_patrol_state(delta, can_see)
		State.CHASE:
			_process_chase_state(delta, can_see)
		State.SEARCH:
			_process_search_state(delta, can_see)
		State.ATTACK:
			_process_attack_state(delta)

	_update_dialogue(delta)

## =====================================================================
## DETECCIÓN Y VISIÓN
## =====================================================================
func _can_see_player() -> bool:
	if not is_instance_valid(player) or player.get("is_hidden"):
		return false
	
	var eye_pos = global_position + Vector3(0, 1.5, 0)
	var player_eye = player.global_position + Vector3(0, 1.3, 0)
	var player_chest = player.global_position + Vector3(0, 0.75, 0)
	var to_player = player_eye - eye_pos
	var dist = to_player.length()

	# Modificador si el jugador tiene la linterna encendida
	var current_vision_range = vision_range
	var flashlight = player.find_child("Flashlight", true, false) as SpotLight3D
	if flashlight and flashlight.visible:
		current_vision_range *= 1.45

	# Proximidad inmediata (si está a menos del rango de proximidad detrás o a los lados)
	if dist <= proximity_range:
		return _has_line_of_sight(eye_pos, player_eye) or _has_line_of_sight(eye_pos, player_chest)

	# Si está más lejos que el rango de visión, no lo ve
	if dist > current_vision_range:
		return false

	# Cono de visión frontal:
	# En escaleras o desniveles, proyectar horizontalmente para no perder de vista por inclinación vertical
	var forward_h = Vector2(transform.basis.z.x, transform.basis.z.z).normalized()
	var dir_to_player_h = Vector2(to_player.x, to_player.z).normalized()
	if forward_h.length() > 0.1 and dir_to_player_h.length() > 0.1:
		var angle_rad = forward_h.angle_to(dir_to_player_h)
		var angle_deg = rad_to_deg(angle_rad)
		if absf(angle_deg) > vision_angle_deg * 0.5:
			return false

	# Desnivel vertical máximo de visión (no ver a través de múltiples pisos)
	if absf(to_player.y) > 3.8:
		return false

	# Raycast para verificar si hay paredes intermedias (prueba a ojos y a torso)
	return _has_line_of_sight(eye_pos, player_eye) or _has_line_of_sight(eye_pos, player_chest)

func _has_line_of_sight(from_pos: Vector3, to_pos: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return true
	
	if result.collider == player or (result.collider is Node and player.is_ancestor_of(result.collider)):
		return true
		
	return false

## =====================================================================
## ESTADOS DE IA
## =====================================================================
func _process_patrol_state(delta: float, can_see_player: bool) -> void:
	current_speed = patrol_speed
	
	if can_see_player:
		_enter_chase_state()
		return

	# Si los pisos superiores están desbloqueados, chequear si es momento de investigar otro piso
	if are_upper_floors_unlocked() and not is_investigating_floor:
		floor_investigate_timer -= delta
		if floor_investigate_timer <= 0.0:
			_start_floor_investigation()

	var target_wp = Vector3.ZERO
	if is_investigating_floor:
		target_wp = target_floor_entry_pos
	else:
		if current_floor_waypoints.is_empty():
			current_floor_waypoints = get_floor_waypoints(current_patrol_floor)
			patrol_waypoints = current_floor_waypoints
		target_wp = current_floor_waypoints[current_waypoint_idx]

	var nav_dest = _get_nav_target_to(target_wp)
	var to_dest = nav_dest - global_position
	var dist_dest = to_dest.length()

	# Si estábamos investigando y llegamos al piso destino (fuera de la escalera):
	if is_investigating_floor:
		var my_floor = get_floor(global_position.y)
		var my_tower = get_stair_tower_name(global_position)
		if my_floor == target_investigate_floor and my_tower == "":
			is_investigating_floor = false
			current_patrol_floor = target_investigate_floor
			current_floor_waypoints = get_floor_waypoints(current_patrol_floor)
			patrol_waypoints = current_floor_waypoints
			_pick_closest_waypoint()
			floor_investigate_timer = randf_range(50.0, 85.0)
			_say("A ver qué alumnos andan por este piso...", Color(1.0, 0.85, 0.5))
	else:
		if dist_dest < 2.0:
			current_waypoint_idx = (current_waypoint_idx + 1) % current_floor_waypoints.size()
			target_wp = current_floor_waypoints[current_waypoint_idx]
			nav_dest = _get_nav_target_to(target_wp)
			to_dest = nav_dest - global_position

	var move_dir: Vector3
	if absf(to_dest.y) > 0.4:
		move_dir = to_dest.normalized()
	else:
		to_dest.y = 0.0
		move_dir = to_dest.normalized()

	_move_towards(delta, move_dir, current_speed, 4.5)

func _process_chase_state(delta: float, can_see_player: bool) -> void:
	if is_screamer_ambush:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	if is_screamer_charging:
		screamer_charge_timer -= delta
		current_speed = 42.0
		if screamer_charge_timer <= 0.0:
			is_screamer_charging = false
			_end_screamer_charge()
	else:
		current_speed = chase_speed
	
	var to_player = player.global_position - global_position
	var dist_to_player = to_player.length()
	var horiz_dist = Vector2(to_player.x, to_player.z).length()

	# Si estaba cargando a toda velocidad y ya alcanzó al jugador, volver a velocidad normal
	if is_screamer_charging and dist_to_player <= attack_range + 0.6:
		_end_screamer_charge()

	if can_see_player:
		last_known_player_pos = player.global_position
		time_without_sight = 0.0
	else:
		time_without_sight += delta
		if time_without_sight >= lost_sight_timeout:
			_enter_search_state()
			return

	# Si el jugador está escondido en un tacho y el profesor lo alcanzó persiguiendo el ruido:
	if player.get("is_hidden") and dist_to_player <= attack_range + 0.6:
		_say("¡¡TE ENCONTRÉ! ¡SALÍ DE ESE TACHO!!", Color(1.0, 0.1, 0.1))
		if player.get("current_hiding_spot") and player.current_hiding_spot.has_method("force_eject"):
			player.current_hiding_spot.force_eject()
		_start_attack()
		return

	# Solo atacar si el jugador está a alcance cuerpo a cuerpo real (3D <= attack_range y desnivel vertical <= 0.85m)
	# Esto evita que se quede trabado atacando al aire/techo si el jugador está en el tramo superior de la escalera
	var vert_diff = absf(to_player.y)
	if dist_to_player <= attack_range and vert_diff <= 0.85 and attack_timer <= 0.0:
		if _has_line_of_sight(global_position + Vector3(0, 1.4, 0), player.global_position + Vector3(0, 1.2, 0)):
			_start_attack()
			return

	var target_dest = player.global_position if can_see_player else last_known_player_pos
	var nav_dest = _get_nav_target_to(target_dest)
	var to_target = nav_dest - global_position

	var move_dir: Vector3
	if absf(to_target.y) > 0.4:
		move_dir = to_target.normalized()
	else:
		to_target.y = 0.0
		move_dir = to_target.normalized()
	
	var rot_spd = 35.0 if is_screamer_charging else 8.0
	_move_towards(delta, move_dir, current_speed, rot_spd)

func _process_search_state(delta: float, can_see_player: bool) -> void:
	if can_see_player:
		_enter_chase_state()
		return

	search_timer -= delta

	# Si la última posición conocida está a más de 2.5m, caminar hacia ella para investigar
	var to_last = last_known_player_pos - global_position
	var dist_last = to_last.length()
	var my_floor = get_floor(global_position.y)
	var last_floor = get_floor(last_known_player_pos.y)

	if dist_last > 2.5 or my_floor != last_floor:
		var nav_dest = _get_nav_target_to(last_known_player_pos)
		var to_nav = nav_dest - global_position
		var move_dir: Vector3
		if absf(to_nav.y) > 0.4:
			move_dir = to_nav.normalized()
		else:
			to_nav.y = 0.0
			move_dir = to_nav.normalized()
		_move_towards(delta, move_dir, patrol_speed * 1.15, 6.0)
	else:
		# Ya está cerca del lugar: detenerse y girar mirando alrededor
		rotation.y += sin(search_timer * 3.0) * delta * 2.0
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		move_and_slide()
		_animate_walk(delta, false)

	if search_timer <= 0.0:
		current_state = State.PATROL
		current_patrol_floor = get_floor(global_position.y)
		current_floor_waypoints = get_floor_waypoints(current_patrol_floor)
		patrol_waypoints = current_floor_waypoints
		_pick_closest_waypoint()
		_say("Debió ser el viento... Volvamos a la ronda.")

func _process_attack_state(delta: float) -> void:
	_process_attack(delta)
	velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
	move_and_slide()

## =====================================================================
## MOVIMIENTO Y ORIENTACIÓN SUAVE CON FLANQUEO INTELIGENTE
## =====================================================================
func _is_walk_path_clear(from_pos: Vector3, to_pos: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	var start_p = from_pos + Vector3(0, 0.55, 0)
	var end_p = to_pos + Vector3(0, 0.55, 0)
	var query = PhysicsRayQueryParameters3D.create(start_p, end_p)
	var excl: Array[RID] = [get_rid()]
	if is_instance_valid(player):
		excl.append(player.get_rid())
	query.exclude = excl
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func _check_flanking(target_dir: Vector3, speed_to_use: float, delta: float) -> Vector3:
	var tower_name = get_stair_tower_name(global_position)
	# En escaleras o en el Laboratorio Central (donde _get_nav_target_to ya rutea por pasillos laterales):
	if tower_name != "" or (global_position.x >= -37.0 and global_position.x <= -17.0 and global_position.z >= -10.0 and global_position.z <= 11.0):
		is_flanking = false
		flank_phase = 0
		flank_timer = 0.0
		return target_dir

	var space_state = get_world_3d().direct_space_state

	# Si ya estamos en modo flanqueo activo:
	if is_flanking:
		flank_timer -= delta
		if flank_timer <= 0.0:
			is_flanking = false
			flank_phase = 0
			return target_dir

		var my_hip = global_position + Vector3(0, 0.55, 0)

		if flank_phase == 0:
			# FASE 0: Deslizarse lateralmente por la mesa hasta llegar al borde
			# Comprobar si en la dirección de paso (hacia el otro lado del obstáculo) ya quedó libre
			var fwd_probe_q = PhysicsRayQueryParameters3D.create(my_hip, my_hip + flank_pass_dir * 1.5)
			var excl_fwd: Array[RID] = [get_rid()]
			if is_instance_valid(player):
				excl_fwd.append(player.get_rid())
			fwd_probe_q.exclude = excl_fwd
			var fwd_hit = space_state.intersect_ray(fwd_probe_q)

			if fwd_hit.is_empty():
				# ¡Superó el borde de la mesa! Pasar a FASE 1 para doblar la esquina y entrar al pasillo
				flank_phase = 1
				flank_timer = 3.0
				return (flank_pass_dir * 0.75 + flank_dir * 0.25).normalized()

			# Si choca contra una pared transversal (ej: pared exterior del edificio), invertir sentido
			if test_move(global_transform, flank_dir * 0.25):
				flank_dir = -flank_dir

			return flank_dir

		elif flank_phase == 1:
			# FASE 1: Doblar la esquina y avanzar superando el ancho/profundidad de la mesa
			var dest_pos = player.global_position if (current_state == State.CHASE and is_instance_valid(player)) else last_known_player_pos
			if dest_pos != Vector3.ZERO and _is_walk_path_clear(global_position, dest_pos):
				# ¡Mesa completamente rodeada! El camino directo hacia el jugador en su pasillo está 100% libre
				is_flanking = false
				flank_phase = 0
				flank_timer = 0.0
				return target_dir

			# Si choca de frente al avanzar en pass_dir:
			if test_move(global_transform, flank_pass_dir * 0.25):
				# Ya superó el obstáculo o tocó la pared opuesta: salir de flanqueo
				is_flanking = false
				flank_phase = 0
				return target_dir

			return (flank_pass_dir * 0.85 + flank_dir * 0.15).normalized()

	# Si NO estamos flanqueando aún:
	# Detectar si estamos chocando contra una mesa/mueble O si hay un obstáculo bajo bloqueando el paso directo
	var should_start_flank = false
	var obstacle_normal = Vector3.ZERO

	if is_on_wall():
		obstacle_normal = get_wall_normal()
		should_start_flank = true
	elif current_state == State.CHASE and is_instance_valid(player):
		# Chequear con raycast a la altura de la cadera (0.55m) si hay un obstáculo intermedio
		var my_hip = global_position + Vector3(0, 0.55, 0)
		var tgt_hip = player.global_position + Vector3(0, 0.55, 0)
		var dist_to_tgt = my_hip.distance_to(tgt_hip)
		if dist_to_tgt < 12.0:
			var ray_q = PhysicsRayQueryParameters3D.create(my_hip, tgt_hip)
			ray_q.exclude = [get_rid(), player.get_rid()]
			var hit = space_state.intersect_ray(ray_q)
			if not hit.is_empty():
				# Hay una mesa o mueble intermedio entre el profesor y el jugador
				if my_hip.distance_to(hit.position) < 2.2:
					obstacle_normal = hit.normal
					should_start_flank = true

	if should_start_flank:
		obstacle_normal.y = 0.0
		if obstacle_normal.length() > 0.1:
			obstacle_normal = obstacle_normal.normalized()
			flank_pass_dir = -obstacle_normal
			
			# Las dos tangentes para rodear el obstáculo
			var tan_l = Vector3(-obstacle_normal.z, 0, obstacle_normal.x)
			var tan_r = -tan_l
			
			var to_target = target_dir
			if current_state == State.CHASE and is_instance_valid(player):
				to_target = (player.global_position - global_position).normalized()
			to_target.y = 0.0
			
			# Testear con rayos si alguna de las tangentes choca contra una pared a 1.2m
			var hip = global_position + Vector3(0, 0.55, 0)
			var q_l = PhysicsRayQueryParameters3D.create(hip, hip + tan_l * 1.5)
			q_l.exclude = [get_rid()]
			var hit_l = not space_state.intersect_ray(q_l).is_empty()
			
			var q_r = PhysicsRayQueryParameters3D.create(hip, hip + tan_r * 1.5)
			q_r.exclude = [get_rid()]
			var hit_r = not space_state.intersect_ray(q_r).is_empty()
			
			var chosen_dir = tan_l
			if hit_l and not hit_r:
				chosen_dir = tan_r
			elif hit_r and not hit_l:
				chosen_dir = tan_l
			else:
				if tan_r.dot(to_target) > tan_l.dot(to_target):
					chosen_dir = tan_r
				else:
					chosen_dir = tan_l
			
			is_flanking = true
			flank_phase = 0
			flank_dir = chosen_dir
			flank_timer = 6.0 # Tiempo suficiente para recorrer mesas largas completas
			return flank_dir

	return target_dir

func _move_towards(delta: float, dir: Vector3, speed_to_use: float, rot_speed: float) -> void:
	var move_vec = dir
	var tower_name = get_stair_tower_name(global_position)

	# En escaleras, velocidad máxima controlada para no chocar paredes ni pasarse de largo
	if tower_name != "":
		speed_to_use = min(speed_to_use, 1.9)
		is_flanking = false
		flank_timer = 0.0
	else:
		# Flanqueo inteligente para rodear mesas, muebles y obstáculos bajos
		if dir.length() > 0.05:
			move_vec = _check_flanking(dir, speed_to_use, delta)
	
	if move_vec.length() > 0.05:
		# Si toca una pared y no está flanqueando activamente, resolver deslizamiento o escape de esquinas
		if not is_flanking and is_on_wall():
			var col_count = get_slide_collision_count()
			if col_count >= 2:
				# Esquina interior: combinar normales para salir en diagonal hacia el espacio abierto
				var combined_normal = Vector3.ZERO
				for i in range(col_count):
					var col = get_slide_collision(i)
					combined_normal += col.get_normal()
				combined_normal.y = 0.0
				if combined_normal.length() > 0.15:
					combined_normal = combined_normal.normalized()
					var corner_escape = move_vec.slide(combined_normal).normalized()
					if corner_escape.length() > 0.15:
						move_vec = (corner_escape * 0.7 + combined_normal * 0.3).normalized()
					else:
						move_vec = combined_normal
			else:
				var wall_n = get_wall_normal()
				wall_n.y = 0.0
				if wall_n.length() > 0.1:
					wall_n = wall_n.normalized()
					var slide = move_vec.slide(wall_n).normalized()
					if slide.length() > 0.15:
						move_vec = slide
					else:
						# Choque frontal: deslizar hacia la tangente
						var tan_a = Vector3(-wall_n.z, 0, wall_n.x)
						var tan_b = -tan_a
						move_vec = tan_a if move_vec.dot(tan_a) >= move_vec.dot(tan_b) else tan_b

		var target_rot_y = atan2(move_vec.x, move_vec.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, rot_speed * delta)
		
		var accel = 140.0 if is_screamer_charging else 14.0
		velocity.x = move_toward(velocity.x, move_vec.x * speed_to_use, accel * delta)
		velocity.z = move_toward(velocity.z, move_vec.z * speed_to_use, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

	var pre_pos = global_position
	var was_on_floor = is_on_floor()
	move_and_slide()

	# Subir pequeños desniveles (Step-up hasta 25cm solo en pasillos, nunca en escaleras para no flotar)
	if tower_name == "" and was_on_floor and is_on_wall() and dir != Vector3.ZERO:
		var step_h: float = 0.25
		var step_t: Transform3D = global_transform
		step_t.origin.y += step_h
		if not test_move(global_transform, Vector3(0, step_h, 0)):
			var fwd: Vector3 = dir.normalized() * (speed_to_use * delta + 0.1)
			if not test_move(step_t, fwd):
				global_position = pre_pos + Vector3(0, step_h, 0)
				move_and_slide()

	# Detección y recuperación automática si se traba (Watchdog anti-stuck)
	pos_sample_timer += delta
	if pos_sample_timer >= 0.3:
		pos_sample_timer = 0.0
		var moved_dist = global_position.distance_to(prev_pos)
		prev_pos = global_position

		# Si está en modo flanqueo pero no avanza (ej: pared transversal inesperada):
		if is_flanking and moved_dist < 0.1:
			if flank_phase == 0:
				flank_dir = -flank_dir
				flank_timer = 4.0
			elif flank_phase == 1:
				is_flanking = false
				flank_phase = 0

		if not is_flanking and is_on_wall() and moved_dist < 0.15 and dir.length() > 0.1:
			stuck_timer += 0.3
		else:
			stuck_timer = max(0.0, stuck_timer - 0.3)

	# Si estuvo trabado contra una pared más de 0.6 segundos:
	if stuck_timer >= 0.6:
		var wall_n = get_wall_normal() if is_on_wall() else Vector3.ZERO
		wall_n.y = 0.0
		if wall_n.length() > 0.1:
			wall_n = wall_n.normalized()
		var push_away = wall_n * 2.0
		velocity.x += push_away.x * speed_to_use
		velocity.z += push_away.z * speed_to_use
		global_position += wall_n * 0.45

		var tower = get_stair_tower_name(global_position)
		if tower != "":
			# En escaleras: recolocar exactamente sobre el nodo más cercano (sin sumarle altura artificial)
			var path = get_stair_path(tower)
			var best_idx = 0
			var best_d = 99999.0
			for i in range(path.size()):
				var d = global_position.distance_to(path[i])
				if d < best_d:
					best_d = d
					best_idx = i
			global_position = path[best_idx]
			stuck_timer = 0.0
		else:
			# Forzar flanqueo lateral inmediato para zafar de la esquina o mueble
			if wall_n.length() > 0.1:
				var tan_esc = Vector3(-wall_n.z, 0, wall_n.x)
				if randf() > 0.5:
					tan_esc = -tan_esc
				is_flanking = true
				flank_dir = tan_esc
				flank_timer = 1.5

			if current_state == State.PATROL:
				if not is_investigating_floor and current_floor_waypoints.size() > 0:
					current_waypoint_idx = (current_waypoint_idx + 1) % current_floor_waypoints.size()
			elif current_state == State.CHASE and not _can_see_player():
				_enter_search_state()
			elif current_state == State.SEARCH:
				current_state = State.PATROL
				_pick_closest_waypoint()

			# Si lleva más de 3.0 segundos acumulados trabado en pasillo: TELETRANSPORTE AL WAYPOINT MÁS CERCANO DEL PISO
			if stuck_timer >= 3.0:
				stuck_timer = 0.0
				is_flanking = false
				var wps = current_floor_waypoints if current_floor_waypoints.size() > 0 else WAYPOINTS_PB
				var best_idx: int = -1
				var best_dist: float = 99999.0
				for i in range(wps.size()):
					var d = global_position.distance_to(wps[i])
					if d >= 3.0 and d < best_dist:
						best_dist = d
						best_idx = i
				if best_idx >= 0:
					global_position = wps[best_idx]
					prev_pos = global_position
					current_waypoint_idx = (best_idx + 1) % wps.size()
					velocity = Vector3.ZERO
					if current_state != State.PATROL:
						current_state = State.PATROL
		stuck_timer = max(stuck_timer, 0.0)

	_animate_walk(delta, dir.length() > 0.1)

## =====================================================================
## TRANSICIONES Y ACCIONES
## =====================================================================
func _enter_chase_state() -> void:
	current_state = State.CHASE
	time_without_sight = 0.0
	is_investigating_floor = false
	last_known_player_pos = player.global_position
	
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.1, 0.1)
		ojos_luz.light_energy = 1.6
		
	_say(phrases_chase[randi() % phrases_chase.size()], Color(1.0, 0.2, 0.2))
	
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_chase_screamer_time > 15.0:
		last_chase_screamer_time = now
		if is_instance_valid(player) and player.has_method("play_jumpscare_screamer"):
			player.play_jumpscare_screamer()

func _enter_search_state() -> void:
	current_state = State.SEARCH
	search_timer = 4.0
	
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.6, 0.1)
		ojos_luz.light_energy = 0.8
		
	_say("¿Dónde se escondió ese alumno...?", Color(1.0, 0.8, 0.4))

## LLAMADO CUANDO EL JUGADOR FALLA EL DESAFÍO MATEMÁTICO
func boost_speed() -> void:
	speed_boost_count += 1
	chase_speed = min(base_chase_speed + (speed_boost_count * 0.25), 3.4)
	patrol_speed = min(base_patrol_speed + (speed_boost_count * 0.15), 2.4)
	
	# Si todavía no apareció, solo acumula la velocidad
	if not is_active:
		return
	
	_enter_chase_state()
	
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.0, 0.0)
		ojos_luz.light_energy = 2.5
		
	_say(phrases_enraged[randi() % phrases_enraged.size()], Color(1.0, 0.0, 0.0))

func _setup_step_audio() -> void:
	step_audio = AudioStreamPlayer3D.new()
	step_audio.name = "ProfesorStepAudio3D"
	step_audio.unit_size = 3.5
	step_audio.max_distance = 35.0
	step_audio.volume_db = -3.0
	step_audio.bus = &"Master"
	add_child(step_audio)

func _play_prof_step() -> void:
	if not step_audio:
		return
	step_audio.stream = HorrorAudio.get_profesor_footstep()
	step_audio.pitch_scale = randf_range(0.96, 1.04)
	step_audio.play()

func _animate_walk(delta: float, is_moving: bool) -> void:
	if is_moving and is_on_floor():
		var step_mult = 2.8 if current_state == State.CHASE else 2.2
		var anim_delta = delta * (current_speed * step_mult)
		walk_anim_time += anim_delta
		step_phase += anim_delta
		
		# Cada medio ciclo se apoya un zapato formal (izquierdo o derecho)
		if step_phase >= PI:
			step_phase -= PI
			_play_prof_step()
			
		var swing_legs = sin(walk_anim_time) * deg_to_rad(28.0)
		var swing_arms = cos(walk_anim_time) * deg_to_rad(25.0)
		
		if pierna_izq: pierna_izq.rotation.x = swing_legs
		if pierna_der: pierna_der.rotation.x = -swing_legs
		if brazo_izq: brazo_izq.rotation.x = -swing_arms
		
		if not is_attacking and brazo_der:
			brazo_der.rotation.x = deg_to_rad(-35.0) + sin(walk_anim_time * 0.8) * deg_to_rad(15.0)
			brazo_der.rotation.z = deg_to_rad(-10.0)
			if regla:
				regla.rotation.x = deg_to_rad(20.0) + cos(walk_anim_time * 1.5) * deg_to_rad(10.0)
	else:
		walk_anim_time = 0.0
		step_phase = 1.0 # Pre-cargado para sonar apenas retome el paso
		if pierna_izq: pierna_izq.rotation.x = lerpf(pierna_izq.rotation.x, 0.0, delta * 6.0)
		if pierna_der: pierna_der.rotation.x = lerpf(pierna_der.rotation.x, 0.0, delta * 6.0)
		if brazo_izq: brazo_izq.rotation.x = lerpf(brazo_izq.rotation.x, 0.0, delta * 6.0)
		if not is_attacking and not is_screamer_ambush and brazo_der:
			brazo_der.rotation.x = lerpf(brazo_der.rotation.x, deg_to_rad(-40.0), delta * 5.0)
			brazo_der.rotation.z = lerpf(brazo_der.rotation.z, deg_to_rad(-10.0), delta * 5.0)

## =====================================================================
## CINEMÁTICA Y SCREAMER DEL LABORATORIO
## =====================================================================
func trigger_screamer_ambush(ambush_pos: Vector3, look_at_pos: Vector3) -> void:
	set_active(true)
	visible = true
	is_investigating_floor = false
	current_patrol_floor = 0
	active_stair_idx = -1
	active_stair_tower = ""
	is_screamer_ambush = true
	global_position = ambush_pos
	prev_pos = ambush_pos
	velocity = Vector3.ZERO
	stuck_timer = 0.0
	attack_timer = 1.8
	is_attacking = false
	
	# Mirar fijamente hacia el jugador y la pared del tablero
	var to_target = look_at_pos - ambush_pos
	to_target.y = 0.0
	if to_target.length() > 0.1:
		rotation.y = atan2(to_target.x, to_target.z)
		
	# Postura amenazante con la regla en alto
	if brazo_der:
		brazo_der.rotation.x = deg_to_rad(-125.0)
		brazo_der.rotation.y = deg_to_rad(-15.0)
		brazo_der.rotation.z = deg_to_rad(-10.0)
	if regla:
		regla.rotation.x = deg_to_rad(-45.0)
		
	# Ojos al rojo vivo con máxima intensidad
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.0, 0.0)
		ojos_luz.light_energy = 4.0
		ojos_luz.spot_range = 15.0
		ojos_luz.visible = true
		
	# Entrar en persecución agresiva con incremento de velocidad
	current_state = State.CHASE
	chase_speed = base_chase_speed + 1.1
	time_without_sight = 0.0
	if is_instance_valid(player):
		last_known_player_pos = player.global_position

func play_ruler_slam_animation() -> void:
	if not brazo_der or not regla:
		return
	var tw = create_tween()
	# Azote rápido hacia abajo contra la mesada
	tw.tween_property(brazo_der, "rotation:x", deg_to_rad(35.0), 0.09)
	tw.parallel().tween_property(regla, "rotation:x", deg_to_rad(65.0), 0.09)
	# Volver a levantar amenazante
	tw.tween_property(brazo_der, "rotation:x", deg_to_rad(-120.0), 0.22)
	tw.parallel().tween_property(regla, "rotation:x", deg_to_rad(-40.0), 0.22)

func start_screamer_charge() -> void:
	is_screamer_ambush = false
	is_screamer_charging = true
	screamer_charge_timer = 1.4
	current_state = State.CHASE
	current_speed = 40.0
	stuck_timer = 0.0
	attack_timer = 0.15
	last_chase_screamer_time = Time.get_ticks_msec() / 1000.0
	_say("¡¡NO HAY SALVACIÓN, DIRECTO A MARZO!!", Color(1.0, 0.0, 0.0))
	if is_instance_valid(player) and player.has_method("play_jumpscare_screamer"):
		player.play_jumpscare_screamer()
	if is_instance_valid(player):
		last_known_player_pos = player.global_position
		var to_p = player.global_position - global_position
		to_p.y = 0.0
		if to_p.length() > 0.1:
			var dir_p = to_p.normalized()
			rotation.y = atan2(dir_p.x, dir_p.z)
			velocity.x = dir_p.x * 42.0
			velocity.z = dir_p.z * 42.0

func _end_screamer_charge() -> void:
	is_screamer_charging = false
	screamer_charge_timer = 0.0
	chase_speed = base_chase_speed + (speed_boost_count * 0.85)
	current_speed = chase_speed
	var horiz_vel = Vector2(velocity.x, velocity.z)
	if horiz_vel.length() > chase_speed:
		var clamped = horiz_vel.normalized() * chase_speed
		velocity.x = clamped.x
		velocity.z = clamped.y

func release_screamer_ambush() -> void:
	is_screamer_ambush = false
	stuck_timer = 0.0
	prev_pos = global_position
	_pick_closest_waypoint()
	# Asegurar que tiene un destino válido de movimiento
	if current_state == State.CHASE and not _can_see_player():
		_enter_search_state()

func _start_attack() -> void:
	_cut_screamer_audio()
	if is_screamer_charging:
		_end_screamer_charge()
	current_state = State.ATTACK
	is_attacking = true
	attack_anim_time = 0.0
	attack_timer = attack_cooldown
	_say("¡¡¡CASTIGO POR COPIARSE!!!", Color(1.0, 0.1, 0.1))

func _process_attack(delta: float) -> void:
	attack_anim_time += delta
	
	if not brazo_der or not regla:
		is_attacking = false
		current_state = State.CHASE
		return
		
	if attack_anim_time < 0.22:
		var p = attack_anim_time / 0.22
		brazo_der.rotation.x = lerpf(deg_to_rad(-40.0), deg_to_rad(-125.0), p)
		brazo_der.rotation.y = lerpf(0.0, deg_to_rad(-20.0), p)
		regla.rotation.x = lerpf(0.0, deg_to_rad(-45.0), p)
	elif attack_anim_time < 0.38:
		var p = (attack_anim_time - 0.22) / 0.16
		brazo_der.rotation.x = lerpf(deg_to_rad(-125.0), deg_to_rad(45.0), p)
		regla.rotation.x = lerpf(deg_to_rad(-45.0), deg_to_rad(70.0), p)
		
		if p > 0.6 and is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist <= attack_range + 0.6:
				_hit_player()
	elif attack_anim_time < 0.65:
		var p = (attack_anim_time - 0.38) / 0.27
		brazo_der.rotation.x = lerpf(deg_to_rad(45.0), deg_to_rad(-40.0), p)
		brazo_der.rotation.y = lerpf(deg_to_rad(-20.0), 0.0, p)
		regla.rotation.x = lerpf(deg_to_rad(70.0), 0.0, p)
	else:
		is_attacking = false
		current_state = State.CHASE

func _hit_player() -> void:
	_cut_screamer_audio()
	if is_instance_valid(player):
		var push_dir = (player.global_position - global_position).normalized()
		player.velocity += push_dir * 9.0 + Vector3(0, 3.2, 0)
		
		var cam = player.find_child("Camera3D", true, false) as Camera3D
		if cam:
			var tw = create_tween()
			tw.tween_property(cam, "rotation:z", deg_to_rad(randf_range(-14.0, 14.0)), 0.05)
			tw.tween_property(cam, "rotation:z", 0.0, 0.18)

func _update_dialogue(delta: float) -> void:
	phrase_timer -= delta
	if phrase_timer <= 0.0:
		phrase_timer = randf_range(7.0, 15.0)
		if current_state == State.PATROL:
			_say(phrases_patrol[randi() % phrases_patrol.size()], Color(1.0, 0.85, 0.5))

func _say(text_msg: String, color: Color = Color(1.0, 0.85, 0.5)) -> void:
	if cartel_dialogo:
		cartel_dialogo.text = text_msg
		cartel_dialogo.modulate = color
		
		get_tree().create_timer(3.5).timeout.connect(func():
			if is_instance_valid(cartel_dialogo) and not is_attacking and current_state == State.PATROL:
				cartel_dialogo.text = ""
		)

func _on_player_noise(volume: float) -> void:
	if not is_active or not is_instance_valid(player):
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= hearing_range:
		_enter_chase_state()
		last_known_player_pos = player.global_position
		
		var my_floor = get_floor(global_position.y)
		var p_floor = get_floor(player.global_position.y)
		if player.get("is_hidden"):
			_say("¡¡¿QUÉ ES ESE RUIDO DENTRO DEL TACHO?!!", Color(1.0, 0.2, 0.2))
		elif my_floor != p_floor:
			_say("¡¡¿QUIÉN ANDA HACIENDO RUIDO EN EL OTRO PISO?!!", Color(1.0, 0.2, 0.2))
		else:
			_say("¡¡¿QUIÉN HACE RUIDO EN MI HORA?!!", Color(1.0, 0.2, 0.2))
			
		var to_player = player.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.1:
			rotation.y = atan2(to_player.x, to_player.z)

func _cut_screamer_audio() -> void:
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group("screamer_audio"):
		if is_instance_valid(node) and node is AudioStreamPlayer:
			node.stop()
			node.queue_free()
	var root_sc = get_tree().root.find_child("ScreamerJumpscareAudio", true, false)
	if root_sc and is_instance_valid(root_sc) and root_sc is AudioStreamPlayer:
		root_sc.stop()
		root_sc.queue_free()
	if is_instance_valid(player):
		if player.has_method("fade_jumpscare_screamer"):
			player.fade_jumpscare_screamer(1.0)
		if player.has_method("trigger_post_screamer_heartbeat"):
			player.trigger_post_screamer_heartbeat(25.0)

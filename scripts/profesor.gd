extends CharacterBody3D
class_name Profesor

enum State {
	PATROL,
	CHASE,   ## Estado HUNT (Persecución activa)
	SEARCH,  ## Estado SEEK (Investigación de estímulo sonoro o visual)
	ATTACK   ## Ataque cuerpo a cuerpo con regla
}

## Velocidades ajustables
@export var base_patrol_speed: float = 2.0
@export var base_chase_speed: float = 2.85
@export var seek_speed: float = 2.4
@export var vision_range: float = 30.0
@export var vision_angle_deg: float = 190.0
@export var proximity_range: float = 5.5
@export var hearing_range: float = 35.0
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.3
@export var lost_sight_timeout: float = 6.0

## Estado actual
var current_state: State = State.PATROL
var current_speed: float = 2.0
var chase_speed: float = 2.85
var patrol_speed: float = 2.0
var speed_boost_count: int = 0

## Referencias al modelo
@onready var visual_root: Node3D = $Visuals
@onready var torso: Node3D = find_child("Torso", true, false)
@onready var pierna_izq: Node3D = find_child("PiernaIzq", true, false)
@onready var pierna_der: Node3D = find_child("PiernaDer", true, false)
@onready var rodilla_izq: Node3D = find_child("RodillaIzq", true, false)
@onready var rodilla_der: Node3D = find_child("RodillaDer", true, false)
@onready var tobillo_izq: Node3D = find_child("TobilloIzq", true, false)
@onready var tobillo_der: Node3D = find_child("TobilloDer", true, false)
@onready var brazo_izq: Node3D = find_child("BrazoIzq", true, false)
@onready var brazo_der: Node3D = find_child("BrazoDer", true, false)
@onready var codo_izq: Node3D = find_child("CodoIzq", true, false)
@onready var codo_der: Node3D = find_child("CodoDer", true, false)
@onready var mano_izq: Node3D = find_child("ManoIzq", true, false)
@onready var mano_der: Node3D = find_child("ManoDer", true, false)
@onready var regla: Node3D = find_child("ReglaPivot", true, false)
@onready var cabeza: Node3D = find_child("Cabeza", true, false)
@onready var cartel_dialogo: Label3D = find_child("DialogoLabel", true, false)
@onready var ojos_luz: SpotLight3D = find_child("OjosLuz", true, false)
@onready var aura_luz: OmniLight3D = find_child("AuraProfesor", true, false)
@onready var ojo_izq: GeometryInstance3D = find_child("OjoBrilloIzq", true, false)
@onready var ojo_der: GeometryInstance3D = find_child("OjoBrilloDer", true, false)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var player: CharacterBody3D = null

var walk_anim_time: float = 0.0
var idle_anim_time: float = 0.0
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_anim_time: float = 0.0

var time_without_sight: float = 0.0
var search_timer: float = 0.0
var search_target_pos: Vector3 = Vector3.ZERO
var last_known_player_pos: Vector3 = Vector3.ZERO
var is_searching_around: bool = false

var stuck_timer: float = 0.0
var prev_pos: Vector3 = Vector3.ZERO
var pos_sample_timer: float = 0.0
var is_screamer_ambush: bool = false
var is_screamer_charging: bool = false
var screamer_charge_timer: float = 0.0
var loop_commit_timer: float = 0.0

## Corrida cinematográfica por el pasillo (susto al terminar el 4to examen)
var is_hallway_dashing: bool = false
var hallway_dash_target: Vector3 = Vector3.ZERO
var hallway_dash_speed: float = 18.5
var hallway_dash_timer: float = 0.0
var hallway_dash_callback: Callable = Callable()

## Fase enfurecida final (al resolver los 4 parciales de PB)
var is_enraged_final: bool = false
## Modo Devour/Pacify extremo al agarrar el Título en el Auditorio
var is_devour_rage: bool = false

## Terror procedimental: balanceo de linterna y espasmos de cabeza
var lantern_sway_timer: float = 0.0
var twitch_timer: float = 6.0
var twitch_active_timer: float = 0.0
var twitch_offset: Vector3 = Vector3.ZERO

## Tensión al inspeccionar tachos de basura
var trash_suspicion_cooldown: float = 0.0
var is_inspecting_trash_suspense: bool = false
var trash_suspense_timer: float = 0.0

## El profesor se concentra en aterrorizar e inspeccionar la Planta Baja (PB)
const ONLY_PATROL_PB: bool = true

## Inspección de aulas en PB
var is_inspecting_aula: bool = false
var aula_inspect_wait_timer: float = 0.0
var aula_inspect_cooldown: float = 12.0
var saw_player_hide: bool = false
var prev_player_hidden: bool = false
var is_trash_rushing: bool = false

## =====================================================================
## RED DE NAVEGACIÓN ASTAR3D PARA PLANTA BAJA (PB)
## Garantiza que el profesor NUNCA camine contra paredes ni atraviese objetos
## =====================================================================
var astar_pb: AStar3D = AStar3D.new()
var current_path: PackedVector3Array = PackedVector3Array()
var current_path_idx: int = 0
var repath_timer: float = 0.0

## Circuito de patrullaje principal de Planta Baja
const PATROL_CIRCUIT_PB: Array[Vector3] = [
	Vector3(-42.0, 0.2, -28.5),   # 0: Pasillo Oeste (Esquina NW)
	Vector3(-42.0, 0.2, -12.0),   # 1: Pasillo Oeste (frente a Aula 106)
	Vector3(-42.0, 0.2, 2.5),     # 2: Pasillo Oeste (frente a Aula 107)
	Vector3(-42.0, 0.2, 17.5),    # 3: Pasillo Oeste (frente a Aula 108)
	Vector3(-42.0, 0.2, 30.0),    # 4: Esquina SW
	Vector3(-20.0, 0.2, 30.0),    # 5: Pasillo Sur oeste (frente a Fotocopiadora 1)
	Vector3(0.0, 0.2, 30.0),      # 6: Pasillo Sur centro (Entrada Patio y Auditorio)
	Vector3(0.0, 0.2, 22.0),      # 7: Galería Sur Patio
	Vector3(0.0, 0.2, 4.0),       # 8: Patio frente a la fuente
	Vector3(0.0, 0.2, 22.0),      # 9: Retorno Galería Sur Patio
	Vector3(0.0, 0.2, 30.0),      # 10: Pasillo Sur centro
	Vector3(20.0, 0.2, 30.0),     # 11: Pasillo Sur este
	Vector3(42.0, 0.2, 30.0),     # 12: Esquina SE
	Vector3(42.0, 0.2, 17.0),     # 13: Pasillo Este sur (frente a Aula 115)
	Vector3(42.0, 0.2, -2.5),     # 14: Pasillo Este centro (frente a Cafetería PB)
	Vector3(42.0, 0.2, -15.0),    # 15: Pasillo Este norte (frente a Aula 114)
	Vector3(42.0, 0.2, -28.5),    # 16: Esquina NE
	Vector3(23.5, 0.2, -28.5),    # 17: Pasillo Norte este (frente a Aula 104)
	Vector3(0.0, 0.2, -28.5),     # 18: Pasillo Norte centro
	Vector3(-25.0, 0.2, -28.5)    # 19: Pasillo Norte oeste (frente a Aula 102)
]
var current_circuit_idx: int = 0

## Inspecciones de aulas en PB
const AULAS_PB_DATA: Array[Dictionary] = [
	{
		"name": "Aula 106",
		"corridor_wp": Vector3(-42.0, 0.2, -12.0),
		"door_pos": Vector3(-47.0, 0.2, -12.0),
		"inside_pos": Vector3(-49.5, 0.2, -12.0),
		"yaw": deg_to_rad(-90.0)
	},
	{
		"name": "Aula 107",
		"corridor_wp": Vector3(-42.0, 0.2, 2.5),
		"door_pos": Vector3(-47.0, 0.2, 2.5),
		"inside_pos": Vector3(-49.5, 0.2, 2.5),
		"yaw": deg_to_rad(-90.0)
	},
	{
		"name": "Aula 108",
		"corridor_wp": Vector3(-42.0, 0.2, 17.5),
		"door_pos": Vector3(-47.0, 0.2, 17.5),
		"inside_pos": Vector3(-49.5, 0.2, 17.5),
		"yaw": deg_to_rad(-90.0)
	},
	{
		"name": "Aula 102",
		"corridor_wp": Vector3(-25.0, 0.2, -28.5),
		"door_pos": Vector3(-27.5, 0.2, -33.0),
		"inside_pos": Vector3(-27.5, 0.2, -35.5),
		"yaw": deg_to_rad(180.0)
	},
	{
		"name": "Cafetería PB",
		"corridor_wp": Vector3(42.0, 0.2, -2.5),
		"door_pos": Vector3(47.0, 0.2, -2.5),
		"inside_pos": Vector3(50.5, 0.2, -2.5),
		"yaw": deg_to_rad(90.0)
	},
	{
		"name": "Lab Central Electrónica",
		"corridor_wp": Vector3(-42.0, 0.2, 0.5),
		"door_pos": Vector3(-37.0, 0.2, 0.5),
		"inside_pos": Vector3(-26.5, 0.2, 1.5),
		"yaw": deg_to_rad(0.0)
	}
]

## Nodos secuenciales de escaleras (por compatibilidad en caso de desbloqueo futuro)
const STAIR_WEST_PATH: Array[Vector3] = [
	Vector3(-64.5, 0.2, 27.5),
	Vector3(-66.0, 0.4, 27.5),
	Vector3(-71.0, 2.1, 27.5),
	Vector3(-72.8, 2.25, 27.5),
	Vector3(-72.8, 2.25, 32.5),
	Vector3(-71.0, 2.4, 32.5),
	Vector3(-66.0, 4.3, 32.5),
	Vector3(-64.5, 4.7, 32.5)
]

var active_stair_idx: int = -1
var active_stair_tower: String = ""

func get_floor(y: float) -> int:
	if y < 2.5: return 0
	elif y < 7.0: return 1
	else: return 2

func get_stair_tower_name(pos: Vector3) -> String:
	if pos.x <= -63.0 and pos.x >= -75.0 and pos.z >= 24.0 and pos.z <= 36.0:
		return "Oeste"
	if pos.x >= 63.0 and pos.x <= 75.0 and pos.z >= 24.0 and pos.z <= 36.0:
		return "Este"
	if pos.x >= 37.0 and pos.x <= 47.0 and pos.z >= -55.0 and pos.z <= -43.0:
		return "Norte"
	return ""

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
var phrases_devour_rage: Array[String] = [
	"¡¡NO TE VAS A RECIBIR NUNCA!!",
	"¡¡ESE TÍTULO NO ES TUYO!! ¡¡DEVUÉLVELO!!",
	"¡¡ESTÁS EXPULSADO DE POR VIDA!!",
	"¡¡DE ESTA FACULTAD NO SALE NADIE VIVO!!",
	"¡¡JAMÁS VAS A CRUZAR ESA PUERTA!!"
]
var phrases_seek: Array[String] = [
	"¿Dónde se metió este alumno? Parecía haber alguien acá...",
	"¿Quién anda haciendo ruidos en mi hora...?",
	"Me pareció escuchar pasos por acá...",
	"Nadie debería estar afuera del aula..."
]

var phrase_timer: float = 0.0
var step_audio: AudioStreamPlayer3D = null
var slam_audio: AudioStreamPlayer3D = null
var creepy_steps_stream: AudioStream = null
var step_phase: float = 0.0
var last_chase_screamer_time: float = -999.0

## Activa o desactiva al profesor
var is_active: bool = true

func _ready() -> void:
	add_to_group("enemies")
	
	_setup_step_audio()
	_build_astar_pb_network()
	
	floor_snap_length = 0.5
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	floor_block_on_wall = false
	
	patrol_speed = base_patrol_speed
	chase_speed = base_chase_speed
	current_speed = patrol_speed
	
	prev_pos = global_position
	
	_find_player()
	_ensure_mic_connected()
		
	phrase_timer = randf_range(4.0, 8.0)
	_pick_closest_patrol_circuit_idx()
	_navigate_to_circuit_idx(current_circuit_idx)

func _ensure_mic_connected() -> void:
	var mic = get_tree().root.find_child("MicDetector", true, false)
	if mic and mic.has_signal("noise_triggered"):
		if not mic.noise_triggered.is_connected(_on_player_noise):
			mic.noise_triggered.connect(_on_player_noise)

func set_active(active: bool) -> void:
	is_active = active
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if not active:
		velocity = Vector3.ZERO
		if step_audio:
			step_audio.stop()
		if slam_audio:
			slam_audio.stop()
		_cut_screamer_audio()
		for ch in find_children("*", "AudioStreamPlayer3D", true, false):
			(ch as AudioStreamPlayer3D).stop()
		for ch in find_children("*", "AudioStreamPlayer", true, false):
			(ch as AudioStreamPlayer).stop()
	elif active and is_inside_tree():
		velocity = Vector3.ZERO
		current_state = State.PATROL
		current_speed = patrol_speed
		time_without_sight = 0.0
		prev_pos = global_position
		_find_player()
		_ensure_mic_connected()
		_pick_closest_patrol_circuit_idx()
		_navigate_to_circuit_idx(current_circuit_idx)

## =====================================================================
## CONSTRUCCIÓN DE LA RED ASTAR3D DE PLANTA BAJA
## =====================================================================
func _build_astar_pb_network() -> void:
	astar_pb.clear()
	
	var points = {
		# Pasillo Oeste (X = -42.0)
		"W_0": Vector3(-42.0, 0.2, -28.5),
		"W_1": Vector3(-42.0, 0.2, -20.0),
		"W_2": Vector3(-42.0, 0.2, -12.0),
		"W_3": Vector3(-42.0, 0.2, -8.0),
		"W_LAB": Vector3(-42.0, 0.2, 0.5),
		"W_4": Vector3(-42.0, 0.2, 2.5),
		"W_5": Vector3(-42.0, 0.2, 17.5),
		"W_6": Vector3(-42.0, 0.2, 30.0),
		# Pasillo Sur (Z = 30.0)
		"S_1": Vector3(-30.0, 0.2, 30.0),
		"S_2": Vector3(-20.0, 0.2, 30.0),
		"S_3": Vector3(-10.0, 0.2, 30.0),
		"S_4": Vector3(0.0, 0.2, 30.0),
		"S_5": Vector3(10.0, 0.2, 30.0),
		"S_6": Vector3(20.0, 0.2, 30.0),
		"S_7": Vector3(30.0, 0.2, 30.0),
		"E_6": Vector3(42.0, 0.2, 30.0),
		# Pasillo Este (X = 42.0)
		"E_5": Vector3(42.0, 0.2, 17.0),
		"E_4": Vector3(42.0, 0.2, 8.0),
		"E_3": Vector3(42.0, 0.2, -2.5),
		"E_2": Vector3(42.0, 0.2, -15.0),
		"E_1": Vector3(42.0, 0.2, -22.0),
		"E_0": Vector3(42.0, 0.2, -28.5),
		# Pasillo Norte (Z = -28.5)
		"N_5": Vector3(30.0, 0.2, -28.5),
		"N_4": Vector3(23.5, 0.2, -28.5),
		"N_3": Vector3(10.0, 0.2, -28.5),
		"N_2": Vector3(0.0, 0.2, -28.5),
		"N_1": Vector3(-15.0, 0.2, -28.5),
		"N_0": Vector3(-25.0, 0.2, -28.5),
		# Patio del Estudiante
		"P_S": Vector3(0.0, 0.2, 22.0),
		"P_MS": Vector3(0.0, 0.2, 14.0),
		"P_FNT": Vector3(0.0, 0.2, 4.0),
		"P_MN": Vector3(0.0, 0.2, -4.0),
		"P_N": Vector3(0.0, 0.2, -12.0),
		"P_W": Vector3(-12.0, 0.2, 6.0),
		"P_E": Vector3(12.0, 0.2, 6.0),
		# Aulas e interiores con pasillos completos entre pupitres
		# Aula 106
		"A106_DOOR": Vector3(-47.0, 0.2, -12.0),
		"A106_FRONT": Vector3(-49.5, 0.2, -12.0),
		"A106_AISLE_N": Vector3(-51.5, 0.2, -17.5),
		"A106_AISLE_N_BACK": Vector3(-62.5, 0.2, -17.5),
		"A106_AISLE_S": Vector3(-51.5, 0.2, -6.5),
		"A106_AISLE_S_BACK": Vector3(-62.5, 0.2, -6.5),
		"A106_BACK_MID": Vector3(-62.5, 0.2, -11.8),
		"A106_ROW_MID": Vector3(-56.5, 0.2, -11.8),
		# Aula 107
		"A107_DOOR": Vector3(-47.0, 0.2, 2.5),
		"A107_FRONT": Vector3(-49.5, 0.2, 2.5),
		"A107_AISLE_N": Vector3(-51.5, 0.2, -3.0),
		"A107_AISLE_N_BACK": Vector3(-62.5, 0.2, -3.0),
		"A107_AISLE_S": Vector3(-51.5, 0.2, 7.5),
		"A107_AISLE_S_BACK": Vector3(-62.5, 0.2, 7.5),
		"A107_BACK_MID": Vector3(-62.5, 0.2, 2.5),
		"A107_ROW_MID": Vector3(-56.5, 0.2, 2.5),
		# Aula 108
		"A108_DOOR": Vector3(-47.0, 0.2, 17.5),
		"A108_FRONT": Vector3(-49.5, 0.2, 17.5),
		"A108_AISLE_N": Vector3(-51.5, 0.2, 12.0),
		"A108_AISLE_N_BACK": Vector3(-62.5, 0.2, 12.0),
		"A108_AISLE_S": Vector3(-51.5, 0.2, 23.0),
		"A108_AISLE_S_BACK": Vector3(-62.5, 0.2, 23.0),
		"A108_BACK_MID": Vector3(-62.5, 0.2, 17.5),
		"A108_ROW_MID": Vector3(-56.5, 0.2, 17.5),
		# Aula 102
		"A102_DOOR": Vector3(-27.5, 0.2, -33.0),
		"A102_IN": Vector3(-27.5, 0.2, -35.5),
		# Cafetería PB
		"CAFE_DOOR": Vector3(47.0, 0.2, -2.5),
		"CAFE_FRONT": Vector3(50.5, 0.2, -2.5),
		"CAFE_NORTH": Vector3(50.5, 0.2, -8.5),
		"CAFE_SOUTH": Vector3(50.5, 0.2, 4.0),
		"CAFE_BACK": Vector3(57.0, 0.2, -2.5),
		# Fotocopiadora
		"FOTO_DOOR": Vector3(-35.0, 0.2, 34.5),
		"FOTO_IN": Vector3(-25.0, 0.2, 38.0),
		# Lab Central de Electrónica (Entrada oeste real en Z = 0.5 y pasillos entre mesadas)
		"LAB_DOOR_OUT": Vector3(-39.5, 0.2, 0.5),
		"LAB_DOOR": Vector3(-37.0, 0.2, 0.5),
		"LAB_DOOR_IN": Vector3(-35.0, 0.2, 0.5),
		"LAB_W_N": Vector3(-35.0, 0.2, -8.3),
		"LAB_W_01": Vector3(-35.0, 0.2, -3.5),
		"LAB_W_12": Vector3(-35.0, 0.2, 1.5),
		"LAB_W_S": Vector3(-35.0, 0.2, 7.5),
		"LAB_MID_N": Vector3(-26.5, 0.2, -8.3),
		"LAB_MID_01": Vector3(-26.5, 0.2, -3.5),
		"LAB_MID_12": Vector3(-26.5, 0.2, 1.5),
		"LAB_MID_S": Vector3(-26.5, 0.2, 7.5),
		"LAB_E_N": Vector3(-18.5, 0.2, -8.3),
		"LAB_E_01": Vector3(-18.5, 0.2, -3.5),
		"LAB_E_PANEL": Vector3(-18.5, 0.2, 0.0),
		"LAB_E_12": Vector3(-18.5, 0.2, 1.5),
		"LAB_E_S": Vector3(-18.5, 0.2, 7.5),
		# Auditorio Principal (Malla completa de pasillos para evitar atascamiento en butacas)
		"AUD_DOOR": Vector3(0.0, 0.2, 35.0),
		"AUD_BACK_W": Vector3(-14.5, 0.2, 39.5),
		"AUD_BACK_C": Vector3(0.0, 0.2, 39.5),
		"AUD_BACK_E": Vector3(13.8, 0.2, 39.5),
		# Pasillo Central del Auditorio (ancho 5.5m entre X=-3.35 y X=2.20)
		"AUD_C_1": Vector3(0.0, 0.2, 44.0),
		"AUD_C_2": Vector3(0.0, 0.2, 49.0),
		"AUD_C_3": Vector3(0.0, 0.2, 54.0),
		"AUD_C_MID": Vector3(0.0, 0.2, 59.0),
		"AUD_C_4": Vector3(0.0, 0.2, 64.0),
		"AUD_C_5": Vector3(0.0, 0.2, 68.0),
		"AUD_C_STAGE": Vector3(0.0, 0.2, 72.5),
		# Pasillo Lateral Oeste del Auditorio (X = -14.5)
		"AUD_W_1": Vector3(-14.5, 0.2, 44.0),
		"AUD_W_2": Vector3(-14.5, 0.2, 51.0),
		"AUD_W_MID": Vector3(-14.5, 0.2, 59.0),
		"AUD_W_3": Vector3(-14.5, 0.2, 66.0),
		"AUD_W_STAGE": Vector3(-14.5, 0.2, 72.5),
		# Pasillo Lateral Este del Auditorio (X = 13.8)
		"AUD_E_1": Vector3(13.8, 0.2, 44.0),
		"AUD_E_2": Vector3(13.8, 0.2, 51.0),
		"AUD_E_MID": Vector3(13.8, 0.2, 59.0),
		"AUD_E_3": Vector3(13.8, 0.2, 66.0),
		"AUD_E_STAGE": Vector3(13.8, 0.2, 72.5),
		# Escenario del Auditorio (Ubicación del Título Universitario)
		"AUD_STAGE_FRONT": Vector3(0.0, 0.2, 74.0),
		"AUD_STAGE_RAMP_L": Vector3(-3.5, 0.4, 74.8),
		"AUD_STAGE_RAMP_R": Vector3(3.5, 0.4, 74.8),
		"AUD_STAGE_TITLE": Vector3(0.0, 0.9, 77.5),
		"AUD_STAGE_BACK": Vector3(0.0, 0.9, 81.0)
	}
	
	var name_to_id = {}
	var id = 0
	for k in points.keys():
		name_to_id[k] = id
		astar_pb.add_point(id, points[k])
		id += 1
		
	var connections = [
		# Pasillo Oeste
		["W_0", "W_1"], ["W_1", "W_2"], ["W_2", "W_3"], ["W_3", "W_LAB"], ["W_LAB", "W_4"], ["W_4", "W_5"], ["W_5", "W_6"],
		# Pasillo Sur
		["W_6", "S_1"], ["S_1", "S_2"], ["S_2", "S_3"], ["S_3", "S_4"], ["S_4", "S_5"], ["S_5", "S_6"], ["S_6", "S_7"], ["S_7", "E_6"],
		# Pasillo Este
		["E_6", "E_5"], ["E_5", "E_4"], ["E_4", "E_3"], ["E_3", "E_2"], ["E_2", "E_1"], ["E_1", "E_0"],
		# Pasillo Norte
		["E_0", "N_5"], ["N_5", "N_4"], ["N_4", "N_3"], ["N_3", "N_2"], ["N_2", "N_1"], ["N_1", "N_0"], ["N_0", "W_0"],
		# Patio
		["S_4", "P_S"], ["P_S", "P_MS"], ["P_MS", "P_FNT"], ["P_FNT", "P_MN"], ["P_MN", "P_N"],
		["P_MS", "P_W"], ["P_W", "P_MN"], ["P_MS", "P_E"], ["P_E", "P_MN"],
		# Aulas
		# Aula 106 (flanqueo completo de pupitres)
		["W_2", "A106_DOOR"], ["A106_DOOR", "A106_FRONT"],
		["A106_FRONT", "A106_AISLE_N"], ["A106_AISLE_N", "A106_AISLE_N_BACK"],
		["A106_FRONT", "A106_AISLE_S"], ["A106_AISLE_S", "A106_AISLE_S_BACK"],
		["A106_AISLE_N_BACK", "A106_BACK_MID"], ["A106_BACK_MID", "A106_AISLE_S_BACK"],
		["A106_AISLE_N", "A106_ROW_MID"], ["A106_ROW_MID", "A106_AISLE_S"],
		# Aula 107
		["W_4", "A107_DOOR"], ["A107_DOOR", "A107_FRONT"],
		["A107_FRONT", "A107_AISLE_N"], ["A107_AISLE_N", "A107_AISLE_N_BACK"],
		["A107_FRONT", "A107_AISLE_S"], ["A107_AISLE_S", "A107_AISLE_S_BACK"],
		["A107_AISLE_N_BACK", "A107_BACK_MID"], ["A107_BACK_MID", "A107_AISLE_S_BACK"],
		["A107_AISLE_N", "A107_ROW_MID"], ["A107_ROW_MID", "A107_AISLE_S"],
		# Aula 108
		["W_5", "A108_DOOR"], ["A108_DOOR", "A108_FRONT"],
		["A108_FRONT", "A108_AISLE_N"], ["A108_AISLE_N", "A108_AISLE_N_BACK"],
		["A108_FRONT", "A108_AISLE_S"], ["A108_AISLE_S", "A108_AISLE_S_BACK"],
		["A108_AISLE_N_BACK", "A108_BACK_MID"], ["A108_BACK_MID", "A108_AISLE_S_BACK"],
		["A108_AISLE_N", "A108_ROW_MID"], ["A108_ROW_MID", "A108_AISLE_S"],
		# Aula 102
		["N_0", "A102_DOOR"], ["A102_DOOR", "A102_IN"],
		# Cafetería PB
		["E_3", "CAFE_DOOR"], ["CAFE_DOOR", "CAFE_FRONT"],
		["CAFE_FRONT", "CAFE_NORTH"], ["CAFE_FRONT", "CAFE_SOUTH"], ["CAFE_FRONT", "CAFE_BACK"],
		# Fotocopiadora
		["S_2", "FOTO_DOOR"], ["FOTO_DOOR", "FOTO_IN"],
		# Lab Central de Electrónica (Entrada y salida por puerta oeste real en Z = 0.5)
		["W_LAB", "LAB_DOOR_OUT"], ["LAB_DOOR_OUT", "LAB_DOOR"], ["LAB_DOOR", "LAB_DOOR_IN"],
		["LAB_DOOR_IN", "LAB_W_01"], ["LAB_DOOR_IN", "LAB_W_12"],
		["LAB_W_01", "LAB_W_N"], ["LAB_W_12", "LAB_W_S"],
		["LAB_W_N", "LAB_MID_N"], ["LAB_MID_N", "LAB_E_N"],
		["LAB_W_01", "LAB_MID_01"], ["LAB_MID_01", "LAB_E_01"],
		["LAB_W_12", "LAB_MID_12"], ["LAB_MID_12", "LAB_E_12"],
		["LAB_W_S", "LAB_MID_S"], ["LAB_MID_S", "LAB_E_S"],
		["LAB_E_N", "LAB_E_01"], ["LAB_E_01", "LAB_E_PANEL"], ["LAB_E_PANEL", "LAB_E_12"], ["LAB_E_12", "LAB_E_S"],
		# Auditorio Principal (Conexiones fluidas por pasillos)
		["S_4", "AUD_DOOR"], ["AUD_DOOR", "AUD_BACK_C"],
		["AUD_BACK_W", "AUD_BACK_C"], ["AUD_BACK_C", "AUD_BACK_E"],
		# Pasillo Central
		["AUD_BACK_C", "AUD_C_1"], ["AUD_C_1", "AUD_C_2"], ["AUD_C_2", "AUD_C_3"],
		["AUD_C_3", "AUD_C_MID"], ["AUD_C_MID", "AUD_C_4"], ["AUD_C_4", "AUD_C_5"],
		["AUD_C_5", "AUD_C_STAGE"],
		# Pasillo Lateral Oeste
		["AUD_BACK_W", "AUD_W_1"], ["AUD_W_1", "AUD_W_2"], ["AUD_W_2", "AUD_W_MID"],
		["AUD_W_MID", "AUD_W_3"], ["AUD_W_3", "AUD_W_STAGE"],
		# Pasillo Lateral Este
		["AUD_BACK_E", "AUD_E_1"], ["AUD_E_1", "AUD_E_2"], ["AUD_E_2", "AUD_E_MID"],
		["AUD_E_MID", "AUD_E_3"], ["AUD_E_3", "AUD_E_STAGE"],
		# Cruce medio (Z = 59.0 entre filas 4 y 5)
		["AUD_W_MID", "AUD_C_MID"], ["AUD_C_MID", "AUD_E_MID"],
		# Cruce frente a escenario (Z = 72.5)
		["AUD_W_STAGE", "AUD_C_STAGE"], ["AUD_C_STAGE", "AUD_E_STAGE"],
		# Acceso y plataforma de Escenario
		["AUD_C_STAGE", "AUD_STAGE_FRONT"],
		["AUD_STAGE_FRONT", "AUD_STAGE_RAMP_L"], ["AUD_STAGE_FRONT", "AUD_STAGE_RAMP_R"],
		["AUD_STAGE_RAMP_L", "AUD_STAGE_TITLE"], ["AUD_STAGE_RAMP_R", "AUD_STAGE_TITLE"],
		["AUD_STAGE_TITLE", "AUD_STAGE_BACK"]
	]
	
	for conn in connections:
		var id_a = name_to_id[conn[0]]
		var id_b = name_to_id[conn[1]]
		astar_pb.connect_points(id_a, id_b, true)

func _get_astar_path_to(destination_pos: Vector3, heading: Vector3 = Vector3.ZERO) -> PackedVector3Array:
	var dest_y0 = Vector3(destination_pos.x, 0.2, destination_pos.z)
	var my_y0 = Vector3(global_position.x, 0.2, global_position.z)
	
	# Si la línea recta hacia el destino está totalmente libre y a corta distancia, ir directo:
	if _is_walk_path_clear(global_position, dest_y0) and global_position.distance_to(dest_y0) < 6.0:
		var direct = PackedVector3Array()
		direct.append(dest_y0)
		return direct
		
	var from_id = _find_best_graph_node(my_y0, heading)
	var to_id = _find_best_graph_node(dest_y0)
	
	if from_id == -1 or to_id == -1:
		from_id = astar_pb.get_closest_point(my_y0)
		to_id = astar_pb.get_closest_point(dest_y0)
		
	var node_path = astar_pb.get_point_path(from_id, to_id)
	var result = PackedVector3Array()
	
	for pt in node_path:
		result.append(pt)
		
	# Agregar la posición final precisa al final de la ruta
	result.append(dest_y0)
	return result

func _find_best_graph_node(pos: Vector3, heading: Vector3 = Vector3.ZERO) -> int:
	var point_ids = astar_pb.get_point_ids()
	var best_id = -1
	var best_score = 99999.0
	
	for pid in point_ids:
		var pt = astar_pb.get_point_position(pid)
		var d = pos.distance_to(pt)
		if _is_walk_path_clear(pos, pt):
			var score = d
			# Si tenemos dirección de avance actual, favorecer nodos hacia adelante
			if heading.length_squared() > 0.01:
				var to_pt = (pt - pos).normalized()
				var dot = heading.dot(to_pt)
				if dot < 0.0:
					score += 2.5 # Penalizar puntos que exigen darse vuelta hacia atrás
			if score < best_score:
				best_score = score
				best_id = pid
				
	if best_id != -1:
		return best_id
		
	return astar_pb.get_closest_point(pos)

func _pick_closest_patrol_circuit_idx() -> void:
	var best_idx = 0
	var best_d = 99999.0
	for i in range(PATROL_CIRCUIT_PB.size()):
		var d = global_position.distance_to(PATROL_CIRCUIT_PB[i])
		if d < best_d:
			best_d = d
			best_idx = i
	current_circuit_idx = best_idx

func _navigate_to_circuit_idx(idx: int) -> void:
	current_circuit_idx = idx % PATROL_CIRCUIT_PB.size()
	var target = PATROL_CIRCUIT_PB[current_circuit_idx]
	current_path = _get_astar_path_to(target)
	current_path_idx = 0

## =====================================================================
## BUCLE PRINCIPAL DE FÍSICA Y ESTADOS
## =====================================================================
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

	# Registrar si el profesor vio explícitamente al jugador entrar a un escondite
	var is_hidden_now = player.get("is_hidden") if is_instance_valid(player) else false
	if is_hidden_now and not prev_player_hidden:
		var has_los = _has_line_of_sight(global_position + Vector3(0, 1.5, 0), player.global_position + Vector3(0, 1.2, 0))
		saw_player_hide = has_los and (current_state == State.CHASE)
	elif not is_hidden_now:
		saw_player_hide = false
		is_trash_rushing = false
	prev_player_hidden = is_hidden_now

	# Restricción absoluta a Planta Baja
	if ONLY_PATROL_PB and global_position.y > 2.0:
		global_position.y = 0.2
		velocity.y = 0.0

	if not is_on_floor():
		velocity.y -= gravity * delta

	if global_position.y < -0.8:
		global_position.y = 0.05
		velocity.y = 0.0

	if attack_timer > 0.0:
		attack_timer -= delta

	if trash_suspicion_cooldown > 0.0:
		trash_suspicion_cooldown -= delta

	if is_inspecting_trash_suspense:
		_process_trash_suspense(delta)
		_update_dialogue(delta)
		return

	if is_screamer_ambush:
		velocity = Vector3.ZERO
		move_and_slide()
		_update_dialogue(delta)
		return

	if is_hallway_dashing:
		_process_hallway_dash(delta)
		_update_dialogue(delta)
		return

	# Comprobar visión hacia el jugador
	var can_see = _can_see_player()

	# Transición inmediata si ve al jugador mientras patrulla o busca
	if can_see and current_state != State.CHASE and current_state != State.ATTACK:
		_enter_chase_state()

	match current_state:
		State.PATROL:
			_process_patrol_state(delta, can_see)
		State.SEARCH:
			_process_search_state(delta, can_see)
		State.CHASE:
			_process_chase_state(delta, can_see)
		State.ATTACK:
			_process_attack_state(delta)

	_update_dialogue(delta)

## =====================================================================
## DETECCIÓN Y VISIÓN
## =====================================================================
func _can_see_player() -> bool:
	if not is_instance_valid(player) or player.get("is_hidden"):
		return false
	if ONLY_PATROL_PB and get_floor(player.global_position.y) != 0:
		return false
	
	var eye_pos = global_position + Vector3(0, 1.5, 0)
	var player_eye = player.global_position + Vector3(0, 1.3, 0)
	var player_chest = player.global_position + Vector3(0, 0.75, 0)
	var player_waist = player.global_position + Vector3(0, 0.45, 0)
	var to_player = player_eye - eye_pos
	var dist = to_player.length()

	var current_vision_range = vision_range
	if current_state == State.CHASE:
		current_vision_range = maxf(current_vision_range, 38.0)
		
	var flashlight = player.find_child("Flashlight", true, false) as SpotLight3D
	if flashlight and flashlight.visible:
		current_vision_range *= 1.45

	# Proximidad inmediata (percepción 360° en distancias cortas por pasos/ruido/presencia)
	if dist <= proximity_range:
		return _has_line_of_sight(eye_pos, player_eye) or _has_line_of_sight(eye_pos, player_chest) or _has_line_of_sight(eye_pos, player_waist)

	if dist > current_vision_range:
		return false

	# Cono de visión horizontal con visión periférica amplia (190° en patrulla, 220° en persecución activa)
	var effective_angle_deg = vision_angle_deg
	if current_state == State.CHASE:
		effective_angle_deg = maxf(effective_angle_deg, 220.0)

	var forward_h = Vector2(transform.basis.z.x, transform.basis.z.z).normalized()
	var dir_to_player_h = Vector2(to_player.x, to_player.z).normalized()
	if forward_h.length() > 0.1 and dir_to_player_h.length() > 0.1:
		var angle_deg = rad_to_deg(absf(forward_h.angle_to(dir_to_player_h)))
		if angle_deg > effective_angle_deg * 0.5:
			return false

	if absf(to_player.y) > 3.8:
		return false

	return _has_line_of_sight(eye_pos, player_eye) or _has_line_of_sight(eye_pos, player_chest) or _has_line_of_sight(eye_pos, player_waist)

func _has_line_of_sight(from_pos: Vector3, to_pos: Vector3) -> bool:
	if not is_inside_tree() or not get_world_3d():
		return false
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return false
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return true
	if result.collider == player or (result.collider is Node and player.is_ancestor_of(result.collider)):
		return true
	return false

## =====================================================================
## ESTADO: PATROL (Patrullaje Metódico por Pasillos y Aulas)
## =====================================================================
func _process_patrol_state(delta: float, can_see_player: bool) -> void:
	current_speed = patrol_speed
	aula_inspect_cooldown = max(0.0, aula_inspect_cooldown - delta)

	# Si no tiene ruta o terminó la actual, avanzar al siguiente punto del circuito
	# Si el jugador está en un tacho cercano durante la ronda, oportunidad de susto de impacto
	if is_instance_valid(player) and player.get("is_hidden") and not saw_player_hide and trash_suspicion_cooldown <= 0.0:
		var d_tacho = global_position.distance_to(player.global_position)
		if d_tacho <= 7.5:
			_trigger_trash_suspense()
			return

	if current_path.is_empty() or current_path_idx >= current_path.size():
		# Oportunidad de inspección de un aula si está cerca de una
		if aula_inspect_cooldown <= 0.0 and randf() < 0.40:
			for aula in AULAS_PB_DATA:
				if global_position.distance_to(aula["corridor_wp"]) < 4.0:
					_start_aula_inspection(aula)
					return

		current_circuit_idx = (current_circuit_idx + 1) % PATROL_CIRCUIT_PB.size()
		_navigate_to_circuit_idx(current_circuit_idx)
		if current_path.is_empty():
			return

	var next_wp = current_path[current_path_idx]
	var dist_wp = global_position.distance_to(next_wp)

	if dist_wp < 1.3:
		current_path_idx += 1
		if current_path_idx >= current_path.size():
			return
		next_wp = current_path[current_path_idx]

	_move_towards(delta, next_wp, current_speed, 4.5)

func _start_aula_inspection(aula: Dictionary) -> void:
	aula_inspect_cooldown = randf_range(25.0, 40.0)
	_enter_search_state(aula["inside_pos"], "aula_inspect")
	if cartel_dialogo:
		var phrases_inspect = [
			"A ver si hay alguien copiándose acá adentro...",
			"Silencio sospechoso en esta aula...",
			"Mmm... me pareció ver una sombra entre los pupitres...",
			"Nadie debería estar en esta aula a oscuras..."
		]
		_say(phrases_inspect[randi() % phrases_inspect.size()], Color(1.0, 0.85, 0.4))

## =====================================================================
## ESTADO: SEARCH / SEEK (Investigación de Ruido o Pérdida de Rastro)
## =====================================================================
func _enter_search_state(target_pos: Vector3, reason: String = "general") -> void:
	current_state = State.SEARCH
	search_target_pos = target_pos
	search_timer = 3.8
	is_searching_around = false
	current_speed = seek_speed
	current_path = _get_astar_path_to(search_target_pos)
	current_path_idx = 0
	
	if ojos_luz:
		if is_enraged_final:
			ojos_luz.light_color = Color(1.0, 0.05, 0.05)
			ojos_luz.light_energy = 2.4
		else:
			ojos_luz.light_color = Color(1.0, 0.65, 0.1)
			ojos_luz.light_energy = 1.0
	if aura_luz:
		aura_luz.light_color = Color(1.0, 0.05, 0.05) if is_enraged_final else Color(1.0, 0.35, 0.12)
		aura_luz.light_energy = 0.85 if is_enraged_final else 0.55
		
	if reason == "noise_trash":
		_say("¡¡¿QUÉ ES ESE RUIDO DENTRO DEL TACHO?!!", Color(1.0, 0.1, 0.1))
	elif reason == "noise":
		_say("¿Quién hace ruido en mi hora...?", Color(1.0, 0.8, 0.4))
	elif reason == "lost_sight":
		_say("¿Dónde se escondió ese alumno...?", Color(1.0, 0.8, 0.4))

func _process_search_state(delta: float, can_see_player: bool) -> void:
	if can_see_player:
		_enter_chase_state()
		return

	# Si el jugador está escondido en un tacho en esta zona:
	if is_instance_valid(player) and player.get("is_hidden"):
		var d_player = global_position.distance_to(player.global_position)
		if saw_player_hide and d_player <= attack_range + 0.8:
			_say("¡¡TE ESCUCHÉ AHÍ ADENTRO! ¡SALÍ DE ESE TACHO!!", Color(1.0, 0.1, 0.1))
			if player.get("current_hiding_spot") and player.current_hiding_spot.has_method("force_eject"):
				player.current_hiding_spot.force_eject()
			_start_attack()
			return
		elif not saw_player_hide and d_player <= 3.2 and is_searching_around:
			if trash_suspicion_cooldown <= 0.0:
				_trigger_trash_suspense()
				return
			_say("¿Dónde se metió este alumno? Parecía haber alguien acá...", Color(1.0, 0.85, 0.5))

	# Si ya llegó al lugar a investigar: detenerse y registrar alrededor
	if is_searching_around:
		search_timer -= delta
		rotation.y += sin(search_timer * 2.8) * delta * 2.2
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		move_and_slide()
		_animate_walk(delta, false)

		if search_timer <= 0.0:
			# Fin de búsqueda: retomar patrulla
			_enter_patrol_state()
		return

	# Avanzar hacia el destino de búsqueda por la ruta AStar
	var dist_target = global_position.distance_to(search_target_pos)
	if dist_target < 1.8 or current_path_idx >= current_path.size():
		is_searching_around = true
		return

	var next_wp = current_path[current_path_idx]
	if global_position.distance_to(next_wp) < 1.3:
		current_path_idx += 1
		if current_path_idx >= current_path.size():
			is_searching_around = true
			return
		next_wp = current_path[current_path_idx]

	_move_towards(delta, next_wp, current_speed, 5.5)

func _enter_patrol_state() -> void:
	current_state = State.PATROL
	current_speed = patrol_speed
	is_searching_around = false
	
	if ojos_luz:
		if is_enraged_final:
			ojos_luz.light_color = Color(1.0, 0.05, 0.05)
			ojos_luz.light_energy = 2.4
			ojos_luz.spot_range = 14.0
		else:
			ojos_luz.light_color = Color(1.0, 0.85, 0.5)
			ojos_luz.light_energy = 0.8
			ojos_luz.spot_range = 9.5
	if aura_luz:
		aura_luz.light_color = Color(1.0, 0.05, 0.05) if is_enraged_final else Color(1.0, 0.35, 0.12)
		aura_luz.light_energy = 0.85 if is_enraged_final else 0.55
		
	_say("Debió ser el viento... Volvamos a la ronda.")
	_pick_closest_patrol_circuit_idx()
	_navigate_to_circuit_idx(current_circuit_idx)

## =====================================================================
## ESTADO: CHASE / HUNT (Persecución Implacable del Jugador)
## =====================================================================
func _enter_chase_state() -> void:
	current_state = State.CHASE
	time_without_sight = 0.0
	is_searching_around = false
	last_known_player_pos = player.global_position if is_instance_valid(player) else global_position
	
	current_path = _get_astar_path_to(last_known_player_pos)
	current_path_idx = 0
	repath_timer = 0.25
	
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.05, 0.05)
		ojos_luz.light_energy = 2.5
	if aura_luz:
		aura_luz.light_color = Color(1.0, 0.05, 0.05)
		aura_luz.light_energy = 0.85
		
	_say(phrases_chase[randi() % phrases_chase.size()], Color(1.0, 0.2, 0.2))
	
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_chase_screamer_time > 15.0:
		last_chase_screamer_time = now
		if is_instance_valid(player) and player.has_method("play_jumpscare_screamer"):
			player.play_jumpscare_screamer()
	if is_instance_valid(player) and player.has_method("start_chase_violins"):
		player.start_chase_violins(35.0)

func _process_chase_state(delta: float, can_see_player: bool) -> void:
	if is_screamer_ambush:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if is_screamer_charging:
		screamer_charge_timer -= delta
		current_speed = 42.0
		if screamer_charge_timer <= 0.0:
			_end_screamer_charge()
	elif is_trash_rushing:
		current_speed = 5.5
	else:
		current_speed = chase_speed

	var to_player = player.global_position - global_position
	var dist_to_player = to_player.length()

	if is_screamer_charging and dist_to_player <= attack_range + 0.6:
		_end_screamer_charge()

	# Si el profesor está en PB y el jugador huyó por la escalera a P1/P2:
	if ONLY_PATROL_PB and not is_devour_rage:
		var p_floor = get_floor(player.global_position.y)
		var p_in_stairs = get_stair_tower_name(player.global_position) != ""
		if p_floor > 0 or p_in_stairs:
			_say("¡¡Cobarde, escapaste arriba... pero vas a tener que bajar!!", Color(1.0, 0.2, 0.2))
			_enter_patrol_state()
			return

	if can_see_player:
		last_known_player_pos = player.global_position
		time_without_sight = 0.0
	elif is_trash_rushing:
		time_without_sight = 0.0
		last_known_player_pos = player.global_position
	elif is_devour_rage:
		time_without_sight = 0.0
		if is_instance_valid(player):
			last_known_player_pos = player.global_position
	else:
		time_without_sight += delta
		if time_without_sight >= lost_sight_timeout:
			_enter_search_state(last_known_player_pos, "lost_sight")
			return

	# Si el jugador está escondido en un tacho
	if player.get("is_hidden"):
		if saw_player_hide:
			if dist_to_player <= attack_range + 0.9:
				is_trash_rushing = false
				_say("¡¡TE ESCUCHÉ AHÍ ADENTRO! ¡SALÍ DE ESE TACHO!!", Color(1.0, 0.1, 0.1))
				if player.get("current_hiding_spot") and player.current_hiding_spot.has_method("force_eject"):
					player.current_hiding_spot.force_eject()
				_start_attack()
				return
		else:
			if dist_to_player <= 3.2:
				_enter_search_state(last_known_player_pos, "lost_sight")
				return

	# Ataque cuerpo a cuerpo real (con alcance de estocada con la regla de madera: 1.85m)
	# Permite golpear por encima de mesas o pupitres si el jugador intenta campear pegado al mueble
	var vert_diff = absf(to_player.y)
	if not player.get("is_hidden") and dist_to_player <= attack_range + 0.25 and vert_diff <= 0.85 and attack_timer <= 0.0:
		if _has_line_of_sight(global_position + Vector3(0, 1.4, 0), player.global_position + Vector3(0, 1.2, 0)):
			_start_attack()
			return

	loop_commit_timer = max(0.0, loop_commit_timer - delta)

	# Persecución en línea recta si tiene camino despejado y lo ve (o sprint directo hacia el tacho si está despejado)
	var can_rush_direct = (can_see_player or is_trash_rushing) and _is_walk_path_clear(global_position, player.global_position)
	if can_rush_direct:
		loop_commit_timer = 0.0
		var rot_spd = 35.0 if (is_screamer_charging or is_trash_rushing) else 15.0
		_move_towards(delta, player.global_position, current_speed, rot_spd)
		return

	# Si hay un obstáculo intermedio (looping): recalcular ruta AStar con compromiso direccional
	repath_timer -= delta
	if repath_timer <= 0.0 or current_path.is_empty():
		repath_timer = 0.35
		var heading = Vector3(velocity.x, 0.0, velocity.z).normalized() if velocity.length() > 0.4 else Vector3.ZERO
		var new_path = _get_astar_path_to(last_known_player_pos, heading)
		
		# Determinar índice inicial inteligente (no retroceder a puntos ya pasados)
		var start_idx = 0
		while start_idx < new_path.size() - 1:
			var to_wp = new_path[start_idx] - global_position
			to_wp.y = 0.0
			if to_wp.length() < 1.1 or (heading.length_squared() > 0.01 and to_wp.dot(heading) < 0.0):
				start_idx += 1
			else:
				break
				
		# Comprobar compromiso direccional (Anti-Looping Hysteresis)
		if current_path.size() > 0 and current_path_idx < current_path.size() and start_idx < new_path.size():
			var cur_dest = current_path[current_path_idx] - global_position
			cur_dest.y = 0.0
			var new_dest = new_path[start_idx] - global_position
			new_dest.y = 0.0
			
			if cur_dest.length() > 0.2 and new_dest.length() > 0.2:
				var cur_heading = cur_dest.normalized()
				var new_heading = new_dest.normalized()
				
				# ¿La nueva ruta exige un giro en U de 180° hacia atrás?
				var is_u_turn = cur_heading.dot(new_heading) < -0.3
				if is_u_turn and loop_commit_timer > 0.0:
					# RECHAZAR EL GIRO EN U: Mantener la ruta actual para rodear la estructura sin zigzaguear
					pass
				else:
					current_path = new_path
					current_path_idx = start_idx
					loop_commit_timer = 1.6
		else:
			current_path = new_path
			current_path_idx = start_idx
			loop_commit_timer = 1.6

	if current_path_idx < current_path.size():
		var next_wp = current_path[current_path_idx]
		if global_position.distance_to(next_wp) < 1.3:
			current_path_idx += 1
			if current_path_idx < current_path.size():
				next_wp = current_path[current_path_idx]
		var rot_spd = 35.0 if is_screamer_charging else 8.0
		_move_towards(delta, next_wp, current_speed, rot_spd)
	else:
		# Llegó a last_known_player_pos y no ve al jugador -> investigar
		_enter_search_state(last_known_player_pos, "lost_sight")

## =====================================================================
## ESTADO: ATTACK
## =====================================================================
func _start_attack() -> void:
	_cut_screamer_audio()
	if is_screamer_charging:
		_end_screamer_charge()
	current_state = State.ATTACK
	is_attacking = true
	attack_anim_time = 0.0
	attack_timer = attack_cooldown
	_say("¡¡¡CASTIGO POR COPIARSE!!!", Color(1.0, 0.1, 0.1))

func _process_attack_state(delta: float) -> void:
	_process_attack(delta)
	velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
	move_and_slide()

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
		if codo_der: codo_der.rotation.x = lerpf(deg_to_rad(20.0), deg_to_rad(55.0), p)
		if torso: torso.rotation.x = lerpf(deg_to_rad(14.0), deg_to_rad(-5.0), p)
		regla.rotation.x = lerpf(0.0, deg_to_rad(-45.0), p)
	elif attack_anim_time < 0.38:
		var p = (attack_anim_time - 0.22) / 0.16
		brazo_der.rotation.x = lerpf(deg_to_rad(-125.0), deg_to_rad(45.0), p)
		if codo_der: codo_der.rotation.x = lerpf(deg_to_rad(55.0), deg_to_rad(15.0), p)
		if torso: torso.rotation.x = lerpf(deg_to_rad(-5.0), deg_to_rad(26.0), p)
		regla.rotation.x = lerpf(deg_to_rad(-45.0), deg_to_rad(70.0), p)
		
		if p > 0.6 and is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist <= attack_range + 0.6:
				_hit_player()
	elif attack_anim_time < 0.65:
		var p = (attack_anim_time - 0.38) / 0.27
		brazo_der.rotation.x = lerpf(deg_to_rad(45.0), deg_to_rad(-40.0), p)
		brazo_der.rotation.y = lerpf(deg_to_rad(-20.0), 0.0, p)
		if codo_der: codo_der.rotation.x = lerpf(deg_to_rad(15.0), deg_to_rad(25.0), p)
		if torso: torso.rotation.x = lerpf(deg_to_rad(26.0), deg_to_rad(14.0), p)
		regla.rotation.x = lerpf(deg_to_rad(70.0), 0.0, p)
	else:
		is_attacking = false
		current_state = State.CHASE

func _hit_player() -> void:
	_cut_screamer_audio()
	if is_instance_valid(player) and player.has_method("start_chase_violins"):
		player.start_chase_violins(45.0)
	if is_instance_valid(player):
		var push_dir = (player.global_position - global_position).normalized()
		player.velocity += push_dir * 9.0 + Vector3(0, 3.2, 0)
		
		var cam = player.find_child("Camera3D", true, false) as Camera3D
		if cam:
			var tw = create_tween()
			tw.tween_property(cam, "rotation:z", deg_to_rad(randf_range(-14.0, 14.0)), 0.05)
			tw.tween_property(cam, "rotation:z", 0.0, 0.18)

## =====================================================================
## MOVIMIENTO Y ESQUIVA CON BIGOTES (WHISKERS)
## =====================================================================
func _is_walk_path_clear(from_pos: Vector3, to_pos: Vector3) -> bool:
	if not is_inside_tree() or not get_world_3d():
		return true
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return true
	var fwd = to_pos - from_pos
	fwd.y = 0.0
	if fwd.length_squared() < 0.01:
		return true
	var dir = fwd.normalized()
	var side = Vector3(-dir.z, 0.0, dir.x) * 0.32
	
	var excl: Array[RID] = [get_rid()]
	if is_instance_valid(player):
		excl.append(player.get_rid())

	# Comprobar a dos alturas críticas:
	# 0.35m: Altura baja (mesadas de laboratorio, pupitres de aula, bancos, sillas)
	# 0.85m: Altura media (mesadas altas, dinteles bajos, medias paredes)
	for h in [0.35, 0.85]:
		var offset = Vector3(0, h, 0)
		var q_mid = PhysicsRayQueryParameters3D.create(from_pos + offset, to_pos + offset)
		q_mid.exclude = excl
		if not space_state.intersect_ray(q_mid).is_empty():
			return false

		var q_left = PhysicsRayQueryParameters3D.create(from_pos + side + offset, to_pos + side + offset)
		q_left.exclude = excl
		if not space_state.intersect_ray(q_left).is_empty():
			return false

		var q_right = PhysicsRayQueryParameters3D.create(from_pos - side + offset, to_pos - side + offset)
		q_right.exclude = excl
		if not space_state.intersect_ray(q_right).is_empty():
			return false

	return true

func _get_steered_dir(desired_dir: Vector3) -> Vector3:
	if not is_inside_tree() or not get_world_3d():
		return desired_dir
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return desired_dir
	# Proyectar bigotes a la altura baja (0.40m) para detectar bordes de mesadas y pupitres
	var eye_pos_low = global_position + Vector3(0, 0.40, 0)
	var forward = Vector3(desired_dir.x, 0.0, desired_dir.z).normalized()
	if forward.length_squared() < 0.01:
		return desired_dir
		
	var right = Vector3(-forward.z, 0.0, forward.x)
	var whisker_dist = 0.95
	
	var left_dir = (forward - right * 0.45).normalized()
	var right_dir = (forward + right * 0.45).normalized()
	
	var excl: Array[RID] = [get_rid()]
	if is_instance_valid(player):
		excl.append(player.get_rid())
		
	var q_left = PhysicsRayQueryParameters3D.create(eye_pos_low, eye_pos_low + left_dir * whisker_dist)
	q_left.exclude = excl
	var hit_left = not space_state.intersect_ray(q_left).is_empty()
	
	var q_right = PhysicsRayQueryParameters3D.create(eye_pos_low, eye_pos_low + right_dir * whisker_dist)
	q_right.exclude = excl
	var hit_right = not space_state.intersect_ray(q_right).is_empty()
	
	# Si ambos lados tocan un obstáculo frontal plano (cara del pupitre/mesada), no oscilar
	if hit_left and hit_right:
		return forward
		
	var steered = forward
	if hit_left and not hit_right:
		steered = (forward + right * 0.6).normalized()
	elif hit_right and not hit_left:
		steered = (forward - right * 0.6).normalized()
		
	return steered

func _move_towards(delta: float, target_pos: Vector3, speed_to_use: float, rot_speed: float) -> void:
	var to_tgt = target_pos - global_position
	to_tgt.y = 0.0
	
	var move_vec = Vector3.ZERO
	if to_tgt.length() > 0.05:
		var raw_dir = to_tgt.normalized()
		move_vec = _get_steered_dir(raw_dir)
		
		var target_rot_y = atan2(move_vec.x, move_vec.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, rot_speed * delta)
		
		var accel = 35.0 if is_screamer_charging else 12.0
		velocity.x = lerpf(velocity.x, move_vec.x * speed_to_use, delta * accel)
		velocity.z = lerpf(velocity.z, move_vec.z * speed_to_use, delta * accel)
	else:
		velocity.x = lerpf(velocity.x, 0.0, delta * 12.0)
		velocity.z = lerpf(velocity.z, 0.0, delta * 12.0)

	var pre_pos := global_position
	var was_on_floor := is_on_floor()
	move_and_slide()

	# Deslizamiento inteligente al colisionar contra paredes, pupitres o mesadas
	if was_on_floor and is_on_wall() and move_vec != Vector3.ZERO:
		var wall_norm = get_wall_normal()
		if move_vec.dot(wall_norm) < -0.05:
			var slide_vec = move_vec.slide(wall_norm).normalized()
			if slide_vec.length_squared() > 0.01:
				velocity.x = slide_vec.x * speed_to_use
				velocity.z = slide_vec.z * speed_to_use
				move_and_slide()
				var target_rot_y = atan2(slide_vec.x, slide_vec.z)
				rotation.y = lerp_angle(rotation.y, target_rot_y, rot_speed * delta)

	# Step-up suave si toca bordes bajos o asientos del auditorio (asientos miden 0.42m)
	if was_on_floor and is_on_wall() and move_vec != Vector3.ZERO:
		var step_h: float = 0.52
		var step_transform: Transform3D = global_transform
		step_transform.origin.y += step_h
		if not test_move(global_transform, Vector3(0, step_h, 0)):
			var fwd: Vector3 = move_vec * (speed_to_use * delta + 0.08)
			if not test_move(step_transform, fwd):
				global_position = pre_pos + Vector3(0, step_h * 0.45, 0)
				move_and_slide()

	# Watchdog antitraba: SIN TELETRANSPORTE FANTASMA
	pos_sample_timer += delta
	if pos_sample_timer >= 0.3:
		pos_sample_timer = 0.0
		var moved_dist = global_position.distance_to(prev_pos)
		prev_pos = global_position

		if moved_dist < 0.08 and speed_to_use > 0.5:
			stuck_timer += 0.3
		else:
			stuck_timer = max(0.0, stuck_timer - 0.3)

	# Si queda atascado más de 1.8 segundos:
	if stuck_timer >= 1.8:
		stuck_timer = 0.0
		if current_state == State.PATROL:
			# Saltar al siguiente punto del circuito y recalcular ruta AStar
			current_circuit_idx = (current_circuit_idx + 1) % PATROL_CIRCUIT_PB.size()
			_navigate_to_circuit_idx(current_circuit_idx)
		elif current_state == State.SEARCH:
			# Si se trabó buscando en un aula/rincón, terminar la búsqueda y retomar patrulla
			_enter_patrol_state()
		elif current_state == State.CHASE:
			# En persecución: solo dar un leve empuje lateral para despegarse del marco
			if is_screamer_charging:
				_end_screamer_charge()
			velocity = Vector3.ZERO
			var unstick_offset = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized() * 0.35
			global_position += unstick_offset
			prev_pos = global_position
			repath_timer = 0.0
			if not _can_see_player():
				_enter_search_state(last_known_player_pos, "lost_sight")

	_animate_walk(delta, move_vec.length() > 0.1)

## =====================================================================
## EVENTOS ESPECIALES Y REACCIONES
## =====================================================================
func _on_player_noise(volume: float) -> void:
	if not is_active or not is_instance_valid(player):
		return
	if ONLY_PATROL_PB and get_floor(player.global_position.y) != 0:
		return
		
	var is_in_trash = player.get("is_hidden")
	# En el tacho de metal el ruido retumba por los pasillos; amplio rango en PB
	var effective_hearing_range = 85.0 if is_in_trash else 45.0
	var dist = global_position.distance_to(player.global_position)
	
	if dist <= effective_hearing_range:
		print(">>> Profesor escuchó ruido! Dist: %.1fm (max %.1fm), En Tacho: %s" % [dist, effective_hearing_range, is_in_trash])
		if is_in_trash:
			saw_player_hide = true
			is_trash_rushing = true
			last_known_player_pos = player.global_position
			current_state = State.CHASE
			current_speed = 5.5 # Sprint ultra-rápido ("casi instantáneo") hacia el tacho
			current_path = _get_astar_path_to(player.global_position)
			current_path_idx = 0
			repath_timer = 0.2
			_say("¡¡TE ESCUCHÉ EN ESE TACHO, NO TE VAS A ESCAPAR!!", Color(1.0, 0.1, 0.1))
			if ojos_luz:
				ojos_luz.light_color = Color(1.0, 0.0, 0.0)
				ojos_luz.light_energy = 2.5
				
			# Si ya está al lado del tacho, actuar de inmediato
			if dist <= attack_range + 0.9:
				is_trash_rushing = false
				_say("¡¡TE ESCUCHÉ AHÍ ADENTRO! ¡SALÍ DE ESE TACHO!!", Color(1.0, 0.1, 0.1))
				if player.get("current_hiding_spot") and player.current_hiding_spot.has_method("force_eject"):
					player.current_hiding_spot.force_eject()
				_start_attack()
				return
		else:
			if current_state == State.PATROL:
				_enter_search_state(player.global_position, "noise")
			elif current_state == State.SEARCH:
				search_target_pos = player.global_position
				current_path = _get_astar_path_to(search_target_pos)
				current_path_idx = 0
				is_searching_around = false
				search_timer = 3.5
			elif current_state == State.CHASE:
				last_known_player_pos = player.global_position
				current_path = _get_astar_path_to(last_known_player_pos)
				current_path_idx = 0

func boost_speed() -> void:
	speed_boost_count += 1
	base_patrol_speed = 2.45
	base_chase_speed = 3.4
	patrol_speed = 2.45
	chase_speed = 3.4
	seek_speed = 2.8
	vision_range = 34.0
	current_speed = patrol_speed
	
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
	step_audio.unit_size = 14.0
	step_audio.max_distance = 65.0
	step_audio.volume_db = 9.0
	step_audio.bus = &"Master"
	add_child(step_audio)
	
	slam_audio = AudioStreamPlayer3D.new()
	slam_audio.name = "ProfesorSlamAudio3D"
	slam_audio.unit_size = 4.5
	slam_audio.max_distance = 35.0
	slam_audio.volume_db = 7.0
	slam_audio.bus = &"Master"
	add_child(slam_audio)

func _play_prof_step() -> void:
	if not step_audio:
		return
	step_audio.stream = HorrorAudio.get_creepy_footstep()
	var pitch_target = 1.0
	if current_state == State.CHASE or is_trash_rushing or is_screamer_charging:
		pitch_target = randf_range(1.15, 1.25)
	else:
		pitch_target = randf_range(0.95, 1.05)
	step_audio.pitch_scale = pitch_target
	var target_vol = 14.5 if is_enraged_final else (13.0 if (current_state == State.CHASE or is_trash_rushing) else 9.0)
	step_audio.volume_db = target_vol
	step_audio.play()

func _animate_walk(delta: float, is_moving: bool) -> void:
	# Lean y postura de la columna (Spine pitch)
	var target_pitch: float = deg_to_rad(6.0)
	if current_state == State.CHASE or is_trash_rushing or is_screamer_charging:
		target_pitch = deg_to_rad(20.0) if is_devour_rage else (deg_to_rad(16.0) if is_enraged_final else deg_to_rad(14.0))
	
	if is_moving and is_on_floor():
		idle_anim_time = 0.0
		var step_mult = 3.6 if (is_trash_rushing or is_screamer_charging) else (2.85 if current_state == State.CHASE else 2.2)
		var anim_delta = delta * (current_speed * step_mult)
		var prev_sin = sin(walk_anim_time)
		walk_anim_time += anim_delta
		var curr_sin = sin(walk_anim_time)
		
		# Disparo sincronizado de pisada en el impacto de cada pierna contra el suelo
		if (prev_sin <= 0.0 and curr_sin > 0.0) or (prev_sin >= 0.0 and curr_sin < 0.0):
			_play_prof_step()
			
		var is_chasing = (current_state == State.CHASE or is_trash_rushing or is_screamer_charging)
		var leg_amp = deg_to_rad(36.0) if is_chasing else deg_to_rad(25.0)
		var knee_amp = deg_to_rad(48.0) if is_chasing else deg_to_rad(32.0)
		var arm_amp = deg_to_rad(32.0) if is_chasing else deg_to_rad(22.0)
		
		var swing_legs = sin(walk_anim_time) * leg_amp
		var swing_arms = cos(walk_anim_time) * arm_amp
		
		# 1. Articulación de Cadera y Muslos
		if pierna_izq: pierna_izq.rotation.x = swing_legs
		if pierna_der: pierna_der.rotation.x = -swing_legs
		
		# 2. Articulación de Rodillas (flexión natural hacia atrás al avanzar)
		if rodilla_izq:
			rodilla_izq.rotation.x = maxf(0.0, sin(walk_anim_time)) * knee_amp
		if rodilla_der:
			rodilla_der.rotation.x = maxf(0.0, -sin(walk_anim_time)) * knee_amp
			
		# 3. Articulación de Tobillos / Pies (dorsiflexión y flexión plantar)
		if tobillo_izq:
			tobillo_izq.rotation.x = -sin(walk_anim_time) * deg_to_rad(18.0)
		if tobillo_der:
			tobillo_der.rotation.x = sin(walk_anim_time) * deg_to_rad(18.0)
			
		# 4. Articulación de Torso y Columna: Inclinación hacia adelante + Balanceo lateral y Torsión
		if torso:
			torso.rotation.x = lerpf(torso.rotation.x, target_pitch, delta * 7.0)
			torso.rotation.z = -sin(walk_anim_time) * deg_to_rad(3.5) # Balanceo pélvico
			torso.rotation.y = sin(walk_anim_time) * deg_to_rad(4.5)  # Torsión espinal
			# Bobbing vertical sincronizado con cada paso (impacto de peso físico)
			var bob_val = absf(sin(walk_anim_time)) * 0.045
			torso.position.y = 1.15 - bob_val
		
		# 5. Articulación de Brazos, Codos y Muñecas
		if brazo_izq:
			brazo_izq.rotation.x = -swing_arms
			brazo_izq.rotation.z = deg_to_rad(4.0) + sin(walk_anim_time) * deg_to_rad(3.0)
		if codo_izq:
			codo_izq.rotation.x = deg_to_rad(20.0) + maxf(0.0, cos(walk_anim_time)) * deg_to_rad(24.0)
			codo_izq.rotation.y = deg_to_rad(8.0)
		if mano_izq:
			mano_izq.rotation.x = sin(walk_anim_time) * deg_to_rad(12.0)
			
		if not is_attacking and brazo_der:
			if is_chasing:
				# Postura amenazante de persecución con la regla en alto
				brazo_der.rotation.x = deg_to_rad(-55.0) + sin(walk_anim_time * 0.85) * deg_to_rad(18.0)
				brazo_der.rotation.y = deg_to_rad(-12.0)
				brazo_der.rotation.z = deg_to_rad(-14.0)
				if codo_der:
					codo_der.rotation.x = deg_to_rad(35.0) + cos(walk_anim_time) * deg_to_rad(14.0)
				if regla:
					regla.rotation.x = deg_to_rad(30.0) + sin(walk_anim_time * 1.4) * deg_to_rad(15.0)
			else:
				# Postura de patrulla: brazo derecho oscilando suave con la regla lista
				brazo_der.rotation.x = deg_to_rad(-30.0) + sin(walk_anim_time * 0.7) * deg_to_rad(10.0)
				brazo_der.rotation.y = deg_to_rad(-8.0)
				brazo_der.rotation.z = deg_to_rad(-8.0)
				if codo_der:
					codo_der.rotation.x = deg_to_rad(18.0)
				if regla:
					regla.rotation.x = deg_to_rad(15.0) + cos(walk_anim_time * 0.7) * deg_to_rad(8.0)
	else:
		walk_anim_time = 0.0
		idle_anim_time += delta
		if step_audio and step_audio.playing:
			step_audio.stop()
		step_phase = 1.0
		
		# Respiración orgánica del torso en reposo
		if torso:
			torso.rotation.x = lerpf(torso.rotation.x, target_pitch, delta * 5.0)
			torso.rotation.z = lerpf(torso.rotation.z, 0.0, delta * 5.0)
			torso.rotation.y = lerpf(torso.rotation.y, 0.0, delta * 5.0)
			torso.position.y = lerpf(torso.position.y, 1.15 + sin(idle_anim_time * 2.2) * 0.012, delta * 4.0)
			
		if pierna_izq: pierna_izq.rotation.x = lerpf(pierna_izq.rotation.x, 0.0, delta * 6.0)
		if pierna_der: pierna_der.rotation.x = lerpf(pierna_der.rotation.x, 0.0, delta * 6.0)
		if rodilla_izq: rodilla_izq.rotation.x = lerpf(rodilla_izq.rotation.x, 0.0, delta * 6.0)
		if rodilla_der: rodilla_der.rotation.x = lerpf(rodilla_der.rotation.x, 0.0, delta * 6.0)
		if tobillo_izq: tobillo_izq.rotation.x = lerpf(tobillo_izq.rotation.x, 0.0, delta * 6.0)
		if tobillo_der: tobillo_der.rotation.x = lerpf(tobillo_der.rotation.x, 0.0, delta * 6.0)
		if brazo_izq:
			brazo_izq.rotation.x = lerpf(brazo_izq.rotation.x, 0.0, delta * 6.0)
			brazo_izq.rotation.z = lerpf(brazo_izq.rotation.z, 0.0, delta * 6.0)
		if codo_izq:
			codo_izq.rotation.x = lerpf(codo_izq.rotation.x, deg_to_rad(18.0), delta * 6.0)
			codo_izq.rotation.y = lerpf(codo_izq.rotation.y, 0.0, delta * 6.0)
		if mano_izq: mano_izq.rotation.x = lerpf(mano_izq.rotation.x, 0.0, delta * 6.0)
		if not is_attacking and not is_screamer_ambush and brazo_der:
			brazo_der.rotation.x = lerpf(brazo_der.rotation.x, deg_to_rad(-40.0), delta * 5.0)
			brazo_der.rotation.y = lerpf(brazo_der.rotation.y, deg_to_rad(-8.0), delta * 5.0)
			brazo_der.rotation.z = lerpf(brazo_der.rotation.z, deg_to_rad(-10.0), delta * 5.0)
			if codo_der: codo_der.rotation.x = lerpf(codo_der.rotation.x, deg_to_rad(20.0), delta * 5.0)
			if regla: regla.rotation.x = lerpf(regla.rotation.x, deg_to_rad(15.0), delta * 5.0)

	# Animación procedimental de cabeza (balanceo de linterna + espasmos tenebrosos)
	if cabeza:
		var spine_compensation = -torso.rotation.x * 0.4 if torso else 0.0
		if current_state == State.CHASE:
			var jitter_val = 0.07 if is_devour_rage else (0.02 if is_enraged_final else 0.0)
			var jitter_x = randf_range(-jitter_val, jitter_val)
			var jitter_y = randf_range(-jitter_val, jitter_val)
			cabeza.rotation = Vector3(spine_compensation + jitter_x, jitter_y, 0.0)
		else:
			lantern_sway_timer += delta * (2.2 if current_state == State.SEARCH else 1.3)
			var sway_yaw = sin(lantern_sway_timer) * deg_to_rad(28.0)
			var sway_pitch = cos(lantern_sway_timer * 0.7) * deg_to_rad(6.0)
			twitch_timer -= delta
			if twitch_timer <= 0.0:
				twitch_timer = randf_range(5.0, 10.0)
				twitch_active_timer = randf_range(0.18, 0.35)
				twitch_offset = Vector3(
					deg_to_rad(randf_range(-14.0, 18.0)),
					deg_to_rad(randf_range(-38.0, 38.0)),
					deg_to_rad(randf_range(-16.0, 16.0))
				)
			if twitch_active_timer > 0.0:
				twitch_active_timer -= delta
				cabeza.rotation = twitch_offset
			else:
				cabeza.rotation = Vector3(spine_compensation + sway_pitch, sway_yaw, 0.0)

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

## =====================================================================
## SUSTO CINEMÁTICO: CORRIDA POR EL PASILLO (4TO EXAMEN)
## =====================================================================
func start_hallway_dash(start_pos: Vector3, end_pos: Vector3, on_finished: Callable = Callable()) -> void:
	set_active(true)
	visible = true
	is_screamer_ambush = false
	is_screamer_charging = false
	is_hallway_dashing = true
	hallway_dash_target = end_pos
	hallway_dash_callback = on_finished
	hallway_dash_speed = 18.5
	hallway_dash_timer = 0.0
	current_speed = 18.5
	attack_timer = 4.0
	is_attacking = false
	stuck_timer = 0.0
	time_without_sight = 0.0
	
	global_position = start_pos
	prev_pos = start_pos
	
	var to_tgt = end_pos - start_pos
	to_tgt.y = 0.0
	if to_tgt.length() > 0.1:
		rotation.y = atan2(to_tgt.x, to_tgt.z)
		
	if step_audio:
		step_audio.volume_db = 4.0
		
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.0, 0.0)
		ojos_luz.light_energy = 4.5
		ojos_luz.spot_range = 18.0
		ojos_luz.visible = true
		
	if brazo_der:
		brazo_der.rotation.x = deg_to_rad(-115.0)
		brazo_der.rotation.y = deg_to_rad(-10.0)
	if regla:
		regla.rotation.x = deg_to_rad(-40.0)

func _process_hallway_dash(delta: float) -> void:
	hallway_dash_timer += delta
	var to_dest = hallway_dash_target - global_position
	to_dest.y = 0.0
	var dist = to_dest.length()
	
	if dist < 1.6 or hallway_dash_timer >= 3.5:
		is_hallway_dashing = false
		velocity = Vector3.ZERO
		current_speed = patrol_speed
		current_state = State.PATROL
		if step_audio:
			step_audio.volume_db = 14.5 if is_enraged_final else 9.0
		if ojos_luz:
			if is_enraged_final:
				ojos_luz.light_color = Color(1.0, 0.05, 0.05)
				ojos_luz.light_energy = 2.4
				ojos_luz.spot_range = 14.0
			else:
				ojos_luz.light_color = Color(1.0, 0.85, 0.5)
				ojos_luz.light_energy = 0.8
				ojos_luz.spot_range = 10.0
		if aura_luz:
			aura_luz.light_color = Color(1.0, 0.05, 0.05) if is_enraged_final else Color(1.0, 0.35, 0.12)
			aura_luz.light_energy = 0.85 if is_enraged_final else 0.55
		if brazo_der:
			brazo_der.rotation = Vector3.ZERO
		if regla:
			regla.rotation = Vector3.ZERO
		_pick_closest_patrol_circuit_idx()
		_navigate_to_circuit_idx(current_circuit_idx)
		if hallway_dash_callback.is_valid():
			hallway_dash_callback.call()
		return
		
	var dir = to_dest.normalized()
	rotation.y = atan2(dir.x, dir.z)
	velocity.x = dir.x * hallway_dash_speed
	velocity.z = dir.z * hallway_dash_speed
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	var pre_pos = global_position
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	if was_on_floor and is_on_wall():
		var step_h: float = 0.25
		var step_transform: Transform3D = global_transform
		step_transform.origin.y += step_h
		if not test_move(global_transform, Vector3(0, step_h, 0)):
			var fwd: Vector3 = dir * (hallway_dash_speed * delta + 0.06)
			if not test_move(step_transform, fwd):
				global_position = pre_pos + Vector3(0, step_h * 0.5, 0)
				move_and_slide()

	_animate_walk(delta, true)

## =====================================================================
## CINEMÁTICA Y EMBOSCADA DEL LABORATORIO (TABLERO ELÉCTRICO)
## =====================================================================
func trigger_screamer_ambush(ambush_pos: Vector3, look_at_pos: Vector3) -> void:
	set_active(true)
	visible = true
	is_screamer_ambush = true
	global_position = ambush_pos
	prev_pos = ambush_pos
	velocity = Vector3.ZERO
	stuck_timer = 0.0
	attack_timer = 1.8
	is_attacking = false
	
	var to_target = look_at_pos - ambush_pos
	to_target.y = 0.0
	if to_target.length() > 0.1:
		rotation.y = atan2(to_target.x, to_target.z)
		
	if brazo_der:
		brazo_der.rotation.x = deg_to_rad(-125.0)
		brazo_der.rotation.y = deg_to_rad(-15.0)
		brazo_der.rotation.z = deg_to_rad(-10.0)
	if regla:
		regla.rotation.x = deg_to_rad(-45.0)
		
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.0, 0.0)
		ojos_luz.light_energy = 4.0
		ojos_luz.spot_range = 15.0
		ojos_luz.visible = true
		
	current_state = State.PATROL
	chase_speed = base_chase_speed + 1.1
	time_without_sight = 0.0
	if is_instance_valid(player):
		last_known_player_pos = player.global_position

func play_ruler_slam_animation() -> void:
	if not brazo_der or not regla:
		return
	var tw = create_tween()
	tw.tween_property(brazo_der, "rotation:x", deg_to_rad(35.0), 0.09)
	tw.parallel().tween_property(regla, "rotation:x", deg_to_rad(65.0), 0.09)
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
	if is_instance_valid(player) and player.has_method("start_chase_violins"):
		player.start_chase_violins(60.0, 5.0)
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
	if current_state == State.CHASE and not _can_see_player():
		_enter_search_state(last_known_player_pos, "lost_sight")


func activate_enraged_final_phase() -> void:
	is_enraged_final = true
	base_patrol_speed = 2.85
	base_chase_speed = 3.9
	patrol_speed = 2.85
	chase_speed = 3.9
	seek_speed = 3.3
	vision_range = 38.0
	vision_angle_deg = 200.0
	proximity_range = 6.5
	
	if current_state == State.PATROL or current_state == State.SEARCH:
		current_speed = patrol_speed
	elif current_state == State.CHASE:
		current_speed = chase_speed
		
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.05, 0.05)
		ojos_luz.light_energy = 2.5
		ojos_luz.spot_range = 14.0
	if aura_luz:
		aura_luz.light_color = Color(1.0, 0.05, 0.05)
		aura_luz.light_energy = 0.85
		aura_luz.omni_range = 5.2
	if step_audio:
		step_audio.volume_db = 14.5
		
	_say("¡¡SE TERMINÓ EL TIEMPO!! ¡NADIE SE VA DE ACÁ SIN ENTREGAR!!", Color(1.0, 0.0, 0.0))

func activate_devour_rage_mode(target_player: Node3D = null) -> void:
	set_active(true)
	is_devour_rage = true
	is_enraged_final = true
	is_screamer_ambush = false
	is_hallway_dashing = false
	is_inspecting_trash_suspense = false
	is_active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	
	if not is_inside_tree():
		return
	
	# Velocidades extremas estilo Devour / Pacify: el demonio se vuelve super rápido
	base_patrol_speed = 4.4
	patrol_speed = 4.4
	base_chase_speed = 6.95 # El jugador sprintea a 7.0: requiere huir a toda velocidad
	chase_speed = 6.95
	seek_speed = 5.8
	vision_range = 50.0
	vision_angle_deg = 270.0
	proximity_range = 12.0
	current_speed = chase_speed
	
	if target_player:
		player = target_player as CharacterBody3D
	elif not is_instance_valid(player):
		_find_player()
	
	# Spawn dramático en el umbral del Auditorio de cara al escenario y al jugador
	global_position = Vector3(0.0, 0.2, 36.5)
	rotation.y = deg_to_rad(0.0) # Mirando directamente al frente hacia el escenario
	velocity = Vector3.ZERO
	
	time_without_sight = 0.0
	repath_timer = 0.0
	current_state = State.CHASE
	
	if is_instance_valid(player):
		last_known_player_pos = player.global_position
		current_path = _get_astar_path_to(last_known_player_pos)
		current_path_idx = 0
		if player.has_method("start_chase_violins"):
			player.start_chase_violins(45.0)
	
	# Efectos lumínicos de furia total demoníaca
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.0, 0.0)
		ojos_luz.light_energy = 3.6
		ojos_luz.spot_range = 16.0
	if aura_luz:
		aura_luz.light_color = Color(1.0, 0.02, 0.02)
		aura_luz.light_energy = 1.4
		aura_luz.omni_range = 7.0
	if step_audio:
		step_audio.volume_db = 16.0
		
	# Sonido inicial de alarido aterrador
	var scream_snd = load("res://audio/sfx/scp_096_scream.mp3")
	if scream_snd:
		var scream_player = AudioStreamPlayer.new()
		scream_player.stream = scream_snd
		scream_player.volume_db = 4.0
		scream_player.bus = "Master"
		add_child(scream_player)
		scream_player.play()
		scream_player.finished.connect(scream_player.queue_free)
			
	_say(phrases_devour_rage[randi() % phrases_devour_rage.size()], Color(1.0, 0.05, 0.05))

func _trigger_trash_suspense() -> void:
	is_inspecting_trash_suspense = true
	trash_suspense_timer = 2.0
	trash_suspicion_cooldown = 20.0
	velocity = Vector3.ZERO
	
	if is_instance_valid(player):
		var to_hiding = (player.global_position - global_position)
		to_hiding.y = 0.0
		if to_hiding.length() > 0.1:
			rotation.y = atan2(to_hiding.x, to_hiding.z)
		
	var slam_stream = HorrorAudio.get_wood_slam_sound()
	if slam_stream and slam_audio:
		slam_audio.stream = slam_stream
		slam_audio.volume_db = 8.5
		slam_audio.pitch_scale = randf_range(0.85, 1.05)
		slam_audio.play()
		
	if is_instance_valid(player) and player.has_method("shake_camera"):
		player.shake_camera(0.65, 0.45)
		
	if brazo_der:
		brazo_der.rotation.x = deg_to_rad(-85.0)
		
	var suspense_phrases = [
		"Sé que andás respirando por acá...",
		"Mmm... ¿Quién anda escondido como una rata?",
		"Puedo oler el miedo a desaprobar...",
		"Salí ahora y tal vez te dé recuperatorio..."
	]
	_say(suspense_phrases[randi() % suspense_phrases.size()], Color(1.0, 0.25, 0.15))

func _process_trash_suspense(delta: float) -> void:
	trash_suspense_timer -= delta
	
	# Acercarse al tacho si está a más de 1.9 metros
	if is_instance_valid(player):
		var to_hiding = (player.global_position - global_position)
		to_hiding.y = 0.0
		var d = to_hiding.length()
		if d > 1.9:
			var dir = to_hiding.normalized()
			velocity.x = dir.x * 1.6
			velocity.z = dir.z * 1.6
			rotation.y = atan2(dir.x, dir.z)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	_animate_walk(delta, velocity.length() > 0.1)
	
	if trash_suspense_timer <= 0.0:
		is_inspecting_trash_suspense = false
		if brazo_der:
			brazo_der.rotation = Vector3.ZERO

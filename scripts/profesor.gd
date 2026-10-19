extends CharacterBody3D
class_name Profesor

enum State {
	PATROL,
	CHASE,
	SEARCH,
	ATTACK
}

## Velocidades ajustables
@export var base_patrol_speed: float = 2.4
@export var base_chase_speed: float = 3.3 ## Ligeramente menor que el jugador (walk_speed = 4.0)
@export var vision_range: float = 18.0 ## Metros de visión en cono
@export var vision_angle_deg: float = 80.0 ## Apertura del cono de visión
@export var proximity_range: float = 3.2 ## Detecta si el jugador está muy cerca en la espalda
@export var hearing_range: float = 35.0 ## Rango para escuchar ruidos del micrófono
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.3
@export var lost_sight_timeout: float = 3.5

## Estado actual
var current_state: State = State.PATROL
var current_speed: float = 2.4
var chase_speed: float = 3.3
var patrol_speed: float = 2.4
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

## Puntos de patrullaje por toda la facultad (Pasillos despejados y Patio)
var patrol_waypoints: Array[Vector3] = [
	Vector3(0.0, 0.2, -18.0),   # Patio Norte
	Vector3(0.0, 0.2, -28.5),   # Pasillo Norte centro
	Vector3(-25.0, 0.2, -28.5), # Pasillo Norte frente a Aula 102
	Vector3(-42.0, 0.2, -28.5), # Esquina Noroeste (frente a Aula 105)
	Vector3(-42.0, 0.2, -12.0), # Pasillo Oeste (frente a Aula 106)
	Vector3(-42.0, 0.2, 5.0),   # Pasillo Oeste (frente a Aula 107)
	Vector3(-42.0, 0.2, 20.0),  # Pasillo Oeste (frente a Aula 108)
	Vector3(-42.0, 0.2, 30.0),  # Esquina Suroeste
	Vector3(-25.0, 0.2, 30.0),  # Pasillo Sur oeste (frente a fotocopiadora 1)
	Vector3(0.0, 0.2, 30.0),    # Pasillo Sur centro (frente a auditorio)
	Vector3(0.0, 0.2, 22.0),    # Entrada Sur al Patio
	Vector3(0.0, 0.2, 4.0),     # Patio interior frente a la fuente
	Vector3(0.0, 0.2, -4.0),    # Patio interior norte
	Vector3(0.0, 0.2, 22.0),    # Salida Patio Sur
	Vector3(25.0, 0.2, 30.0),   # Pasillo Sur este (frente a fotocopiadora 2)
	Vector3(42.0, 0.2, 30.0),   # Esquina Sureste
	Vector3(42.0, 0.2, 17.0),   # Pasillo Este sur (frente a Aula 115)
	Vector3(42.0, 0.2, 0.0),    # Pasillo Este centro (frente a Cafetería PB)
	Vector3(42.0, 0.2, -15.0),  # Pasillo Este norte (frente a Aula 114)
	Vector3(42.0, 0.2, -28.5),  # Esquina Noreste
	Vector3(25.0, 0.2, -28.5)   # Pasillo Norte este (frente a Aula 104)
]
var current_waypoint_idx: int = 0

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

func _ready() -> void:
	add_to_group("enemies")
	
	# Configuración de física para caminar suave y sin saltos
	floor_snap_length = 0.4
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	floor_block_on_wall = false
	
	patrol_speed = base_patrol_speed
	chase_speed = base_chase_speed
	current_speed = patrol_speed
	
	prev_pos = global_position
	
	_find_player()
	
	var mic = get_tree().root.find_child("MicDetector", true, false)
	if mic and mic.has_signal("noise_triggered"):
		mic.noise_triggered.connect(_on_player_noise)
	
	phrase_timer = randf_range(3.0, 7.0)
	_pick_closest_waypoint()

func _pick_closest_waypoint() -> void:
	var best_dist = 99999.0
	for i in range(patrol_waypoints.size()):
		var d = global_position.distance_to(patrol_waypoints[i])
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
	if not is_instance_valid(player):
		return false
	
	var eye_pos = global_position + Vector3(0, 1.5, 0)
	var player_eye = player.global_position + Vector3(0, 1.3, 0)
	var to_player = player_eye - eye_pos
	var dist = to_player.length()

	# Modificador si el jugador tiene la linterna encendida
	var current_vision_range = vision_range
	var flashlight = player.find_child("Flashlight", true, false) as SpotLight3D
	if flashlight and flashlight.visible:
		current_vision_range *= 1.45

	# Proximidad inmediata (si está a menos de 3.2m detrás o a los lados)
	if dist <= proximity_range:
		return _has_line_of_sight(eye_pos, player_eye)

	# Si está más lejos que el rango de visión, no lo ve
	if dist > current_vision_range:
		return false

	# Cono de visión frontal:
	# La cara del profesor está orientada hacia +Z del nodo
	var forward = transform.basis.z.normalized()
	var dir_to_player = to_player.normalized()
	var angle_rad = forward.angle_to(dir_to_player)
	var angle_deg = rad_to_deg(angle_rad)

	if angle_deg > vision_angle_deg * 0.5:
		return false

	# Raycast para verificar si hay paredes intermedias
	return _has_line_of_sight(eye_pos, player_eye)

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

	var target_wp = patrol_waypoints[current_waypoint_idx]
	var to_wp = target_wp - global_position
	to_wp.y = 0.0
	var dist_wp = to_wp.length()

	if dist_wp < 1.4:
		current_waypoint_idx = (current_waypoint_idx + 1) % patrol_waypoints.size()
		target_wp = patrol_waypoints[current_waypoint_idx]
		to_wp = target_wp - global_position
		to_wp.y = 0.0

	var move_dir = to_wp.normalized()
	_move_towards(delta, move_dir, current_speed, 4.0)

func _process_chase_state(delta: float, can_see_player: bool) -> void:
	if is_screamer_ambush:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	current_speed = chase_speed
	
	var to_player = player.global_position - global_position
	var dist_to_player = Vector2(to_player.x, to_player.z).length()

	if can_see_player:
		last_known_player_pos = player.global_position
		time_without_sight = 0.0
	else:
		time_without_sight += delta
		if time_without_sight >= lost_sight_timeout:
			_enter_search_state()
			return

	if dist_to_player <= attack_range and attack_timer <= 0.0:
		_start_attack()
		return

	var target_dest = player.global_position if can_see_player else last_known_player_pos
	var to_target = target_dest - global_position
	to_target.y = 0.0
	var move_dir = to_target.normalized()
	
	_move_towards(delta, move_dir, current_speed, 7.0)

func _process_search_state(delta: float, can_see_player: bool) -> void:
	if can_see_player:
		_enter_chase_state()
		return

	search_timer -= delta
	rotation.y += sin(search_timer * 3.0) * delta * 2.0
	
	velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
	move_and_slide()
	_animate_walk(delta, false)

	if search_timer <= 0.0:
		current_state = State.PATROL
		_pick_closest_waypoint()
		_say("Debió ser el viento... Volvamos a la ronda.")

func _process_attack_state(delta: float) -> void:
	_process_attack(delta)
	velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
	move_and_slide()

## =====================================================================
## MOVIMIENTO Y ORIENTACIÓN SUAVE
## =====================================================================
func _move_towards(delta: float, dir: Vector3, speed_to_use: float, rot_speed: float) -> void:
	var move_vec = dir
	
	if dir.length() > 0.05:
		# Si toca una pared, deslizarse suavemente a lo largo de ella
		if is_on_wall():
			var wall_n = get_wall_normal()
			var slide = dir.slide(wall_n).normalized()
			if slide.length() > 0.1:
				move_vec = slide

		var target_rot_y = atan2(move_vec.x, move_vec.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, rot_speed * delta)
		
		velocity.x = move_toward(velocity.x, move_vec.x * speed_to_use, 12.0 * delta)
		velocity.z = move_toward(velocity.z, move_vec.z * speed_to_use, 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

	var pre_pos = global_position
	var was_on_floor = is_on_floor()
	move_and_slide()

	# Subir pequeños desniveles (Step-up hasta 35cm)
	if was_on_floor and is_on_wall() and dir != Vector3.ZERO:
		var step_h: float = 0.35
		var step_t: Transform3D = global_transform
		step_t.origin.y += step_h
		if not test_move(global_transform, Vector3(0, step_h, 0)):
			var fwd: Vector3 = dir.normalized() * (speed_to_use * delta + 0.1)
			if not test_move(step_t, fwd):
				global_position = pre_pos + Vector3(0, step_h, 0)
				move_and_slide()

	# Detección y recuperación automática si se traba (Watchdog anti-stuck)
	pos_sample_timer += delta
	if pos_sample_timer >= 0.4:
		pos_sample_timer = 0.0
		var moved_dist = global_position.distance_to(prev_pos)
		prev_pos = global_position
		if is_on_wall() and moved_dist < 0.2 and dir.length() > 0.1:
			stuck_timer += 0.4
		else:
			stuck_timer = max(0.0, stuck_timer - 0.4)

	# Si estuvo trabado contra una pared más de 1.0 segundo
	if stuck_timer >= 1.0:
		stuck_timer = 0.0
		if current_state == State.PATROL:
			current_waypoint_idx = (current_waypoint_idx + 1) % patrol_waypoints.size()
			var away_wall = get_wall_normal() * 1.5
			velocity.x = away_wall.x * speed_to_use
			velocity.z = away_wall.z * speed_to_use
		elif current_state == State.CHASE and not _can_see_player():
			_enter_search_state()

	_animate_walk(delta, dir.length() > 0.1)

## =====================================================================
## TRANSICIONES Y ACCIONES
## =====================================================================
func _enter_chase_state() -> void:
	current_state = State.CHASE
	time_without_sight = 0.0
	last_known_player_pos = player.global_position
	
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.1, 0.1)
		ojos_luz.light_energy = 1.6
		
	_say(phrases_chase[randi() % phrases_chase.size()], Color(1.0, 0.2, 0.2))

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
	chase_speed += 0.85
	patrol_speed += 0.45
	
	current_state = State.CHASE
	if is_instance_valid(player):
		last_known_player_pos = player.global_position
	
	if ojos_luz:
		ojos_luz.light_color = Color(1.0, 0.0, 0.0)
		ojos_luz.light_energy = 2.5
		
	_say(phrases_enraged[randi() % phrases_enraged.size()], Color(1.0, 0.0, 0.0))

func _animate_walk(delta: float, is_moving: bool) -> void:
	if is_moving and is_on_floor():
		walk_anim_time += delta * (current_speed * 2.3)
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

func release_screamer_ambush() -> void:
	is_screamer_ambush = false

func _start_attack() -> void:
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
	if not is_instance_valid(player):
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= hearing_range:
		_say("¡¿QUIÉN HACE RUIDO EN MI HORA?!", Color(1.0, 0.2, 0.2))
		current_state = State.CHASE
		last_known_player_pos = player.global_position
		var to_player = player.global_position - global_position
		rotation.y = atan2(to_player.x, to_player.z)

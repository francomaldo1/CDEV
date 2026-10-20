extends CharacterBody3D
class_name Player

@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var acceleration: float = 10.0
@export var mouse_sensitivity: float = 0.003
@export var bob_frequency: float = 2.4
@export var bob_amplitude: float = 0.05

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var flashlight: SpotLight3D = $CameraPivot/Camera3D/Flashlight

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var bob_time: float = 0.0
var step_distance_accum: float = 0.0
var time_stopped: float = 0.0
var original_cam_y: float = 0.0
var is_frozen: bool = false
var shake_tween: Tween = null
var look_tween: Tween = null

var footstep_player: AudioStreamPlayer = null
var heartbeat_player: AudioStreamPlayer = null
var heartbeat_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	_setup_audio_players()
	# Capturar el ratón inmediatamente
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if camera:
		original_cam_y = camera.position.y
	# Configurar suavizado de pendientes y escalones
	floor_snap_length = 0.3
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	floor_block_on_wall = false

func set_frozen(frozen: bool) -> void:
	is_frozen = frozen
	if is_frozen:
		velocity.x = 0.0
		velocity.z = 0.0

func shake_camera(amount: float = 0.5, duration: float = 0.5) -> void:
	if not camera:
		return
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
	shake_tween = create_tween()
	var steps = int(duration / 0.04)
	for i in range(steps):
		var factor = (1.0 - float(i) / float(steps)) * amount
		var rand_h = randf_range(-factor, factor) * 0.12
		var rand_v = randf_range(-factor, factor) * 0.12
		var rand_rot = randf_range(-factor, factor) * 0.04
		shake_tween.tween_property(camera, "h_offset", rand_h, 0.04)
		shake_tween.parallel().tween_property(camera, "v_offset", rand_v, 0.04)
		shake_tween.parallel().tween_property(camera, "rotation:z", rand_rot, 0.04)
	shake_tween.tween_property(camera, "h_offset", 0.0, 0.04)
	shake_tween.parallel().tween_property(camera, "v_offset", 0.0, 0.04)
	shake_tween.parallel().tween_property(camera, "rotation:z", 0.0, 0.04)

func force_flashlight(state: bool) -> void:
	if flashlight:
		flashlight.visible = state

func flicker_flashlight(times: int = 3, interval: float = 0.08) -> void:
	if not flashlight:
		return
	var tw = create_tween()
	for i in range(times):
		tw.tween_callback(func(): if flashlight: flashlight.visible = false)
		tw.tween_interval(interval)
		tw.tween_callback(func(): if flashlight: flashlight.visible = true)
		tw.tween_interval(interval)

func force_look_at(target_global_pos: Vector3, duration: float = 0.45) -> Tween:
	var flat_target = Vector3(target_global_pos.x, global_position.y, target_global_pos.z)
	var to_flat = flat_target - global_position
	if to_flat.length() < 0.1:
		return null
		
	var target_rot_y = atan2(-to_flat.x, -to_flat.z)
	var cam_target_pitch = 0.0
	if camera_pivot:
		var eye_y = global_position.y + 1.5
		var dy = target_global_pos.y - eye_y
		var dist_h = to_flat.length()
		cam_target_pitch = clampf(atan2(dy, dist_h), deg_to_rad(-40.0), deg_to_rad(40.0))
		
	if look_tween and look_tween.is_valid():
		look_tween.kill()
		
	look_tween = create_tween()
	look_tween.set_parallel(true)
	var start_rot_y = rotation.y
	var diff_angle = wrapf(target_rot_y - start_rot_y, -PI, PI)
	var final_rot_y = start_rot_y + diff_angle
	look_tween.tween_property(self, "rotation:y", final_rot_y, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if camera_pivot:
		look_tween.tween_property(camera_pivot, "rotation:x", cam_target_pitch, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return look_tween

func _is_ui_active() -> bool:
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("is_modal_active") and hud.is_modal_active():
		return true
	return false

func _input(event: InputEvent) -> void:
	# Si hay un menú o examen abierto, no capturar mouse ni rotar cámara
	if _is_ui_active():
		return

	# Al hacer clic con cualquier botón, si el mouse no está capturado, capturarlo
	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Control de la cámara con el movimiento del ratón (solo si no está congelado en cinemática)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if not is_frozen:
			rotate_y(-event.relative.x * mouse_sensitivity)
			if camera_pivot:
				camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
				camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	# Linterna (solo si no está congelado por evento)
	if event.is_action_pressed("flashlight") or (event is InputEventKey and event.pressed and event.keycode == KEY_F):
		if not is_frozen:
			toggle_flashlight()

	# Tecla ESC para liberar o volver a capturar el cursor
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_flashlight() -> void:
	if is_frozen:
		return
	if flashlight:
		flashlight.visible = not flashlight.visible

func _physics_process(delta: float) -> void:
	# Si hay un menú/examen abierto o el jugador está congelado en una cinemática de terror
	if _is_ui_active() or is_frozen:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Input de movimiento
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_backward") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()

	# Dirección relativa a la rotación del jugador
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Determinar velocidad actual (caminar vs correr)
	var is_sprinting = (Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)) and input_dir.y < 0
	var current_speed = sprint_speed if is_sprinting else walk_speed

	# Aceleración horizontal
	if direction:
		velocity.x = lerpf(velocity.x, direction.x * current_speed, delta * acceleration)
		velocity.z = lerpf(velocity.z, direction.z * current_speed, delta * acceleration)
	else:
		velocity.x = lerpf(velocity.x, 0.0, delta * acceleration)
		velocity.z = lerpf(velocity.z, 0.0, delta * acceleration)

	var pre_pos := global_position
	var was_on_floor := is_on_floor()
	move_and_slide()

	# Subir escalones automáticamente (Step-up hasta 35cm)
	if was_on_floor and is_on_wall() and direction != Vector3.ZERO:
		var step_h: float = 0.35
		var step_transform: Transform3D = global_transform
		step_transform.origin.y += step_h
		if not test_move(global_transform, Vector3(0, step_h, 0)):
			var fwd: Vector3 = direction.normalized() * (current_speed * delta + 0.1)
			if not test_move(step_transform, fwd):
				global_position = pre_pos + Vector3(0, step_h, 0)
				move_and_slide()

	# Head Bobbing y pasos
	_apply_head_bob_and_footsteps(delta, is_sprinting)
	
	# Latidos cardíacos cuando el peligro acecha
	_update_heartbeat(delta)

func _setup_audio_players() -> void:
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepPlayer"
	footstep_player.volume_db = -14.0
	footstep_player.bus = &"Master"
	add_child(footstep_player)

	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.name = "HeartbeatPlayer"
	heartbeat_player.volume_db = -8.0
	heartbeat_player.bus = &"Master"
	add_child(heartbeat_player)

func _apply_head_bob_and_footsteps(delta: float, is_sprinting: bool) -> void:
	if not camera:
		return
	var horizontal_vel = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_vel > 0.4:
		time_stopped = 0.0
		var speed_mult = 1.35 if is_sprinting else 1.0
		bob_time += delta * bob_frequency * speed_mult
		camera.position.y = original_cam_y + sin(bob_time) * bob_amplitude
		camera.position.x = cos(bob_time * 0.5) * (bob_amplitude * 0.5)
		
		# Pasos perfectamente proporcionados a la distancia recorrida
		step_distance_accum += horizontal_vel * delta
		var required_dist = 1.85 if is_sprinting else 1.55
		if step_distance_accum >= required_dist:
			step_distance_accum = 0.0
			_play_footstep(is_sprinting)
	else:
		bob_time = 0.0
		time_stopped += delta
		if time_stopped > 0.25:
			step_distance_accum = 1.25 # Al reanudar la marcha, el primer paso suena casi de inmediato
		camera.position.y = lerpf(camera.position.y, original_cam_y, delta * 6.0)
		camera.position.x = lerpf(camera.position.x, 0.0, delta * 6.0)

func _play_footstep(is_sprint: bool) -> void:
	if not footstep_player:
		return
	footstep_player.stream = HorrorAudio.get_player_footstep(is_sprint)
	footstep_player.volume_db = -14.0 + randf_range(-1.0, 1.0) if not is_sprint else -11.0 + randf_range(-1.0, 1.0)
	footstep_player.pitch_scale = randf_range(0.97, 1.03)
	footstep_player.play()

func _update_heartbeat(delta: float) -> void:
	var prof = get_tree().root.find_child("Profesor", true, false)
	if not is_instance_valid(prof):
		return
		
	var dist = global_position.distance_to(prof.global_position)
	var is_chasing = (prof.current_state == 1) # State.CHASE
	
	# Latidos cardíacos únicamente cuando el profesor está cerca y acechando/persiguiendo
	if (is_chasing and dist < 14.0) or dist < 6.5:
		var danger_factor = clampf(1.0 - (dist / 14.0), 0.2, 1.0)
		var beat_interval = lerpf(1.15, 0.45, danger_factor)
		
		heartbeat_timer += delta
		if heartbeat_timer >= beat_interval:
			heartbeat_timer = 0.0
			if heartbeat_player:
				heartbeat_player.stream = HorrorAudio.get_heartbeat_sound()
				heartbeat_player.volume_db = lerpf(-12.0, -2.0, danger_factor)
				heartbeat_player.pitch_scale = lerpf(0.92, 1.15, danger_factor)
				heartbeat_player.play()
	else:
		heartbeat_timer = 0.0


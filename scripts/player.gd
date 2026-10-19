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
var step_phase: float = 0.0
var original_cam_y: float = 0.0
var is_frozen: bool = false
var shake_tween: Tween = null

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

	# Control de la cámara con el movimiento del ratón
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
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
	footstep_player.volume_db = -8.0
	footstep_player.bus = &"Master"
	add_child(footstep_player)

	heartbeat_player = AudioStreamPlayer.new()
	heartbeat_player.name = "HeartbeatPlayer"
	heartbeat_player.volume_db = -6.0
	heartbeat_player.bus = &"Master"
	add_child(heartbeat_player)

func _apply_head_bob_and_footsteps(delta: float, is_sprinting: bool) -> void:
	if not camera:
		return
	var horizontal_vel = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_vel > 0.5:
		var speed_mult = 1.35 if is_sprinting else 1.0
		var step_delta = delta * bob_frequency * speed_mult
		bob_time += step_delta
		step_phase += step_delta
		
		# Cada medio ciclo (apoyo alternado de pie izquierdo y derecho)
		if step_phase >= PI:
			step_phase -= PI
			_play_footstep(is_sprinting)
			
		camera.position.y = original_cam_y + sin(bob_time) * bob_amplitude
		camera.position.x = cos(bob_time * 0.5) * (bob_amplitude * 0.5)
	else:
		bob_time = 0.0
		step_phase = 0.0
		camera.position.y = lerpf(camera.position.y, original_cam_y, delta * 6.0)
		camera.position.x = lerpf(camera.position.x, 0.0, delta * 6.0)

func _play_footstep(is_sprint: bool) -> void:
	if not footstep_player:
		return
	footstep_player.stream = HorrorAudio.get_player_footstep(is_sprint)
	footstep_player.pitch_scale = randf_range(0.94, 1.06)
	footstep_player.play()

func _update_heartbeat(delta: float) -> void:
	var prof = get_tree().root.find_child("Profesor", true, false)
	if not is_instance_valid(prof):
		return
		
	var dist = global_position.distance_to(prof.global_position)
	var is_chasing = (prof.current_state == 1) # State.CHASE
	
	# Latidos si está persiguiendo o si está muy cerca en la oscuridad
	if is_chasing or dist < 8.0:
		var danger_factor = clampf(1.0 - (dist / 22.0), 0.15, 1.0)
		var beat_interval = lerpf(1.3, 0.45, danger_factor) # Más rápido cuanto más cerca
		
		heartbeat_timer += delta
		if heartbeat_timer >= beat_interval:
			heartbeat_timer = 0.0
			if heartbeat_player:
				heartbeat_player.stream = HorrorAudio.get_heartbeat_sound()
				heartbeat_player.volume_db = lerpf(-14.0, -3.0, danger_factor)
				heartbeat_player.pitch_scale = lerpf(0.92, 1.18, danger_factor)
				heartbeat_player.play()
	else:
		heartbeat_timer = 0.0


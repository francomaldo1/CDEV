extends CharacterBody3D
class_name Player

@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 20.0
@export var stamina_regen_rate: float = 16.0
@export var stamina_regen_delay: float = 1.0
@export var acceleration: float = 10.0
@export var mouse_sensitivity: float = 0.003
@export var bob_frequency: float = 2.4
@export var bob_amplitude: float = 0.05

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var flashlight: SpotLight3D = $CameraPivot/Camera3D/Flashlight
@onready var retro_post_process: CanvasLayer = get_node_or_null("RetroPostProcess")
@onready var night_vision_light: SpotLight3D = get_node_or_null("CameraPivot/Camera3D/NightVisionLight")
@onready var night_vision_omni: OmniLight3D = get_node_or_null("CameraPivot/Camera3D/NightVisionOmni")

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var bob_time: float = 0.0
var step_distance_accum: float = 0.0
var time_stopped: float = 0.0
var original_cam_y: float = 0.0
var original_cam_pivot_y: float = 1.6
var hiding_base_yaw: float = 0.0
var is_frozen: bool = false
var is_hidden: bool = false
var current_hiding_spot: Node = null
var was_flashlight_on_before_hiding: bool = false
var is_night_vision_on: bool = false
var night_vision_active_val: float = 0.0
var night_vision_battery: float = 100.0
const NIGHT_VISION_BATTERY_DRAIN_SPEED: float = 0.65
const NIGHT_VISION_BATTERY_RECHARGE_SPEED: float = 1.2
var shake_tween: Tween = null
var look_tween: Tween = null

var current_stamina: float = 100.0
var is_sprinting: bool = false
var stamina_exhausted: bool = false
var time_since_sprint: float = 0.0
var peronachos_count: int = 0
var battery_count: int = 0

var footstep_player: AudioStreamPlayer = null
var heartbeat_player: AudioStreamPlayer = null
var jumpscare_player: AudioStreamPlayer = null
var snack_audio_player: AudioStreamPlayer = null
var stinger_player: AudioStreamPlayer = null
var jumpscare_play_time: float = 0.0
var heartbeat_timer: float = 0.0
var post_screamer_heartbeat_timer: float = 0.0
var panic_drone_player: AudioStreamPlayer = null
var chase_violins_player: AudioStreamPlayer = null
var chase_violins_timer: float = 0.0
var current_panic_glitch: float = 0.0

## La linterna fue reemplazada permanentemente por la visión nocturna de la videocámara
var flashlight_enabled: bool = false

func enable_flashlight() -> void:
	flashlight_enabled = false
	if flashlight:
		flashlight.visible = false

func _ready() -> void:
	add_to_group("player")
	if flashlight:
		flashlight.visible = false
	_setup_audio_players()
	# Capturar el ratón inmediatamente
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if camera:
		original_cam_y = camera.position.y
	if camera_pivot:
		original_cam_pivot_y = camera_pivot.position.y
	# Configurar suavizado de pendientes y escalones
	floor_snap_length = 0.3
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	floor_block_on_wall = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if not _is_ui_active() and not is_frozen:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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

func force_flashlight(_state: bool) -> void:
	if flashlight:
		flashlight.visible = false

func flicker_flashlight(_times: int = 3, _interval: float = 0.08) -> void:
	if flashlight:
		flashlight.visible = false

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
			if is_hidden:
				# Rotación adentro del tacho: puede mirar al frente y a los costados por las 3 grandes rendijas (+/- 105 grados)
				var yaw_delta = -event.relative.x * mouse_sensitivity
				var target_yaw = rotation.y + yaw_delta
				var diff = wrapf(target_yaw - hiding_base_yaw, -PI, PI)
				var max_yaw = deg_to_rad(105.0)
				rotation.y = hiding_base_yaw + clampf(diff, -max_yaw, max_yaw)
				
				if camera_pivot:
					camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
					camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-22.0), deg_to_rad(22.0))
			else:
				rotate_y(-event.relative.x * mouse_sensitivity)
				if camera_pivot:
					camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
					camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	# Linterna (solo si no está congelado por evento)
	# Visión Nocturna tipo Outlast (Click Derecho del ratón, tecla F o tecla N)
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT) \
	   or (event is InputEventKey and event.pressed and (event.keycode == KEY_F or event.keycode == KEY_N or event.keycode == KEY_V)):
		if not is_frozen:
			toggle_night_vision()
			return

	if event.is_action_pressed("flashlight") or (event is InputEventKey and event.pressed and event.keycode == KEY_F):
		if not is_frozen:
			toggle_flashlight()

	# Consumir Peronachos con la tecla Q
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
		if not is_frozen:
			consume_peronachos()

	# Recargar Batería de la Videocámara con la tecla R
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		if not is_frozen:
			reload_camera_battery()

	# Tecla ESC para liberar o volver a capturar el cursor
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_flashlight() -> void:
	if flashlight:
		flashlight.visible = false

func _process(delta: float) -> void:
	_update_night_vision_process(delta)
	_update_heartbeat(delta)

func _physics_process(delta: float) -> void:
	# Si hay un menú/examen abierto o el jugador está congelado en una cinemática de terror
	if is_hidden:
		velocity.x = 0.0
		velocity.z = 0.0
		_regenerate_stamina(delta)
		return
	if _is_ui_active() or is_frozen:
		velocity.x = 0.0
		velocity.z = 0.0
		if _is_ui_active():
			_regenerate_stamina(delta)
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

	# Determinar velocidad actual (caminar vs correr con estamina)
	var wants_to_sprint = (Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)) and input_dir.y < 0 and input_dir.length_squared() > 0.01

	if wants_to_sprint and not stamina_exhausted and current_stamina > 0.0:
		is_sprinting = true
		current_stamina = maxf(0.0, current_stamina - stamina_drain_rate * delta)
		time_since_sprint = 0.0
		if current_stamina <= 0.0:
			stamina_exhausted = true
			is_sprinting = false
	else:
		_regenerate_stamina(delta)

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

	# Subir pequeños bordes o cordones automáticamente (Step-up suave hasta 20cm)
	if was_on_floor and is_on_wall() and direction != Vector3.ZERO:
		var step_h: float = 0.20
		var step_transform: Transform3D = global_transform
		step_transform.origin.y += step_h
		if not test_move(global_transform, Vector3(0, step_h, 0)):
			var fwd: Vector3 = direction.normalized() * (current_speed * delta + 0.05)
			if not test_move(step_transform, fwd):
				global_position = pre_pos + Vector3(0, step_h * 0.5, 0)
				move_and_slide()

	if jumpscare_player and jumpscare_player.playing:
		jumpscare_play_time += delta

	# Head Bobbing y pasos
	_apply_head_bob_and_footsteps(delta, is_sprinting)
	


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
	var hb_stream = HorrorAudio.get_heartbeat_sound()
	if hb_stream is AudioStreamMP3:
		(hb_stream as AudioStreamMP3).loop = true
	heartbeat_player.stream = hb_stream
	add_child(heartbeat_player)

	jumpscare_player = AudioStreamPlayer.new()
	jumpscare_player.name = "JumpscarePlayer"
	jumpscare_player.stream = load("res://audio/sfx/jumpscare_sound_effect.wav")
	jumpscare_player.volume_db = 8.0
	jumpscare_player.bus = &"Master"
	add_child(jumpscare_player)
	jumpscare_player.finished.connect(_on_jumpscare_finished)

	snack_audio_player = AudioStreamPlayer.new()
	snack_audio_player.name = "SnackAudioPlayer"
	snack_audio_player.volume_db = 2.0
	snack_audio_player.bus = &"Master"
	add_child(snack_audio_player)

	stinger_player = AudioStreamPlayer.new()
	stinger_player.name = "StingerPlayer"
	stinger_player.stream = load("res://audio/sfx/horror-stinger.mp3")
	stinger_player.volume_db = 6.0
	stinger_player.bus = &"Master"
	add_child(stinger_player)

	panic_drone_player = AudioStreamPlayer.new()
	panic_drone_player.name = "PanicDronePlayer"
	panic_drone_player.volume_db = -45.0
	panic_drone_player.bus = &"Master"
	panic_drone_player.stream = HorrorAudio.get_panic_sub_drone()
	add_child(panic_drone_player)

	chase_violins_player = AudioStreamPlayer.new()
	chase_violins_player.name = "ChaseViolinsPlayer"
	chase_violins_player.volume_db = -80.0
	chase_violins_player.bus = &"Master"
	var violins_stream = load("res://audio/ambient/freesound_community-scaryviolins-6829.mp3")
	if violins_stream is AudioStreamMP3:
		(violins_stream as AudioStreamMP3).loop = true
	chase_violins_player.stream = violins_stream
	chase_violins_player.finished.connect(func():
		if is_instance_valid(chase_violins_player) and (chase_violins_timer > 0.0 or not is_hidden):
			chase_violins_player.play()
	)
	add_child(chase_violins_player)

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

func _on_jumpscare_finished() -> void:
	trigger_post_screamer_heartbeat(25.0)

func play_jumpscare_screamer() -> void:
	jumpscare_play_time = 0.0
	if jumpscare_player:
		jumpscare_player.stop()
		jumpscare_player.volume_db = 8.0
		jumpscare_player.play()
	
	# Música de persecución intensa con violines aterradores a volumen alto (+5.0 dB)
	start_chase_violins(60.0, 5.0)

func start_chase_violins(duration: float = 60.0, boost_db: float = 5.0) -> void:
	chase_violins_timer = maxf(chase_violins_timer, duration)
	if not chase_violins_player or not chase_violins_player.stream:
		return
	if not chase_violins_player.playing:
		chase_violins_player.volume_db = boost_db - 3.0
		chase_violins_player.play()
	var tw = create_tween()
	tw.tween_property(chase_violins_player, "volume_db", boost_db, 0.25)

func stop_chase_violins(fade_time: float = 1.8) -> void:
	chase_violins_timer = 0.0
	if chase_violins_player and chase_violins_player.playing:
		var tw = create_tween()
		tw.tween_property(chase_violins_player, "volume_db", -50.0, fade_time)
		tw.tween_callback(chase_violins_player.stop)

func stop_jumpscare_screamer(fade_time: float = 0.3) -> void:
	if jumpscare_player and jumpscare_player.playing:
		var tw = create_tween()
		tw.tween_property(jumpscare_player, "volume_db", -40.0, fade_time)
		tw.tween_callback(jumpscare_player.stop)

func fade_jumpscare_screamer(fade_time: float = 0.3) -> void:
	if jumpscare_play_time < 3.2:
		var remaining = 3.2 - jumpscare_play_time
		var tw = create_tween()
		tw.tween_interval(remaining)
		tw.tween_property(jumpscare_player, "volume_db", -40.0, fade_time)
		tw.tween_callback(jumpscare_player.stop)
	else:
		stop_jumpscare_screamer(fade_time)

func trigger_post_screamer_heartbeat(duration: float = 25.0) -> void:
	post_screamer_heartbeat_timer = maxf(post_screamer_heartbeat_timer, duration)
	if heartbeat_player and not heartbeat_player.playing:
		heartbeat_player.volume_db = -6.0
		heartbeat_player.play()

func _update_heartbeat(delta: float) -> void:
	var prof = get_tree().root.find_child("Profesor", true, false)
	var dist: float = 999.0
	var is_chasing: bool = false
	if is_instance_valid(prof) and prof.visible:
		dist = global_position.distance_to(prof.global_position)
		var prof_state = prof.get("current_state")
		is_chasing = (prof_state == 1) # State.CHASE
		
	if post_screamer_heartbeat_timer > 0.0:
		post_screamer_heartbeat_timer -= delta
		
	var in_danger = (is_chasing and dist < 16.0) or dist < 8.0 or post_screamer_heartbeat_timer > 0.0
	if in_danger:
		if heartbeat_player and not heartbeat_player.playing:
			heartbeat_player.volume_db = -8.0
			heartbeat_player.play()
		var danger_factor = 0.5
		if post_screamer_heartbeat_timer > 0.0:
			danger_factor = maxf(danger_factor, clampf(post_screamer_heartbeat_timer / 15.0, 0.5, 1.0))
		if dist < 16.0:
			var prox_factor = clampf(1.0 - (dist / 16.0), 0.35, 1.0)
			danger_factor = maxf(danger_factor, prox_factor)
		var target_vol = lerpf(-15.0, -4.0, danger_factor)
		if heartbeat_player:
			heartbeat_player.volume_db = lerpf(heartbeat_player.volume_db, target_vol, delta * 3.0)
	else:
		if heartbeat_player and heartbeat_player.playing:
			heartbeat_player.volume_db = lerpf(heartbeat_player.volume_db, -45.0, delta * 2.0)
			if heartbeat_player.volume_db <= -40.0:
				heartbeat_player.stop()

	if chase_violins_timer > 0.0:
		chase_violins_timer -= delta
		
	var prof_ambush = is_instance_valid(prof) and (prof.get("is_screamer_ambush") == true)
	var prof_in_pursuit = is_instance_valid(prof) and prof.visible and not prof_ambush and (prof.get("current_state") == 1 or prof.get("current_state") == 2 or prof.get("is_screamer_charging")) and dist < 32.0
	var should_play_violins = (chase_violins_timer > 0.0) or prof_in_pursuit
	if is_hidden:
		should_play_violins = false
		chase_violins_timer = 0.0
		
	if chase_violins_player:
		if should_play_violins:
			if not chase_violins_player.playing:
				chase_violins_player.volume_db = 1.0
				chase_violins_player.play()
			var target_v = 5.0 if dist < 12.0 else 2.0
			chase_violins_player.volume_db = lerpf(chase_violins_player.volume_db, target_v, delta * 3.5)
		else:
			if chase_violins_player.playing:
				chase_violins_player.volume_db = lerpf(chase_violins_player.volume_db, -50.0, delta * 2.5)
				if chase_violins_player.volume_db <= -42.0:
					chase_violins_player.stop()

	# Proximidad al profesor y efecto pánico analógico (Opción C - Distancia ampliada a 7.5m)
	var prox_panic: float = 0.0
	if is_instance_valid(prof) and prof.visible and dist < 7.5:
		prox_panic = clampf(1.0 - (dist / 7.5), 0.0, 1.0)
	current_panic_glitch = lerpf(current_panic_glitch, prox_panic, delta * 6.0)

	# Modulación del zumbido subgrave (sub-bass drone)
	if panic_drone_player:
		if current_panic_glitch > 0.03:
			if not panic_drone_player.playing:
				panic_drone_player.play()
			var drone_vol = lerpf(-36.0, 1.5, current_panic_glitch)
			panic_drone_player.volume_db = drone_vol
		else:
			if panic_drone_player.playing:
				panic_drone_player.volume_db = lerpf(panic_drone_player.volume_db, -50.0, delta * 3.0)
				if panic_drone_player.volume_db <= -45.0:
					panic_drone_player.stop()

	# Distorsión y estática VHS según proximidad al peligro
	var retro_rect = retro_post_process.get_node_or_null("EffectRect") if is_instance_valid(retro_post_process) else null
	if retro_rect and retro_rect.material is ShaderMaterial:
		var mat = retro_rect.material as ShaderMaterial
		mat.set_shader_parameter("panic_glitch", current_panic_glitch)
		if in_danger and dist < 12.0:
			var glitch_intensity = clampf(1.0 - (dist / 12.0), 0.0, 1.0)
			var target_noise = lerpf(0.03, 0.065, glitch_intensity)
			var target_chroma = lerpf(0.0018, 0.0042, glitch_intensity)
			var cur_noise = mat.get_shader_parameter("video_noise")
			var cur_chroma = mat.get_shader_parameter("chromatic_aberration")
			if cur_noise != null:
				mat.set_shader_parameter("video_noise", lerpf(cur_noise, target_noise, delta * 3.5))
			if cur_chroma != null:
				mat.set_shader_parameter("chromatic_aberration", lerpf(cur_chroma, target_chroma, delta * 3.5))
		else:
			var cur_noise = mat.get_shader_parameter("video_noise")
			var cur_chroma = mat.get_shader_parameter("chromatic_aberration")
			if cur_noise != null and cur_noise > 0.0305:
				mat.set_shader_parameter("video_noise", lerpf(cur_noise, 0.03, delta * 2.5))
			if cur_chroma != null and cur_chroma > 0.00185:
				mat.set_shader_parameter("chromatic_aberration", lerpf(cur_chroma, 0.0018, delta * 2.5))
	
	# Si está escondido en el tacho y el profesor pasa pegado (< 3.2m), vibración de pánico en cámara
	if is_hidden and current_panic_glitch > 0.45:
		shake_camera(0.18 * current_panic_glitch, 0.08)


func enter_hiding(spot: Node, hide_global_pos: Vector3, face_dir: Vector3) -> void:
	is_hidden = true
	current_hiding_spot = spot
	velocity = Vector3.ZERO
	was_flashlight_on_before_hiding = flashlight and flashlight.visible
	if flashlight:
		flashlight.visible = false
	global_position = hide_global_pos
	
	# Desactivar colisión física para no ser expulsado por el sólido del tacho
	var col = find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col:
		col.disabled = true
		
	# Bajar la altura del pivote de cámara para quedar adentro del tacho a nivel de las aberturas (Y = 1.22m)
	if camera_pivot:
		camera_pivot.position.y = 1.22
		camera_pivot.rotation.x = 0.0
	# Acercar la cámara a la abertura frontal e iluminar hacia el pasillo
	if camera:
		camera.position.y = 0.0
		camera.position.z = -0.20
	if night_vision_light:
		night_vision_light.position = Vector3(0, 0, -0.45)
		
	# Asegurar que el cuerpo esté perfectamente vertical
	rotation.x = 0.0
	rotation.z = 0.0
	if face_dir != Vector3.ZERO:
		rotation.y = atan2(-face_dir.x, -face_dir.z)
	hiding_base_yaw = rotation.y

func exit_hiding(exit_global_pos: Vector3) -> void:
	is_hidden = false
	current_hiding_spot = null
	global_position = exit_global_pos
	
	var col = find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col:
		col.disabled = false
		
	# Restaurar altura original de pie
	if camera_pivot:
		camera_pivot.position.y = original_cam_pivot_y
	if camera:
		camera.position.y = 0.0
		camera.position.z = 0.0
	if night_vision_light:
		night_vision_light.position = Vector3.ZERO
		
	if was_flashlight_on_before_hiding and flashlight:
		flashlight.visible = true
	was_flashlight_on_before_hiding = false
	
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("set_trash_overlay_visible"):
		hud.set_trash_overlay_visible(false)
	if hud and hud.has_method("update_trash_overlay_parallax"):
		hud.update_trash_overlay_parallax(0.0, 0.0)

func _regenerate_stamina(delta: float) -> void:
	is_sprinting = false
	time_since_sprint += delta
	if time_since_sprint >= stamina_regen_delay:
		current_stamina = minf(max_stamina, current_stamina + stamina_regen_rate * delta)
		if stamina_exhausted and current_stamina >= 25.0:
			stamina_exhausted = false

func play_horror_stinger() -> void:
	if stinger_player:
		stinger_player.stop()
		stinger_player.play()
	# Duración reducida para el jumpscare del 4to examen: acompaña únicamente la corrida por el pasillo y se apaga rápido
	start_chase_violins(3.5, 2.0)

func add_peronachos(amount: int = 1) -> void:
	peronachos_count += amount
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_inventory_display"):
		hud.update_inventory_display()
	if hud and hud.has_method("show_temporary_alert"):
		hud.show_temporary_alert("🎒 ¡Recogiste una bolsa de Peronachos! Presioná [Q] en emergencia para recuperar estamina.", Color(1.0, 0.85, 0.2))

func consume_peronachos() -> bool:
	var hud = get_tree().root.find_child("HUD", true, false)
	if peronachos_count <= 0:
		if hud and hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("❌ No tenés paquetes de Peronachos en la mochila.", Color(1.0, 0.4, 0.3))
		return false
		
	if current_stamina >= max_stamina - 1.0 and not stamina_exhausted:
		if hud and hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("⚡ Tu estamina ya está llena al 100%.", Color(0.7, 0.9, 1.0))
		return false

	peronachos_count -= 1
	current_stamina = max_stamina
	stamina_exhausted = false
	time_since_sprint = stamina_regen_delay
	
	if snack_audio_player:
		snack_audio_player.stream = load("res://audio/sfx/eating-chips.mp3")
		snack_audio_player.pitch_scale = randf_range(0.96, 1.04)
		snack_audio_player.play()
		
	shake_camera(0.25, 0.25)
	
	if hud:
		if hud.has_method("update_inventory_display"):
			hud.update_inventory_display()
		if hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("⚡ ¡Peronachos crujientes consumidos! ¡Estamina al 100%! ⚡", Color(0.3, 1.0, 0.6))
			
	return true

func add_battery(amount: int = 1) -> void:
	battery_count += amount
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("update_inventory_display"):
		hud.update_inventory_display()

func reload_camera_battery() -> bool:
	var hud = get_tree().root.find_child("HUD", true, false)
	if battery_count <= 0:
		if hud and hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("⚠ No tenés pilas AA en el inventario.", Color(1.0, 0.4, 0.3))
		return false
		
	if night_vision_battery >= 99.5:
		if hud and hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("🔋 La batería de la videocámara ya está al 100%.", Color(0.4, 0.9, 1.0))
		return false
		
	battery_count -= 1
	var gained = recharge_night_vision(50.0)
	shake_camera(0.15, 0.2)
	
	if hud:
		if hud.has_method("update_inventory_display"):
			hud.update_inventory_display()
		if hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("🔋 ¡Batería recargada (+%d%%)! Pilas restantes: %d" % [int(gained), battery_count], Color(0.3, 1.0, 0.55))
			
	return true

func toggle_retro_shader() -> bool:
	if is_instance_valid(retro_post_process):
		retro_post_process.visible = not retro_post_process.visible
		return retro_post_process.visible
	return false

func is_retro_shader_enabled() -> bool:
	if is_instance_valid(retro_post_process):
		return retro_post_process.visible
	return false


func toggle_night_vision() -> void:
	if is_frozen:
		return
	if night_vision_battery <= 2.0 and not is_night_vision_on:
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("show_temporary_alert"):
			hud.show_temporary_alert("🪫 Batería de la cámara agotada... Esperá a que recargue.", Color(1.0, 0.3, 0.3))
		return
	
	is_night_vision_on = not is_night_vision_on
	_update_night_vision_lights()
	_play_night_vision_sound(is_night_vision_on)
	
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("set_night_vision_active"):
		hud.set_night_vision_active(is_night_vision_on)

func _update_night_vision_lights() -> void:
	if night_vision_light:
		night_vision_light.visible = is_night_vision_on

func _update_night_vision_process(delta: float) -> void:
	if is_night_vision_on:
		night_vision_battery = maxf(0.0, night_vision_battery - delta * NIGHT_VISION_BATTERY_DRAIN_SPEED)
		if night_vision_battery <= 0.0:
			toggle_night_vision()
	else:
		pass # La batería de visión nocturna no se autorregenera al apagarse
	
	var target_nv = 1.0 if is_night_vision_on else 0.0
	night_vision_active_val = lerpf(night_vision_active_val, target_nv, delta * 9.0)
	
	var retro_rect = retro_post_process.get_node_or_null("EffectRect") if is_instance_valid(retro_post_process) else null
	if retro_rect and retro_rect.material is ShaderMaterial:
		(retro_rect.material as ShaderMaterial).set_shader_parameter("night_vision_active", night_vision_active_val)
	
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("set_night_vision_battery"):
		hud.set_night_vision_battery(night_vision_battery)

func recharge_night_vision(amount: float = 50.0) -> float:
	var prev = night_vision_battery
	night_vision_battery = minf(100.0, night_vision_battery + amount)
	var gained = night_vision_battery - prev
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("set_night_vision_battery"):
		hud.set_night_vision_battery(night_vision_battery)
	_play_battery_pickup_sound()
	return gained

func _play_battery_pickup_sound() -> void:
	var p = AudioStreamPlayer.new()
	p.bus = &"Master"
	p.volume_db = -2.0
	add_child(p)
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 44100
	gen.buffer_length = 0.15
	p.stream = gen
	p.play()
	var pb = p.get_stream_playback()
	if pb:
		var frames = int(44100 * 0.12)
		for i in range(frames):
			var t = float(i) / 44100.0
			var f = 800.0 + t * 4000.0 if t < 0.05 else 1600.0
			var env = exp(-t * 22.0)
			var s = sin(TAU * f * t) * env * 0.4
			pb.push_frame(Vector2(s, s))
	p.finished.connect(p.queue_free)

func _play_night_vision_sound(is_on: bool) -> void:
	var click_player = AudioStreamPlayer.new()
	click_player.bus = &"Master"
	click_player.volume_db = -5.0
	add_child(click_player)
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 44100
	gen.buffer_length = 0.08
	click_player.stream = gen
	click_player.play()
	var pb = click_player.get_stream_playback()
	if pb:
		var freq = 1800.0 if is_on else 1100.0
		var frames = int(44100 * 0.04)
		for i in range(frames):
			var t = float(i) / 44100.0
			var decay = 1.0 - (float(i) / float(frames))
			var sample = sin(t * freq * TAU) * decay * 0.35
			pb.push_frame(Vector2(sample, sample))
	get_tree().create_timer(0.2).timeout.connect(func():
		if is_instance_valid(click_player):
			click_player.queue_free()
	)

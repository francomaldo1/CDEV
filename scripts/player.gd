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
var original_cam_y: float = 0.0

func _ready() -> void:
	add_to_group("player")
	# Capturar el ratón inmediatamente
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if camera:
		original_cam_y = camera.position.y
	# Configurar suavizado de pendientes y escalones
	floor_snap_length = 0.3
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(50.0)
	floor_block_on_wall = false

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

	# Linterna
	if event.is_action_pressed("flashlight") or (event is InputEventKey and event.pressed and event.keycode == KEY_F):
		toggle_flashlight()

	# Tecla ESC para liberar o volver a capturar el cursor
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_flashlight() -> void:
	if flashlight:
		flashlight.visible = not flashlight.visible

func _physics_process(delta: float) -> void:
	# Si hay un menú/examen abierto, no procesar movimiento
	if _is_ui_active():
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

	# Head Bobbing (balanceo de cámara)
	_apply_head_bob(delta, is_sprinting)

func _apply_head_bob(delta: float, is_sprinting: bool) -> void:
	if not camera:
		return
	var horizontal_vel = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_vel > 0.5:
		var speed_mult = 1.35 if is_sprinting else 1.0
		bob_time += delta * bob_frequency * speed_mult
		camera.position.y = original_cam_y + sin(bob_time) * bob_amplitude
		camera.position.x = cos(bob_time * 0.5) * (bob_amplitude * 0.5)
	else:
		bob_time = 0.0
		camera.position.y = lerpf(camera.position.y, original_cam_y, delta * 6.0)
		camera.position.x = lerpf(camera.position.x, 0.0, delta * 6.0)

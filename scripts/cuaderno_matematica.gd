extends Area3D
class_name CuadernoMatematica

signal exam_opened(cuaderno: CuadernoMatematica)
signal exam_solved(success: bool)

@export var classroom_name: String = "Aula"

@onready var prompt_label: Label3D = $PromptLabel
@onready var light: OmniLight3D = $OmniLight3D

var is_player_nearby: bool = false
var is_solved: bool = false
var player_ref: CharacterBody3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if prompt_label:
		prompt_label.text = "[E] Cuaderno: %s" % classroom_name

func _process(delta: float) -> void:
	if is_solved:
		return
		
	# Efecto de levitación/pulsación sutil de luz
	if light:
		light.light_energy = 0.5 + sin(Time.get_ticks_msec() * 0.004) * 0.25

	if is_player_nearby and Input.is_action_just_pressed("interact") or (is_player_nearby and Input.is_key_pressed(KEY_E)):
		_open_challenge()

func _open_challenge() -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.has_method("open_math_exam"):
		hud.open_math_exam(self)
		exam_opened.emit(self)

func on_exam_result(success: bool) -> void:
	exam_solved.emit(success)
	if success:
		is_solved = true
		if prompt_label:
			prompt_label.text = "✓ ¡PARCIAL APROBADO!"
			prompt_label.modulate = Color(0.2, 1.0, 0.4)
		if light:
			light.light_color = Color(0.2, 1.0, 0.4)
			light.light_energy = 0.8
	else:
		# Si falló, puede volver a intentar luego o queda penalizado
		if prompt_label:
			prompt_label.text = "✗ DESAPROBADO [E para reintentar]"
			prompt_label.modulate = Color(1.0, 0.2, 0.2)
		if light:
			light.light_color = Color(1.0, 0.2, 0.2)

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("set_interact_prompt"):
			hud.set_interact_prompt("[E] Resolver Parcial de Matemáticas")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("set_interact_prompt"):
			hud.set_interact_prompt("")

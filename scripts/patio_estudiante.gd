extends Node3D
## Script para el patio del estudiante - efectos de horror
## Luces parpadeantes, sonidos ambientales, etc.

@onready var luz_fuente: OmniLight3D = $LuzFuente
@onready var luz_galeria_o: OmniLight3D = $LuzGaleriaO
@onready var luz_galeria_e: OmniLight3D = $LuzGaleriaE

var _flicker_timer: float = 0.0
var _flicker_interval: float = 0.15
var _flicker_target: OmniLight3D = null
var _flicker_original_energy: float = 0.0
var _next_flicker_event: float = 5.0

## Agua de la fuente oscilación
var _water_time: float = 0.0


func _ready() -> void:
	_schedule_next_flicker()


func _process(delta: float) -> void:
	_process_flicker(delta)
	_process_water_effect(delta)


## Hace que las luces de las galerías parpadeen aleatoriamente
## como si estuvieran a punto de quemarse (efecto horror)
func _process_flicker(delta: float) -> void:
	_next_flicker_event -= delta
	
	if _next_flicker_event <= 0:
		if _flicker_target == null:
			# Iniciar un nuevo parpadeo
			var targets = [luz_galeria_o, luz_galeria_e]
			_flicker_target = targets[randi() % targets.size()]
			if _flicker_target:
				_flicker_original_energy = _flicker_target.light_energy
				_flicker_timer = randf_range(0.3, 1.5)  # Duración del parpadeo
		
		if _flicker_target:
			_flicker_timer -= delta
			
			if _flicker_timer > 0:
				# Parpadeo rápido
				if fmod(_flicker_timer, _flicker_interval) < _flicker_interval * 0.5:
					_flicker_target.light_energy = _flicker_original_energy * randf_range(0.1, 0.4)
				else:
					_flicker_target.light_energy = _flicker_original_energy * randf_range(0.7, 1.2)
			else:
				# Fin del parpadeo
				_flicker_target.light_energy = _flicker_original_energy
				_flicker_target = null
				_schedule_next_flicker()


func _schedule_next_flicker() -> void:
	_next_flicker_event = randf_range(3.0, 12.0)


## Efecto sutil de "movimiento" en la luz de la fuente
## Simula el reflejo del agua
func _process_water_effect(delta: float) -> void:
	_water_time += delta
	if luz_fuente:
		var base_energy = 0.6
		var wobble = sin(_water_time * 2.0) * 0.1 + sin(_water_time * 3.7) * 0.05
		luz_fuente.light_energy = base_energy + wobble

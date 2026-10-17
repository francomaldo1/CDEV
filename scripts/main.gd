extends Node3D

@onready var mic_detector = $MicDetector
@onready var hud = $HUD
@onready var profesor = $Profesor
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var moon_light: DirectionalLight3D = $MoonLight

var cuaderno_scene = preload("res://scenes/cuaderno_matematica.tscn")
var puerta_salida_scene = preload("res://scenes/puerta_salida.tscn")
var tablero_scene = preload("res://scenes/tablero_electrico.tscn")
var fusible_scene = preload("res://scenes/fusible.tscn")

## Retraso en segundos hasta que se corte la luz
@export var blackout_delay: float = 45.0

var tablero_electrico: Area3D = null
var is_blackout: bool = false
var original_ambient_energy: float = 0.4
var original_moon_energy: float = 0.35

## Ubicaciones de pupitres en todas las aulas de Planta Baja
var classroom_spots = [
	{"pos": Vector3(-52.5, 0.82, -39.0), "name": "Aula 101 (Norte)"},
	{"pos": Vector3(-27.5, 0.82, -39.0), "name": "Aula 102 (Norte)"},
	{"pos": Vector3(-2.5, 0.82, -39.0),  "name": "Aula 103 (Norte)"},
	{"pos": Vector3(23.5, 0.82, -39.0),  "name": "Aula 104 (Norte)"},
	{"pos": Vector3(-56.5, 0.82, -25.8), "name": "Laboratorio W1 (Oeste)"},
	{"pos": Vector3(-56.5, 0.82, -11.8), "name": "Aula W2 (Oeste)"},
	{"pos": Vector3(-56.5, 0.82, 2.2),   "name": "Aula W3 (Oeste)"},
	{"pos": Vector3(-56.5, 0.82, 17.2),  "name": "Aula W4 (Oeste)"}
]

func _ready() -> void:
	randomize()
	
	if mic_detector and hud:
		mic_detector.volume_updated.connect(hud.on_mic_volume_updated)
		
	if world_env and world_env.environment:
		original_ambient_energy = world_env.environment.ambient_light_energy
	if moon_light:
		original_moon_energy = moon_light.light_energy
		
	_spawn_exit_door()
	_spawn_tablero_electronica()
	_spawn_fusible()
	_spawn_multiple_cuadernos()
	
	# Programar el corte de luz
	_start_blackout_timer()

func _spawn_exit_door() -> void:
	var puerta = puerta_salida_scene.instantiate()
	puerta.position = Vector3(0.0, 0.0, 34.8)
	puerta.rotation_degrees = Vector3(0, 180, 0)
	add_child(puerta)

func _spawn_tablero_electronica() -> void:
	# Ubicado en el Departamento de Ingeniería Electrónica (Planta Baja Oeste)
	tablero_electrico = tablero_scene.instantiate() as Area3D
	tablero_electrico.position = Vector3(-25.0, 0.0, -4.5)
	tablero_electrico.rotation_degrees = Vector3(0, 90, 0)
	tablero_electrico.power_restored.connect(_on_power_restored)
	add_child(tablero_electrico)
	print(">>> Tablero Eléctrico instalado en Depto. de Ingeniería Electrónica")

func _spawn_fusible() -> void:
	# El fusible está guardado en la Cafetería o Bedelía (ala este)
	var fusible = fusible_scene.instantiate()
	fusible.position = Vector3(45.0, 0.85, 28.0)
	add_child(fusible)
	print(">>> Fusible de alta tensión colocado en Cafetería (45, 0.85, 28)")

func _spawn_multiple_cuadernos() -> void:
	classroom_spots.shuffle()
	
	# Colocar exámenes en 6 de las 8 aulas disponibles para que sea fácil encontrarlos
	var count = min(6, classroom_spots.size())
	for i in range(count):
		var spot = classroom_spots[i]
		var cuaderno = cuaderno_scene.instantiate()
		cuaderno.position = spot["pos"]
		cuaderno.classroom_name = spot["name"]
		add_child(cuaderno)
		print(">>> Cuaderno matemático colocado en: %s" % spot["name"])

func _start_blackout_timer() -> void:
	get_tree().create_timer(blackout_delay).timeout.connect(_trigger_blackout)

func _trigger_blackout() -> void:
	if is_blackout:
		return
	is_blackout = true
	
	# Efecto de parpadeo y corte general
	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = 0.04
	if moon_light:
		moon_light.light_energy = 0.08
		
	# Apagar luces de galerías en el patio si existen
	var luces_galeria = get_tree().get_nodes_in_group("building_lights")
	for l in luces_galeria:
		if l is Light3D:
			l.visible = false
			
	if tablero_electrico:
		tablero_electrico.trigger_blackout()
		
	if hud and hud.has_method("show_temporary_alert"):
		hud.show_temporary_alert("⚡ ¡CORTE GENERAL DE LUZ! Los disyuntores saltaron. Busca el FUSIBLE y llévalo al Depto. de Electrónica.", Color(1.0, 0.25, 0.25))
		
	if profesor and profesor.has_method("_say"):
		profesor._say("¡¿Quién tocó los disyuntores?! ¡Quedaron todos a oscuras!", Color(1.0, 0.3, 0.3))
		
	print(">>> ¡CORTE DE LUZ ACTIVADO EN LA FACULTAD!")

func _on_power_restored() -> void:
	is_blackout = false
	
	# Restaurar iluminación
	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = original_ambient_energy
	if moon_light:
		moon_light.light_energy = original_moon_energy
		
	var luces_galeria = get_tree().get_nodes_in_group("building_lights")
	for l in luces_galeria:
		if l is Light3D:
			l.visible = true
			
	print(">>> ¡ENERGÍA RESTABLECIDA EN TODA LA FACULTAD!")

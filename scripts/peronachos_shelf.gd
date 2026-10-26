extends Area3D
class_name PeronachosShelf

static var global_last_pickup_time: int = 0

@export var max_capacity: int = 13
var available_bags: Array[Node3D] = []
var is_player_nearby: bool = false
var player_ref: CharacterBody3D = null
var audio_player: AudioStreamPlayer3D = null

func _ready() -> void:
	add_to_group("peronachos_shelves")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "PickupSound3D"
	audio_player.unit_size = 3.0
	audio_player.max_distance = 15.0
	audio_player.bus = &"Master"
	add_child(audio_player)
	
	_collect_bag_nodes()

func _collect_bag_nodes() -> void:
	for child in get_children():
		if child is MeshInstance3D and child.name.begins_with("Peronachos_"):
			available_bags.append(child)
	# Ordenar de arriba hacia abajo para tomar primero las bolsas de los estantes superiores
	available_bags.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)

func register_external_bags(bags: Array) -> void:
	available_bags.clear()
	for b in bags:
		if is_instance_valid(b) and b is Node3D:
			available_bags.append(b)
	available_bags.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)

func _process(_delta: float) -> void:
	if is_player_nearby and Input.is_action_just_pressed("interact"):
		_try_take_bag()

func _try_take_bag() -> void:
	var now = Time.get_ticks_msec()
	if now - global_last_pickup_time < 350:
		return
		
	var hud = get_tree().root.find_child("HUD", true, false)
	if not is_instance_valid(player_ref):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_ref = players[0] as CharacterBody3D
			
	if not is_instance_valid(player_ref):
		return
		
	# Si hay otro estante de Peronachos más cerca del jugador, dejar que ese estante procese la toma
	for other in get_tree().get_nodes_in_group("peronachos_shelves"):
		if other != self and is_instance_valid(other):
			if other.get("available_bags") != null and not other.available_bags.is_empty():
				if other.global_position.distance_squared_to(player_ref.global_position) < global_position.distance_squared_to(player_ref.global_position):
					return
		
	if available_bags.is_empty():
		if hud:
			hud.set_interact_prompt("No quedan más paquetes de Peronachos en este estante.")
		return
		
	if player_ref.get("peronachos_count") != null and player_ref.peronachos_count >= 8:
		if hud:
			hud.show_temporary_alert("🎒 Mochila llena de Peronachos (máximo 8 paquetes).", Color(1.0, 0.75, 0.2))
		return
		
	global_last_pickup_time = now
	get_viewport().set_input_as_handled()
		
	# Tomar exactamente UNA sola bolsa de los estantes
	var bag = available_bags.pop_front()
	if is_instance_valid(bag):
		bag.visible = false
		bag.queue_free()
		
	if audio_player:
		audio_player.stream = load("res://audio/sfx/freesound_community-closing-a-bag-of-chips-103921.mp3")
		audio_player.volume_db = 3.0
		audio_player.pitch_scale = randf_range(0.96, 1.04)
		audio_player.play()
		
	if player_ref.has_method("add_peronachos"):
		player_ref.add_peronachos(1)
		
	_update_hud_prompt()

func _update_hud_prompt() -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and is_player_nearby:
		if available_bags.is_empty():
			hud.set_interact_prompt("Estante de Peronachos vacío")
		else:
			hud.set_interact_prompt("[E] Agarrar Peronachos (%d en el estante)" % available_bags.size())

func _on_body_entered(body: Node3D) -> void:
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		_update_hud_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

extends Area3D
class_name PuertaAuditorio

## Puerta central del auditorio (planta baja). Se abre solo con la llave del auditorio.

signal auditorium_opened

## Nodos de EdificioCentral que forman la hoja de la puerta y se quitan al abrir
@export var door_nodes: Array[String] = [
	"Aud_Puerta2_VidrioIzq",
	"Aud_Puerta2_VidrioDer",
	"Aud_Puerta2_Centro",
	"Aud_Puerta2_Franja",
	"Aud_Puerta2_ManijonL",
	"Aud_Puerta2_ManijonR",
]

@onready var prompt_label: Label3D = $PromptLabel

var is_player_nearby: bool = false
var player_ref: CharacterBody3D = null
var is_open: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if is_open or not is_player_nearby:
		return
	if Input.is_action_just_pressed("interact"):
		_try_open()

func _try_open() -> void:
	var hud = get_tree().root.find_child("HUD", true, false)
	if not hud:
		return
	if not hud.has_auditorium_key:
		hud.show_temporary_alert("🔒 El auditorio está cerrado. Necesitás la LLAVE DEL AUDITORIO.", Color(1.0, 0.3, 0.3))
		return
	_open()
	hud.show_temporary_alert("🚪 ¡Abriste el AUDITORIO! Tu TÍTULO te espera en el atril del escenario.", Color(0.3, 1.0, 0.5))
	if hud.has_method("set_objective_text"):
		hud.set_objective_text("NUEVO OBJETIVO: Entrá al Auditorio y agarrá tu Título Universitario del estrado", Color(0.2, 1.0, 0.5))
	hud.set_interact_prompt("")

func _open() -> void:
	is_open = true
	var edificio = get_tree().root.find_child("EdificioCentral", true, false)
	if edificio:
		for n in door_nodes:
			var node = edificio.find_child(n, true, false)
			if node:
				node.queue_free()
			else:
				push_warning("PuertaAuditorio: no se encontró el nodo " + n)
	if prompt_label:
		prompt_label.visible = false
	auditorium_opened.emit()
	print(">>> ¡AUDITORIO ABIERTO!")

func _on_body_entered(body: Node3D) -> void:
	if is_open:
		return
	if body is Player or body.is_in_group("player") or body.name == "Player":
		is_player_nearby = true
		player_ref = body as CharacterBody3D
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			if hud.has_auditorium_key:
				hud.set_interact_prompt("[E] Abrir Auditorio con la llave")
			else:
				hud.set_interact_prompt("[E] Auditorio cerrado (requiere llave)")

func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		is_player_nearby = false
		player_ref = null
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud:
			hud.set_interact_prompt("")

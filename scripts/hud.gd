extends CanvasLayer

@onready var mic_progress_bar: ProgressBar = $MicContainer/ProgressBar
@onready var mic_label: Label = $MicContainer/MicLabel
@onready var alert_label: Label = $AlertLabel
@onready var instruction_label: Label = $InstructionLabel

func _ready() -> void:
	# Asegurar que ningún elemento de UI bloquee el mouse ni la cámara
	_set_mouse_filter_ignore(self)
	
	if alert_label:
		alert_label.visible = false
	if instruction_label:
		instruction_label.text = "[W,A,S,D] Caminar  |  [Shift] Correr  |  [F] Linterna  |  [ESC] Cursor  |  Click: Capturar"

func _set_mouse_filter_ignore(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignore(child)

func on_mic_volume_updated(volume: float, is_alert: bool) -> void:
	if mic_progress_bar:
		mic_progress_bar.value = volume * 100.0
		
		# Cambiar color según intensidad
		if is_alert:
			mic_progress_bar.modulate = Color(1.0, 0.2, 0.2) # Rojo
			if alert_label:
				alert_label.visible = true
				alert_label.text = "¡PELIGRO: HACES DEMASIADO RUIDO!"
		elif volume > 0.4:
			mic_progress_bar.modulate = Color(1.0, 0.8, 0.2) # Amarillo
			if alert_label:
				alert_label.visible = false
		else:
			mic_progress_bar.modulate = Color(0.2, 1.0, 0.4) # Verde
			if alert_label:
				alert_label.visible = false

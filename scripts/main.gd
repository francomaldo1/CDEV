extends Node3D

@onready var mic_detector = $MicDetector
@onready var hud = $HUD

func _ready() -> void:
	if mic_detector and hud:
		mic_detector.volume_updated.connect(hud.on_mic_volume_updated)

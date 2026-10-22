extends Node
class_name MicDetector

## Emitted every frame with normalized volume (0.0 to 1.0) and whether it exceeds threshold
signal volume_updated(current_volume: float, is_alert: bool)
signal noise_triggered(volume: float)

@export var bus_name: String = "Record"
@export var threshold_db: float = -24.0 ## Sensitivity threshold in dB (configurable in settings)
@export var smoothing: float = 12.0 ## How quickly the UI bar reacts/smooths

var bus_index: int = -1
var capture_effect: AudioEffectCapture
var smoothed_level: float = 0.0
var is_active: bool = true

func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("MicDetector: Bus '%s' no encontrado. Asegurate de tener configurado default_bus_layout.tres" % bus_name)
		return
	
	# Buscar el efecto de captura en el bus
	for i in range(AudioServer.get_bus_effect_count(bus_index)):
		var effect = AudioServer.get_bus_effect(bus_index, i)
		if effect is AudioEffectCapture:
			capture_effect = effect
			break
	
	if not capture_effect:
		push_warning("MicDetector: No se encontro AudioEffectCapture en el bus '%s'." % bus_name)

func _process(delta: float) -> void:
	if not is_active:
		return
		
	var peak_db: float = -80.0
	
	if bus_index >= 0:
		# Obtener volumen pico en dB
		var l_peak = AudioServer.get_bus_peak_volume_left_db(bus_index, 0)
		var r_peak = AudioServer.get_bus_peak_volume_right_db(bus_index, 0)
		peak_db = max(l_peak, r_peak)
	
	# También drenamos el buffer de captura si existe para evitar overflow
	if capture_effect:
		var available = capture_effect.get_frames_available()
		if available > 0:
			capture_effect.get_buffer(available)

	# Convertir dB (-60dB a 0dB) a escala lineal 0.0 -> 1.0
	# -60 dB o menos = silencio total
	# 0 dB = maximo volumen (grito/saturacion)
	var raw_linear = db_to_linear(peak_db)
	var target_norm = clampf(remap(peak_db, -60.0, 0.0, 0.0, 1.0), 0.0, 1.0)
	
	smoothed_level = lerpf(smoothed_level, target_norm, delta * smoothing)
	
	var is_alert = peak_db > threshold_db
	if is_alert:
		noise_triggered.emit(smoothed_level)
		
	volume_updated.emit(smoothed_level, is_alert)

## Permite activar o desactivar la barra cuando te escondes
func set_mic_active(active: bool) -> void:
	is_active = active
	if not is_active:
		smoothed_level = 0.0
		volume_updated.emit(0.0, false)

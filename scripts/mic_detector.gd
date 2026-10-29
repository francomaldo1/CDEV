extends Node
class_name MicDetector

## Emitted every frame with normalized volume (0.0 to 1.0) and whether it exceeds threshold
signal volume_updated(current_volume: float, is_alert: bool)
signal noise_triggered(volume: float)

@export var bus_name: String = "Record"
@export var threshold_db: float = -28.0 ## Sensitivity threshold in dB (configurable in settings)
@export var smoothing: float = 12.0 ## How quickly the UI bar reacts/smooths

var bus_index: int = -1
var capture_effect: AudioEffectCapture
var smoothed_level: float = 0.0
var is_active: bool = false
var mic_player: AudioStreamPlayer = null

func _ready() -> void:
	# 1. Configurar y priorizar dispositivo de entrada de micrófono (ej: CONEXANT USB AUDIO)
	_setup_preferred_input_device()

	bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("MicDetector: Bus '%s' no encontrado. Asegurate de tener configurado default_bus_layout.tres" % bus_name)
		return
	
	# 2. Buscar el efecto de captura en el bus
	for i in range(AudioServer.get_bus_effect_count(bus_index)):
		var effect = AudioServer.get_bus_effect(bus_index, i)
		if effect is AudioEffectCapture:
			capture_effect = effect
			break
	
	if not capture_effect:
		push_warning("MicDetector: No se encontro AudioEffectCapture en el bus '%s'." % bus_name)
		
	# 3. Iniciar reproductor de entrada con AudioStreamMicrophone
	_setup_mic_player()

func _setup_preferred_input_device() -> void:
	var devices = AudioServer.get_input_device_list()
	print(">>> MicDetector: Dispositivos de audio detectados:")
	var selected = ""
	for dev in devices:
		print("    - ", dev)
		var d_low = dev.to_lower()
		if "conexant" in d_low or "usb" in d_low:
			selected = dev
	
	if selected != "":
		AudioServer.input_device = selected
		print(">>> MicDetector: Seleccionado dispositivo preferido: '", selected, "'")
	else:
		print(">>> MicDetector: Utilizando dispositivo por defecto: '", AudioServer.input_device, "'")

func _setup_mic_player() -> void:
	if not mic_player:
		mic_player = AudioStreamPlayer.new()
		mic_player.name = "MicStreamPlayer"
		mic_player.stream = AudioStreamMicrophone.new()
		mic_player.bus = bus_name
		add_child(mic_player)
		mic_player.play()
		print(">>> MicDetector: AudioStreamMicrophone iniciado en bus '%s'." % bus_name)

func _process(delta: float) -> void:
	if not is_active:
		return
		
	var peak_db: float = -80.0
	
	# 1. Leer directamente los frames del buffer de AudioEffectCapture
	if capture_effect:
		var available = capture_effect.get_frames_available()
		if available > 0:
			var buffer = capture_effect.get_buffer(available)
			var max_amp: float = 0.0
			for frame in buffer:
				var a1 = absf(frame.x)
				var a2 = absf(frame.y)
				if a1 > max_amp: max_amp = a1
				if a2 > max_amp: max_amp = a2
			if max_amp > 0.0001:
				peak_db = linear_to_db(max_amp)
	
	# 2. Respaldo adicional vía bus peak volume
	if bus_index >= 0:
		var l_peak = AudioServer.get_bus_peak_volume_left_db(bus_index, 0)
		var r_peak = AudioServer.get_bus_peak_volume_right_db(bus_index, 0)
		var bus_max = maxf(l_peak, r_peak)
		if bus_max > peak_db:
			peak_db = bus_max

	# Tecla opcional de test / debug (G o T) para simular ruido sin micrófono
	var debug_noise = Input.is_key_pressed(KEY_G) or Input.is_key_pressed(KEY_T)
	if debug_noise:
		peak_db = maxf(peak_db, -10.0)

	# Convertir dB (-60dB a 0dB) a escala lineal 0.0 -> 1.0
	var target_norm = clampf(remap(peak_db, -60.0, 0.0, 0.0, 1.0), 0.0, 1.0)
	
	smoothed_level = lerpf(smoothed_level, target_norm, delta * smoothing)
	
	var is_alert = peak_db > threshold_db
	if is_alert:
		noise_triggered.emit(smoothed_level)
		
	volume_updated.emit(smoothed_level, is_alert)

## Permite activar o desactivar la barra cuando te escondes
func set_mic_active(active: bool) -> void:
	is_active = active
	if is_active:
		if mic_player and not mic_player.playing:
			mic_player.play()
		if capture_effect:
			var av = capture_effect.get_frames_available()
			if av > 0:
				capture_effect.get_buffer(av)
	else:
		smoothed_level = 0.0
		volume_updated.emit(0.0, false)

class_name HorrorAudio
extends RefCounted

## Generador de audio procedural para efectos de terror, pasos y ambientación
## Produce AudioStreamWAV en formato 16-bit PCM sin depender de archivos externos.

static var _cached_spark: AudioStreamWAV = null
static var _cached_slam: AudioStreamWAV = null
static var _cached_stinger: AudioStreamWAV = null
static var _cached_drone_normal: AudioStreamWAV = null
static var _cached_drone_blackout: AudioStreamWAV = null
static var _cached_footstep_walk: AudioStreamWAV = null
static var _cached_footstep_sprint: AudioStreamWAV = null
static var _cached_prof_step: AudioStreamWAV = null
static var _cached_heartbeat: AudioStreamWAV = null
static var _cached_creak: AudioStreamWAV = null

static func get_spark_sound() -> AudioStreamWAV:
	if _cached_spark == null:
		_cached_spark = _generate_spark()
	return _cached_spark

static func get_wood_slam_sound() -> AudioStreamWAV:
	if _cached_slam == null:
		_cached_slam = _generate_wood_slam()
	return _cached_slam

static func get_screamer_stinger() -> AudioStreamWAV:
	if _cached_stinger == null:
		_cached_stinger = _generate_stinger()
	return _cached_stinger

static func get_ambient_drone(is_blackout: bool = false) -> AudioStreamWAV:
	if is_blackout:
		if _cached_drone_blackout == null:
			_cached_drone_blackout = _generate_ambient_drone(true)
		return _cached_drone_blackout
	else:
		if _cached_drone_normal == null:
			_cached_drone_normal = _generate_ambient_drone(false)
		return _cached_drone_normal

static func get_player_footstep(is_sprint: bool = false) -> AudioStreamWAV:
	if is_sprint:
		if _cached_footstep_sprint == null:
			_cached_footstep_sprint = _generate_footstep(true)
		return _cached_footstep_sprint
	else:
		if _cached_footstep_walk == null:
			_cached_footstep_walk = _generate_footstep(false)
		return _cached_footstep_walk

static func get_profesor_footstep() -> AudioStreamWAV:
	if _cached_prof_step == null:
		_cached_prof_step = _generate_prof_step()
	return _cached_prof_step

static func get_heartbeat_sound() -> AudioStreamWAV:
	if _cached_heartbeat == null:
		_cached_heartbeat = _generate_heartbeat()
	return _cached_heartbeat

static func get_spooky_creak() -> AudioStreamWAV:
	# Generamos variantes para que suene orgánico y no repetitivo
	return _generate_spooky_creak()

static func _generate_spark() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 0.45
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 9.0)
		var noise = (randf() * 2.0 - 1.0) * 0.75
		var buzz = sin(t * 60.0 * TAU) * 0.35 + sin(t * 120.0 * TAU) * 0.25 + sin(t * 180.0 * TAU) * 0.15
		var crackle = 1.0 if randf() < 0.08 else 0.0
		var sample_val = clampf((noise + buzz + crackle) * env * 1.2, -1.0, 1.0)
		var pcm = int(sample_val * 31000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

static func _generate_wood_slam() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 0.6
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 14.0)
		var click = exp(-t * 90.0) * (randf() * 2.0 - 1.0) * 1.5
		var resonance = sin(t * 160.0 * TAU) * 0.6 + sin(t * 85.0 * TAU) * 0.4
		var sample_val = clampf((click + resonance * env) * 1.1, -1.0, 1.0)
		var pcm = int(sample_val * 32000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

static func _generate_stinger() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 1.2
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = exp(-t * 3.5)
		var sub_bass = sin(t * 48.0 * TAU) * 0.7 * exp(-t * 2.0)
		var disharmony = (sin(t * 440.0 * TAU) + sin(t * 466.16 * TAU) + sin(t * 622.25 * TAU) + sin(t * 880.0 * TAU)) * 0.22
		var screech_noise = (randf() * 2.0 - 1.0) * 0.15 * exp(-t * 6.0)
		var sample_val = clampf((sub_bass + disharmony * env + screech_noise) * 1.2, -1.0, 1.0)
		var pcm = int(sample_val * 31500.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

## Dron oscuro continuo (Dark Ambient Drone) - atmósfera profunda, suave y sin zumbidos molestos
static func _generate_ambient_drone(is_blackout: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 4.0
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	# Frecuencias armónicas suaves para colchón atmosférico envolvente
	var f_base = 44.0 # Sub-grave F1 muy limpio
	var f_harm = 88.0 # Octava armónica suave
	var noise_filter = 0.0
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var progress = t / length_sec
		
		# Modulación LFO suave y lenta (0.25 Hz y 0.5 Hz)
		var lfo = sin(progress * TAU) * 0.5 + 0.5
		
		# Generador de aire frío / viento distante (ruido browniano filtrado paso bajo)
		noise_filter = noise_filter * 0.965 + (randf() * 2.0 - 1.0) * 0.035
		var air_draft = noise_filter * (0.18 + 0.08 * lfo)
		
		# Tonos sinusoidales puros y calmos (sin frecuencias que vibren como redoblante)
		var sub = sin(t * f_base * TAU) * 0.28
		var harm = sin(t * f_harm * TAU) * 0.10 * (0.7 + 0.3 * lfo)
		
		# En apagón añadimos un tono disonante fantasmal tenue
		var blackout_layer = 0.0
		if is_blackout:
			blackout_layer = sin(t * 46.5 * TAU) * 0.16 + noise_filter * 0.08
			
		# Ventana de fundido suave en los bordes para bucle 100% perfecto sin chasquidos
		var edge_fade = minf(1.0, minf(t / 0.06, (length_sec - t) / 0.06))
		var sample_val = clampf((sub + harm + air_draft + blackout_layer) * edge_fade * 0.85, -1.0, 1.0)
		var pcm = int(sample_val * 24000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples_count
	return wav

## Pasos claros, audibles y realistas del jugador sobre piso de granito/mosaico
static func _generate_footstep(is_sprint: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 0.18 if not is_sprint else 0.15
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	var speed_mult = 1.15 if is_sprint else 1.0
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		# Impacto táctil de suela contra piso duro (transición de frecuencia rápida 540Hz -> 180Hz)
		var sweep_freq = lerpf(540.0 * speed_mult, 180.0 * speed_mult, clampf(t * 32.0, 0.0, 1.0))
		var impact = sin(t * sweep_freq * TAU) * exp(-t * 36.0) * 0.85
		# Resonancia corporal y peso del calzado
		var thud = sin(t * 135.0 * speed_mult * TAU) * exp(-t * 24.0) * 0.60
		# Fricción breve de suela
		var scuff = (randf() * 2.0 - 1.0) * exp(-t * 48.0) * 0.28
		# Eco sutil de pasillo
		var room_tail = sin(t * 260.0 * TAU) * exp(-t * 18.0) * 0.20
		
		var sample_val = clampf((impact + thud + scuff + room_tail) * 1.3, -1.0, 1.0)
		var pcm = int(sample_val * 31000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

## Pasos pesados, autoritarios y con eco de zapatos formales del profesor
static func _generate_prof_step() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 0.32
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		# Taconeo seco y contundente de zapato de cuero (CLACK)
		var heel_freq = lerpf(980.0, 240.0, clampf(t * 38.0, 0.0, 1.0))
		var heel_strike = sin(t * heel_freq * TAU) * exp(-t * 32.0) * 0.90
		# Golpe grave del peso corporal contra la losa
		var body_thud = sin(t * 92.0 * TAU) * exp(-t * 16.0) * 0.85
		# Fricción del cuero
		var leather = (randf() * 2.0 - 1.0) * exp(-t * 45.0) * 0.25
		# Reverberación en pasillos altos
		var reverb = (sin(t * 180.0 * TAU) + sin(t * 310.0 * TAU)) * 0.25 * exp(-t * 9.0)
		
		var sample_val = clampf((heel_strike + body_thud + leather + reverb) * 1.35, -1.0, 1.0)
		var pcm = int(sample_val * 32000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

## Latido de corazón sordo y visceral ("lub-dub")
static func _generate_heartbeat() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 0.50
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		# Primer latido (lub) suave y profundo
		var beat1 = sin(t * 45.0 * TAU) * exp(-t * 18.0) * 0.85
		# Segundo latido (dub) a los 0.16s
		var t2 = t - 0.16
		var beat2 = 0.0
		if t2 >= 0.0:
			beat2 = sin(t2 * 52.0 * TAU) * exp(-t2 * 16.0) * 0.70
		
		var sample_val = clampf((beat1 + beat2) * 1.25, -1.0, 1.0)
		var pcm = int(sample_val * 30000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

## Crujido ambiental repentino o golpe en las cañerías
static func _generate_spooky_creak() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = randf_range(0.8, 1.6)
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	var is_metallic = randf() < 0.5
	var base_freq = randf_range(160.0, 320.0) if is_metallic else randf_range(70.0, 140.0)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var env = sin((t / length_sec) * PI) * exp(-t * 2.5)
		var mod_freq = base_freq + sin(t * 8.0 * TAU) * 25.0
		var tone = sin(t * mod_freq * TAU) * 0.6
		var grit = (randf() * 2.0 - 1.0) * (0.25 if not is_metallic else 0.1)
		
		var sample_val = clampf((tone + grit) * env * 0.8, -1.0, 1.0)
		var pcm = int(sample_val * 24000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

class_name HorrorAudio
extends RefCounted

## Generador de audio procedural para efectos de terror, pasos y ambientación
## Produce AudioStreamWAV en formato 16-bit PCM sin depender de archivos externos.

static var _cached_spark: AudioStreamWAV = null
static var _cached_slam: AudioStreamWAV = null
static var _cached_stinger: AudioStreamWAV = null
static var _cached_ambient_file: AudioStreamWAV = null
static var _cached_drone_normal: AudioStreamWAV = null
static var _cached_drone_blackout: AudioStreamWAV = null
static var _cached_player_walk: Array[AudioStreamWAV] = []
static var _cached_player_sprint: Array[AudioStreamWAV] = []
static var _cached_prof_step: Array[AudioStreamWAV] = []
static var _player_walk_idx: int = 0
static var _player_sprint_idx: int = 0
static var _prof_step_idx: int = 0
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
	if _cached_ambient_file == null:
		var path = "res://audio/ambient/horror_ambience_atmos_11.wav"
		if ResourceLoader.exists(path):
			var s = load(path) as AudioStreamWAV
			if s:
				s.loop_mode = AudioStreamWAV.LOOP_FORWARD
				_cached_ambient_file = s
	if _cached_ambient_file != null:
		return _cached_ambient_file
	if is_blackout:
		if _cached_drone_blackout == null:
			_cached_drone_blackout = _generate_ambient_drone(true)
		return _cached_drone_blackout
	else:
		if _cached_drone_normal == null:
			_cached_drone_normal = _generate_ambient_drone(false)
		return _cached_drone_normal

static func get_player_footstep(is_sprint: bool = false) -> AudioStreamWAV:
	_ensure_footsteps_loaded()
	if is_sprint:
		if _cached_player_sprint.is_empty():
			return _generate_footstep(true)
		_player_sprint_idx = (_player_sprint_idx + 1) % _cached_player_sprint.size()
		return _cached_player_sprint[_player_sprint_idx]
	else:
		if _cached_player_walk.is_empty():
			return _generate_footstep(false)
		_player_walk_idx = (_player_walk_idx + 1) % _cached_player_walk.size()
		return _cached_player_walk[_player_walk_idx]

static func get_profesor_footstep() -> AudioStreamWAV:
	_ensure_footsteps_loaded()
	if _cached_prof_step.is_empty():
		return _generate_prof_step()
	_prof_step_idx = (_prof_step_idx + 1) % _cached_prof_step.size()
	return _cached_prof_step[_prof_step_idx]

static func _ensure_footsteps_loaded() -> void:
	if _cached_player_walk.is_empty():
		for i in range(1, 5):
			var path = "res://audio/footsteps/player_walk_%02d.wav" % i
			if ResourceLoader.exists(path):
				var stream = load(path) as AudioStreamWAV
				if stream:
					_cached_player_walk.append(stream)
		if _cached_player_walk.is_empty():
			for i in range(4):
				_cached_player_walk.append(_generate_realistic_player_step(i, false))

	if _cached_player_sprint.is_empty():
		for i in range(1, 3):
			var path = "res://audio/footsteps/player_sprint_%02d.wav" % i
			if ResourceLoader.exists(path):
				var stream = load(path) as AudioStreamWAV
				if stream:
					_cached_player_sprint.append(stream)
		if _cached_player_sprint.is_empty():
			for i in range(2):
				_cached_player_sprint.append(_generate_realistic_player_step(i, true))

	if _cached_prof_step.is_empty():
		for i in range(1, 4):
			var path = "res://audio/footsteps/profesor_step_%02d.wav" % i
			if ResourceLoader.exists(path):
				var stream = load(path) as AudioStreamWAV
				if stream:
					_cached_prof_step.append(stream)
		if _cached_prof_step.is_empty():
			for i in range(3):
				_cached_prof_step.append(_generate_realistic_prof_step(i))

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

## Pasos realistas y naturales de zapatilla sobre piso duro (baldosa / granito)
static func _generate_footstep(is_sprint: bool) -> AudioStreamWAV:
	return _generate_realistic_player_step(0, is_sprint)

## Pasos realistas del profesor con zapatos de vestir sobre piso duro
static func _generate_prof_step() -> AudioStreamWAV:
	return _generate_realistic_prof_step(0)

## Generador acústico de pasos del jugador modelando impacto de talón y planta con fricción de goma
static func _generate_realistic_player_step(variation: int, is_sprint: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 0.15 if not is_sprint else 0.12
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	var heel_freq = 90.0 + (variation % 4) * 8.0 # Frecuencia sorda de impacto (85-115 Hz)
	var toe_freq = 135.0 + (variation % 4) * 10.0 # Contacto de la planta delantera
	var toe_delay = 0.034 + (variation % 2) * 0.006 # Retardo talón-punta (34-40 ms)
	if is_sprint:
		toe_delay *= 0.70
		heel_freq *= 1.15
	
	# Filtros de estado variable (Chamberlin SVF) para modelar fricción acústica de goma contra cerámica
	var svf1_low = 0.0
	var svf1_band = 0.0
	var f1 = 2.0 * sin(PI * 650.0 / 22050.0)
	var q1 = 1.5
	
	var svf2_low = 0.0
	var svf2_band = 0.0
	var f2 = 2.0 * sin(PI * 1250.0 / 22050.0)
	var q2 = 2.0
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var noise = randf() * 2.0 - 1.0
		
		svf1_low += f1 * svf1_band
		var svf1_high = noise - svf1_low - q1 * svf1_band
		svf1_band += f1 * svf1_high
		
		svf2_low += f2 * svf2_band
		var svf2_high = noise - svf2_low - q2 * svf2_band
		svf2_band += f2 * svf2_high
		
		# Impacto 1: Talón al pisar (sordo, amortiguado rápidamente)
		var env_heel = exp(-t * 75.0)
		var heel_thud = sin(t * heel_freq * TAU) * env_heel * 0.48
		var heel_friction = svf1_band * env_heel * 0.35
		
		# Impacto 2: Apoyo de la planta delantera
		var toe_thud = 0.0
		var toe_friction = 0.0
		if t >= toe_delay:
			var t_toe = t - toe_delay
			var env_toe = exp(-t_toe * 90.0)
			toe_thud = sin(t_toe * toe_freq * TAU) * env_toe * 0.24
			toe_friction = (svf2_band * 0.65 + svf1_band * 0.35) * env_toe * 0.26
			
		var total = heel_thud + heel_friction + toe_thud + toe_friction
		total = tanh(total * 1.5) * 0.82
		
		var pcm = int(clampf(total, -1.0, 1.0) * 16000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

## Generador acústico de pasos del profesor con zapatos de vestir (taconeo seco y peso)
static func _generate_realistic_prof_step(variation: int) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 0.24
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	var heel_freq = 76.0 + variation * 6.0
	var clack_freq = 1450.0 + variation * 100.0
	var toe_delay = 0.048 + (variation % 2) * 0.008
	
	var svf_low = 0.0
	var svf_band = 0.0
	var f_clack = 2.0 * sin(PI * clack_freq / 22050.0)
	var q_clack = 1.3
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var noise = randf() * 2.0 - 1.0
		
		svf_low += f_clack * svf_band
		var svf_high = noise - svf_low - q_clack * svf_band
		svf_band += f_clack * svf_high
		
		# Taconeo seco inicial
		var env_clack = exp(-t * 85.0)
		var heel_clack = (sin(t * clack_freq * TAU) * 0.30 + svf_band * 0.45) * env_clack
		
		# Peso corporal en baja frecuencia
		var env_thud = exp(-t * 32.0)
		var heel_thud = sin(t * heel_freq * TAU) * env_thud * 0.58
		
		# Apoyo secundario de la suela
		var toe_sound = 0.0
		if t >= toe_delay:
			var t_toe = t - toe_delay
			var env_toe = exp(-t_toe * 75.0)
			toe_sound = (sin(t_toe * (heel_freq * 1.6) * TAU) * 0.22 + svf_band * 0.20) * env_toe
			
		# Eco sutil de pasillo vacío
		var echo = sin(t * 155.0 * TAU) * exp(-t * 20.0) * 0.12
		
		var total = heel_clack + heel_thud + toe_sound + echo
		total = tanh(total * 1.5) * 0.85
		
		var pcm = int(clampf(total, -1.0, 1.0) * 18000.0)
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


static func get_door_unlock_sound() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var samples_count = int(22050 * 0.7)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var click1 = sin(t * 880.0 * TAU) * exp(-t * 45.0)
		var click2 = (sin((t - 0.12) * 1250.0 * TAU) if t > 0.12 else 0.0) * exp(-max(0.0, t - 0.12) * 35.0)
		var heavy_thud = sin(t * 110.0 * TAU) * exp(-t * 12.0)
		var sample_val = clampf((click1 * 0.6 + click2 * 0.7 + heavy_thud * 0.5), -1.0, 1.0)
		var pcm = int(sample_val * 28000.0)
		data.encode_s16(i * 2, pcm)
	wav.data = data
	return wav

static func get_door_rattle_sound() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var samples_count = int(22050 * 0.4)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var r1 = sin(t * 320.0 * TAU) * exp(-t * 30.0)
		var r2 = (sin((t - 0.08) * 440.0 * TAU) if t > 0.08 else 0.0) * exp(-max(0.0, t - 0.08) * 35.0)
		var sample_val = clampf((r1 * 0.5 + r2 * 0.6), -1.0, 1.0)
		var pcm = int(sample_val * 22000.0)
		data.encode_s16(i * 2, pcm)
	wav.data = data
	return wav

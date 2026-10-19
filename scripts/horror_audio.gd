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

## Dron oscuro continuo (Dark Ambient Drone) en bucle perfecto
static func _generate_ambient_drone(is_blackout: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	# Duración exacta de 4.0 segundos para bucle periódico sin chasquidos
	var length_sec = 4.0
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	# Frecuencias armónicas base múltiplos exactos de 1/4 Hz (0.25 Hz) para fase perfecta en extremos
	var f1 = 55.0  # A1 subgrave
	var f2 = 82.5  # E2 quinta
	var f3 = 110.0 # A2 octava
	var f_dissonance = 58.25 if is_blackout else 55.0 # Tono disonante siniestro en apagón
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		var phase_progress = t / length_sec
		
		# Viento/aire filtrado sutil con modulación lenta
		var slow_lfo = sin(phase_progress * TAU * 1.0) * 0.5 + 0.5
		var slow_lfo2 = cos(phase_progress * TAU * 2.0) * 0.5 + 0.5
		
		var sub = sin(t * f1 * TAU) * 0.45
		var fifth = sin(t * f2 * TAU) * 0.25 * (0.8 + 0.2 * slow_lfo)
		var rumble = sin(t * 32.0 * TAU) * (0.35 if is_blackout else 0.2)
		
		# En apagón añadimos disonancia oscura y zumbido electromagnético distante
		var extra = 0.0
		if is_blackout:
			var dark_drone = sin(t * f_dissonance * TAU) * 0.3
			var distant_hiss = (randf() * 2.0 - 1.0) * 0.06 * (0.6 + 0.4 * slow_lfo2)
			extra = dark_drone + distant_hiss
		else:
			# Zumbido normal de transformadores/iluminación tenue
			var light_hum = sin(t * 100.0 * TAU) * 0.08
			extra = light_hum
			
		var sample_val = clampf((sub + fifth + rumble + extra) * 0.7, -1.0, 1.0)
		var pcm = int(sample_val * 28000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples_count
	return wav

## Pasos del jugador sobre piso de granito/mosaico
static func _generate_footstep(is_sprint: bool) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 0.22 if not is_sprint else 0.26
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	var pitch_mult = 1.15 if is_sprint else 1.0
	var vol_mult = 1.3 if is_sprint else 0.85
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		# Golpe inicial de suela (transitorio duro) + resonancia hueca de pasillo
		var env = exp(-t * (24.0 if not is_sprint else 18.0))
		var heel_click = exp(-t * 90.0) * (randf() * 2.0 - 1.0) * 0.9
		var thud = sin(t * 95.0 * pitch_mult * TAU) * 0.7 * exp(-t * 18.0)
		var floor_resonance = sin(t * 220.0 * pitch_mult * TAU) * 0.25 * env
		var reverb_tail = (randf() * 2.0 - 1.0) * 0.12 * exp(-t * 10.0)
		
		var sample_val = clampf((heel_click + thud + floor_resonance + reverb_tail) * vol_mult, -1.0, 1.0)
		var pcm = int(sample_val * 26000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

## Pasos pesados y amenazantes del profesor (suela de zapato de vestir con eco 3D)
static func _generate_prof_step() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 0.38
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		# Taconeo seco de zapato formal + golpe sordo grave en losa
		var heel = exp(-t * 120.0) * (randf() * 2.0 - 1.0) * 1.1
		var sole = exp(-t * 45.0) * sin(t * 140.0 * TAU) * 0.65
		var bass_impact = exp(-t * 14.0) * sin(t * 58.0 * TAU) * 0.8
		var hall_reverb = (sin(t * 185.0 * TAU) + sin(t * 310.0 * TAU)) * 0.2 * exp(-t * 8.0)
		
		var sample_val = clampf((heel + sole + bass_impact + hall_reverb) * 1.15, -1.0, 1.0)
		var pcm = int(sample_val * 30000.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

## Latido de corazón sordo y visceral ("lub-dub")
static func _generate_heartbeat() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	
	var length_sec = 0.55
	var samples_count = int(22050 * length_sec)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / 22050.0
		# Primer latido (lub) en t=0.0s, segundo latido (dub) en t=0.18s
		var beat1_env = exp(-t * 16.0) if t >= 0.0 else 0.0
		var beat1 = sin(t * 52.0 * TAU) * beat1_env * 0.95
		
		var t2 = t - 0.18
		var beat2_env = exp(-t2 * 14.0) if t2 >= 0.0 else 0.0
		var beat2 = sin(maxf(0.0, t2) * 62.0 * TAU) * beat2_env * 0.75
		
		var sub_rumble = sin(t * 38.0 * TAU) * 0.3 * exp(-t * 8.0)
		var sample_val = clampf((beat1 + beat2 + sub_rumble) * 1.3, -1.0, 1.0)
		var pcm = int(sample_val * 31000.0)
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

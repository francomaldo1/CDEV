class_name HorrorAudio
extends RefCounted

## Generador de audio procedural para efectos de terror e impacto
## Produce AudioStreamWAV en formato 16-bit PCM sin depender de archivos externos.

static var _cached_spark: AudioStreamWAV = null
static var _cached_slam: AudioStreamWAV = null
static var _cached_stinger: AudioStreamWAV = null

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
		# Golpe inicial fuerte + chispas caóticas + zumbido eléctrico de 60Hz/120Hz
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
		# Golpe seco (transitorio rápido) con resonancia de madera a 180Hz y 90Hz
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
		# Acorde disonante de terror (tritono / clúster agudo y caída de sub-graves)
		var env = exp(-t * 3.5)
		var sub_bass = sin(t * 48.0 * TAU) * 0.7 * exp(-t * 2.0)
		var disharmony = (sin(t * 440.0 * TAU) + sin(t * 466.16 * TAU) + sin(t * 622.25 * TAU) + sin(t * 880.0 * TAU)) * 0.22
		var screech_noise = (randf() * 2.0 - 1.0) * 0.15 * exp(-t * 6.0)
		var sample_val = clampf((sub_bass + disharmony * env + screech_noise) * 1.2, -1.0, 1.0)
		var pcm = int(sample_val * 31500.0)
		data.encode_s16(i * 2, pcm)
		
	wav.data = data
	return wav

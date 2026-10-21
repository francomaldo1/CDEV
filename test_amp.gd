extends SceneTree
func _init():
	var s = load("res://audio/sfx/jumpscare_sound_effect.mp3") as AudioStreamMP3
	var playback = s.instantiate_playback()
	var buf = PackedVector2Array()
	buf.resize(44100)
	var frames = playback.mix(buf.to_byte_array(), 1.0, 44100)
	print("Mixed frames: ", frames)
	# Check max amplitude in buffer
	var max_amp = 0.0
	for f in buf:
		max_amp = max(max_amp, abs(f.x), abs(f.y))
	print("Max amplitude in first second: ", max_amp)
	quit()

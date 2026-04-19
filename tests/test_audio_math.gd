extends RefCounted

const AudioMathScript = preload("res://scripts/audio/audio_math.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	assertions += 1
	if AudioMathScript.gain_to_db(0.0) != -60.0:
		failures.append("muted gain should clamp to -60 dB")

	assertions += 1
	if absf(AudioMathScript.midi_to_frequency(69) - 440.0) > 0.001:
		failures.append("MIDI note 69 should resolve to concert A")

	assertions += 1
	if absf(AudioMathScript.sine_wave(0.25) - 1.0) > 0.001:
		failures.append("quarter-cycle sine should peak at 1")

	assertions += 1
	if absf(AudioMathScript.triangle_wave(0.25)) > 0.001:
		failures.append("triangle wave should cross zero at quarter-cycle")

	assertions += 1
	if AudioMathScript.square_wave(0.75) != -1.0:
		failures.append("square wave should flip negative on the back half-cycle")

	assertions += 1
	var pattern: Array[float] = AudioMathScript.build_rhythm_pattern(rng, 16, 1, 2)
	if pattern.size() != 16:
		failures.append("rhythm patterns should match the requested bar length")

	assertions += 1
	if pattern[1] <= 0.0:
		failures.append("hat patterns should place activity on off-beats")

	return {
		"assertions": assertions,
		"failures": failures,
	}

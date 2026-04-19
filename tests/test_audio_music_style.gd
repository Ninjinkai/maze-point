extends RefCounted

const MusicStyleLibraryScript = preload("res://scripts/audio/audio_music_style_library.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var style = MusicStyleLibraryScript.from_run_seed(7)

	assertions += 1
	if style.style_id != 2:
		failures.append("run-seed style selection should be stable")

	assertions += 1
	if style.steps_per_bar != 12 or style.bars != 9:
		failures.append("style presets should expose their timing settings")

	assertions += 1
	if style.get_pulses_per_beat() != 3.0:
		failures.append("style 2 should use triplet pulses")

	assertions += 1
	var bpm: float = style.pick_bpm(rng)
	if bpm < style.bpm_range.x or bpm > style.bpm_range.y:
		failures.append("picked BPM should stay inside the preset range")

	assertions += 1
	if style.pick_mode(rng).is_empty():
		failures.append("styles should provide selectable melodic modes")

	assertions += 1
	if style.pick_chord_pattern(rng).is_empty():
		failures.append("styles should provide selectable chord patterns")

	return {
		"assertions": assertions,
		"failures": failures,
	}

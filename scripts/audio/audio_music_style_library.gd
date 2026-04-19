extends RefCounted
class_name ProceduralAudioMusicStyleLibrary

const MusicStyleScript = preload("res://scripts/audio/audio_music_style.gd")

const STYLE_PRESETS: Array[Dictionary] = [
	{"bpm_range": Vector2(88.0, 102.0), "steps_per_bar": 16, "bars": 8, "root_range": Vector2i(41, 49), "modes": [[0, 2, 4, 7, 9, 11], [0, 4, 7, 9, 11, 14], [0, 2, 5, 7, 9, 12]], "chords": [[0, 5, 3, 4], [0, 3, 5, 2], [0, 4, 1, 5]], "rest_chance": 0.14, "accent_jump_chance": 0.1, "bass_offset": 0},
	{"bpm_range": Vector2(96.0, 112.0), "steps_per_bar": 16, "bars": 8, "root_range": Vector2i(46, 54), "modes": [[0, 3, 5, 7, 10, 12], [0, 2, 3, 7, 8, 10], [0, 3, 5, 8, 10, 12]], "chords": [[0, 6, 5, 3], [0, 3, 1, 4], [0, 5, 4, 2]], "rest_chance": 0.08, "accent_jump_chance": 0.2, "bass_offset": 0},
	{"bpm_range": Vector2(104.0, 118.0), "steps_per_bar": 12, "bars": 9, "root_range": Vector2i(48, 57), "modes": [[0, 2, 5, 7, 9, 12], [0, 4, 7, 9, 12, 14], [0, 2, 4, 7, 11, 14]], "chords": [[0, 4, 5, 3], [0, 2, 5, 4], [0, 5, 1, 4]], "rest_chance": 0.18, "accent_jump_chance": 0.12, "bass_offset": 5},
	{"bpm_range": Vector2(90.0, 106.0), "steps_per_bar": 16, "bars": 7, "root_range": Vector2i(38, 45), "modes": [[0, 1, 5, 7, 8, 12], [0, 3, 5, 6, 10, 12], [0, 2, 5, 7, 8, 11]], "chords": [[0, 1, 5, 4], [0, 3, 2, 6], [0, 4, 1, 3]], "rest_chance": 0.16, "accent_jump_chance": 0.08, "bass_offset": -5},
	{"bpm_range": Vector2(110.0, 126.0), "steps_per_bar": 8, "bars": 10, "root_range": Vector2i(50, 58), "modes": [[0, 2, 4, 7, 9, 12], [0, 2, 5, 7, 10, 12], [0, 4, 7, 9, 11, 12]], "chords": [[0, 4, 1, 5], [0, 5, 3, 4], [0, 2, 4, 5]], "rest_chance": 0.1, "accent_jump_chance": 0.16, "bass_offset": 3},
]


static func from_run_seed(run_seed: int):
	var preset_index: int = int(abs(run_seed) % STYLE_PRESETS.size())
	var preset: Dictionary = STYLE_PRESETS[preset_index]
	return MusicStyleScript.new(
		preset_index,
		preset["bpm_range"],
		int(preset["steps_per_bar"]),
		int(preset["bars"]),
		preset["root_range"],
		preset["modes"],
		preset["chords"],
		float(preset["rest_chance"]),
		float(preset["accent_jump_chance"]),
		int(preset["bass_offset"])
	)

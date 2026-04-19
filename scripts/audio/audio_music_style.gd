extends RefCounted
class_name ProceduralAudioMusicStyle

var style_id: int
var bpm_range: Vector2
var steps_per_bar: int
var bars: int
var root_range: Vector2i
var modes: Array
var chords: Array
var rest_chance: float
var accent_jump_chance: float
var bass_offset: int


func _init(
	in_style_id: int,
	in_bpm_range: Vector2,
	in_steps_per_bar: int,
	in_bars: int,
	in_root_range: Vector2i,
	in_modes: Array,
	in_chords: Array,
	in_rest_chance: float,
	in_accent_jump_chance: float,
	in_bass_offset: int
) -> void:
	style_id = in_style_id
	bpm_range = in_bpm_range
	steps_per_bar = in_steps_per_bar
	bars = in_bars
	root_range = in_root_range
	modes = in_modes
	chords = in_chords
	rest_chance = in_rest_chance
	accent_jump_chance = in_accent_jump_chance
	bass_offset = in_bass_offset


func pick_bpm(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(bpm_range.x, bpm_range.y)


func pick_root_note(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(root_range.x, root_range.y)


func pick_mode(rng: RandomNumberGenerator) -> Array:
	return modes[rng.randi_range(0, modes.size() - 1)]


func pick_chord_pattern(rng: RandomNumberGenerator) -> Array:
	return chords[rng.randi_range(0, chords.size() - 1)]


func get_pulses_per_beat() -> float:
	return 3.0 if style_id == 2 else 4.0

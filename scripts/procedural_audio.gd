extends Node
class_name ProceduralAudio

const SAMPLE_RATE := 22050
const SFX_POOL_SIZE := 6
const AudioMathScript = preload("res://scripts/audio/audio_math.gd")
const AudioStreamFactoryScript = preload("res://scripts/audio/audio_stream_factory.gd")

var audio_enabled: bool = true
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var cached_sfx: Dictionary = {}
var current_music_signature: String = ""
var music_target_volume_db: float = -8.5
var music_target_pitch_scale: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	audio_enabled = DisplayServer.get_name() != "headless"
	if not audio_enabled:
		return
	_build_players()
	_build_sfx_cache()


func _exit_tree() -> void:
	if music_player != null:
		music_player.stop()
		music_player.stream = null

	for player in sfx_players:
		player.stop()
		player.stream = null

	cached_sfx.clear()
	sfx_players.clear()
	current_music_signature = ""


func _process(delta: float) -> void:
	if not audio_enabled or music_player == null:
		return
	if not music_player.playing and music_player.stream != null:
		music_player.play()
	music_player.volume_db = lerpf(music_player.volume_db, music_target_volume_db + AudioMathScript.gain_to_db(music_volume), clampf(delta * 3.2, 0.0, 1.0))
	music_player.pitch_scale = lerpf(music_player.pitch_scale, music_target_pitch_scale, clampf(delta * 2.4, 0.0, 1.0))


func start_run_music(run_seed: int) -> void:
	if not audio_enabled:
		return
	_update_music_stream(run_seed)

func sync_music_state(level: int, retries: int, player_total: int, goal_target: int, is_splash: bool, is_complete: bool) -> void:
	if not audio_enabled or music_player == null:
		return
	var target_value: float = maxf(float(goal_target), 1.0)
	var distance_ratio: float = absf(float(goal_target - player_total)) / target_value
	var closeness: float = 1.0 - clampf(distance_ratio, 0.0, 1.0)
	var level_energy: float = clampf(float(level - 1) / 12.0, 0.0, 1.0)
	var retry_energy: float = minf(float(retries) * 0.06, 0.18)
	if is_complete:
		music_target_pitch_scale = 1.02 + closeness * 0.05
		music_target_volume_db = -7.0 + closeness * 1.3
		return
	if is_splash:
		music_target_pitch_scale = 0.97
		music_target_volume_db = -9.8
		return
	var overshoot_energy: float = 0.04 if goal_target > 0 and player_total > goal_target else 0.0
	music_target_pitch_scale = clampf(0.97 + level_energy * 0.06 + closeness * 0.03 + retry_energy + overshoot_energy, 0.95, 1.1)
	music_target_volume_db = lerpf(-8.8, -5.6, closeness * 0.55 + level_energy * 0.35) + retry_energy * 2.6


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)


func get_music_volume() -> float:
	return music_volume


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)


func get_sfx_volume() -> float:
	return sfx_volume


func play_move() -> void:
	_play_sfx("move")

func play_success() -> void:
	_play_sfx("success")


func play_failure() -> void:
	_play_sfx("failure")


func play_menu_move() -> void:
	_play_sfx("menu_move")


func play_menu_confirm() -> void:
	_play_sfx("menu_confirm")


func play_restart() -> void:
	_play_sfx("restart")


func play_player_entry() -> void:
	_play_sfx("player_entry")


func play_invert() -> void:
	_play_sfx("invert")


func _build_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "ProceduralMusic"
	music_player.volume_db = -15.0
	music_player.finished.connect(_restart_music_loop)
	add_child(music_player)

	for index in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % index
		player.volume_db = -8.0
		add_child(player)
		sfx_players.append(player)


func _build_sfx_cache() -> void:
	cached_sfx["move"] = _build_move_stream()
	cached_sfx["success"] = _build_success_stream()
	cached_sfx["failure"] = _build_failure_stream()
	cached_sfx["menu_move"] = _build_menu_move_stream()
	cached_sfx["menu_confirm"] = _build_menu_confirm_stream()
	cached_sfx["restart"] = _build_restart_stream()
	cached_sfx["player_entry"] = _build_player_entry_stream()
	cached_sfx["invert"] = _build_invert_stream()


func _play_sfx(key: String) -> void:
	if not audio_enabled:
		return
	if not cached_sfx.has(key):
		return
	var player: AudioStreamPlayer = _get_available_sfx_player()
	player.volume_db = -5.0 + AudioMathScript.gain_to_db(sfx_volume)
	player.stream = cached_sfx[key]
	player.play()


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]


func _restart_music_loop() -> void:
	if music_player.stream == null:
		return
	music_player.play()


func _update_music_stream(run_seed: int) -> void:
	var signature: String = "run:%d" % run_seed
	if signature == current_music_signature:
		return

	current_music_signature = signature
	music_player.stream = _build_music_stream(run_seed)
	music_player.volume_db = music_target_volume_db + AudioMathScript.gain_to_db(music_volume)
	music_player.pitch_scale = music_target_pitch_scale
	music_player.play()


func _build_music_stream(run_seed: int) -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = maxi(run_seed, 1)
	var style_id: int = int(abs(run_seed) % 5)
	var bpm_ranges: Array = [[88.0, 102.0], [96.0, 112.0], [104.0, 118.0], [90.0, 106.0], [110.0, 126.0]]
	var steps_per_bar_options: Array[int] = [16, 16, 12, 16, 8]
	var bar_options: Array[int] = [8, 8, 9, 7, 10]
	var root_ranges: Array = [[41, 49], [46, 54], [48, 57], [38, 45], [50, 58]]
	var mode_options: Array = [
		[[0, 2, 4, 7, 9, 11], [0, 4, 7, 9, 11, 14], [0, 2, 5, 7, 9, 12]],
		[[0, 3, 5, 7, 10, 12], [0, 2, 3, 7, 8, 10], [0, 3, 5, 8, 10, 12]],
		[[0, 2, 5, 7, 9, 12], [0, 4, 7, 9, 12, 14], [0, 2, 4, 7, 11, 14]],
		[[0, 1, 5, 7, 8, 12], [0, 3, 5, 6, 10, 12], [0, 2, 5, 7, 8, 11]],
		[[0, 2, 4, 7, 9, 12], [0, 2, 5, 7, 10, 12], [0, 4, 7, 9, 11, 12]],
	]
	var chord_options: Array = [
		[[0, 5, 3, 4], [0, 3, 5, 2], [0, 4, 1, 5]],
		[[0, 6, 5, 3], [0, 3, 1, 4], [0, 5, 4, 2]],
		[[0, 4, 5, 3], [0, 2, 5, 4], [0, 5, 1, 4]],
		[[0, 1, 5, 4], [0, 3, 2, 6], [0, 4, 1, 3]],
		[[0, 4, 1, 5], [0, 5, 3, 4], [0, 2, 4, 5]],
	]
	var bpm_range: Array = bpm_ranges[style_id]
	var bpm: float = rng.randf_range(float(bpm_range[0]), float(bpm_range[1]))
	var steps_per_bar: int = steps_per_bar_options[style_id]
	var bars: int = bar_options[style_id]
	var pulses_per_beat: float = 3.0 if style_id == 2 else 4.0
	var step_duration: float = 60.0 / bpm / pulses_per_beat
	var total_duration: float = step_duration * float(steps_per_bar * bars)
	var total_frames: int = maxi(1, int(round(total_duration * SAMPLE_RATE)))
	var root_range: Array = root_ranges[style_id]
	var root_note: int = rng.randi_range(int(root_range[0]), int(root_range[1]))
	var mode_choices: Array = mode_options[style_id]
	var chord_choices: Array = chord_options[style_id]
	var mode: Array = mode_choices[rng.randi_range(0, mode_choices.size() - 1)]
	var chord_pattern: Array = chord_choices[rng.randi_range(0, chord_choices.size() - 1)]
	var lead_pattern: Array[int] = []
	var bass_pattern: Array[int] = []
	var counter_pattern: Array[int] = []
	var total_steps: int = steps_per_bar * bars
	var rest_chance: float = [0.14, 0.08, 0.18, 0.16, 0.1][style_id]
	var accent_jump_chance: float = [0.1, 0.2, 0.12, 0.08, 0.16][style_id]
	for index in range(total_steps):
		var chord_span: int = 4 if steps_per_bar >= 16 else 3
		var chord_offset: int = int(chord_pattern[int(floor(float(index % steps_per_bar) / chord_span)) % chord_pattern.size()])
		var melodic_pick: int = int(mode[rng.randi_range(0, mode.size() - 1)])
		var lead_offset: int = chord_offset + melodic_pick
		if index % steps_per_bar == 0:
			lead_offset += 12
		elif rng.randf() < accent_jump_chance:
			lead_offset += 7
		if rng.randf() < rest_chance and index % steps_per_bar != 0:
			lead_pattern.append(-1000)
		else:
			lead_pattern.append(lead_offset)
		if index % 2 == 0:
			bass_pattern.append(chord_offset - 12 + ([0, 0, 5, -5, 3][style_id]))
		if index % 2 == (0 if style_id != 3 else 1):
			counter_pattern.append(chord_offset + int(mode[(index + 2) % mode.size()]) + (12 if style_id == 1 else 0))
		else:
			counter_pattern.append(-1000)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	var syncopation: float = 0.03 + rng.randf() * 0.08
	var shimmer_rate: float = 1.1 + rng.randf() * 2.4
	var hat_seed: int = rng.randi()
	var kick_pattern: Array[float] = AudioMathScript.build_rhythm_pattern(rng, steps_per_bar, style_id, 0)
	var clap_pattern: Array[float] = AudioMathScript.build_rhythm_pattern(rng, steps_per_bar, style_id, 1)
	var hat_pattern: Array[float] = AudioMathScript.build_rhythm_pattern(rng, steps_per_bar, style_id, 2)
	var sub_pattern: Array[float] = AudioMathScript.build_rhythm_pattern(rng, steps_per_bar, style_id, 3)

	for frame in range(total_frames):
		var time: float = float(frame) / SAMPLE_RATE
		var step_position: float = time / step_duration
		var step_index: int = int(floor(step_position)) % total_steps
		var step_progress: float = fposmod(step_position, 1.0)
		var bar_progress: float = float(step_index / steps_per_bar) / float(maxi(bars - 1, 1))
		var section_lift: float = 0.86 + 0.22 * sin(bar_progress * PI)
		var bar_index: int = int(floor(float(step_index % steps_per_bar) / (4 if steps_per_bar >= 16 else 3))) % chord_pattern.size()
		var lead_note_value: int = lead_pattern[step_index]
		var counter_note_value: int = counter_pattern[step_index]
		var lead_note: float = AudioMathScript.midi_to_frequency(root_note + maxi(lead_note_value, 0))
		var bass_note: float = AudioMathScript.midi_to_frequency(root_note + bass_pattern[int(floor(float(step_index) / 2.0)) % bass_pattern.size()])
		var counter_note: float = AudioMathScript.midi_to_frequency(root_note + maxi(counter_note_value, 0))
		var pad_root: float = AudioMathScript.midi_to_frequency(root_note + int(chord_pattern[bar_index]))
		var pad_third: float = AudioMathScript.midi_to_frequency(root_note + int(chord_pattern[bar_index]) + int(mode[(bar_index + 2) % mode.size()]))
		var kick_phase: float = step_progress
		var clap_phase: float = step_progress
		var hat_phase: float = step_progress

		var lead_env: float = pow(1.0 - step_progress, 1.3) * section_lift
		var counter_env: float = pow(1.0 - step_progress, 1.9) * (0.72 + 0.28 * bar_progress)
		var bass_env: float = 0.72 + 0.24 * sin(TAU * (time / (step_duration * 8.0)))
		var pad_env: float = 0.4 + 0.34 * sin(TAU * (time / (step_duration * (8.0 + float(style_id)))))
		var kick_env: float = pow(maxf(1.0 - kick_phase * 2.4, 0.0), 2.8) * kick_pattern[step_index % steps_per_bar]
		var clap_env: float = pow(maxf(1.0 - clap_phase * 3.8, 0.0), 3.0) * clap_pattern[step_index % steps_per_bar]
		var hat_env: float = pow(maxf(1.0 - hat_phase * 5.0, 0.0), 2.2) * hat_pattern[step_index % steps_per_bar]
		var sub_env: float = sub_pattern[step_index % steps_per_bar] * (0.4 + 0.3 * sin(TAU * bar_progress))

		var lead_sample: float = 0.0
		if lead_note_value > -1000:
			match style_id:
				0:
					lead_sample = (AudioMathScript.triangle_wave(time * lead_note) * 0.62 + AudioMathScript.square_wave(time * lead_note * 0.5) * syncopation + AudioMathScript.sine_wave(time * lead_note * 2.0) * 0.1) * lead_env
				1:
					lead_sample = (AudioMathScript.square_wave(time * lead_note) * 0.32 + AudioMathScript.triangle_wave(time * lead_note * 0.5) * 0.34 + AudioMathScript.sine_wave(time * lead_note * 1.5) * 0.18) * lead_env
				2:
					lead_sample = (AudioMathScript.triangle_wave(time * lead_note) * 0.54 + AudioMathScript.sine_wave(time * lead_note * 2.0) * 0.2 + AudioMathScript.noise_like_sample(time, 3) * 0.02) * lead_env
				3:
					lead_sample = (AudioMathScript.sine_wave(time * lead_note) * 0.46 + AudioMathScript.triangle_wave(time * lead_note * 0.5) * 0.34 + AudioMathScript.square_wave(time * lead_note * 0.25) * 0.08) * lead_env
				_:
					lead_sample = (AudioMathScript.triangle_wave(time * lead_note) * 0.5 + AudioMathScript.sine_wave(time * lead_note * 1.5) * 0.26 + AudioMathScript.square_wave(time * lead_note * 0.25) * 0.08) * lead_env

		var counter_sample: float = 0.0
		if counter_note_value > -1000:
			counter_sample = (AudioMathScript.sine_wave(time * counter_note) * 0.52 + AudioMathScript.triangle_wave(time * counter_note * 0.5) * 0.2) * counter_env

		var bass_sample: float = (AudioMathScript.sine_wave(time * bass_note) * 0.78 + AudioMathScript.triangle_wave(time * bass_note * 0.5) * 0.12) * bass_env
		var pad_sample: float = (AudioMathScript.sine_wave(time * pad_root) * 0.42 + AudioMathScript.triangle_wave(time * pad_third) * 0.25 + AudioMathScript.sine_wave(time * pad_root * 0.5) * 0.16) * pad_env
		var kick_sample: float = AudioMathScript.sine_wave(time * lerpf(52.0, 28.0, kick_phase)) * kick_env
		var clap_sample: float = (AudioMathScript.noise_like_sample(time, 5) * 0.64 + AudioMathScript.triangle_wave(time * 1040.0) * 0.06) * clap_env
		var hat_sample: float = (AudioMathScript.noise_like_sample(time, hat_seed) * 0.48 + AudioMathScript.square_wave(time * 2880.0) * 0.04) * hat_env
		var sparkle_sample: float = AudioMathScript.sine_wave(time * (lead_note * (1.4 + 0.3 * sin(time * shimmer_rate)))) * lead_env * 0.11
		var sub_sample: float = AudioMathScript.sine_wave(time * (bass_note * 0.5)) * sub_env

		var mix: float = lead_sample * 0.25 + counter_sample * 0.1 + bass_sample * 0.22 + pad_sample * 0.19 + kick_sample * 0.13 + clap_sample * 0.04 + hat_sample * 0.025 + sparkle_sample * 0.65 + sub_sample * 0.075

		data.encode_s16(frame * 2, int(round(clampf(mix * 0.8, -1.0, 1.0) * 32767.0)))

	return AudioStreamFactoryScript.make_wav_stream(data, true, total_frames)


func _build_move_stream() -> AudioStreamWAV:
	var duration: float = 0.08
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 2.2)
		var freq: float = lerpf(520.0, 760.0, progress)
		var sample: float = AudioMathScript.triangle_wave(time * freq) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.55, -1.0, 1.0) * 32767.0)))
	return AudioStreamFactoryScript.make_wav_stream(data)


func _build_success_stream() -> AudioStreamWAV:
	var duration: float = 0.62
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var segment: int = mini(int(floor(progress * 4.0)), 3)
		var local_progress: float = fposmod(progress * 4.0, 1.0)
		var env: float = pow(1.0 - local_progress, 1.7)
		var note: float = notes[segment]
		var sample: float = (AudioMathScript.triangle_wave(time * note) * 0.52 + AudioMathScript.sine_wave(time * note * 1.5) * 0.28 + AudioMathScript.sine_wave(time * note * 2.0) * 0.12) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.74, -1.0, 1.0) * 32767.0)))
	return AudioStreamFactoryScript.make_wav_stream(data)


func _build_failure_stream() -> AudioStreamWAV:
	var duration: float = 0.44
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 1.1)
		var freq: float = lerpf(310.0, 118.0, progress)
		var wobble: float = 1.0 + sin(TAU * time * 8.0) * 0.05
		var sample: float = (AudioMathScript.square_wave(time * freq * wobble) * 0.36 + AudioMathScript.triangle_wave(time * freq * 0.5) * 0.26 + AudioMathScript.noise_like_sample(time, 9) * 0.07) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.8, -1.0, 1.0) * 32767.0)))
	return AudioStreamFactoryScript.make_wav_stream(data)


func _build_menu_move_stream() -> AudioStreamWAV:
	var duration: float = 0.05
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 2.6)
		var sample: float = AudioMathScript.triangle_wave(time * 920.0) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.38, -1.0, 1.0) * 32767.0)))
	return AudioStreamFactoryScript.make_wav_stream(data)


func _build_menu_confirm_stream() -> AudioStreamWAV:
	var duration: float = 0.12
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var freq: float = 520.0 if progress < 0.45 else 780.0
		var env: float = pow(1.0 - progress, 2.0)
		var sample: float = (AudioMathScript.triangle_wave(time * freq) * 0.68 + AudioMathScript.sine_wave(time * freq * 1.5) * 0.32) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.55, -1.0, 1.0) * 32767.0)))
	return AudioStreamFactoryScript.make_wav_stream(data)


func _build_restart_stream() -> AudioStreamWAV:
	var duration: float = 0.18
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 1.5)
		var freq: float = lerpf(260.0, 520.0, progress)
		var sample: float = (AudioMathScript.sine_wave(time * freq) * 0.55 + AudioMathScript.triangle_wave(time * freq * 0.5) * 0.45) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.52, -1.0, 1.0) * 32767.0)))
	return AudioStreamFactoryScript.make_wav_stream(data)


func _build_player_entry_stream() -> AudioStreamWAV:
	var duration: float = 0.46
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var primary_env: float = sin(clampf(progress / 0.74, 0.0, 1.0) * PI)
		primary_env *= primary_env
		var bounce_env: float = sin(clampf((progress - 0.36) / 0.48, 0.0, 1.0) * PI)
		bounce_env *= bounce_env
		var env: float = primary_env * 0.82 + bounce_env * 0.42
		var freq: float = lerpf(170.0, 760.0, pow(progress, 0.68))
		var bounce_freq: float = lerpf(360.0, 540.0, clampf((progress - 0.34) / 0.52, 0.0, 1.0))
		var shimmer: float = AudioMathScript.sine_wave(time * freq * 1.5) * 0.14
		var bounce_layer: float = (AudioMathScript.triangle_wave(time * bounce_freq) * 0.3 + AudioMathScript.sine_wave(time * bounce_freq * 0.5) * 0.14) * bounce_env
		var sample: float = (AudioMathScript.triangle_wave(time * freq) * 0.48 + AudioMathScript.sine_wave(time * freq * 0.5) * 0.2 + shimmer + bounce_layer) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.72, -1.0, 1.0) * 32767.0)))
	return AudioStreamFactoryScript.make_wav_stream(data)


func _build_invert_stream() -> AudioStreamWAV:
	var duration: float = 0.16
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 1.9)
		var freq: float = 420.0 if progress < 0.5 else 260.0
		var sample: float = (AudioMathScript.triangle_wave(time * freq) * 0.5 + AudioMathScript.square_wave(time * freq * 1.25) * 0.2) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.48, -1.0, 1.0) * 32767.0)))
	return AudioStreamFactoryScript.make_wav_stream(data)

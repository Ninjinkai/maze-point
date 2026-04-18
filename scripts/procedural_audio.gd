extends Node
class_name ProceduralAudio

const SAMPLE_RATE := 22050
const SFX_POOL_SIZE := 6

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var cached_sfx: Dictionary = {}
var current_music_signature: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_players()
	_build_sfx_cache()
	update_level_music(1, 1)


func update_level_music(level: int, level_seed: int) -> void:
	_update_music_stream(level, level_seed)


func play_move() -> void:
	_play_sfx("move")


func play_bonus(bonus_value: int) -> void:
	_play_sfx("bonus_bad" if bonus_value > 0 else "bonus_good")


func play_goal() -> void:
	_play_sfx("goal")


func play_timeout() -> void:
	_play_sfx("timeout")


func play_menu_move() -> void:
	_play_sfx("menu_move")


func play_menu_confirm() -> void:
	_play_sfx("menu_confirm")


func play_restart() -> void:
	_play_sfx("restart")


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
	cached_sfx["bonus_good"] = _build_bonus_good_stream()
	cached_sfx["bonus_bad"] = _build_bonus_bad_stream()
	cached_sfx["goal"] = _build_goal_stream()
	cached_sfx["timeout"] = _build_timeout_stream()
	cached_sfx["menu_move"] = _build_menu_move_stream()
	cached_sfx["menu_confirm"] = _build_menu_confirm_stream()
	cached_sfx["restart"] = _build_restart_stream()
	cached_sfx["invert"] = _build_invert_stream()


func _play_sfx(key: String) -> void:
	if not cached_sfx.has(key):
		return
	var player: AudioStreamPlayer = _get_available_sfx_player()
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


func _update_music_stream(level: int, level_seed: int) -> void:
	var signature: String = "%d:%d" % [level, level_seed]
	if signature == current_music_signature:
		return

	current_music_signature = signature
	music_player.stream = _build_music_stream(level, level_seed)
	music_player.play()


func _build_music_stream(level: int, level_seed: int) -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = maxi(level_seed, 1)
	var bpm: float = 92.0 + float((level_seed % 19)) + float(mini(level - 1, 6)) * 2.0
	var steps_per_bar: int = 16
	var bars: int = 2 + int(level_seed % 2)
	var step_duration: float = 60.0 / bpm / 4.0
	var total_duration: float = step_duration * float(steps_per_bar * bars)
	var total_frames: int = maxi(1, int(round(total_duration * SAMPLE_RATE)))
	var root_note: int = 46 + int(level_seed % 9)
	var mode_options: Array = [
		[0, 2, 4, 7, 9, 11],
		[0, 3, 5, 7, 10, 12],
		[0, 2, 5, 7, 9, 12],
	]
	var chord_options: Array = [
		[0, 5, 3, 4],
		[0, 3, 5, 2],
		[0, 4, 1, 5],
	]
	var mode: Array = mode_options[int(level_seed % mode_options.size())]
	var chord_pattern: Array = chord_options[int((level_seed / 3) % chord_options.size())]
	var lead_pattern: Array[int] = []
	var bass_pattern: Array[int] = []
	for index in range(steps_per_bar * bars):
		var chord_offset: int = int(chord_pattern[int(floor(float(index) / 4.0)) % chord_pattern.size()])
		var lead_offset: int = int(mode[rng.randi_range(0, mode.size() - 1)]) + chord_offset
		if index % 4 == 0:
			lead_offset += 12
		elif index % 4 == 2 and rng.randf() < 0.5:
			lead_offset += 7
		lead_pattern.append(lead_offset)
		if index % 2 == 0:
			bass_pattern.append(chord_offset - 12)
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	var syncopation: float = 0.08 + rng.randf() * 0.07
	var shimmer_rate: float = 2.0 + rng.randf() * 3.0

	for frame in range(total_frames):
		var time: float = float(frame) / SAMPLE_RATE
		var step_position: float = time / step_duration
		var step_index: int = int(floor(step_position)) % (steps_per_bar * bars)
		var step_progress: float = fposmod(step_position, 1.0)
		var bar_index: int = int(floor(float(step_index) / 4.0)) % chord_pattern.size()
		var lead_note: float = _midi_to_frequency(root_note + lead_pattern[step_index])
		var bass_note: float = _midi_to_frequency(root_note + bass_pattern[int(floor(float(step_index) / 2.0)) % bass_pattern.size()])
		var pad_note: float = _midi_to_frequency(root_note + int(chord_pattern[bar_index]) + 7)
		var kick_phase: float = fposmod(time / (step_duration * 2.0), 1.0)
		var clap_phase: float = fposmod((time + step_duration * 0.9) / (step_duration * 4.0), 1.0)

		var lead_env: float = pow(1.0 - step_progress, 1.5)
		var bass_env: float = 0.72 + 0.28 * sin(TAU * (time / (step_duration * 8.0)))
		var pad_env: float = 0.48 + 0.32 * sin(TAU * (time / (step_duration * 12.0)))
		var kick_env: float = pow(maxf(1.0 - kick_phase * 2.2, 0.0), 2.4)
		var clap_env: float = pow(maxf(1.0 - clap_phase * 4.0, 0.0), 3.0)

		var lead_sample: float = (_triangle_wave(time * lead_note) * 0.72 + _square_wave(time * lead_note * 0.5) * syncopation) * lead_env
		var bass_sample: float = _sine_wave(time * bass_note) * bass_env
		var pad_sample: float = (_sine_wave(time * pad_note) * 0.7 + _triangle_wave(time * pad_note * 0.5) * 0.3) * pad_env
		var kick_sample: float = _sine_wave(time * lerpf(48.0, 26.0, kick_phase)) * kick_env
		var clap_sample: float = _noise_like_sample(time, 5) * clap_env
		var sparkle_sample: float = _sine_wave(time * (lead_note * (1.5 + 0.2 * sin(time * shimmer_rate)))) * lead_env * 0.12

		var mix: float = lead_sample * 0.27 + bass_sample * 0.22 + pad_sample * 0.16 + kick_sample * 0.18 + clap_sample * 0.07 + sparkle_sample

		data.encode_s16(frame * 2, int(round(clampf(mix * 0.8, -1.0, 1.0) * 32767.0)))

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.data = data
	return stream


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
		var sample: float = _triangle_wave(time * freq) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.55, -1.0, 1.0) * 32767.0)))
	return _make_wav_stream(data)


func _build_bonus_good_stream() -> AudioStreamWAV:
	var duration: float = 0.2
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 1.7)
		var local_freq: float = 420.0 if progress < 0.5 else 680.0
		var harmony: float = 560.0 if progress < 0.5 else 920.0
		var sample: float = (_triangle_wave(time * local_freq) * 0.65 + _sine_wave(time * harmony) * 0.35) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.62, -1.0, 1.0) * 32767.0)))
	return _make_wav_stream(data)


func _build_bonus_bad_stream() -> AudioStreamWAV:
	var duration: float = 0.22
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 1.5)
		var freq: float = lerpf(340.0, 160.0, progress)
		var sample: float = (_square_wave(time * freq) * 0.6 + _sine_wave(time * (freq * 0.5)) * 0.4) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.58, -1.0, 1.0) * 32767.0)))
	return _make_wav_stream(data)


func _build_goal_stream() -> AudioStreamWAV:
	var duration: float = 0.48
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	var notes: Array[float] = [523.25, 659.25, 783.99]
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var note_index: int = mini(int(floor(progress * 3.0)), 2)
		var local_progress: float = fposmod(progress * 3.0, 1.0)
		var env: float = pow(1.0 - local_progress, 1.8)
		var sample: float = (_triangle_wave(time * notes[note_index]) * 0.6 + _sine_wave(time * notes[note_index] * 1.5) * 0.4) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.7, -1.0, 1.0) * 32767.0)))
	return _make_wav_stream(data)


func _build_timeout_stream() -> AudioStreamWAV:
	var duration: float = 0.56
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 0.9)
		var freq: float = lerpf(280.0, 72.0, progress)
		var wobble: float = sin(TAU * time * 7.0) * 0.03
		var sample: float = (_square_wave(time * freq * (1.0 + wobble)) * 0.55 + _sine_wave(time * freq * 0.5) * 0.45) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.72, -1.0, 1.0) * 32767.0)))
	return _make_wav_stream(data)


func _build_menu_move_stream() -> AudioStreamWAV:
	var duration: float = 0.05
	var total_frames: int = int(round(duration * SAMPLE_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(total_frames * 2)
	for frame in range(total_frames):
		var progress: float = float(frame) / float(maxi(total_frames - 1, 1))
		var time: float = float(frame) / SAMPLE_RATE
		var env: float = pow(1.0 - progress, 2.6)
		var sample: float = _triangle_wave(time * 920.0) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.38, -1.0, 1.0) * 32767.0)))
	return _make_wav_stream(data)


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
		var sample: float = (_triangle_wave(time * freq) * 0.68 + _sine_wave(time * freq * 1.5) * 0.32) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.55, -1.0, 1.0) * 32767.0)))
	return _make_wav_stream(data)


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
		var sample: float = (_sine_wave(time * freq) * 0.55 + _triangle_wave(time * freq * 0.5) * 0.45) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.52, -1.0, 1.0) * 32767.0)))
	return _make_wav_stream(data)


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
		var sample: float = (_triangle_wave(time * freq) * 0.5 + _square_wave(time * freq * 1.25) * 0.2) * env
		data.encode_s16(frame * 2, int(round(clampf(sample * 0.48, -1.0, 1.0) * 32767.0)))
	return _make_wav_stream(data)


func _make_wav_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.data = data
	return stream


func _midi_to_frequency(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)


func _sine_wave(phase: float) -> float:
	return sin(TAU * phase)


func _triangle_wave(phase: float) -> float:
	var cycle: float = phase - floor(phase)
	return 1.0 - 4.0 * absf(cycle - 0.5)


func _square_wave(phase: float) -> float:
	return 1.0 if sin(TAU * phase) >= 0.0 else -1.0


func _noise_like_sample(time: float, seed: int) -> float:
	return sin(time * 913.0 + float(seed) * 1.7) * sin(time * 527.0 + float(seed) * 0.9)

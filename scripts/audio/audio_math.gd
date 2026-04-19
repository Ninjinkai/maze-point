extends RefCounted
class_name ProceduralAudioMath

static func gain_to_db(value: float) -> float:
	if value <= 0.001:
		return -60.0
	return 20.0 * log(value) / log(10.0)


static func midi_to_frequency(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)


static func sine_wave(phase: float) -> float:
	return sin(TAU * phase)


static func triangle_wave(phase: float) -> float:
	var cycle: float = phase - floor(phase)
	return 1.0 - 4.0 * absf(cycle - 0.5)


static func square_wave(phase: float) -> float:
	return 1.0 if sin(TAU * phase) >= 0.0 else -1.0


static func noise_like_sample(time: float, seed: int) -> float:
	return sin(time * 913.0 + float(seed) * 1.7) * sin(time * 527.0 + float(seed) * 0.9)


static func build_rhythm_pattern(rng: RandomNumberGenerator, steps_per_bar: int, style_id: int, channel_id: int) -> Array[float]:
	var pattern: Array[float] = []
	for step in range(steps_per_bar):
		var value: float = 0.0
		match channel_id:
			0:
				value = 1.0 if step == 0 or step == steps_per_bar / 2 else 0.0
				if style_id == 1 and step % 4 == 2:
					value = maxf(value, 0.68)
				elif style_id == 2 and step % 3 == 0:
					value = maxf(value, 0.64)
				elif style_id == 3 and step in [0, steps_per_bar / 2, steps_per_bar - 2]:
					value = maxf(value, 0.76)
			1:
				if style_id == 2:
					value = 0.46 if step % 6 == 3 else 0.0
				else:
					value = 0.5 if step == steps_per_bar / 4 or step == (steps_per_bar * 3) / 4 else 0.0
			2:
				value = 0.12 + rng.randf() * 0.14 if step % 2 == 1 else 0.0
				if style_id == 1 and step % 4 == 3:
					value = maxf(value, 0.28)
				elif style_id == 2 and step % 3 == 2:
					value = maxf(value, 0.3)
			_:
				value = 0.34 if step % (3 if style_id == 2 else 4) == 0 else 0.0
		pattern.append(value)
	return pattern

extends RefCounted

const StreamFactoryScript = preload("res://scripts/audio/audio_stream_factory.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var data := PackedByteArray()
	data.resize(8)
	var stream := StreamFactoryScript.make_wav_stream(data, true, 4)

	assertions += 1
	if stream.mix_rate != 22050:
		failures.append("stream factory should apply the shared sample rate")

	assertions += 1
	if stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		failures.append("looping streams should enable forward looping")

	assertions += 1
	if stream.loop_end != 4:
		failures.append("loop end should be preserved on looping streams")

	assertions += 1
	if stream.data != data:
		failures.append("stream factory should preserve the provided PCM data")

	return {
		"assertions": assertions,
		"failures": failures,
	}

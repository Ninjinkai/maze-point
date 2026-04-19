extends RefCounted
class_name ProceduralAudioStreamFactory

const SAMPLE_RATE := 22050

static func make_wav_stream(data: PackedByteArray, loop: bool = false, loop_end: int = 0) -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = loop_end
	stream.data = data
	return stream

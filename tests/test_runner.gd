extends SceneTree

const TEST_SCRIPTS: Array[Script] = [
	preload("res://tests/test_progression.gd"),
	preload("res://tests/test_input.gd"),
	preload("res://tests/test_generator.gd"),
	preload("res://tests/test_generator_metrics.gd"),
	preload("res://tests/test_localization.gd"),
	preload("res://tests/test_playfield_utils.gd"),
	preload("res://tests/test_audio_math.gd"),
	preload("res://tests/test_audio_music_style.gd"),
	preload("res://tests/test_audio_stream_factory.gd"),
	preload("res://tests/test_ui_styles.gd"),
]


func _init() -> void:
	var total_assertions: int = 0
	var failures: Array[String] = []

	for test_script in TEST_SCRIPTS:
		var test_case = test_script.new()
		var result: Dictionary = test_case.run()
		total_assertions += int(result.get("assertions", 0))
		for failure_variant in result.get("failures", []):
			failures.append(String(failure_variant))

	if failures.is_empty():
		print("All tests passed (%d assertions)." % total_assertions)
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	print("%d assertions run, %d failures." % [total_assertions, failures.size()])
	quit(1)

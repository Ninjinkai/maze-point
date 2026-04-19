extends RefCounted
class_name MazePointPersistence

static func load_settings(save_file_path: String, default_language: String, language_validator: Callable) -> Dictionary:
	var result: Dictionary = {
		"invert_colors_enabled": false,
		"language_code": default_language,
		"music_volume": 1.0,
		"sfx_volume": 1.0,
		"best_run_score": 0,
	}
	var config: ConfigFile = ConfigFile.new()
	if config.load(save_file_path) != OK:
		return result
	result["invert_colors_enabled"] = bool(config.get_value("settings", "invert_colors_enabled", false))
	var language_code: String = String(config.get_value("settings", "language_code", default_language))
	if not language_validator.call(language_code):
		language_code = default_language
	result["language_code"] = language_code
	result["music_volume"] = clampf(float(config.get_value("audio", "music_volume", 1.0)), 0.0, 1.0)
	result["sfx_volume"] = clampf(float(config.get_value("audio", "sfx_volume", 1.0)), 0.0, 1.0)
	result["best_run_score"] = maxi(int(config.get_value("records", "best_run_score", 0)), 0)
	return result


static func save_settings(save_file_path: String, invert_colors_enabled: bool, language_code: String, music_volume: float, sfx_volume: float, best_run_score: int) -> int:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("settings", "invert_colors_enabled", invert_colors_enabled)
	config.set_value("settings", "language_code", language_code)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("records", "best_run_score", best_run_score)
	return config.save(save_file_path)

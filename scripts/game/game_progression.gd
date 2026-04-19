extends RefCounted
class_name MazePointProgression

static func get_level_dimensions(current_level: int, player_skill_rating: float, profiles: Array[Vector2i]) -> Vector2i:
	var stage_progress: float = float(maxi(current_level - 1, 0)) * 0.48 + get_skill_pressure(current_level, player_skill_rating) * 0.55
	var stage_index: int = clampi(int(floor(stage_progress)), 0, profiles.size() - 1)
	return profiles[stage_index]


static func get_level_difficulty_scale(current_level: int, player_skill_rating: float) -> float:
	var level_span: int = maxi(current_level - 1, 0)
	var early_levels: int = mini(level_span, 6)
	var late_levels: int = maxi(level_span - 6, 0)
	return 1.0 + float(early_levels) * 0.08 + float(late_levels) * 0.035 + get_skill_pressure(current_level, player_skill_rating) * 0.12


static func get_skill_pressure(current_level: int, player_skill_rating: float) -> float:
	var taper: float = lerpf(1.35, 0.72, clampf(float(current_level - 1) / 8.0, 0.0, 1.0))
	return clampf(player_skill_rating * taper, 0.0, 1.0)


static func update_skill_rating(current_rating: float, was_successful: bool, optimal_steps: int, player_steps: int, level_retries: int, level: int) -> float:
	var sample: float = 0.0
	if was_successful:
		var path_efficiency: float = clampf(float(optimal_steps) / maxf(float(player_steps), float(optimal_steps)), 0.0, 1.0)
		var retry_penalty: float = minf(float(level_retries) * 0.14, 0.35)
		sample = clampf(path_efficiency - retry_penalty, 0.0, 1.0)
	else:
		sample = maxf(0.0, current_rating - 0.16 - float(level_retries) * 0.03)

	var adapt_rate: float = 0.38 if level <= 4 else 0.18
	return clampf(lerpf(current_rating, sample, adapt_rate), 0.0, 1.0)


static func calculate_star_rating(player_steps: int, optimal_steps: int, difficulty_scale: float) -> int:
	var move_margin: int = maxi(player_steps - optimal_steps, 0)
	if move_margin == 0:
		return 3
	if move_margin <= maxi(2, int(ceili(difficulty_scale))):
		return 2
	return 1


static func calculate_final_run_score(run_total_score: int, run_levels_cleared: int, run_total_resets: int, max_tracked_value: int) -> int:
	return clampi(run_total_score * 120 + run_levels_cleared * 45 - run_total_resets * 18, 0, max_tracked_value)


static func saturating_add(value: int, delta: int, max_tracked_value: int) -> int:
	return clampi(value + delta, 0, max_tracked_value)


static func build_star_string(stars: int) -> String:
	var segments: Array[String] = []
	for index in range(3):
		segments.append("★" if index < stars else "☆")
	return " ".join(segments)


static func get_best_score_text(best_run_score: int, empty_text: String, value_format: String) -> String:
	if best_run_score <= 0:
		return empty_text
	return value_format % best_run_score

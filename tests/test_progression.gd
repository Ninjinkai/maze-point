extends RefCounted

const ProgressionScript = preload("res://scripts/game/game_progression.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0

	assertions += 1
	var profiles: Array[Vector2i] = [Vector2i(4, 4), Vector2i(5, 4), Vector2i(5, 5)]
	if ProgressionScript.get_level_dimensions(1, 0.0, profiles) != Vector2i(4, 4):
		failures.append("level 1 should use the first board profile")

	assertions += 1
	if ProgressionScript.get_level_dimensions(6, 1.0, profiles) != Vector2i(5, 5):
		failures.append("higher pressure levels should advance to later board profiles")

	assertions += 1
	if ProgressionScript.calculate_star_rating(9, 9, 1.0) != 3:
		failures.append("perfect routes should award three stars")

	assertions += 1
	if ProgressionScript.calculate_star_rating(11, 9, 1.2) != 2:
		failures.append("small move overruns should award two stars")

	assertions += 1
	if ProgressionScript.calculate_star_rating(16, 9, 1.2) != 1:
		failures.append("large move overruns should award one star")

	assertions += 1
	if ProgressionScript.calculate_final_run_score(10, 3, 2, 999999) != 1299:
		failures.append("final score formula changed unexpectedly")

	assertions += 1
	if ProgressionScript.saturating_add(999995, 12, 999999) != 999999:
		failures.append("saturating add should clamp to the tracked maximum")

	assertions += 1
	if ProgressionScript.build_star_string(2) != "★ ★ ☆":
		failures.append("star strings should render filled stars first")

	assertions += 1
	if ProgressionScript.get_best_score_text(0, "None", "Best %d") != "None":
		failures.append("empty best-score text should be used when no score exists")

	assertions += 1
	if ProgressionScript.get_best_score_text(42, "None", "Best %d") != "Best 42":
		failures.append("best-score formatting should include the stored score")

	return {
		"assertions": assertions,
		"failures": failures,
	}

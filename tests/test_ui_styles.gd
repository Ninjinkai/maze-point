extends RefCounted

const LocalizationScript = preload("res://scripts/localization_data.gd")
const UiStylesScript = preload("res://scripts/game/game_ui_styles.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var primary_font: FontFile = FontFile.new()
	var multilingual_font: SystemFont = SystemFont.new()

	assertions += 1
	if UiStylesScript.uses_multilingual_font("en"):
		failures.append("English should keep the primary display font")

	for entry_variant in LocalizationScript.get_languages():
		var entry: Dictionary = entry_variant
		var code: String = String(entry.get("code", ""))
		var active_font: Font = UiStylesScript.get_active_font(code, primary_font, multilingual_font)

		assertions += 1
		if code == "en":
			if active_font != primary_font:
				failures.append("English should use the primary font")
		elif active_font != multilingual_font:
			failures.append("localized language %s should use the multilingual font for full glyph coverage" % code)

	assertions += 1
	if UiStylesScript.get_active_font("ja", primary_font, null) != ThemeDB.fallback_font:
		failures.append("multilingual languages should fall back safely when the system font is unavailable")

	return {
		"assertions": assertions,
		"failures": failures,
	}

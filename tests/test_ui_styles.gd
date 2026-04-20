extends RefCounted

const LocalizationScript = preload("res://scripts/localization_data.gd")
const UiStylesScript = preload("res://scripts/game/game_ui_styles.gd")
const CJK_FALLBACK_FONT_PATH := "res://assets/fonts/NotoSansCJKsc-Regular.otf"


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var primary_font: FontFile = FontFile.new()
	var bundled_cjk_font: Font = UiStylesScript.load_font_or_null(CJK_FALLBACK_FONT_PATH)
	var multilingual_fallbacks: Array[Font] = []
	if bundled_cjk_font != null:
		multilingual_fallbacks.append(bundled_cjk_font)
	var multilingual_font: Font = UiStylesScript.build_multilingual_font(multilingual_fallbacks)

	assertions += 1
	if UiStylesScript.uses_multilingual_font("en"):
		failures.append("English should keep the primary display font")

	assertions += 1
	if bundled_cjk_font == null:
		failures.append("bundled Simplified Chinese fallback font should load")
	else:
		for glyph in ["简", "体", "中", "文", "语", "言", "载"]:
			assertions += 1
			if not bundled_cjk_font.has_char(glyph.unicode_at(0)):
				failures.append("bundled Simplified Chinese fallback font should include glyph %s" % glyph)

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

	assertions += 1
	if bundled_cjk_font != null and not multilingual_font.has_char("简".unicode_at(0)):
		failures.append("multilingual font stack should expose bundled Chinese glyph coverage")

	return {
		"assertions": assertions,
		"failures": failures,
	}

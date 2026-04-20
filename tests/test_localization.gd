extends RefCounted

const LocalizationScript = preload("res://scripts/localization_data.gd")


func run() -> Dictionary:
	var failures: Array[String] = []
	var assertions: int = 0
	var default_table: Dictionary = LocalizationScript.STRINGS[LocalizationScript.DEFAULT_LANGUAGE]
	var expected_keys: Array = default_table.keys()

	assertions += 1
	if LocalizationScript.get_language_name("zh_CN") != "简体中文":
		failures.append("Chinese language name should preserve its full glyphs")

	assertions += 1
	if LocalizationScript.get_language_name("es") != "Español":
		failures.append("Spanish language name should preserve accented characters")

	assertions += 1
	if LocalizationScript.get_language_name("fr") != "Français":
		failures.append("French language name should preserve accented characters")

	assertions += 1
	if LocalizationScript.get_language_name("pt_BR") != "Português (Brasil)":
		failures.append("Brazilian Portuguese language name should preserve accented characters")

	assertions += 1
	if LocalizationScript.get_text("zh_CN", "BUILDING_RUN") != "正在生成新一轮":
		failures.append("Chinese run-building text should remain intact")

	assertions += 1
	if LocalizationScript.get_language_code_by_offset("en", 1) != "zh_CN":
		failures.append("language cycling should advance to the next locale")

	assertions += 1
	if LocalizationScript.get_language_code_by_offset("zh_CN", -1) != "en":
		failures.append("language cycling should move backward to the previous locale")

	assertions += 1
	if LocalizationScript.get_language_code_by_offset("en", -1) != "ko":
		failures.append("language cycling should wrap backward from the first locale")

	for entry_variant in LocalizationScript.get_languages():
		var entry: Dictionary = entry_variant
		var code: String = String(entry.get("code", ""))
		var table: Dictionary = LocalizationScript.STRINGS.get(code, {})

		assertions += 1
		if table.is_empty():
			failures.append("language %s should have a localization table" % code)
			continue

		for key_variant in expected_keys:
			var key: String = String(key_variant)
			assertions += 1
			if not table.has(key):
				failures.append("language %s is missing key %s" % [code, key])
				continue
			if String(table[key]).is_empty():
				failures.append("language %s should not have an empty value for %s" % [code, key])

	return {
		"assertions": assertions,
		"failures": failures,
	}

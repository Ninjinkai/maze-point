extends RefCounted
class_name MazePointUiStyles

static func load_primary_font(font_path: String) -> Font:
	var font_bytes: PackedByteArray = FileAccess.get_file_as_bytes(font_path)
	if font_bytes.is_empty():
		return ThemeDB.fallback_font
	var font_file: FontFile = FontFile.new()
	font_file.data = font_bytes
	return font_file


static func build_multilingual_font() -> Font:
	var system_font: SystemFont = SystemFont.new()
	system_font.font_names = PackedStringArray([
		"Hiragino Sans",
		"Hiragino Kaku Gothic ProN",
		"Yu Gothic",
		"PingFang SC",
		"PingFang TC",
		"Heiti SC",
		"STHeiti",
		"Songti SC",
		"Apple SD Gothic Neo",
		"Noto Sans CJK JP",
		"Noto Sans CJK SC",
		"Noto Sans CJK TC",
		"Noto Sans CJK KR",
		"Noto Sans JP",
		"Noto Sans SC",
		"Noto Sans TC",
		"Noto Sans KR",
		"Noto Sans Arabic",
		"Noto Sans Devanagari",
		"Geeza Pro",
		"Kohinoor Devanagari",
		"Microsoft YaHei",
		"Malgun Gothic",
		"Segoe UI",
	])
	return system_font


static func uses_multilingual_font(language_code: String) -> bool:
	return language_code != "en"


static func get_active_font(language_code: String, primary_font: Font, multilingual_font: Font) -> Font:
	if uses_multilingual_font(language_code):
		return multilingual_font if multilingual_font != null else ThemeDB.fallback_font
	return primary_font if primary_font != null else ThemeDB.fallback_font


static func make_panel_style(bg_color: Color, border_color: Color, shadow_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color.lightened(0.08)
	style.border_blend = true
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.corner_detail = 10
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = with_alpha(shadow_color.darkened(0.35), 0.34)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


static func make_button_style(bg_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = bg_color.lightened(0.22)
	style.border_blend = true
	style.set_border_width_all(4)
	style.set_corner_radius_all(24)
	style.corner_detail = 10
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 18
	style.shadow_color = with_alpha(bg_color.darkened(0.62), 0.46)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


static func make_button_focus_style(border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = border_color.lightened(0.25)
	style.set_border_width_all(6)
	style.set_corner_radius_all(26)
	style.corner_detail = 10
	style.shadow_color = with_alpha(border_color.lightened(0.15), 0.38)
	style.shadow_size = 14
	style.shadow_offset = Vector2.ZERO
	return style


static func make_slider_grabber_icon(color: Color, size: int = 28) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var center: Vector2 = Vector2(size * 0.5, size * 0.5)
	var radius: float = size * 0.38
	for y in range(size):
		for x in range(size):
			var distance: float = Vector2(float(x), float(y)).distance_to(center)
			if distance <= radius:
				image.set_pixel(x, y, color)
			elif distance <= radius + 2.0:
				image.set_pixel(x, y, color.darkened(0.35))
	return ImageTexture.create_from_image(image)


static func apply_label_style(label: Label, font: Font, font_size: int, outline_size: int, text_color: Color, outline_color: Color) -> void:
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", outline_color)


static func apply_button_style_metrics(button: Button, font: Font, font_size: int, outline_size: int, text_color: Color, outline_color: Color, ui_scale: float, minimum_width: float = 0.0) -> void:
	button.custom_minimum_size = Vector2(minimum_width, round(122.0 * ui_scale))
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_constant_override("outline_size", outline_size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_outline_color", outline_color)


static func apply_button_palette(button: Button, normal_color: Color, hover_color: Color, pressed_color: Color) -> void:
	button.add_theme_stylebox_override("normal", make_button_style(normal_color))
	button.add_theme_stylebox_override("hover", make_button_style(hover_color))
	button.add_theme_stylebox_override("pressed", make_button_style(pressed_color))
	button.add_theme_stylebox_override("focus", make_button_focus_style(hover_color))


static func apply_slider_palette(slider: HSlider, panel_color: Color, goal_color: Color, retry_button_color: Color, end_button_color: Color, end_button_hover_color: Color, pulse_time: float) -> void:
	var is_focused: bool = slider != null and slider.has_focus()
	var pulse: float = 0.5 + 0.5 * sin(pulse_time * 5.2)
	var focus_mix: float = (0.16 + pulse * 0.2) if is_focused else 0.0
	var rail_style: StyleBoxFlat = StyleBoxFlat.new()
	rail_style.bg_color = panel_color.darkened(0.12).lerp(goal_color.lightened(0.18), focus_mix * 0.2)
	rail_style.set_corner_radius_all(18)
	rail_style.content_margin_left = 18
	rail_style.content_margin_right = 18
	rail_style.content_margin_top = 14 + int(round(focus_mix * 5.0))
	rail_style.content_margin_bottom = 14 + int(round(focus_mix * 5.0))
	slider.add_theme_stylebox_override("slider", rail_style)
	var active_style: StyleBoxFlat = StyleBoxFlat.new()
	active_style.bg_color = retry_button_color.lightened(0.18).lerp(goal_color.lightened(0.22), focus_mix)
	active_style.set_corner_radius_all(18)
	active_style.content_margin_left = 18
	active_style.content_margin_right = 18
	active_style.content_margin_top = 14 + int(round(focus_mix * 5.0))
	active_style.content_margin_bottom = 14 + int(round(focus_mix * 5.0))
	slider.add_theme_stylebox_override("grabber_area", active_style)
	slider.add_theme_stylebox_override("grabber_area_highlight", active_style)
	slider.add_theme_icon_override("grabber", make_slider_grabber_icon(end_button_color, 34 if is_focused else 28))
	slider.add_theme_icon_override("grabber_highlight", make_slider_grabber_icon(end_button_hover_color, 36 if is_focused else 30))


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

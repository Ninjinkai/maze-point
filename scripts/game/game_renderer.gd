extends RefCounted
class_name MazePointRenderer

const TypesScript = preload("res://scripts/game/game_types.gd")

func draw(game: Node2D) -> void:
	var viewport_rect: Rect2 = game.get_viewport_rect()
	game.draw_rect(viewport_rect, game.background_color)
	_draw_background_glow(game, viewport_rect)
	var draw_area: Rect2 = game._get_draw_area()
	_draw_playfield_trim(game, draw_area)

	if game.grid_width <= 0 or game.grid_height <= 0:
		return

	var cell_size: float = game._get_cell_size()
	var origin: Vector2 = game._get_grid_origin(cell_size)
	_draw_grid_cells(game, origin, cell_size)
	_draw_goal_overlay(game, cell_size)
	_draw_player_overlay(game, cell_size)


func _draw_background_glow(game: Node2D, viewport_rect: Rect2) -> void:
	_draw_floating_background_circle(game, viewport_rect, Vector2(0.16, 0.16), 0.16, game.background_glow_color, 0.0, 0.03)
	_draw_floating_background_circle(game, viewport_rect, Vector2(0.86, 0.22), 0.12, game.secondary_glow_color, 1.7, 0.026)
	_draw_floating_background_circle(game, viewport_rect, Vector2(0.82, 0.84), 0.18, game.goal_color, 3.2, 0.034)
	if game.splash_mode == TypesScript.SplashMode.TITLE:
		_draw_floating_background_circle(game, viewport_rect, Vector2(0.38, 0.72), 0.1, game.retry_button_hover_color, 0.9, 0.04)
		_draw_floating_background_circle(game, viewport_rect, Vector2(0.68, 0.58), 0.08, game.player_color, 2.4, 0.045)


func _draw_floating_background_circle(game: Node2D, viewport_rect: Rect2, anchor: Vector2, radius_scale: float, color: Color, time_offset: float, drift_scale: float) -> void:
	var min_size: float = minf(viewport_rect.size.x, viewport_rect.size.y)
	var time: float = game.pulse_time + time_offset
	var center: Vector2 = Vector2(
		viewport_rect.size.x * anchor.x + sin(time * 0.42) * viewport_rect.size.x * drift_scale,
		viewport_rect.size.y * anchor.y + cos(time * 0.36) * viewport_rect.size.y * drift_scale
	)
	var radius: float = min_size * radius_scale * (0.84 + (0.5 + 0.5 * sin(time * 0.78)) * 0.42)
	var hue_shift: float = 0.5 + 0.5 * sin(time * 0.22 + anchor.x * 7.0 + anchor.y * 5.0)
	var hue: float = fposmod(color.h + 0.18 * hue_shift, 1.0)
	var saturation: float = 0.32 + 0.12 * (0.5 + 0.5 * cos(time * 0.28 + time_offset))
	var value: float = 0.15 + 0.06 * (0.5 + 0.5 * sin(time * 0.24))
	if game.invert_colors_enabled:
		value += 0.12
	var bubble_color: Color = Color.from_hsv(hue, saturation, value, 0.14)
	game.draw_circle(center, radius, bubble_color)


func _draw_playfield_trim(game: Node2D, draw_area: Rect2) -> void:
	game.draw_rect(draw_area.grow(2.0), _with_alpha(game.playfield_trim_color, 0.58), false, 3.0)


func _draw_grid_cells(game: Node2D, origin: Vector2, cell_size: float) -> void:
	var line_width: float = clampf(cell_size * 0.04, 2.0, 5.0)
	var number_font_size: int = clampi(int(round(cell_size * 0.46)), 20, 60)
	var goal_font_size: int = clampi(int(round(cell_size * 0.38)), 18, 52)

	for y in range(game.grid_height):
		for x in range(game.grid_width):
			var cell: Vector2i = Vector2i(x, y)
			var base_rect: Rect2 = Rect2(origin + Vector2(x, y) * cell_size, Vector2.ONE * cell_size)
			var rect: Rect2 = _get_tile_draw_rect(game, base_rect, cell, cell_size)
			var fill_color: Color = _get_cell_fill_color(game, cell)
			_draw_tile_surface(game, rect, fill_color, line_width, _is_cell_available(game, cell))

			if cell == game.goal_cell:
				_draw_centered_text(game, rect, str(game.goal_target), goal_font_size, game.text_color, 4)
			else:
				_draw_centered_text(game, rect, str(game._get_cell_value(cell)), number_font_size, game.text_color, 4)


func _draw_goal_overlay(game: Node2D, cell_size: float) -> void:
	var fail_shake: Vector2 = game._get_goal_fail_shake(cell_size)
	var center: Vector2 = game._cell_to_screen(game.goal_cell) + fail_shake
	var radius: float = cell_size * 0.42 * game._get_goal_clear_scale() * game._get_goal_fail_scale()
	var pulse: float = 0.5 + 0.5 * sin(game.pulse_time * 2.6)
	var arc_color: Color = game.warning_color if game._is_goal_fail_active() else game.goal_color
	var outer_alpha: float = 0.94 if not game._is_goal_fail_active() else 0.98
	var inner_alpha: float = 0.42 if not game._is_goal_fail_active() else 0.58
	game.draw_arc(center, radius * (1.16 + pulse * 0.1), 0.0, TAU, 40, _with_alpha(arc_color.lightened(0.16), outer_alpha), maxf(cell_size * 0.04, 2.0))
	game.draw_arc(center, radius * 0.82, 0.0, TAU, 32, _with_alpha(arc_color, inner_alpha), maxf(cell_size * 0.03, 2.0))
	if game._is_goal_fail_active():
		game.draw_arc(center, radius * 1.34, PI * 0.08, PI * 0.92, 22, _with_alpha(game.warning_color.lightened(0.08), 0.84), maxf(cell_size * 0.035, 2.0))


func _draw_player_overlay(game: Node2D, cell_size: float) -> void:
	var pulse: float = 0.5 + 0.5 * sin(game.pulse_time * 3.0)
	var player_radius: float = clampf(cell_size * 0.34, 17.0, 36.0)
	var player_intro_scale: float = game._get_marker_intro_scale(player_radius)
	var player_clear_scale: float = game._get_player_clear_scale()
	var player_fail_scale: float = game._get_player_fail_scale()
	var player_move_scale: float = game._get_player_move_scale()
	var player_total_scale: float = game._get_player_total_bounce_scale()
	var fail_shake: Vector2 = game._get_goal_fail_shake(cell_size)
	_draw_player_marker(
		game,
		game._get_player_draw_position() + fail_shake,
		player_radius * player_intro_scale * player_clear_scale * player_fail_scale * player_move_scale * player_total_scale,
		pulse,
		cell_size
	)


func _draw_player_marker(game: Node2D, center: Vector2, radius: float, pulse: float, cell_size: float) -> void:
	var ring_color: Color = game.warning_color if game._is_goal_fail_active() else game.player_color.lightened(0.2)
	var outer_fill: Color = game.warning_color.lightened(0.24) if game._is_goal_fail_active() else game.player_core_color
	var core_fill: Color = game.warning_color if game._is_goal_fail_active() else game.player_color
	game.draw_circle(center, radius * (1.08 + pulse * 0.04), _with_alpha(ring_color, 0.18))
	game.draw_circle(center, radius, outer_fill)
	game.draw_circle(center, radius * 0.92, core_fill)
	var text_rect: Rect2 = Rect2(center - Vector2.ONE * radius * 0.92, Vector2.ONE * radius * 1.84)
	var total_text: String = str(game.player_total)
	var text_scale_factor: float = minf(0.46, 1.42 / maxf(float(total_text.length()), 2.0))
	var text_size: int = clampi(int(round(cell_size * text_scale_factor)), 12, 52)
	_draw_centered_text(game, text_rect, total_text, text_size, game.text_color, 4)


func _draw_centered_text(game: Node2D, rect: Rect2, text: String, font_size: int, color: Color, outline_thickness: int = 2) -> void:
	var font: Font = game._get_active_ui_font()
	if font == null:
		return
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var outline: Color = game.outline_color if color != game.DARK_TEXT_COLOR else game.BRIGHT_TEXT_COLOR
	var baseline: Vector2 = Vector2(
		rect.position.x + (rect.size.x - text_size.x) * 0.5,
		rect.position.y + rect.size.y * 0.5 + font.get_ascent(font_size) * 0.38
	)
	for offset_y in range(-outline_thickness, outline_thickness + 1):
		for offset_x in range(-outline_thickness, outline_thickness + 1):
			if offset_x == 0 and offset_y == 0:
				continue
			if absf(float(offset_x)) + absf(float(offset_y)) > float(outline_thickness) * 1.6:
				continue
			game.draw_string(font, baseline + Vector2(offset_x, offset_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _with_alpha(outline, 0.95))
	game.draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _get_cell_fill_color(game: Node2D, cell: Vector2i) -> Color:
	if cell == game.goal_cell:
		return game.playfield_color.lerp(game.goal_color, 0.18)
	var value: int = game._get_cell_value(cell)
	if game.tile_value_colors.has(value):
		return game.tile_value_colors[value]
	var value_ratio: float = clampf(float(value - 1) / maxf(float(game.max_cell_value - 1), 1.0), 0.0, 1.0)
	return game.playfield_color.lerp(game.playfield_trim_color, 0.12 + value_ratio * 0.28)


func _get_tile_draw_rect(game: Node2D, base_rect: Rect2, cell: Vector2i, cell_size: float) -> Rect2:
	var center: Vector2 = base_rect.get_center()
	var scale_x: float = 0.9
	var scale_y: float = 0.9
	var offset_y: float = 0.0

	if _is_cell_available(game, cell):
		var available_pulse: float = 0.5 + 0.5 * sin(game.pulse_time * 4.4 + float(cell.x + cell.y))
		scale_x += 0.05 + available_pulse * 0.05
		scale_y += 0.05 + available_pulse * 0.05
		offset_y -= available_pulse * cell_size * 0.02

	if game._is_landing_bounce_active() and cell == game.landing_bounce_cell:
		var progress: float = clampf(game.landing_bounce_elapsed / game.LANDING_BOUNCE_DURATION, 0.0, 1.0)
		var wave: float = sin(progress * PI)
		scale_x += wave * 0.08
		scale_y += wave * 0.12
		offset_y -= wave * cell_size * 0.14

	var size: Vector2 = base_rect.size * Vector2(scale_x, scale_y)
	return Rect2(center - size * 0.5 + Vector2(0.0, offset_y), size)


func _draw_tile_surface(game: Node2D, rect: Rect2, fill_color: Color, line_width: float, is_available: bool) -> void:
	var corner_radius: float = rect.size.x * 0.18
	var display_color: Color = fill_color
	if is_available:
		var pulse: float = 0.5 + 0.5 * sin(game.pulse_time * 2.2 + float(rect.position.x + rect.position.y) * 0.02)
		var inverted: Color = Color(1.0 - fill_color.r, 1.0 - fill_color.g, 1.0 - fill_color.b, fill_color.a)
		display_color = fill_color.lerp(inverted, 0.38 + pulse * 0.62)
	var shell_color: Color = display_color.lightened(0.26)
	var core_color: Color = display_color.darkened(0.36)
	var face_color: Color = display_color.lightened(0.14)
	_draw_rounded_rect(game, rect, shell_color, corner_radius)
	var middle_rect: Rect2 = rect.grow(-line_width * 0.45)
	var middle_radius: float = maxf(corner_radius - line_width * 0.85, 3.0)
	_draw_rounded_rect(game, middle_rect, core_color, middle_radius)
	var face_rect: Rect2 = middle_rect.grow(-line_width * 0.62)
	var face_radius: float = maxf(middle_radius - line_width * 0.9, 2.0)
	_draw_rounded_rect(game, face_rect, face_color, face_radius)
	var top_glow_rect: Rect2 = Rect2(face_rect.position + Vector2(0.0, face_rect.size.y * 0.02), Vector2(face_rect.size.x, face_rect.size.y * 0.46))
	var bottom_shade_rect: Rect2 = Rect2(face_rect.position + Vector2(0.0, face_rect.size.y * 0.48), Vector2(face_rect.size.x, face_rect.size.y * 0.42))
	_draw_rounded_rect(game, top_glow_rect, _with_alpha(shell_color.lightened(0.18), 0.22), face_radius)
	_draw_rounded_rect(game, bottom_shade_rect, _with_alpha(core_color.darkened(0.12), 0.18), face_radius)
	_draw_corner_lights(game, face_rect, _with_alpha(Color.WHITE, 0.17), face_radius)
	_draw_rounded_rect_outline(game, face_rect, _with_alpha(Color.WHITE, 0.22), face_radius, maxf(1.0, line_width * 0.48))
	_draw_rounded_rect_outline(game, middle_rect, _with_alpha(core_color.darkened(0.3), 0.46), middle_radius, maxf(1.0, line_width * 0.45))
	_draw_rounded_rect_outline(game, rect, _with_alpha(shell_color.lightened(0.16), 0.62), corner_radius, maxf(1.0, line_width * 0.82))
	if is_available:
		var pulse_outline: float = 0.5 + 0.5 * sin(game.pulse_time * 2.2 + float(rect.position.x + rect.position.y) * 0.02)
		_draw_corner_lights(game, face_rect, _with_alpha(Color.WHITE, 0.18 + pulse_outline * 0.08), face_radius)
		_draw_rounded_rect_outline(game, rect, _with_alpha(game.player_core_color, 0.3 + pulse_outline * 0.35), corner_radius, maxf(2.0, line_width * 1.1))


func _draw_rounded_rect(game: Node2D, rect: Rect2, color: Color, radius: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 1.0:
		game.draw_rect(rect, color, true)
		return
	game.draw_rect(Rect2(rect.position + Vector2(r, 0.0), Vector2(rect.size.x - r * 2.0, rect.size.y)), color, true)
	game.draw_rect(Rect2(rect.position + Vector2(0.0, r), Vector2(rect.size.x, rect.size.y - r * 2.0)), color, true)
	game.draw_circle(rect.position + Vector2(r, r), r, color)
	game.draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	game.draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
	game.draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)


func _draw_rounded_rect_outline(game: Node2D, rect: Rect2, color: Color, radius: float, width: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 1.0:
		game.draw_rect(rect, color, false, width)
		return
	var top_left: Vector2 = rect.position + Vector2(r, r)
	var top_right: Vector2 = rect.position + Vector2(rect.size.x - r, r)
	var bottom_left: Vector2 = rect.position + Vector2(r, rect.size.y - r)
	var bottom_right: Vector2 = rect.position + Vector2(rect.size.x - r, rect.size.y - r)
	game.draw_arc(top_left, r, PI, PI * 1.5, 10, color, width)
	game.draw_arc(top_right, r, PI * 1.5, TAU, 10, color, width)
	game.draw_arc(bottom_right, r, 0.0, PI * 0.5, 10, color, width)
	game.draw_arc(bottom_left, r, PI * 0.5, PI, 10, color, width)
	game.draw_line(rect.position + Vector2(r, 0.0), rect.position + Vector2(rect.size.x - r, 0.0), color, width)
	game.draw_line(rect.position + Vector2(rect.size.x, r), rect.position + Vector2(rect.size.x, rect.size.y - r), color, width)
	game.draw_line(rect.position + Vector2(r, rect.size.y), rect.position + Vector2(rect.size.x - r, rect.size.y), color, width)
	game.draw_line(rect.position + Vector2(0.0, r), rect.position + Vector2(0.0, rect.size.y - r), color, width)


func _draw_corner_lights(game: Node2D, rect: Rect2, color: Color, radius: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 1.0:
		return
	game.draw_circle(rect.position + Vector2(r, r), r, color)
	game.draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	game.draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
	game.draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)


func _is_cell_available(game: Node2D, cell: Vector2i) -> bool:
	if game.splash_mode != TypesScript.SplashMode.NONE or game.completed:
		return false
	if cell == game.player_cell:
		return false
	return game._orthogonal_neighbors(game.player_cell).has(cell)


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

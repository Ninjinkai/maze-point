extends Node2D

const MazeGeneratorScript = preload("res://scripts/maze_generator.gd")
const TEXT_COLOR := Color("f5f7fb")
const OUTLINE_COLOR := Color("1a1f2a")
const AUTO_ADVANCE_SECONDS := 2.8
const JOYPAD_DEADZONE := 0.38
const JOYPAD_TRIGGER := 0.72
const BASE_LEVEL_AREA := 24.0
const BASE_TOP_HUD_HEIGHT := 180.0
const BASE_BOTTOM_HUD_HEIGHT := 150.0
const BASE_OUTER_MARGIN := 12.0
const ACTION_ACCEPT := "maze_accept"
const ACTION_RETRY := "maze_retry"
const ACTION_END_RUN := "maze_end_run"

enum SplashMode {
	NONE,
	LEVEL_COMPLETE,
	RUN_COMPLETE,
}

var run_seed: int = 0
var level: int = 1
var maze_width: int = 0
var maze_height: int = 0
var level_seed: int = 0
var cells: Array[PackedInt32Array] = []
var goal_cell: Vector2i = Vector2i.ZERO
var player_cell: Vector2i = Vector2i.ZERO
var solution_path: Array[Vector2i] = []
var optimal_steps: int = 0
var perfect_score: int = 0
var player_steps: int = 0
var level_retries: int = 0
var collected_bonus_total: int = 0
var level_elapsed_time: float = 0.0
var par_time_seconds: int = 0
var completed: bool = false
var pulse_time: float = 0.0
var joypad_x_state: int = 0
var joypad_y_state: int = 0
var run_total_score: int = 0
var run_levels_cleared: int = 0
var splash_mode: SplashMode = SplashMode.NONE
var last_viewport_size: Vector2 = Vector2.ZERO

var level_bonus_values: Dictionary = {}
var collected_bonus_cells: Dictionary = {}

var background_color: Color = Color("101826")
var background_glow_color: Color = Color("3b4dff")
var secondary_glow_color: Color = Color("ff5ec7")
var playfield_color: Color = Color("162233")
var playfield_trim_color: Color = Color("466283")
var wall_color: Color = Color("4d6685")
var node_color: Color = Color("d8e4f4")
var goal_color: Color = Color("ffcc66")
var bonus_color: Color = Color("5fd08c")
var bonus_inner_color: Color = Color("f8fff4")
var player_color: Color = Color("73d2ff")
var player_core_color: Color = Color("f7fbff")
var panel_color: Color = Color("203147")
var panel_border_color: Color = Color("314864")
var retry_button_color: Color = Color("466283")
var retry_button_hover_color: Color = Color("58779c")
var retry_button_pressed_color: Color = Color("6f97c6")
var end_button_color: Color = Color("7a4cff")
var end_button_hover_color: Color = Color("915eff")
var end_button_pressed_color: Color = Color("aa7bff")

var maze_label: Label
var score_label: Label
var timer_label: Label
var retry_button: Button
var end_run_button: Button
var splash_action_button: Button
var splash_center: CenterContainer
var top_panel: PanelContainer
var bottom_panel: PanelContainer
var splash_panel: PanelContainer
var splash_title_label: Label
var splash_score_label: Label
var splash_optimal_label: Label
var splash_retries_label: Label
var splash_stars_label: Label
var splash_caption_label: Label
var advance_timer: Timer
var ui_font: Font


func _ready() -> void:
	randomize()
	_configure_input_actions()
	_load_ui_font()
	_apply_palette(level)
	_build_ui()
	_build_advance_timer()
	_refresh_ui_layout()
	_start_new_run()


func _process(delta: float) -> void:
	pulse_time += delta
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size != last_viewport_size:
		last_viewport_size = viewport_size
		_refresh_ui_layout()
	if splash_mode == SplashMode.NONE and not completed:
		level_elapsed_time += delta
		_update_ui()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_ACCEPT):
		if splash_mode == SplashMode.RUN_COMPLETE or splash_mode == SplashMode.LEVEL_COMPLETE:
			_handle_splash_action()
		return

	if splash_mode == SplashMode.RUN_COMPLETE or splash_mode == SplashMode.LEVEL_COMPLETE or completed:
		return

	if event.is_action_pressed(ACTION_RETRY):
		_restart_level()
		return

	if event.is_action_pressed(ACTION_END_RUN):
		_end_run()
		return

	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			_handle_maze_tap(touch_event.position)
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_maze_tap(mouse_event.position)
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo:
			var key_direction: Vector2i = _direction_from_key(key_event)
			if key_direction != Vector2i.ZERO:
				_try_move_in_direction(key_direction)
		return

	if event is InputEventJoypadButton:
		var button_event: InputEventJoypadButton = event
		if button_event.pressed:
			var button_direction: Vector2i = _direction_from_joypad_button(button_event)
			if button_direction != Vector2i.ZERO:
				_try_move_in_direction(button_direction)
		return

	if event is InputEventJoypadMotion:
		var motion_event: InputEventJoypadMotion = event
		_handle_joypad_motion(motion_event)


func _draw() -> void:
	var viewport_rect: Rect2 = get_viewport_rect()
	draw_rect(Rect2(Vector2.ZERO, viewport_rect.size), background_color, true)
	_draw_background_glow(viewport_rect)

	if maze_width <= 0 or maze_height <= 0:
		return

	var draw_area: Rect2 = _get_draw_area()
	draw_rect(draw_area, playfield_color, true)
	_draw_playfield_trim(draw_area)

	var cell_size: float = _get_cell_size()
	var origin: Vector2 = _get_grid_origin(cell_size)
	var wall_width: float = clampf(cell_size * 0.1, 3.0, 10.0)
	var node_radius: float = clampf(cell_size * 0.08, 3.0, 7.0)
	var player_radius: float = clampf(cell_size * 0.19, 8.0, 17.0)
	var goal_radius: float = clampf(cell_size * 0.21, 9.0, 18.0)
	var bonus_radius: float = clampf(cell_size * 0.12, 5.0, 11.0)
	var pulse: float = 0.84 + 0.16 * sin(pulse_time * 4.0)

	for y in range(maze_height):
		for x in range(maze_width):
			var cell: Vector2i = Vector2i(x, y)
			var cell_origin: Vector2 = origin + Vector2(x, y) * cell_size
			var top_left: Vector2 = cell_origin
			var top_right: Vector2 = cell_origin + Vector2(cell_size, 0.0)
			var bottom_left: Vector2 = cell_origin + Vector2(0.0, cell_size)
			var bottom_right: Vector2 = cell_origin + Vector2(cell_size, cell_size)

			if y == 0:
				draw_line(top_left, top_right, wall_color, wall_width)
			if x == 0:
				draw_line(top_left, bottom_left, wall_color, wall_width)
			if not MazeGeneratorScript.has_connection(cells, cell, Vector2i.RIGHT):
				draw_line(top_right, bottom_right, wall_color, wall_width)
			if not MazeGeneratorScript.has_connection(cells, cell, Vector2i.DOWN):
				draw_line(bottom_left, bottom_right, wall_color, wall_width)

	for node_y in range(maze_height):
		for node_x in range(maze_width):
			draw_circle(_cell_to_screen(Vector2i(node_x, node_y)), node_radius, node_color)

	for bonus_cell_variant in level_bonus_values.keys():
		var bonus_cell: Vector2i = bonus_cell_variant
		if collected_bonus_cells.has(bonus_cell):
			continue
		if bonus_cell == goal_cell:
			continue
		_draw_bonus_marker(_cell_to_screen(bonus_cell), bonus_radius, pulse, int(level_bonus_values[bonus_cell]))

	_draw_goal_marker(_cell_to_screen(goal_cell), goal_radius, pulse)
	_draw_player_marker(_cell_to_screen(player_cell), player_radius, pulse)


func _start_new_run() -> void:
	run_seed = randi()
	level = 1
	level_retries = 0
	run_total_score = 0
	run_levels_cleared = 0
	_generate_level()


func _restart_level() -> void:
	level_retries += 1
	_generate_level()


func _end_run() -> void:
	advance_timer.stop()
	_show_run_complete_splash()


func _generate_level() -> void:
	advance_timer.stop()
	completed = false
	splash_mode = SplashMode.NONE
	joypad_x_state = 0
	joypad_y_state = 0
	_set_footer_enabled(true)
	_set_splash_visible(false)

	var dimensions: Vector2i = _get_level_dimensions(level)
	var difficulty_scale: float = pow(1.1, float(level - 1))
	maze_width = dimensions.x
	maze_height = dimensions.y
	level_seed = abs(hash([run_seed, level, maze_width, maze_height]))
	if level_seed == 0:
		level_seed = 1

	_apply_palette(level)

	var maze: Dictionary = MazeGeneratorScript.generate(maze_width, maze_height, level_seed, difficulty_scale)
	cells = maze["cells"]
	goal_cell = maze["goal"]
	player_cell = maze["start"]
	solution_path = maze["solution_path"]
	optimal_steps = maze["solution_length"]
	perfect_score = maze["perfect_score"]
	player_steps = 0
	collected_bonus_total = 0
	level_elapsed_time = 0.0
	level_bonus_values = {}
	collected_bonus_cells = {}

	for bonus_variant in maze["bonuses"]:
		var bonus: Dictionary = bonus_variant
		var bonus_cell: Vector2i = bonus["cell"]
		level_bonus_values[bonus_cell] = int(bonus["value"])

	par_time_seconds = _calculate_par_time_seconds()
	_collect_bonus_at(player_cell)
	_update_ui()
	queue_redraw()


func _get_level_dimensions(current_level: int) -> Vector2i:
	var draw_area: Rect2 = _get_draw_area()
	var aspect_ratio: float = maxf(draw_area.size.x / maxf(draw_area.size.y, 1.0), 0.45)
	var scaled_area: float = BASE_LEVEL_AREA * pow(1.1, float(current_level - 1))
	var target_area: int = maxi(int(ceili(scaled_area)), int(BASE_LEVEL_AREA) + current_level - 1)
	var width: int = maxi(4, int(round(sqrt(float(target_area) * aspect_ratio))))
	var height: int = maxi(4, int(ceili(float(target_area) / float(width))))

	while width * height < target_area:
		height += 1

	return Vector2i(width, height)


func _handle_maze_tap(screen_position: Vector2) -> void:
	var tapped_cell: Vector2i = _find_tapped_neighbor(screen_position)
	if tapped_cell.x < 0:
		return

	_move_player_to(tapped_cell)


func _find_tapped_neighbor(screen_position: Vector2) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_distance: float = INF

	for neighbor in MazeGeneratorScript.connected_neighbors(cells, maze_width, maze_height, player_cell):
		var distance: float = screen_position.distance_to(_cell_to_screen(neighbor))
		if distance > _get_tap_radius():
			continue
		if distance < best_distance:
			best_distance = distance
			best_cell = neighbor

	return best_cell


func _try_move_in_direction(direction: Vector2i) -> void:
	var target_cell: Vector2i = player_cell + direction
	for neighbor in MazeGeneratorScript.connected_neighbors(cells, maze_width, maze_height, player_cell):
		if neighbor == target_cell:
			_move_player_to(target_cell)
			return


func _move_player_to(target_cell: Vector2i) -> void:
	player_cell = target_cell
	player_steps += 1
	_collect_bonus_at(player_cell)

	if player_cell == goal_cell:
		_complete_level()
	else:
		_update_ui()

	queue_redraw()


func _collect_bonus_at(cell: Vector2i) -> void:
	if not level_bonus_values.has(cell):
		return
	if collected_bonus_cells.has(cell):
		return

	collected_bonus_cells[cell] = true
	collected_bonus_total += int(level_bonus_values[cell])


func _complete_level() -> void:
	completed = true
	splash_mode = SplashMode.LEVEL_COMPLETE
	run_total_score += _current_level_score()
	run_levels_cleared += 1
	_set_footer_enabled(false)
	_update_ui()
	_update_completion_splash()


func _advance_to_next_level() -> void:
	if splash_mode != SplashMode.LEVEL_COMPLETE:
		return

	level += 1
	level_retries = 0
	_generate_level()


func _update_ui() -> void:
	maze_label.text = "Maze %d" % level
	score_label.text = "Score %d" % _current_level_score()
	timer_label.text = "Time %ds / %ds" % [_current_elapsed_seconds(), par_time_seconds]


func _update_completion_splash() -> void:
	var stars: int = _calculate_star_rating()
	splash_title_label.text = "Maze %d cleared" % level
	splash_score_label.text = "Player score: %d  |  Time: %ds" % [_current_level_score(), _current_elapsed_seconds()]
	splash_optimal_label.text = "Optimal score: %d  |  Par time: %ds" % [perfect_score, par_time_seconds]
	splash_retries_label.text = "Retries: %d  |  Bonus: -%d" % [level_retries, collected_bonus_total]
	splash_stars_label.visible = true
	splash_stars_label.text = _build_star_string(stars)
	splash_stars_label.add_theme_color_override("font_color", goal_color)
	splash_caption_label.text = "%s Press Enter or A when you're ready." % _get_star_caption(stars)
	splash_action_button.text = _get_splash_action_text()
	splash_action_button.visible = true
	_set_splash_visible(true)


func _show_run_complete_splash() -> void:
	splash_mode = SplashMode.RUN_COMPLETE
	completed = true
	_set_footer_enabled(false)
	var final_score: int = _current_run_total_score()
	splash_title_label.text = "Run ended"
	splash_score_label.text = "Final score: %d" % final_score
	splash_optimal_label.text = "Mazes cleared: %d" % run_levels_cleared
	splash_retries_label.text = "Current maze: %d  |  Time: %ds" % [level, _current_elapsed_seconds()]
	splash_stars_label.visible = false
	splash_caption_label.text = "Press Enter or A when you're ready to start again."
	splash_action_button.text = _get_splash_action_text()
	splash_action_button.visible = true
	_set_splash_visible(true)


func _current_level_score() -> int:
	return maxi(player_steps + _current_time_penalty() - collected_bonus_total, 0)


func _current_run_total_score() -> int:
	if splash_mode == SplashMode.LEVEL_COMPLETE:
		return run_total_score
	return run_total_score + _current_level_score()


func _calculate_star_rating() -> int:
	var level_score: int = _current_level_score()
	if level_score == perfect_score and level_retries == 0:
		return 3

	var two_star_limit: int = maxi(1, int(ceili(float(optimal_steps) * 0.25)))
	if level_score <= two_star_limit and level_retries <= 1:
		return 2

	return 1


func _build_star_string(stars: int) -> String:
	var segments: Array[String] = []

	for index in range(3):
		if index < stars:
			segments.append("★")
		else:
			segments.append("☆")

	return " ".join(segments)


func _get_star_caption(stars: int) -> String:
	match stars:
		3:
			return "Perfect zero-score run."
		2:
			return "Sharp route."
		_:
			return "Cleared with room to optimize."


func _direction_from_key(event: InputEventKey) -> Vector2i:
	match event.keycode:
		KEY_UP, KEY_W:
			return Vector2i.UP
		KEY_RIGHT, KEY_D:
			return Vector2i.RIGHT
		KEY_DOWN, KEY_S:
			return Vector2i.DOWN
		KEY_LEFT, KEY_A:
			return Vector2i.LEFT
		_:
			return Vector2i.ZERO


func _direction_from_joypad_button(event: InputEventJoypadButton) -> Vector2i:
	match event.button_index:
		JOY_BUTTON_DPAD_UP:
			return Vector2i.UP
		JOY_BUTTON_DPAD_RIGHT:
			return Vector2i.RIGHT
		JOY_BUTTON_DPAD_DOWN:
			return Vector2i.DOWN
		JOY_BUTTON_DPAD_LEFT:
			return Vector2i.LEFT
		_:
			return Vector2i.ZERO


func _handle_joypad_motion(event: InputEventJoypadMotion) -> void:
	match event.axis:
		JOY_AXIS_LEFT_X:
			_handle_joypad_axis(event.axis_value, true)
		JOY_AXIS_LEFT_Y:
			_handle_joypad_axis(event.axis_value, false)


func _handle_joypad_axis(value: float, is_horizontal: bool) -> void:
	var magnitude: float = absf(value)
	if magnitude <= JOYPAD_DEADZONE:
		if is_horizontal:
			joypad_x_state = 0
		else:
			joypad_y_state = 0
		return

	if magnitude < JOYPAD_TRIGGER:
		return

	var direction_sign: int = 1 if value > 0.0 else -1
	if is_horizontal:
		if joypad_x_state == direction_sign:
			return
		joypad_x_state = direction_sign
		_try_move_in_direction(Vector2i.RIGHT if direction_sign > 0 else Vector2i.LEFT)
		return

	if joypad_y_state == direction_sign:
		return
	joypad_y_state = direction_sign
	_try_move_in_direction(Vector2i.DOWN if direction_sign > 0 else Vector2i.UP)


func _get_draw_area() -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	return Rect2(
		Vector2(_get_outer_margin(), _get_top_hud_height()),
		viewport_size - Vector2(_get_outer_margin() * 2.0, _get_top_hud_height() + _get_bottom_hud_height())
	)


func _get_cell_size() -> float:
	var draw_area: Rect2 = _get_draw_area()
	return minf(draw_area.size.x / float(maze_width), draw_area.size.y / float(maze_height))


func _get_grid_origin(cell_size: float) -> Vector2:
	var draw_area: Rect2 = _get_draw_area()
	var grid_size: Vector2 = Vector2(maze_width, maze_height) * cell_size
	return draw_area.position + (draw_area.size - grid_size) * 0.5


func _cell_to_screen(cell: Vector2i) -> Vector2:
	var cell_size: float = _get_cell_size()
	return _get_grid_origin(cell_size) + (Vector2(cell.x, cell.y) + Vector2.ONE * 0.5) * cell_size


func _get_tap_radius() -> float:
	return maxf(_get_cell_size() * 0.28, 28.0)


func _build_ui() -> void:
	var ui: CanvasLayer = CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	top_panel = PanelContainer.new()
	top_panel.anchor_right = 1.0
	ui.add_child(top_panel)

	var top_content: VBoxContainer = VBoxContainer.new()
	top_content.add_theme_constant_override("separation", 8)
	top_panel.add_child(top_content)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 24)
	top_content.add_child(top_row)

	maze_label = Label.new()
	maze_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(maze_label)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(score_label)

	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_content.add_child(timer_label)

	bottom_panel = PanelContainer.new()
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	ui.add_child(bottom_panel)

	var bottom_content: HBoxContainer = HBoxContainer.new()
	bottom_content.add_theme_constant_override("separation", 12)
	bottom_panel.add_child(bottom_content)

	retry_button = _make_button("Retry maze [R / Y]")
	retry_button.pressed.connect(_restart_level)
	bottom_content.add_child(retry_button)

	end_run_button = _make_button("End run [Esc / Start]")
	end_run_button.pressed.connect(_end_run)
	bottom_content.add_child(end_run_button)

	splash_center = CenterContainer.new()
	splash_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(splash_center)

	splash_panel = PanelContainer.new()
	splash_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	splash_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	splash_panel.visible = false
	splash_center.add_child(splash_panel)

	var splash_content: VBoxContainer = VBoxContainer.new()
	splash_content.add_theme_constant_override("separation", 12)
	splash_panel.add_child(splash_content)

	splash_title_label = Label.new()
	splash_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_content.add_child(splash_title_label)

	splash_score_label = _make_splash_stat_label()
	splash_content.add_child(splash_score_label)

	splash_optimal_label = _make_splash_stat_label()
	splash_content.add_child(splash_optimal_label)

	splash_retries_label = _make_splash_stat_label()
	splash_content.add_child(splash_retries_label)

	splash_stars_label = Label.new()
	splash_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_content.add_child(splash_stars_label)

	splash_caption_label = Label.new()
	splash_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_content.add_child(splash_caption_label)

	splash_action_button = _make_button(_get_splash_action_text())
	splash_action_button.pressed.connect(_handle_splash_action)
	splash_content.add_child(splash_action_button)

	_apply_palette_to_ui()


func _build_advance_timer() -> void:
	advance_timer = Timer.new()
	advance_timer.one_shot = true
	advance_timer.timeout.connect(_advance_to_next_level)
	add_child(advance_timer)


func _handle_splash_action() -> void:
	match splash_mode:
		SplashMode.LEVEL_COMPLETE:
			_advance_to_next_level()
		SplashMode.RUN_COMPLETE:
			_start_new_run()


func _configure_input_actions() -> void:
	_ensure_key_action(ACTION_ACCEPT, KEY_ENTER)
	_ensure_key_action(ACTION_ACCEPT, KEY_KP_ENTER)
	_ensure_key_action(ACTION_ACCEPT, KEY_SPACE)
	_ensure_joypad_action(ACTION_ACCEPT, JOY_BUTTON_A)
	_ensure_key_action(ACTION_RETRY, KEY_R)
	_ensure_joypad_action(ACTION_RETRY, JOY_BUTTON_Y)
	_ensure_key_action(ACTION_END_RUN, KEY_ESCAPE)
	_ensure_joypad_action(ACTION_END_RUN, JOY_BUTTON_START)


func _ensure_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)


func _ensure_joypad_action(action_name: String, button_index: JoyButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)


func _get_splash_action_text() -> String:
	if splash_mode == SplashMode.RUN_COMPLETE:
		return "Start new run [Enter / A]"
	return "Continue [Enter / A]"


func _make_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button


func _make_splash_stat_label() -> Label:
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _apply_palette(level_value: int) -> void:
	var difficulty: float = clampf(float(level_value - 1) / 14.0, 0.0, 1.0)
	background_color = Color.from_hsv(0.62 - 0.07 * difficulty, 0.5, 0.12 + 0.03 * difficulty)
	background_glow_color = Color.from_hsv(0.72 - 0.1 * difficulty, 0.58, 0.92)
	secondary_glow_color = Color.from_hsv(0.92 - 0.14 * difficulty, 0.52 + 0.12 * difficulty, 0.94)
	playfield_color = Color.from_hsv(0.6 - 0.06 * difficulty, 0.34 + 0.08 * difficulty, 0.22 + 0.05 * difficulty)
	playfield_trim_color = Color.from_hsv(0.14 + 0.04 * difficulty, 0.48, 0.86)
	wall_color = Color.from_hsv(0.56 - 0.1 * difficulty, 0.28 + 0.2 * difficulty, 0.86 - 0.1 * difficulty)
	node_color = Color.from_hsv(0.58 - 0.03 * difficulty, 0.08 + 0.06 * difficulty, 0.96)
	goal_color = Color.from_hsv(0.12 - 0.02 * difficulty, 0.65, 0.98)
	bonus_color = Color.from_hsv(0.34 - 0.05 * difficulty, 0.54, 0.92)
	bonus_inner_color = Color.from_hsv(0.18 + 0.03 * difficulty, 0.08, 1.0)
	player_color = Color.from_hsv(0.5 - 0.07 * difficulty, 0.6, 0.98)
	player_core_color = Color.from_hsv(0.12 + 0.03 * difficulty, 0.12, 1.0)
	panel_color = playfield_color.lightened(0.1)
	panel_border_color = playfield_trim_color
	retry_button_color = wall_color.darkened(0.12)
	retry_button_hover_color = wall_color.lightened(0.06)
	retry_button_pressed_color = player_color.darkened(0.08)
	end_button_color = secondary_glow_color.darkened(0.2)
	end_button_hover_color = secondary_glow_color.darkened(0.08)
	end_button_pressed_color = goal_color.darkened(0.14)
	_apply_palette_to_ui()


func _apply_palette_to_ui() -> void:
	if top_panel == null:
		return

	top_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_color, panel_border_color, background_glow_color))
	bottom_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_color, panel_border_color, secondary_glow_color))
	splash_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_color.lightened(0.06), panel_border_color.lightened(0.08), goal_color))

	maze_label.add_theme_color_override("font_color", player_color)
	maze_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	score_label.add_theme_color_override("font_color", goal_color)
	score_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	timer_label.add_theme_color_override("font_color", bonus_color)
	timer_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)

	retry_button.add_theme_stylebox_override("normal", _make_button_style(retry_button_color))
	retry_button.add_theme_stylebox_override("hover", _make_button_style(retry_button_hover_color))
	retry_button.add_theme_stylebox_override("pressed", _make_button_style(retry_button_pressed_color))
	end_run_button.add_theme_stylebox_override("normal", _make_button_style(end_button_color))
	end_run_button.add_theme_stylebox_override("hover", _make_button_style(end_button_hover_color))
	end_run_button.add_theme_stylebox_override("pressed", _make_button_style(end_button_pressed_color))
	splash_action_button.add_theme_stylebox_override("normal", _make_button_style(end_button_color))
	splash_action_button.add_theme_stylebox_override("hover", _make_button_style(end_button_hover_color))
	splash_action_button.add_theme_stylebox_override("pressed", _make_button_style(end_button_pressed_color))

	splash_title_label.add_theme_color_override("font_color", goal_color)
	splash_title_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	splash_score_label.add_theme_color_override("font_color", player_color)
	splash_score_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	splash_optimal_label.add_theme_color_override("font_color", bonus_color)
	splash_optimal_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	splash_retries_label.add_theme_color_override("font_color", TEXT_COLOR)
	splash_retries_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	splash_stars_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	splash_caption_label.add_theme_color_override("font_color", secondary_glow_color.lightened(0.2))
	splash_caption_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)


func _refresh_ui_layout() -> void:
	if top_panel == null:
		return

	var margin: float = _get_outer_margin()
	var top_height: float = _get_top_hud_height()
	var bottom_height: float = _get_bottom_hud_height()
	var splash_width: float = minf(get_viewport_rect().size.x - margin * 2.0, 760.0 * _get_ui_scale())
	var splash_height: float = minf(get_viewport_rect().size.y - margin * 3.0, 820.0 * _get_ui_scale())

	top_panel.offset_left = margin
	top_panel.offset_top = margin
	top_panel.offset_right = -margin
	top_panel.offset_bottom = top_height - margin

	bottom_panel.offset_left = margin
	bottom_panel.offset_top = -bottom_height + margin
	bottom_panel.offset_right = -margin
	bottom_panel.offset_bottom = -margin

	splash_center.offset_left = margin
	splash_center.offset_top = margin
	splash_center.offset_right = -margin
	splash_center.offset_bottom = -margin
	splash_panel.custom_minimum_size = Vector2(splash_width, splash_height)

	_apply_ui_metrics()


func _apply_ui_metrics() -> void:
	var scale: float = _get_ui_scale()
	var header_size: int = int(round(52.0 * scale))
	var timer_size: int = int(round(38.0 * scale))
	var button_size: int = int(round(30.0 * scale))
	var splash_title_size: int = int(round(58.0 * scale))
	var splash_stat_size: int = int(round(34.0 * scale))
	var splash_star_size: int = int(round(72.0 * scale))
	var splash_caption_size: int = int(round(32.0 * scale))

	_apply_label_style(maze_label, header_size, 7, player_color)
	maze_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_style(score_label, header_size, 7, goal_color)
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_style(timer_label, timer_size, 6, bonus_color)
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_apply_label_style(splash_title_label, splash_title_size, 8, goal_color)
	_apply_label_style(splash_score_label, splash_stat_size, 6, player_color)
	_apply_label_style(splash_optimal_label, splash_stat_size, 6, bonus_color)
	_apply_label_style(splash_retries_label, splash_stat_size, 6, TEXT_COLOR)
	_apply_label_style(splash_caption_label, splash_caption_size, 6, secondary_glow_color.lightened(0.2))

	splash_stars_label.add_theme_font_override("font", ui_font)
	splash_stars_label.add_theme_font_size_override("font_size", splash_star_size)
	splash_stars_label.add_theme_constant_override("outline_size", 8)
	splash_stars_label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)

	_apply_button_style_metrics(retry_button, button_size)
	_apply_button_style_metrics(end_run_button, button_size)
	_apply_button_style_metrics(splash_action_button, button_size)


func _apply_label_style(label: Label, font_size: int, outline_size: int, color: Color) -> void:
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)


func _apply_button_style_metrics(button: Button, font_size: int) -> void:
	button.custom_minimum_size = Vector2(0.0, round(86.0 * _get_ui_scale()))
	button.add_theme_font_override("font", ui_font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_constant_override("outline_size", 5)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_outline_color", OUTLINE_COLOR)


func _get_ui_scale() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	return clampf(minf(viewport_size.x / 1080.0, viewport_size.y / 1920.0), 0.92, 1.45)


func _get_top_hud_height() -> float:
	return BASE_TOP_HUD_HEIGHT * _get_ui_scale()


func _get_bottom_hud_height() -> float:
	return BASE_BOTTOM_HUD_HEIGHT * _get_ui_scale()


func _get_outer_margin() -> float:
	return BASE_OUTER_MARGIN * _get_ui_scale()


func _load_ui_font() -> void:
	var font_bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://assets/fonts/Fredoka.ttf")
	if font_bytes.is_empty():
		ui_font = ThemeDB.fallback_font
		return

	var font_file: FontFile = FontFile.new()
	font_file.data = font_bytes
	ui_font = font_file


func _make_panel_style(bg_color: Color, border_color: Color, shadow_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.shadow_color = _with_alpha(shadow_color, 0.28)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0.0, 6.0)
	return style


func _make_button_style(bg_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = bg_color.lightened(0.18)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = _with_alpha(bg_color.darkened(0.55), 0.35)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _set_splash_visible(is_visible: bool) -> void:
	splash_panel.visible = is_visible


func _set_footer_enabled(is_enabled: bool) -> void:
	retry_button.disabled = not is_enabled
	end_run_button.disabled = not is_enabled


func _draw_background_glow(viewport_rect: Rect2) -> void:
	draw_circle(
		Vector2(viewport_rect.size.x * 0.16, viewport_rect.size.y * 0.16),
		minf(viewport_rect.size.x, viewport_rect.size.y) * 0.16,
		_with_alpha(background_glow_color, 0.11)
	)
	draw_circle(
		Vector2(viewport_rect.size.x * 0.86, viewport_rect.size.y * 0.22),
		minf(viewport_rect.size.x, viewport_rect.size.y) * 0.12,
		_with_alpha(secondary_glow_color, 0.1)
	)
	draw_circle(
		Vector2(viewport_rect.size.x * 0.82, viewport_rect.size.y * 0.84),
		minf(viewport_rect.size.x, viewport_rect.size.y) * 0.18,
		_with_alpha(goal_color, 0.07)
	)


func _draw_playfield_trim(draw_area: Rect2) -> void:
	var corner_radius: float = clampf(minf(draw_area.size.x, draw_area.size.y) * 0.04, 18.0, 38.0)
	draw_circle(draw_area.position + Vector2(corner_radius, corner_radius), corner_radius, _with_alpha(playfield_trim_color, 0.14))
	draw_circle(draw_area.position + Vector2(draw_area.size.x - corner_radius, draw_area.size.y - corner_radius), corner_radius, _with_alpha(background_glow_color, 0.1))


func _draw_bonus_marker(center: Vector2, radius: float, pulse: float, bonus_value: int) -> void:
	var points: PackedVector2Array = _make_regular_polygon(center, radius * (0.98 + pulse * 0.08), 6, PI / 6.0)
	draw_colored_polygon(points, bonus_color)
	draw_circle(center, radius * 0.42, bonus_inner_color)
	_draw_bonus_value(center, radius, bonus_value)


func _draw_goal_marker(center: Vector2, radius: float, pulse: float) -> void:
	var star_points: PackedVector2Array = _make_star_polygon(center, radius * 1.04, radius * 0.48, 5, -PI / 2.0)
	draw_colored_polygon(star_points, goal_color)
	draw_circle(center, radius * 0.26, player_core_color)
	draw_arc(center, radius * (1.18 + pulse * 0.16), 0.0, TAU, 40, _with_alpha(goal_color.lightened(0.18), 0.96), 3.0)


func _draw_player_marker(center: Vector2, radius: float, pulse: float) -> void:
	var diamond_points: PackedVector2Array = _make_regular_polygon(center, radius, 4, PI / 4.0)
	var inner_points: PackedVector2Array = _make_regular_polygon(center, radius * 0.44, 4, PI / 4.0)
	draw_colored_polygon(diamond_points, player_color)
	draw_colored_polygon(inner_points, player_core_color)
	draw_circle(center + Vector2(radius * 0.5, -radius * 0.46), radius * 0.18, _with_alpha(secondary_glow_color.lightened(0.2), 0.95))
	draw_arc(center, radius * (1.08 + pulse * 0.15), PI * 1.05, PI * 2.1, 28, _with_alpha(player_color.lightened(0.22), 0.92), 3.0)


func _make_regular_polygon(center: Vector2, radius: float, sides: int, rotation: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in range(sides):
		var angle: float = rotation + TAU * float(index) / float(sides)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _make_star_polygon(center: Vector2, outer_radius: float, inner_radius: float, points_count: int, rotation: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var total_points: int = points_count * 2
	for index in range(total_points):
		var angle: float = rotation + TAU * float(index) / float(total_points)
		var point_radius: float = outer_radius if index % 2 == 0 else inner_radius
		points.append(center + Vector2(cos(angle), sin(angle)) * point_radius)
	return points


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


func _current_elapsed_seconds() -> int:
	return int(ceili(level_elapsed_time))


func _current_time_penalty() -> int:
	return maxi(_current_elapsed_seconds() - par_time_seconds, 0)


func _calculate_par_time_seconds() -> int:
	var base_time: float = float(optimal_steps) * 1.75
	var layout_time: float = sqrt(float(maze_width * maze_height)) * 1.2
	return maxi(6, int(ceili(base_time + layout_time)))


func _draw_bonus_value(center: Vector2, radius: float, bonus_value: int) -> void:
	var font_size: int = maxi(18, mini(32, int(round(radius * 2.1))))
	var label_width: float = radius * 6.8
	var label_height: float = font_size * 1.35
	var label_rect: Rect2 = Rect2(
		center + Vector2(-label_width * 0.5, radius * 1.55),
		Vector2(label_width, label_height)
	)
	draw_rect(label_rect, _with_alpha(OUTLINE_COLOR, 0.86), true)
	draw_rect(label_rect.grow(-2.0), _with_alpha(panel_color.lightened(0.16), 0.96), true)
	var baseline: Vector2 = label_rect.position + Vector2(0.0, label_height * 0.78)
	draw_string(
		ui_font,
		baseline + Vector2(0.0, 1.0),
		"-%d" % bonus_value,
		HORIZONTAL_ALIGNMENT_CENTER,
		label_width,
		font_size,
		OUTLINE_COLOR
	)
	draw_string(
		ui_font,
		baseline,
		"-%d" % bonus_value,
		HORIZONTAL_ALIGNMENT_CENTER,
		label_width,
		font_size,
		TEXT_COLOR
	)

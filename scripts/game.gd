extends Node2D

const MazeGeneratorScript = preload("res://scripts/maze_generator.gd")
const ProceduralAudioScript = preload("res://scripts/procedural_audio.gd")
const LocalizationScript = preload("res://scripts/localization_data.gd")
const COMPANY_LOGO_PATH := "res://assets/branding/SlopwAIr_logo_vector.png"
const SAVE_FILE_PATH := "user://maze_point_settings.cfg"
const MAX_TRACKED_VALUE := 999999999

const BRIGHT_TEXT_COLOR := Color("f7fbff")
const DARK_TEXT_COLOR := Color("102030")
const DARK_OUTLINE_COLOR := Color("09111d")
const LIGHT_OUTLINE_COLOR := Color("eef4ff")
const MARKER_INTRO_DURATION := 2.2
const MARKER_INTRO_START_SCALE := 3.4
const MOVE_ANIMATION_DURATION := 0.16
const LANDING_BOUNCE_DURATION := 0.24
const PLAYER_TOTAL_BOUNCE_DURATION := 0.26
const GOAL_CLEAR_DURATION := 0.32
const GOAL_FAIL_DURATION := 0.42
const CONTENT_FADE_DURATION := 0.24
const TITLE_LOADING_DELAY := 0.18
const JOYPAD_DEADZONE := 0.38
const JOYPAD_TRIGGER := 0.72
const BASE_TOP_HUD_HEIGHT := 180.0
const BASE_BOTTOM_HUD_HEIGHT := 150.0
const BASE_OUTER_MARGIN := 12.0
const LEVEL_DIMENSION_PROFILES := [
	Vector2i(4, 4),
	Vector2i(4, 5),
	Vector2i(5, 5),
	Vector2i(5, 6),
	Vector2i(6, 6),
	Vector2i(6, 7),
]
const ACTION_ACCEPT := "maze_accept"
const ACTION_RETRY := "maze_retry"
const ACTION_END_RUN := "maze_end_run"
const ACTION_INVERT := "maze_invert"
const ACTION_PAUSE := "maze_pause"

enum SplashMode {
	NONE,
	TITLE,
	PAUSED,
	LEVEL_COMPLETE,
	LEVEL_FAILED,
	RUN_COMPLETE,
}

enum GoalResolveOutcome {
	NONE,
	SUCCESS,
	FAILURE,
}

enum TransitionAction {
	NONE,
	START_RUN,
	NEXT_LEVEL,
}

var run_seed: int = 0
var level: int = 1
var grid_width: int = 0
var grid_height: int = 0
var level_seed: int = 0
var cell_values: Array[PackedInt32Array] = []
var start_cell: Vector2i = Vector2i.ZERO
var goal_cell: Vector2i = Vector2i.ZERO
var player_cell: Vector2i = Vector2i.ZERO
var solution_path: Array[Vector2i] = []
var optimal_steps: int = 0
var goal_target: int = 0
var max_cell_value: int = 9
var player_total: int = 0
var player_steps: int = 0
var level_retries: int = 0
var run_total_resets: int = 0
var completed: bool = false
var pulse_time: float = 0.0
var marker_intro_elapsed: float = MARKER_INTRO_DURATION
var move_animation_elapsed: float = MOVE_ANIMATION_DURATION
var landing_bounce_elapsed: float = LANDING_BOUNCE_DURATION
var landing_bounce_cell: Vector2i = Vector2i(-1, -1)
var player_total_bounce_elapsed: float = PLAYER_TOTAL_BOUNCE_DURATION
var goal_clear_elapsed: float = GOAL_CLEAR_DURATION
var goal_fail_elapsed: float = GOAL_FAIL_DURATION
var move_animation_from: Vector2 = Vector2.ZERO
var move_animation_to: Vector2 = Vector2.ZERO
var pending_goal_outcome: GoalResolveOutcome = GoalResolveOutcome.NONE
var joypad_x_state: int = 0
var joypad_y_state: int = 0
var run_total_score: int = 0
var run_levels_cleared: int = 0
var splash_mode: SplashMode = SplashMode.NONE
var last_viewport_size: Vector2 = Vector2.ZERO
var invert_colors_enabled: bool = false
var menu_focus_index: int = -1
var player_skill_rating: float = 0.0
var current_level_difficulty_scale: float = 1.0
var tile_value_colors: Dictionary = {}
var music_volume_setting: float = 1.0
var sfx_volume_setting: float = 1.0
var best_run_score: int = 0
var language_code: String = LocalizationScript.DEFAULT_LANGUAGE
var title_loading_active: bool = false

var text_color: Color = BRIGHT_TEXT_COLOR
var outline_color: Color = DARK_OUTLINE_COLOR
var background_color: Color = Color("101826")
var background_glow_color: Color = Color("3b4dff")
var secondary_glow_color: Color = Color("ff5ec7")
var playfield_color: Color = Color("162233")
var playfield_trim_color: Color = Color("466283")
var grid_line_color: Color = Color("4d6685")
var start_color: Color = Color("5fd08c")
var goal_color: Color = Color("ffcc66")
var warning_color: Color = Color("ff6f61")
var player_color: Color = Color("73d2ff")
var player_core_color: Color = Color("f7fbff")
var cell_number_color: Color = Color("d8e4f4")
var panel_color: Color = Color("203147")
var panel_border_color: Color = Color("314864")
var retry_button_color: Color = Color("466283")
var retry_button_hover_color: Color = Color("58779c")
var retry_button_pressed_color: Color = Color("6f97c6")
var end_button_color: Color = Color("7a4cff")
var end_button_hover_color: Color = Color("915eff")
var end_button_pressed_color: Color = Color("aa7bff")

var maze_label: Label
var hud_by_label: Label
var hud_logo_rect: TextureRect
var score_label: Label
var timer_label: Label
var retry_button: Button
var end_run_button: Button
var splash_action_button: Button
var splash_retry_button: Button
var splash_end_run_button: Button
var splash_invert_button: Button
var invert_button: Button
var pause_button: Button
var splash_logo_rect: TextureRect
var splash_music_label: Label
var splash_music_slider: HSlider
var splash_sfx_label: Label
var splash_sfx_slider: HSlider
var splash_language_button: Button
var splash_content: VBoxContainer
var splash_center: CenterContainer
var top_panel: PanelContainer
var bottom_panel: PanelContainer
var splash_panel: PanelContainer
var splash_title_label: Label
var splash_score_label: Label
var splash_optimal_label: Label
var splash_retries_label: Label
var splash_best_label: Label
var splash_stars_label: Label
var advance_timer: Timer
var loading_timer: Timer
var ui_font: Font
var multilingual_ui_font: Font
var company_logo_texture: Texture2D
var audio_controller
var content_fade_elapsed: float = CONTENT_FADE_DURATION
var content_fade_direction: int = 0
var pending_transition_action: TransitionAction = TransitionAction.NONE


func _ready() -> void:
	randomize()
	_load_persistent_data()
	_configure_input_actions()
	_load_ui_font()
	_apply_palette(level)
	_build_ui()
	_build_advance_timer()
	_build_loading_timer()
	_build_audio()
	_apply_persistent_audio_settings()
	_refresh_ui_layout()
	_refresh_localized_text()
	_show_title_screen()


func _process(delta: float) -> void:
	pulse_time += delta
	_refresh_dynamic_control_styles()
	if title_loading_active:
		_refresh_loading_indicator()
	if _is_content_fade_active():
		content_fade_elapsed = minf(content_fade_elapsed + delta, CONTENT_FADE_DURATION)
		if not _is_content_fade_active():
			if content_fade_direction > 0 and pending_transition_action != TransitionAction.NONE:
				_perform_pending_transition_action()
			else:
				content_fade_direction = 0
	_apply_content_fade_to_ui()
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size != last_viewport_size:
		last_viewport_size = viewport_size
		_refresh_ui_layout()

	if splash_mode == SplashMode.NONE and not completed:
		if _is_marker_intro_active():
			marker_intro_elapsed = minf(marker_intro_elapsed + delta, MARKER_INTRO_DURATION)

		if splash_mode != SplashMode.NONE or completed:
			_update_ui()
			queue_redraw()
			return

		if _is_move_animation_active():
			move_animation_elapsed = minf(move_animation_elapsed + delta, MOVE_ANIMATION_DURATION)
			if not _is_move_animation_active() and pending_goal_outcome != GoalResolveOutcome.NONE:
				_begin_goal_resolution()
		elif _is_goal_clear_active():
			goal_clear_elapsed = minf(goal_clear_elapsed + delta, GOAL_CLEAR_DURATION)
			if not _is_goal_clear_active():
				_finish_level_complete()
		elif _is_goal_fail_active():
			goal_fail_elapsed = minf(goal_fail_elapsed + delta, GOAL_FAIL_DURATION)
			if not _is_goal_fail_active():
				_finish_level_failed()
		if _is_landing_bounce_active():
			landing_bounce_elapsed = minf(landing_bounce_elapsed + delta, LANDING_BOUNCE_DURATION)
		if _is_player_total_bounce_active():
			player_total_bounce_elapsed = minf(player_total_bounce_elapsed + delta, PLAYER_TOTAL_BOUNCE_DURATION)

		_update_ui()

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_ACCEPT):
		if _is_loading_transition_active():
			return
		if _is_content_fade_active():
			return
		if splash_mode == SplashMode.NONE and _has_active_animation():
			_skip_active_animations()
			return
		if splash_mode != SplashMode.NONE:
			_activate_focused_menu_button()
		return

	if event.is_action_pressed(ACTION_PAUSE):
		if _is_loading_transition_active():
			return
		if _is_content_fade_active():
			return
		if splash_mode == SplashMode.PAUSED:
			_resume_from_pause()
		elif splash_mode == SplashMode.NONE and not completed:
			_show_pause_menu()
		return

	if event.is_action_pressed(ACTION_RETRY) and (splash_mode == SplashMode.LEVEL_COMPLETE or splash_mode == SplashMode.LEVEL_FAILED):
		if _is_loading_transition_active():
			return
		if _is_content_fade_active():
			return
		_handle_splash_retry()
		return

	if event.is_action_pressed(ACTION_END_RUN) and (splash_mode == SplashMode.LEVEL_COMPLETE or splash_mode == SplashMode.LEVEL_FAILED):
		if _is_loading_transition_active():
			return
		if _is_content_fade_active():
			return
		_handle_splash_end_run()
		return

	if event.is_action_pressed(ACTION_INVERT):
		if _is_loading_transition_active():
			return
		if _is_content_fade_active():
			return
		_toggle_invert_colors()
		return

	if _is_menu_navigation_active():
		if _handle_menu_navigation_input(event):
			return

	if splash_mode != SplashMode.NONE or completed:
		return

	if _is_loading_transition_active():
		return
	if _is_content_fade_active():
		return

	if _is_skip_input_event(event):
		var skip_movement_intro: bool = _is_marker_intro_active() and _is_movement_input_event(event)
		_skip_active_animations()
		if splash_mode != SplashMode.NONE or completed:
			return
		if _is_marker_intro_active() and not skip_movement_intro:
			return

	if _is_marker_intro_active() or _is_goal_clear_active():
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
			_handle_grid_tap(touch_event.position)
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_grid_tap(mouse_event.position)
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

	if grid_width <= 0 or grid_height <= 0:
		return

	var draw_area: Rect2 = _get_draw_area()
	draw_rect(draw_area, playfield_color, true)
	_draw_playfield_trim(draw_area)

	var cell_size: float = _get_cell_size()
	var origin: Vector2 = _get_grid_origin(cell_size)
	_draw_grid_cells(origin, cell_size)
	_draw_goal_overlay(cell_size)
	_draw_start_overlay(cell_size)
	_draw_player_overlay(cell_size)


func _start_new_run() -> void:
	var preserve_loading_overlay: bool = title_loading_active
	if loading_timer != null:
		loading_timer.stop()
	_reset_content_fade()
	run_seed = randi()
	level = 1
	level_retries = 0
	run_total_score = 0
	run_levels_cleared = 0
	run_total_resets = 0
	player_skill_rating = 0.0
	if not preserve_loading_overlay:
		_set_hud_visible(true)
	if splash_logo_rect != null:
		splash_logo_rect.visible = false
	_set_volume_controls_visible(false)
	if audio_controller != null:
		audio_controller.start_run_music(run_seed)
		audio_controller.play_restart()
	_generate_level_internal(false, not preserve_loading_overlay)
	if preserve_loading_overlay:
		_set_hud_visible(true)
	title_loading_active = false


func _restart_level() -> void:
	level_retries = _saturating_add(level_retries, 1)
	run_total_resets = _saturating_add(run_total_resets, 1)
	if audio_controller != null:
		audio_controller.play_restart()
	_generate_level(true)


func _end_run() -> void:
	advance_timer.stop()
	if audio_controller != null:
		audio_controller.play_menu_confirm()
	_show_run_complete_splash()


func _generate_level(reuse_current_profile: bool = false) -> void:
	_generate_level_internal(reuse_current_profile, true)


func _generate_level_internal(reuse_current_profile: bool = false, hide_splash_before_generate: bool = true) -> void:
	advance_timer.stop()
	_reset_content_fade()
	completed = false
	joypad_x_state = 0
	joypad_y_state = 0
	marker_intro_elapsed = 0.0
	move_animation_elapsed = MOVE_ANIMATION_DURATION
	landing_bounce_elapsed = LANDING_BOUNCE_DURATION
	landing_bounce_cell = Vector2i(-1, -1)
	player_total_bounce_elapsed = PLAYER_TOTAL_BOUNCE_DURATION
	goal_clear_elapsed = GOAL_CLEAR_DURATION
	goal_fail_elapsed = GOAL_FAIL_DURATION
	pending_goal_outcome = GoalResolveOutcome.NONE
	if hide_splash_before_generate:
		splash_mode = SplashMode.NONE
		_set_footer_enabled(true)
		_set_splash_visible(false)

	if not reuse_current_profile:
		var dimensions: Vector2i = _get_level_dimensions(level)
		current_level_difficulty_scale = _get_level_difficulty_scale(level)
		grid_width = dimensions.x
		grid_height = dimensions.y
		level_seed = abs(hash([run_seed, level, grid_width, grid_height]))
		if level_seed == 0:
			level_seed = 1

	_apply_palette(level)

	var puzzle: Dictionary = MazeGeneratorScript.generate(grid_width, grid_height, level_seed, current_level_difficulty_scale)
	cell_values = puzzle["cell_values"]
	start_cell = puzzle["start"]
	goal_cell = puzzle["goal"]
	player_cell = start_cell
	move_animation_from = Vector2(player_cell)
	move_animation_to = Vector2(player_cell)
	solution_path = puzzle["solution_path"]
	optimal_steps = puzzle["solution_length"]
	goal_target = puzzle["target_total"]
	max_cell_value = int(puzzle.get("max_cell_value", 9))
	player_total = 0
	player_steps = 0
	_rebuild_tile_value_colors()

	if audio_controller != null:
		audio_controller.play_player_entry()
		_sync_music_state()

	splash_mode = SplashMode.NONE
	_set_footer_enabled(true)
	_set_splash_visible(false)
	_update_ui()
	queue_redraw()


func _get_level_dimensions(current_level: int) -> Vector2i:
	var stage_progress: float = float(maxi(current_level - 1, 0)) * 0.48 + _get_skill_pressure(current_level) * 0.55
	var stage_index: int = clampi(int(floor(stage_progress)), 0, LEVEL_DIMENSION_PROFILES.size() - 1)
	return LEVEL_DIMENSION_PROFILES[stage_index]


func _get_level_difficulty_scale(current_level: int) -> float:
	var level_span: int = maxi(current_level - 1, 0)
	var early_levels: int = mini(level_span, 6)
	var late_levels: int = maxi(level_span - 6, 0)
	return 1.0 + float(early_levels) * 0.08 + float(late_levels) * 0.035 + _get_skill_pressure(current_level) * 0.12


func _get_skill_pressure(current_level: int) -> float:
	var taper: float = lerpf(1.35, 0.72, clampf(float(current_level - 1) / 8.0, 0.0, 1.0))
	return clampf(player_skill_rating * taper, 0.0, 1.0)


func _handle_grid_tap(screen_position: Vector2) -> void:
	var tapped_cell: Vector2i = _find_tapped_neighbor(screen_position)
	if tapped_cell.x < 0:
		return
	_move_player_to(tapped_cell)


func _find_tapped_neighbor(screen_position: Vector2) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_distance: float = INF
	for neighbor in _orthogonal_neighbors(player_cell):
		var distance: float = screen_position.distance_to(_cell_to_screen(neighbor))
		if distance > _get_tap_radius():
			continue
		if distance < best_distance:
			best_distance = distance
			best_cell = neighbor
	return best_cell


func _try_move_in_direction(direction: Vector2i) -> void:
	var target_cell: Vector2i = player_cell + direction
	if not _is_inside(target_cell):
		return
	_move_player_to(target_cell)


func _move_player_to(target_cell: Vector2i) -> void:
	var previous_cell: Vector2i = player_cell
	player_cell = target_cell
	move_animation_from = Vector2(previous_cell)
	move_animation_to = Vector2(target_cell)
	move_animation_elapsed = 0.0
	landing_bounce_cell = target_cell
	landing_bounce_elapsed = 0.0
	player_steps = _saturating_add(player_steps, 1)

	if player_cell != goal_cell:
		player_total = _saturating_add(player_total, _get_cell_value(player_cell))
		player_total_bounce_elapsed = 0.0

	if audio_controller != null:
		audio_controller.play_move()

	if player_cell == goal_cell:
		_resolve_goal_reached()
	else:
		_update_ui()
		_sync_music_state()

	queue_redraw()


func _complete_level() -> void:
	_queue_goal_resolution(GoalResolveOutcome.SUCCESS)


func _resolve_goal_reached() -> void:
	if player_total == goal_target:
		_complete_level()
		return
	_queue_goal_resolution(GoalResolveOutcome.FAILURE)


func _queue_goal_resolution(outcome: GoalResolveOutcome) -> void:
	pending_goal_outcome = outcome
	if not _is_move_animation_active():
		_begin_goal_resolution()


func _begin_goal_resolution() -> void:
	match pending_goal_outcome:
		GoalResolveOutcome.SUCCESS:
			goal_clear_elapsed = 0.0
			goal_fail_elapsed = GOAL_FAIL_DURATION
			if audio_controller != null:
				audio_controller.play_success()
		GoalResolveOutcome.FAILURE:
			goal_fail_elapsed = 0.0
			goal_clear_elapsed = GOAL_CLEAR_DURATION
			if audio_controller != null:
				audio_controller.play_failure()
		_:
			return
	pending_goal_outcome = GoalResolveOutcome.NONE
	_sync_music_state()


func _finish_level_complete() -> void:
	completed = true
	splash_mode = SplashMode.LEVEL_COMPLETE
	_record_level_result(true)
	run_total_score = _saturating_add(run_total_score, _calculate_star_rating())
	run_levels_cleared = _saturating_add(run_levels_cleared, 1)
	_set_footer_enabled(false)
	_update_ui()
	_update_completion_splash()
	_sync_music_state()


func _finish_level_failed() -> void:
	_record_level_result(false)
	_show_failure_splash()


func _advance_to_next_level() -> void:
	if splash_mode != SplashMode.LEVEL_COMPLETE:
		return
	level = _saturating_add(level, 1)
	level_retries = 0
	_generate_level(false)


func _update_ui() -> void:
	maze_label.text = _loc("GAME_TITLE")
	hud_by_label.text = _loc("BY")
	score_label.text = _loc("LEVEL_STATUS") % [level, player_total, goal_target]
	timer_label.text = _loc("MOVES") % player_steps
	invert_button.text = _get_invert_button_text()
	_refresh_localized_text()


func _update_completion_splash() -> void:
	_apply_ui_metrics()
	var stars: int = _calculate_star_rating()
	splash_title_label.text = _loc("LEVEL_CLEAR")
	splash_score_label.text = _loc("TOTAL_MOVES") % [player_total, goal_target, player_steps]
	if splash_logo_rect != null:
		splash_logo_rect.visible = false
	splash_optimal_label.visible = true
	splash_optimal_label.text = _loc("OPTIMAL") % optimal_steps
	splash_retries_label.visible = true
	splash_retries_label.text = _loc("RETRIES") % level_retries
	splash_best_label.visible = false
	splash_best_label.text = ""
	splash_stars_label.visible = true
	splash_stars_label.text = _build_star_string(stars)
	splash_stars_label.add_theme_color_override("font_color", goal_color)
	splash_action_button.text = _loc("NEXT")
	splash_action_button.visible = true
	splash_retry_button.visible = true
	splash_end_run_button.visible = true
	splash_invert_button.visible = false
	_set_volume_controls_visible(false)
	_set_language_control_visible(false)
	_set_splash_content_order([
		splash_action_button,
		splash_retry_button,
		splash_language_button,
		splash_music_label,
		splash_music_slider,
		splash_sfx_label,
		splash_sfx_slider,
		splash_invert_button,
		splash_end_run_button,
	])
	_set_splash_visible(true)
	_sync_menu_focus(true)


func _show_failure_splash() -> void:
	_apply_ui_metrics()
	splash_mode = SplashMode.LEVEL_FAILED
	completed = true
	_set_footer_enabled(false)
	splash_title_label.text = _loc("TRY_AGAIN")
	splash_score_label.text = _loc("TOTAL_MOVES") % [player_total, goal_target, player_steps]
	if splash_logo_rect != null:
		splash_logo_rect.visible = false
	splash_optimal_label.visible = true
	splash_optimal_label.text = _loc("OPTIMAL") % optimal_steps
	splash_retries_label.visible = false
	splash_retries_label.text = ""
	splash_best_label.visible = false
	splash_best_label.text = ""
	splash_stars_label.visible = false
	splash_action_button.text = _loc("RETRY")
	splash_action_button.visible = true
	splash_retry_button.visible = false
	splash_end_run_button.visible = true
	splash_invert_button.visible = false
	_set_volume_controls_visible(false)
	_set_language_control_visible(false)
	_set_splash_content_order([
		splash_action_button,
		splash_end_run_button,
		splash_retry_button,
		splash_language_button,
		splash_music_label,
		splash_music_slider,
		splash_sfx_label,
		splash_sfx_slider,
		splash_invert_button,
	])
	_set_splash_visible(true)
	_sync_menu_focus(true)
	_sync_music_state()


func _show_run_complete_splash() -> void:
	var final_score: int = _calculate_final_run_score()
	_remember_best_run_score(final_score)
	splash_mode = SplashMode.RUN_COMPLETE
	completed = true
	_set_footer_enabled(false)
	splash_title_label.text = _loc("RUN_OVER")
	splash_score_label.text = _loc("SCORE") % final_score
	if splash_logo_rect != null:
		splash_logo_rect.visible = false
	splash_optimal_label.visible = true
	splash_optimal_label.text = _loc("LEVELS") % run_levels_cleared
	splash_retries_label.visible = true
	splash_retries_label.text = _loc("RETRIES") % run_total_resets
	splash_best_label.visible = false
	splash_best_label.text = ""
	splash_stars_label.visible = true
	splash_stars_label.text = _loc("STARS") % run_total_score
	splash_stars_label.add_theme_color_override("font_color", text_color)
	splash_action_button.text = _get_splash_action_text()
	splash_action_button.visible = true
	splash_retry_button.visible = false
	splash_end_run_button.visible = false
	splash_invert_button.visible = false
	_set_volume_controls_visible(false)
	_set_language_control_visible(false)
	_apply_ui_metrics()
	_set_splash_content_order([
		splash_action_button,
		splash_retry_button,
		splash_end_run_button,
		splash_language_button,
		splash_music_label,
		splash_music_slider,
		splash_sfx_label,
		splash_sfx_slider,
		splash_invert_button,
	])
	_set_splash_visible(true)
	_sync_menu_focus(true)
	_sync_music_state()


func _show_pause_menu() -> void:
	if completed:
		return
	if splash_mode != SplashMode.NONE and splash_mode != SplashMode.PAUSED:
		return
	_apply_ui_metrics()
	splash_mode = SplashMode.PAUSED
	_set_footer_enabled(false)
	splash_title_label.text = _loc("PAUSED")
	splash_score_label.text = _loc("TOTAL_MOVES") % [player_total, goal_target, player_steps]
	if splash_logo_rect != null:
		splash_logo_rect.visible = false
	splash_optimal_label.visible = true
	splash_optimal_label.text = _loc("OPTIMAL") % optimal_steps
	splash_retries_label.visible = true
	splash_retries_label.text = _loc("RETRIES") % level_retries
	splash_best_label.visible = true
	splash_best_label.text = _get_best_score_text()
	splash_stars_label.visible = false
	splash_action_button.text = _loc("RESUME")
	splash_action_button.visible = true
	splash_retry_button.text = _loc("RETRY")
	splash_retry_button.visible = true
	splash_invert_button.visible = true
	splash_end_run_button.visible = true
	_set_volume_controls_visible(true)
	_set_language_control_visible(true)
	_sync_volume_controls()
	_set_splash_content_order([
		splash_action_button,
		splash_retry_button,
		splash_language_button,
		splash_music_label,
		splash_music_slider,
		splash_sfx_label,
		splash_sfx_slider,
		splash_invert_button,
		splash_end_run_button,
	])
	_set_splash_visible(true)
	_sync_menu_focus(true)
	_sync_music_state()


func _resume_from_pause() -> void:
	if splash_mode != SplashMode.PAUSED:
		return
	splash_mode = SplashMode.NONE
	_set_footer_enabled(true)
	_set_splash_visible(false)
	_update_ui()
	_sync_music_state()


func _show_title_screen() -> void:
	_apply_ui_metrics()
	splash_mode = SplashMode.TITLE
	completed = true
	title_loading_active = false
	if loading_timer != null:
		loading_timer.stop()
	grid_width = 0
	grid_height = 0
	_set_hud_visible(false)
	_set_footer_enabled(false)
	splash_title_label.text = _loc("GAME_TITLE")
	splash_score_label.text = _loc("BY")
	splash_score_label.visible = true
	splash_optimal_label.visible = true
	splash_optimal_label.text = _get_best_score_text()
	splash_retries_label.visible = false
	splash_retries_label.text = ""
	splash_best_label.visible = false
	splash_best_label.text = ""
	splash_stars_label.visible = false
	splash_action_button.text = _loc("START")
	splash_action_button.visible = true
	splash_retry_button.visible = false
	splash_end_run_button.visible = false
	splash_invert_button.visible = false
	_set_volume_controls_visible(true)
	_set_language_control_visible(true)
	_sync_volume_controls()
	_set_splash_content_order([
		splash_action_button,
		splash_language_button,
		splash_music_label,
		splash_music_slider,
		splash_sfx_label,
		splash_sfx_slider,
		splash_retry_button,
		splash_invert_button,
		splash_end_run_button,
	])
	if splash_logo_rect != null:
		splash_logo_rect.visible = true
	_set_splash_visible(true)
	_sync_menu_focus(true)


func _record_level_result(was_successful: bool) -> void:
	var sample: float = 0.0
	if was_successful:
		var path_efficiency: float = clampf(float(optimal_steps) / maxf(float(player_steps), float(optimal_steps)), 0.0, 1.0)
		var retry_penalty: float = minf(float(level_retries) * 0.14, 0.35)
		sample = clampf(path_efficiency - retry_penalty, 0.0, 1.0)
	else:
		sample = maxf(0.0, player_skill_rating - 0.16 - float(level_retries) * 0.03)

	var adapt_rate: float = 0.38 if level <= 4 else 0.18
	player_skill_rating = clampf(lerpf(player_skill_rating, sample, adapt_rate), 0.0, 1.0)


func _sync_music_state() -> void:
	if audio_controller == null:
		return
	audio_controller.sync_music_state(level, level_retries, player_total, goal_target, splash_mode != SplashMode.NONE, splash_mode == SplashMode.LEVEL_COMPLETE)


func _calculate_star_rating() -> int:
	var move_margin: int = maxi(player_steps - optimal_steps, 0)
	if move_margin == 0:
		return 3
	if move_margin <= maxi(2, int(ceili(current_level_difficulty_scale))):
		return 2
	return 1


func _calculate_final_run_score() -> int:
	return clampi(run_total_score * 120 + run_levels_cleared * 45 - run_total_resets * 18, 0, MAX_TRACKED_VALUE)


func _saturating_add(value: int, delta: int) -> int:
	return clampi(value + delta, 0, MAX_TRACKED_VALUE)


func _build_star_string(stars: int) -> String:
	var segments: Array[String] = []
	for index in range(3):
		segments.append("★" if index < stars else "☆")
	return " ".join(segments)


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
		var horizontal_direction: Vector2i = Vector2i.RIGHT if direction_sign > 0 else Vector2i.LEFT
		if _is_menu_navigation_active():
			_move_menu_focus(horizontal_direction)
			return
		_try_move_in_direction(horizontal_direction)
		return

	if joypad_y_state == direction_sign:
		return
	joypad_y_state = direction_sign
	var vertical_direction: Vector2i = Vector2i.DOWN if direction_sign > 0 else Vector2i.UP
	if _is_menu_navigation_active():
		_move_menu_focus(vertical_direction)
		return
	_try_move_in_direction(vertical_direction)


func _get_draw_area() -> Rect2:
	var viewport_size: Vector2 = get_viewport_rect().size
	return Rect2(
		Vector2(_get_outer_margin(), _get_top_hud_height()),
		viewport_size - Vector2(_get_outer_margin() * 2.0, _get_top_hud_height() + _get_bottom_hud_height())
	)


func _get_cell_size() -> float:
	var draw_area: Rect2 = _get_draw_area()
	return minf(draw_area.size.x / float(grid_width), draw_area.size.y / float(grid_height))


func _get_grid_origin(cell_size: float) -> Vector2:
	var draw_area: Rect2 = _get_draw_area()
	var grid_size: Vector2 = Vector2(grid_width, grid_height) * cell_size
	return draw_area.position + (draw_area.size - grid_size) * 0.5


func _cell_to_screen(cell: Vector2i) -> Vector2:
	var cell_size: float = _get_cell_size()
	return _get_grid_origin(cell_size) + (Vector2(cell.x, cell.y) + Vector2.ONE * 0.5) * cell_size


func _cell_vector_to_screen(cell: Vector2) -> Vector2:
	var cell_size: float = _get_cell_size()
	return _get_grid_origin(cell_size) + (cell + Vector2.ONE * 0.5) * cell_size


func _get_tap_radius() -> float:
	return maxf(_get_cell_size() * 0.42, 34.0)


func _build_ui() -> void:
	var ui: CanvasLayer = CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	top_panel = PanelContainer.new()
	top_panel.anchor_right = 1.0
	ui.add_child(top_panel)

	var top_content: VBoxContainer = VBoxContainer.new()
	top_content.add_theme_constant_override("separation", 10)
	top_panel.add_child(top_content)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_content.add_child(top_row)

	var brand_row: HBoxContainer = HBoxContainer.new()
	brand_row.add_theme_constant_override("separation", 10)
	brand_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(brand_row)

	maze_label = Label.new()
	maze_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	maze_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_row.add_child(maze_label)

	hud_by_label = Label.new()
	hud_by_label.text = _loc("BY")
	hud_by_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brand_row.add_child(hud_by_label)

	hud_logo_rect = TextureRect.new()
	hud_logo_rect.texture = _load_company_logo_texture()
	hud_logo_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	hud_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud_logo_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brand_row.add_child(hud_logo_rect)

	pause_button = _make_button("||")
	pause_button.custom_minimum_size = Vector2(round(88.0 * _get_ui_scale()), 0.0)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.pressed.connect(_show_pause_menu)
	top_row.add_child(pause_button)

	var detail_row: HBoxContainer = HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 14)
	top_content.add_child(detail_row)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(score_label)

	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(timer_label)

	invert_button = _make_button(_get_invert_button_text())
	invert_button.focus_mode = Control.FOCUS_NONE
	invert_button.pressed.connect(_toggle_invert_colors)
	detail_row.add_child(invert_button)

	bottom_panel = PanelContainer.new()
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	ui.add_child(bottom_panel)

	var bottom_content: HBoxContainer = HBoxContainer.new()
	bottom_content.add_theme_constant_override("separation", 12)
	bottom_panel.add_child(bottom_content)

	retry_button = _make_button("RETRY")
	retry_button.pressed.connect(_restart_level)
	retry_button.focus_mode = Control.FOCUS_NONE
	bottom_content.add_child(retry_button)

	end_run_button = _make_button("END RUN")
	end_run_button.pressed.connect(_end_run)
	end_run_button.focus_mode = Control.FOCUS_NONE
	bottom_content.add_child(end_run_button)

	splash_center = CenterContainer.new()
	splash_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_center.mouse_filter = Control.MOUSE_FILTER_PASS
	ui.add_child(splash_center)

	splash_panel = PanelContainer.new()
	splash_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	splash_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	splash_panel.visible = false
	splash_center.add_child(splash_panel)

	splash_content = VBoxContainer.new()
	splash_content.add_theme_constant_override("separation", 12)
	splash_panel.add_child(splash_content)

	splash_title_label = Label.new()
	splash_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_content.add_child(splash_title_label)

	splash_score_label = _make_splash_stat_label()
	splash_content.add_child(splash_score_label)

	splash_logo_rect = TextureRect.new()
	splash_logo_rect.texture = _load_company_logo_texture()
	splash_logo_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	splash_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	splash_logo_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	splash_logo_rect.visible = false
	splash_content.add_child(splash_logo_rect)

	splash_optimal_label = _make_splash_stat_label()
	splash_content.add_child(splash_optimal_label)

	splash_retries_label = _make_splash_stat_label()
	splash_content.add_child(splash_retries_label)

	splash_best_label = _make_splash_stat_label()
	splash_best_label.visible = false
	splash_content.add_child(splash_best_label)

	splash_stars_label = Label.new()
	splash_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_content.add_child(splash_stars_label)

	splash_music_label = _make_splash_stat_label()
	splash_music_label.text = _loc("MUSIC")
	splash_music_label.visible = false
	splash_content.add_child(splash_music_label)

	splash_music_slider = HSlider.new()
	splash_music_slider.min_value = 0.0
	splash_music_slider.max_value = 1.0
	splash_music_slider.step = 0.05
	splash_music_slider.focus_mode = Control.FOCUS_ALL
	splash_music_slider.visible = false
	splash_music_slider.value_changed.connect(_handle_music_volume_changed)
	_connect_menu_focus(splash_music_slider)
	splash_content.add_child(splash_music_slider)

	splash_sfx_label = _make_splash_stat_label()
	splash_sfx_label.text = _loc("SFX")
	splash_sfx_label.visible = false
	splash_content.add_child(splash_sfx_label)

	splash_sfx_slider = HSlider.new()
	splash_sfx_slider.min_value = 0.0
	splash_sfx_slider.max_value = 1.0
	splash_sfx_slider.step = 0.05
	splash_sfx_slider.focus_mode = Control.FOCUS_ALL
	splash_sfx_slider.visible = false
	splash_sfx_slider.value_changed.connect(_handle_sfx_volume_changed)
	_connect_menu_focus(splash_sfx_slider)
	splash_content.add_child(splash_sfx_slider)

	splash_language_button = _make_button("")
	splash_language_button.pressed.connect(_cycle_language)
	splash_language_button.visible = false
	_connect_menu_focus(splash_language_button)
	splash_content.add_child(splash_language_button)

	splash_action_button = _make_button(_get_splash_action_text())
	splash_action_button.pressed.connect(_handle_splash_action)
	_connect_menu_focus(splash_action_button)
	splash_content.add_child(splash_action_button)

	splash_retry_button = _make_button(_loc("RETRY"))
	splash_retry_button.pressed.connect(_handle_splash_retry)
	splash_retry_button.visible = false
	_connect_menu_focus(splash_retry_button)
	splash_content.add_child(splash_retry_button)

	splash_invert_button = _make_button(_loc("INVERT"))
	splash_invert_button.pressed.connect(_handle_splash_invert)
	splash_invert_button.visible = false
	_connect_menu_focus(splash_invert_button)
	splash_content.add_child(splash_invert_button)

	splash_end_run_button = _make_button(_loc("END_RUN"))
	splash_end_run_button.pressed.connect(_handle_splash_end_run)
	splash_end_run_button.visible = false
	_connect_menu_focus(splash_end_run_button)
	splash_content.add_child(splash_end_run_button)

	_apply_palette_to_ui()


func _build_advance_timer() -> void:
	advance_timer = Timer.new()
	advance_timer.one_shot = true
	advance_timer.timeout.connect(_advance_to_next_level)
	add_child(advance_timer)


func _build_loading_timer() -> void:
	loading_timer = Timer.new()
	loading_timer.one_shot = true
	loading_timer.timeout.connect(_finish_title_loading)
	add_child(loading_timer)


func _build_audio() -> void:
	audio_controller = ProceduralAudioScript.new()
	audio_controller.name = "ProceduralAudio"
	add_child(audio_controller)


func _handle_splash_action() -> void:
	if _is_content_fade_active():
		return
	if audio_controller != null:
		audio_controller.play_menu_confirm()
	match splash_mode:
		SplashMode.TITLE:
			_begin_content_fade(TransitionAction.START_RUN)
		SplashMode.PAUSED:
			_resume_from_pause()
		SplashMode.LEVEL_COMPLETE:
			_begin_content_fade(TransitionAction.NEXT_LEVEL)
		SplashMode.LEVEL_FAILED:
			_restart_level()
		SplashMode.RUN_COMPLETE:
			_begin_content_fade(TransitionAction.START_RUN)


func _handle_splash_retry() -> void:
	if _is_content_fade_active():
		return
	if splash_mode == SplashMode.PAUSED:
		splash_mode = SplashMode.NONE
		completed = false
		_restart_level()
		return

	if splash_mode == SplashMode.LEVEL_FAILED:
		splash_mode = SplashMode.NONE
		completed = false
		_restart_level()
		return

	if splash_mode != SplashMode.LEVEL_COMPLETE:
		return

	run_total_score = clampi(run_total_score - _calculate_star_rating(), 0, MAX_TRACKED_VALUE)
	run_levels_cleared = clampi(run_levels_cleared - 1, 0, MAX_TRACKED_VALUE)
	splash_mode = SplashMode.NONE
	completed = false
	_restart_level()


func _handle_splash_end_run() -> void:
	if _is_content_fade_active():
		return
	if audio_controller != null:
		audio_controller.play_menu_confirm()
	_show_run_complete_splash()


func _handle_splash_invert() -> void:
	if _is_content_fade_active():
		return
	if splash_mode != SplashMode.PAUSED:
		return
	_toggle_invert_colors()
	_show_pause_menu()


func _begin_content_fade(action: TransitionAction) -> void:
	pending_transition_action = action
	content_fade_direction = 1
	content_fade_elapsed = 0.0
	_set_footer_enabled(false)


func _perform_pending_transition_action() -> void:
	var action: TransitionAction = pending_transition_action
	pending_transition_action = TransitionAction.NONE
	match action:
		TransitionAction.START_RUN:
			title_loading_active = true
			_show_loading_splash()
			if loading_timer != null:
				loading_timer.start(TITLE_LOADING_DELAY)
		TransitionAction.NEXT_LEVEL:
			_advance_to_next_level()
		_:
			_reset_content_fade()
			return
	if action == TransitionAction.START_RUN:
		_reset_content_fade()
		return
	content_fade_direction = -1
	content_fade_elapsed = 0.0


func _is_content_fade_active() -> bool:
	return content_fade_direction != 0 and content_fade_elapsed < CONTENT_FADE_DURATION


func _get_content_fade_alpha() -> float:
	if content_fade_direction == 0:
		return 1.0
	var progress: float = clampf(content_fade_elapsed / CONTENT_FADE_DURATION, 0.0, 1.0)
	return 1.0 - progress if content_fade_direction > 0 else progress


func _reset_content_fade() -> void:
	content_fade_direction = 0
	content_fade_elapsed = CONTENT_FADE_DURATION
	pending_transition_action = TransitionAction.NONE


func _apply_content_fade_to_ui() -> void:
	var alpha: float = _get_content_fade_alpha()
	if splash_panel != null:
		splash_panel.modulate.a = alpha


func _finish_title_loading() -> void:
	if not title_loading_active:
		return
	_start_new_run()


func _show_loading_splash() -> void:
	_apply_ui_metrics()
	splash_mode = SplashMode.TITLE
	completed = true
	_set_hud_visible(false)
	_set_footer_enabled(false)
	splash_title_label.text = _loc("LOADING")
	splash_score_label.text = _loc("BUILDING_RUN")
	splash_score_label.visible = true
	splash_optimal_label.visible = false
	splash_optimal_label.text = ""
	splash_retries_label.visible = false
	splash_retries_label.text = ""
	splash_best_label.visible = false
	splash_best_label.text = ""
	splash_stars_label.visible = true
	splash_stars_label.add_theme_color_override("font_color", goal_color)
	splash_action_button.visible = false
	splash_retry_button.visible = false
	splash_end_run_button.visible = false
	splash_invert_button.visible = false
	_set_volume_controls_visible(false)
	_set_language_control_visible(false)
	if splash_logo_rect != null:
		splash_logo_rect.visible = true
	_set_splash_visible(true)
	_refresh_loading_indicator()


func _refresh_loading_indicator() -> void:
	if not title_loading_active or splash_stars_label == null:
		return
	var step: int = int(floor(pulse_time * 6.0)) % 4
	var dots: String = ".".repeat(maxi(step, 1))
	splash_stars_label.text = dots


func _set_splash_content_order(nodes: Array) -> void:
	if splash_content == null or splash_stars_label == null:
		return
	var insert_index: int = splash_stars_label.get_index() + 1
	for node_variant in nodes:
		var node: Node = node_variant
		if node == null or node.get_parent() != splash_content:
			continue
		splash_content.move_child(node, insert_index)
		insert_index += 1


func _is_loading_transition_active() -> bool:
	return title_loading_active


func _loc(key: String) -> String:
	return LocalizationScript.get_text(language_code, key)


func _get_language_button_text() -> String:
	return _loc("LANGUAGE_VALUE") % LocalizationScript.get_language_name(language_code)


func _refresh_localized_text() -> void:
	if splash_music_label != null:
		splash_music_label.text = _loc("MUSIC")
	if splash_sfx_label != null:
		splash_sfx_label.text = _loc("SFX")
	if retry_button != null:
		retry_button.text = _loc("RETRY")
	if end_run_button != null:
		end_run_button.text = _loc("END_RUN")
	if splash_retry_button != null and splash_mode != SplashMode.LEVEL_COMPLETE:
		splash_retry_button.text = _loc("RETRY")
	if splash_invert_button != null:
		splash_invert_button.text = _loc("INVERT")
	if splash_end_run_button != null:
		splash_end_run_button.text = _loc("END_RUN")
	if splash_language_button != null:
		splash_language_button.text = _get_language_button_text()


func _configure_input_actions() -> void:
	_ensure_key_action(ACTION_ACCEPT, KEY_ENTER)
	_ensure_key_action(ACTION_ACCEPT, KEY_KP_ENTER)
	_ensure_key_action(ACTION_ACCEPT, KEY_SPACE)
	_ensure_joypad_action(ACTION_ACCEPT, JOY_BUTTON_A)
	_ensure_key_action(ACTION_RETRY, KEY_R)
	_ensure_joypad_action(ACTION_RETRY, JOY_BUTTON_Y)
	_ensure_key_action(ACTION_END_RUN, KEY_E)
	_ensure_joypad_action(ACTION_END_RUN, JOY_BUTTON_B)
	_ensure_key_action(ACTION_INVERT, KEY_I)
	_ensure_joypad_action(ACTION_INVERT, JOY_BUTTON_X)
	_ensure_key_action(ACTION_PAUSE, KEY_ESCAPE)
	_ensure_joypad_action(ACTION_PAUSE, JOY_BUTTON_START)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and existing_event.keycode == keycode:
			return
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)


func _ensure_joypad_action(action_name: StringName, button_index: JoyButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventJoypadButton and existing_event.button_index == button_index:
			return
	var button_event: InputEventJoypadButton = InputEventJoypadButton.new()
	button_event.button_index = button_index
	InputMap.action_add_event(action_name, button_event)


func _get_splash_action_text() -> String:
	if splash_mode == SplashMode.TITLE:
		return _loc("START")
	if splash_mode == SplashMode.RUN_COMPLETE:
		return _loc("NEW_RUN")
	return _loc("NEXT")


func _get_invert_button_text() -> String:
	return _loc("INVERT")


func _toggle_invert_colors() -> void:
	invert_colors_enabled = not invert_colors_enabled
	_apply_palette(level)
	_update_ui()
	_save_persistent_data()
	if audio_controller != null:
		audio_controller.play_invert()
	queue_redraw()


func _make_button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _connect_menu_focus(control: Control) -> void:
	control.focus_entered.connect(func() -> void:
		_set_menu_focus_from_control(control)
	)
	control.mouse_entered.connect(func() -> void:
		if control.visible:
			control.grab_focus()
	)


func _make_splash_stat_label() -> Label:
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _load_company_logo_texture() -> Texture2D:
	if company_logo_texture != null:
		return company_logo_texture
	var image: Image = Image.new()
	if image.load(ProjectSettings.globalize_path(COMPANY_LOGO_PATH)) != OK:
		return null
	company_logo_texture = ImageTexture.create_from_image(image)
	return company_logo_texture


func _set_hud_visible(is_visible: bool) -> void:
	if top_panel != null:
		top_panel.visible = is_visible
	if bottom_panel != null:
		bottom_panel.visible = is_visible
	_refresh_ui_layout()


func _set_volume_controls_visible(is_visible: bool) -> void:
	if splash_music_label != null:
		splash_music_label.visible = is_visible
	if splash_music_slider != null:
		splash_music_slider.visible = is_visible
	if splash_sfx_label != null:
		splash_sfx_label.visible = is_visible
	if splash_sfx_slider != null:
		splash_sfx_slider.visible = is_visible


func _set_language_control_visible(is_visible: bool) -> void:
	if splash_language_button != null:
		splash_language_button.visible = is_visible
		if is_visible:
			splash_language_button.text = _get_language_button_text()


func _sync_volume_controls() -> void:
	if audio_controller == null:
		return
	if splash_music_slider != null:
		splash_music_slider.set_value_no_signal(audio_controller.get_music_volume())
	if splash_sfx_slider != null:
		splash_sfx_slider.set_value_no_signal(audio_controller.get_sfx_volume())


func _cycle_language() -> void:
	var languages: Array = LocalizationScript.get_languages()
	if languages.is_empty():
		return
	var current_index: int = 0
	for index in range(languages.size()):
		var entry: Dictionary = languages[index]
		if String(entry.get("code", "")) == language_code:
			current_index = index
			break
	var next_index: int = posmod(current_index + 1, languages.size())
	var next_entry: Dictionary = languages[next_index]
	_set_language(String(next_entry.get("code", LocalizationScript.DEFAULT_LANGUAGE)))


func _set_language(next_language_code: String) -> void:
	var normalized_code: String = next_language_code if LocalizationScript.has_language(next_language_code) else LocalizationScript.DEFAULT_LANGUAGE
	if language_code == normalized_code and splash_language_button != null:
		splash_language_button.text = _get_language_button_text()
		return
	language_code = normalized_code
	_refresh_ui_layout()
	_refresh_localized_text()
	match splash_mode:
		SplashMode.TITLE:
			if title_loading_active:
				_show_loading_splash()
			else:
				_show_title_screen()
		SplashMode.PAUSED:
			_show_pause_menu()
		SplashMode.LEVEL_COMPLETE:
			_update_completion_splash()
		SplashMode.LEVEL_FAILED:
			_show_failure_splash()
		SplashMode.RUN_COMPLETE:
			_show_run_complete_splash()
		_:
			_update_ui()
	_save_persistent_data()
	queue_redraw()


func _handle_music_volume_changed(value: float) -> void:
	music_volume_setting = clampf(value, 0.0, 1.0)
	if audio_controller == null:
		_save_persistent_data()
		return
	audio_controller.set_music_volume(music_volume_setting)
	_save_persistent_data()


func _handle_sfx_volume_changed(value: float) -> void:
	sfx_volume_setting = clampf(value, 0.0, 1.0)
	if audio_controller == null:
		_save_persistent_data()
		return
	audio_controller.set_sfx_volume(sfx_volume_setting)
	_save_persistent_data()


func _is_marker_intro_active() -> bool:
	return marker_intro_elapsed < MARKER_INTRO_DURATION


func _is_goal_clear_active() -> bool:
	return goal_clear_elapsed < GOAL_CLEAR_DURATION


func _is_goal_fail_active() -> bool:
	return goal_fail_elapsed < GOAL_FAIL_DURATION


func _is_move_animation_active() -> bool:
	return move_animation_elapsed < MOVE_ANIMATION_DURATION


func _is_landing_bounce_active() -> bool:
	return landing_bounce_elapsed < LANDING_BOUNCE_DURATION and landing_bounce_cell.x >= 0


func _is_player_total_bounce_active() -> bool:
	return player_total_bounce_elapsed < PLAYER_TOTAL_BOUNCE_DURATION


func _has_active_animation() -> bool:
	return _is_marker_intro_active() or _is_move_animation_active() or _is_landing_bounce_active() or _is_goal_clear_active() or _is_goal_fail_active() or pending_goal_outcome != GoalResolveOutcome.NONE


func _skip_active_animations() -> void:
	marker_intro_elapsed = MARKER_INTRO_DURATION
	if _is_goal_clear_active():
		move_animation_elapsed = MOVE_ANIMATION_DURATION
		goal_clear_elapsed = GOAL_CLEAR_DURATION
		pending_goal_outcome = GoalResolveOutcome.NONE
		_finish_level_complete()
		return
	if _is_goal_fail_active():
		move_animation_elapsed = MOVE_ANIMATION_DURATION
		goal_fail_elapsed = GOAL_FAIL_DURATION
		pending_goal_outcome = GoalResolveOutcome.NONE
		_finish_level_failed()
		return
	if _is_move_animation_active():
		move_animation_elapsed = MOVE_ANIMATION_DURATION
		landing_bounce_elapsed = LANDING_BOUNCE_DURATION
		if pending_goal_outcome != GoalResolveOutcome.NONE:
			_begin_goal_resolution()
		return
	move_animation_elapsed = MOVE_ANIMATION_DURATION
	landing_bounce_elapsed = LANDING_BOUNCE_DURATION
	goal_clear_elapsed = GOAL_CLEAR_DURATION
	goal_fail_elapsed = GOAL_FAIL_DURATION


func _is_skip_input_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventJoypadMotion:
		return absf(event.axis_value) >= JOYPAD_TRIGGER
	return false


func _is_movement_input_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return _direction_from_key(event) != Vector2i.ZERO
	if event is InputEventJoypadButton:
		return _direction_from_joypad_button(event) != Vector2i.ZERO
	if event is InputEventJoypadMotion:
		return absf(event.axis_value) >= JOYPAD_TRIGGER
	if event is InputEventMouseButton and event.pressed:
		return true
	if event is InputEventScreenTouch and event.pressed:
		return true
	return false


func _get_marker_intro_scale(base_radius: float) -> float:
	if not _is_marker_intro_active():
		return 1.0

	var viewport_size: Vector2 = get_viewport_rect().size
	var target_start_radius: float = minf(viewport_size.x, viewport_size.y) * 0.36
	var start_scale: float = maxf(MARKER_INTRO_START_SCALE, target_start_radius / maxf(base_radius, 1.0))
	var progress: float = clampf(marker_intro_elapsed / MARKER_INTRO_DURATION, 0.0, 1.0)
	var eased_progress: float = 1.0 - pow(1.0 - progress, 3.0)
	var settle_scale: float = lerpf(start_scale, 1.0, eased_progress)
	var bounce_progress: float = clampf((progress - 0.32) / 0.68, 0.0, 1.0)
	var bounce: float = sin(bounce_progress * PI * 2.6) * pow(1.0 - bounce_progress, 1.35) * 0.24
	return settle_scale * (1.0 + bounce)


func _get_player_draw_position() -> Vector2:
	if not _is_move_animation_active():
		return _cell_to_screen(player_cell)

	var progress: float = clampf(move_animation_elapsed / MOVE_ANIMATION_DURATION, 0.0, 1.0)
	var eased_progress: float = 1.0 - pow(1.0 - progress, 2.2)
	var animated_cell: Vector2 = move_animation_from.lerp(move_animation_to, eased_progress)
	var screen_position: Vector2 = _cell_vector_to_screen(animated_cell)
	var hop_height: float = sin(progress * PI) * _get_cell_size() * 0.18
	return screen_position + Vector2(0.0, -hop_height)


func _get_player_move_scale() -> float:
	if not _is_move_animation_active():
		return 1.0
	var progress: float = clampf(move_animation_elapsed / MOVE_ANIMATION_DURATION, 0.0, 1.0)
	return 1.0 + sin(progress * PI) * 0.12


func _get_player_total_bounce_scale() -> float:
	if not _is_player_total_bounce_active():
		return 1.0
	var progress: float = clampf(player_total_bounce_elapsed / PLAYER_TOTAL_BOUNCE_DURATION, 0.0, 1.0)
	return 1.0 + sin(progress * PI) * 0.22


func _get_goal_clear_scale() -> float:
	if not _is_goal_clear_active():
		return 1.0

	var progress: float = clampf(goal_clear_elapsed / GOAL_CLEAR_DURATION, 0.0, 1.0)
	var wave: float = sin(progress * PI)
	return 1.0 + wave * 0.5


func _get_goal_fail_scale() -> float:
	if not _is_goal_fail_active():
		return 1.0
	var progress: float = clampf(goal_fail_elapsed / GOAL_FAIL_DURATION, 0.0, 1.0)
	return 1.0 + sin(progress * PI) * 0.18


func _get_goal_fail_shake(cell_size: float) -> Vector2:
	if not _is_goal_fail_active():
		return Vector2.ZERO
	var progress: float = clampf(goal_fail_elapsed / GOAL_FAIL_DURATION, 0.0, 1.0)
	var damping: float = 1.0 - progress
	return Vector2(sin(progress * TAU * 6.0) * cell_size * 0.045 * damping, 0.0)


func _get_player_clear_scale() -> float:
	if not _is_goal_clear_active():
		return 1.0

	var progress: float = clampf(goal_clear_elapsed / GOAL_CLEAR_DURATION, 0.0, 1.0)
	var eased_progress: float = 1.0 - pow(1.0 - progress, 3.0)
	return lerpf(1.24, 0.92, eased_progress)


func _get_player_fail_scale() -> float:
	if not _is_goal_fail_active():
		return 1.0
	var progress: float = clampf(goal_fail_elapsed / GOAL_FAIL_DURATION, 0.0, 1.0)
	return 1.0 + sin(progress * PI) * 0.1


func _apply_palette(level_value: int) -> void:
	var difficulty: float = clampf(float(level_value - 1) / 14.0, 0.0, 1.0)
	var accent_hue: float = lerpf(0.58, 0.03, difficulty)
	if invert_colors_enabled:
		text_color = DARK_TEXT_COLOR
		outline_color = LIGHT_OUTLINE_COLOR
		background_color = Color("f4f0ff")
		background_glow_color = Color.from_hsv(accent_hue, 0.24, 0.98)
		secondary_glow_color = Color.from_hsv(fposmod(accent_hue + 0.12, 1.0), 0.3, 0.9)
		playfield_color = Color("fffaf8")
		playfield_trim_color = Color.from_hsv(accent_hue, 0.46, 0.66)
		grid_line_color = Color.from_hsv(fposmod(accent_hue - 0.05, 1.0), 0.4, 0.56)
		start_color = Color.from_hsv(0.35, 0.45, 0.7)
		goal_color = Color.from_hsv(0.12 - 0.02 * difficulty, 0.74, 0.9)
		warning_color = Color.from_hsv(0.02 + 0.01 * difficulty, 0.68, 0.84)
		player_color = Color("d774af")
		player_core_color = Color("ffe8b6")
		cell_number_color = Color("203147")
		panel_color = Color("efe6ff")
		panel_border_color = Color("b58cff")
		retry_button_color = Color("d8d1ff")
		retry_button_hover_color = Color("e5dcff")
		retry_button_pressed_color = Color("c7bcff")
		end_button_color = Color("ffd1e6")
		end_button_hover_color = Color("ffddef")
		end_button_pressed_color = Color("ffb7da")
	else:
		text_color = BRIGHT_TEXT_COLOR
		outline_color = DARK_OUTLINE_COLOR
		background_color = Color("130f24")
		background_glow_color = Color.from_hsv(accent_hue, 0.42, 0.56)
		secondary_glow_color = Color.from_hsv(fposmod(accent_hue + 0.16, 1.0), 0.34, 0.88)
		playfield_color = Color("1f1638")
		playfield_trim_color = Color.from_hsv(accent_hue, 0.56, 0.96)
		grid_line_color = Color.from_hsv(fposmod(accent_hue - 0.03, 1.0), 0.48, 0.88)
		start_color = Color("5fd08c")
		goal_color = Color.from_hsv(0.12 - 0.02 * difficulty, 0.72, 0.98)
		warning_color = Color.from_hsv(0.01 + 0.02 * difficulty, 0.74, 0.94)
		player_color = Color("ff78bf")
		player_core_color = Color("ffe7b3")
		cell_number_color = Color("d7e3f4")
		panel_color = Color("2a1b52")
		panel_border_color = Color("6c4cff")
		retry_button_color = Color("4f4bb5")
		retry_button_hover_color = Color("6765c9")
		retry_button_pressed_color = Color("807de0")
		end_button_color = Color("ba4f9c")
		end_button_hover_color = Color("d465ad")
		end_button_pressed_color = Color("e87cc0")
	_apply_palette_to_ui()
	_rebuild_tile_value_colors()


func _apply_palette_to_ui() -> void:
	if top_panel == null:
		return

	top_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_color, panel_border_color, background_glow_color))
	bottom_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_color, panel_border_color, secondary_glow_color))
	splash_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_color.lightened(0.06), panel_border_color.lightened(0.08), goal_color))

	maze_label.add_theme_color_override("font_color", text_color)
	maze_label.add_theme_color_override("font_outline_color", outline_color)
	hud_by_label.add_theme_color_override("font_color", text_color)
	hud_by_label.add_theme_color_override("font_outline_color", outline_color)
	score_label.add_theme_color_override("font_color", text_color)
	score_label.add_theme_color_override("font_outline_color", outline_color)
	timer_label.add_theme_color_override("font_color", text_color)
	timer_label.add_theme_color_override("font_outline_color", outline_color)

	_apply_button_palette(retry_button, retry_button_color, retry_button_hover_color, retry_button_pressed_color)
	_apply_button_palette(end_run_button, end_button_color, end_button_hover_color, end_button_pressed_color)
	_apply_button_palette(invert_button, retry_button_color, retry_button_hover_color, retry_button_pressed_color)
	_apply_button_palette(pause_button, end_button_color, end_button_hover_color, end_button_pressed_color)
	_apply_button_palette(splash_language_button, retry_button_color, retry_button_hover_color, retry_button_pressed_color)
	_apply_button_palette(splash_action_button, end_button_color, end_button_hover_color, end_button_pressed_color)
	_apply_button_palette(splash_retry_button, retry_button_color, retry_button_hover_color, retry_button_pressed_color)
	_apply_button_palette(splash_invert_button, retry_button_color, retry_button_hover_color, retry_button_pressed_color)
	_apply_button_palette(splash_end_run_button, end_button_color, end_button_hover_color, end_button_pressed_color)

	splash_title_label.add_theme_color_override("font_color", text_color)
	splash_title_label.add_theme_color_override("font_outline_color", outline_color)
	splash_score_label.add_theme_color_override("font_color", text_color)
	splash_score_label.add_theme_color_override("font_outline_color", outline_color)
	splash_optimal_label.add_theme_color_override("font_color", text_color)
	splash_optimal_label.add_theme_color_override("font_outline_color", outline_color)
	splash_retries_label.add_theme_color_override("font_color", text_color)
	splash_retries_label.add_theme_color_override("font_outline_color", outline_color)
	splash_best_label.add_theme_color_override("font_color", text_color)
	splash_best_label.add_theme_color_override("font_outline_color", outline_color)
	splash_music_label.add_theme_color_override("font_color", text_color)
	splash_music_label.add_theme_color_override("font_outline_color", outline_color)
	splash_sfx_label.add_theme_color_override("font_color", text_color)
	splash_sfx_label.add_theme_color_override("font_outline_color", outline_color)
	splash_stars_label.add_theme_color_override("font_outline_color", outline_color)
	_apply_slider_palette(splash_music_slider)
	_apply_slider_palette(splash_sfx_slider)


func _refresh_ui_layout() -> void:
	if top_panel == null:
		return

	var margin: float = _get_outer_margin()
	_apply_ui_metrics()
	var top_height: float = _get_top_hud_height()
	var bottom_height: float = _get_bottom_hud_height()
	var viewport_size: Vector2 = get_viewport_rect().size
	var available_middle_height: float = maxf(viewport_size.y - top_height - bottom_height - margin * 4.0, 280.0 * _get_ui_scale())
	var splash_width: float = minf(viewport_size.x - margin * 2.0, 820.0 * _get_ui_scale())
	var splash_height: float = minf(available_middle_height, 900.0 * _get_ui_scale())

	top_panel.offset_left = margin
	top_panel.offset_top = margin
	top_panel.offset_right = -margin
	top_panel.offset_bottom = top_height - margin

	bottom_panel.offset_left = margin
	bottom_panel.offset_top = -bottom_height + margin
	bottom_panel.offset_right = -margin
	bottom_panel.offset_bottom = -margin

	splash_center.offset_left = margin
	splash_center.offset_top = top_height
	splash_center.offset_right = -margin
	splash_center.offset_bottom = -bottom_height
	splash_panel.custom_minimum_size = Vector2(splash_width, splash_height)


func _apply_ui_metrics() -> void:
	var scale: float = _get_ui_scale()
	var header_size: int = int(round(58.0 * scale))
	var detail_size: int = int(round(44.0 * scale))
	var button_size: int = int(round(38.0 * scale))
	var splash_title_size: int = int(round(92.0 * scale))
	var splash_stat_size: int = int(round(48.0 * scale))
	var splash_score_size: int = int(round((96.0 if splash_mode == SplashMode.RUN_COMPLETE else 48.0) * scale))
	var splash_star_size: int = int(round((54.0 if splash_mode == SplashMode.RUN_COMPLETE else 92.0) * scale))
	_apply_label_style(maze_label, header_size, 7, player_color)
	maze_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_style(hud_by_label, detail_size, 5, goal_color)
	hud_by_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_style(score_label, header_size, 7, goal_color)
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_style(timer_label, detail_size, 6, text_color)
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_logo_rect.custom_minimum_size = Vector2(round(292.0 * scale), round(62.0 * scale))

	_apply_label_style(splash_title_label, splash_title_size, 8, goal_color)
	_apply_label_style(splash_score_label, splash_score_size, 8 if splash_mode == SplashMode.RUN_COMPLETE else 6, player_color)
	_apply_label_style(splash_optimal_label, splash_stat_size, 6, start_color)
	_apply_label_style(splash_retries_label, splash_stat_size, 6, text_color)
	_apply_label_style(splash_best_label, splash_stat_size, 6, goal_color)
	_apply_label_style(splash_music_label, splash_stat_size, 6, text_color)
	_apply_label_style(splash_sfx_label, splash_stat_size, 6, text_color)
	splash_logo_rect.custom_minimum_size = Vector2(0.0, round(220.0 * scale))
	splash_music_slider.custom_minimum_size = Vector2(round(520.0 * scale), round(62.0 * scale))
	splash_sfx_slider.custom_minimum_size = Vector2(round(520.0 * scale), round(62.0 * scale))

	splash_stars_label.add_theme_font_override("font", _get_active_ui_font())
	splash_stars_label.add_theme_font_size_override("font_size", splash_star_size)
	splash_stars_label.add_theme_constant_override("outline_size", 8)
	splash_stars_label.add_theme_color_override("font_outline_color", outline_color)

	_apply_button_style_metrics(retry_button, button_size)
	_apply_button_style_metrics(end_run_button, button_size)
	_apply_button_style_metrics(invert_button, button_size)
	_apply_button_style_metrics(pause_button, button_size)
	_apply_button_style_metrics(splash_language_button, splash_stat_size)
	_apply_button_style_metrics(splash_action_button, splash_stat_size)
	_apply_button_style_metrics(splash_retry_button, splash_stat_size)
	_apply_button_style_metrics(splash_invert_button, splash_stat_size)
	_apply_button_style_metrics(splash_end_run_button, splash_stat_size)


func _apply_label_style(label: Label, font_size: int, outline_size: int, color: Color) -> void:
	label.add_theme_font_override("font", _get_active_ui_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", outline_color)


func _apply_button_style_metrics(button: Button, font_size: int) -> void:
	button.custom_minimum_size = Vector2(0.0, round(122.0 * _get_ui_scale()))
	button.add_theme_font_override("font", _get_active_ui_font())
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_constant_override("outline_size", 10 if button in [splash_language_button, splash_action_button, splash_retry_button, splash_invert_button, splash_end_run_button] else 8)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_outline_color", outline_color)

	if button == pause_button:
		button.custom_minimum_size.x = round(162.0 * _get_ui_scale())
	elif button == invert_button:
		button.custom_minimum_size.x = round(162.0 * _get_ui_scale())
	elif button == splash_language_button:
		button.custom_minimum_size.x = round(420.0 * _get_ui_scale())


func _apply_slider_palette(slider: HSlider) -> void:
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
	slider.add_theme_icon_override("grabber", _make_slider_grabber_icon(end_button_color, 34 if is_focused else 28))
	slider.add_theme_icon_override("grabber_highlight", _make_slider_grabber_icon(end_button_hover_color, 36 if is_focused else 30))


func _make_slider_grabber_icon(color: Color, size: int = 28) -> ImageTexture:
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


func _refresh_dynamic_control_styles() -> void:
	if splash_music_slider != null and splash_music_slider.visible:
		_apply_slider_palette(splash_music_slider)
	if splash_sfx_slider != null and splash_sfx_slider.visible:
		_apply_slider_palette(splash_sfx_slider)


func _get_ui_scale() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	return clampf(minf(viewport_size.x / 1080.0, viewport_size.y / 1920.0), 0.92, 1.45)


func _get_top_hud_height() -> float:
	var base_height: float = BASE_TOP_HUD_HEIGHT * _get_ui_scale()
	if top_panel == null:
		return base_height
	if not top_panel.visible:
		return 0.0
	return minf(maxf(base_height, top_panel.get_combined_minimum_size().y + _get_outer_margin() * 2.0), get_viewport_rect().size.y * 0.3)


func _get_bottom_hud_height() -> float:
	var base_height: float = BASE_BOTTOM_HUD_HEIGHT * _get_ui_scale()
	if bottom_panel == null:
		return base_height
	if not bottom_panel.visible:
		return 0.0
	return minf(maxf(base_height, bottom_panel.get_combined_minimum_size().y + _get_outer_margin() * 2.0), get_viewport_rect().size.y * 0.28)


func _get_outer_margin() -> float:
	return BASE_OUTER_MARGIN * _get_ui_scale()


func _load_ui_font() -> void:
	var font_bytes: PackedByteArray = FileAccess.get_file_as_bytes("res://assets/fonts/Fredoka.ttf")
	if font_bytes.is_empty():
		ui_font = ThemeDB.fallback_font
	else:
		var font_file: FontFile = FontFile.new()
		font_file.data = font_bytes
		ui_font = font_file

	var system_font: SystemFont = SystemFont.new()
	system_font.font_names = PackedStringArray([
		"Hiragino Sans",
		"Hiragino Kaku Gothic ProN",
		"Yu Gothic",
		"PingFang SC",
		"Heiti SC",
		"Apple SD Gothic Neo",
		"Noto Sans CJK JP",
		"Noto Sans CJK SC",
		"Noto Sans CJK KR",
		"Noto Sans JP",
		"Noto Sans SC",
		"Noto Sans KR",
		"Noto Sans Arabic",
		"Noto Sans Devanagari",
		"Geeza Pro",
		"Kohinoor Devanagari",
		"Microsoft YaHei",
		"Malgun Gothic",
		"Segoe UI",
	])
	multilingual_ui_font = system_font


func _get_active_ui_font() -> Font:
	if language_code in ["zh_CN", "hi", "ar", "ja", "ko"]:
		return multilingual_ui_font if multilingual_ui_font != null else ThemeDB.fallback_font
	return ui_font


func _make_panel_style(bg_color: Color, border_color: Color, shadow_color: Color) -> StyleBoxFlat:
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
	style.shadow_color = _with_alpha(shadow_color.darkened(0.35), 0.34)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


func _make_button_style(bg_color: Color) -> StyleBoxFlat:
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
	style.shadow_color = _with_alpha(bg_color.darkened(0.62), 0.46)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


func _make_button_focus_style(border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = border_color.lightened(0.25)
	style.set_border_width_all(6)
	style.set_corner_radius_all(26)
	style.corner_detail = 10
	style.shadow_color = _with_alpha(border_color.lightened(0.15), 0.38)
	style.shadow_size = 14
	style.shadow_offset = Vector2.ZERO
	return style


func _load_persistent_data() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_FILE_PATH) != OK:
		return
	invert_colors_enabled = bool(config.get_value("settings", "invert_colors_enabled", false))
	language_code = String(config.get_value("settings", "language_code", LocalizationScript.DEFAULT_LANGUAGE))
	if not LocalizationScript.has_language(language_code):
		language_code = LocalizationScript.DEFAULT_LANGUAGE
	music_volume_setting = clampf(float(config.get_value("audio", "music_volume", 1.0)), 0.0, 1.0)
	sfx_volume_setting = clampf(float(config.get_value("audio", "sfx_volume", 1.0)), 0.0, 1.0)
	best_run_score = maxi(int(config.get_value("records", "best_run_score", 0)), 0)


func _save_persistent_data() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("settings", "invert_colors_enabled", invert_colors_enabled)
	config.set_value("settings", "language_code", language_code)
	config.set_value("audio", "music_volume", music_volume_setting)
	config.set_value("audio", "sfx_volume", sfx_volume_setting)
	config.set_value("records", "best_run_score", best_run_score)
	config.save(SAVE_FILE_PATH)


func _apply_persistent_audio_settings() -> void:
	if audio_controller == null:
		return
	audio_controller.set_music_volume(music_volume_setting)
	audio_controller.set_sfx_volume(sfx_volume_setting)
	_sync_volume_controls()


func _remember_best_run_score(score: int) -> void:
	if score <= best_run_score:
		return
	best_run_score = clampi(score, 0, MAX_TRACKED_VALUE)
	_save_persistent_data()


func _apply_button_palette(button: Button, normal_color: Color, hover_color: Color, pressed_color: Color) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(normal_color))
	button.add_theme_stylebox_override("hover", _make_button_style(hover_color))
	button.add_theme_stylebox_override("pressed", _make_button_style(pressed_color))
	button.add_theme_stylebox_override("focus", _make_button_focus_style(hover_color))


func _set_splash_visible(is_visible: bool) -> void:
	splash_panel.visible = is_visible
	if not is_visible:
		menu_focus_index = -1


func _set_footer_enabled(is_enabled: bool) -> void:
	retry_button.disabled = not is_enabled
	end_run_button.disabled = not is_enabled


func _is_menu_navigation_active() -> bool:
	return splash_mode != SplashMode.NONE


func _handle_menu_navigation_input(event: InputEvent) -> bool:
	var direction: Vector2i = Vector2i.ZERO
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo:
			direction = _direction_from_key(key_event)
	elif event is InputEventJoypadButton:
		var button_event: InputEventJoypadButton = event
		if button_event.pressed:
			direction = _direction_from_joypad_button(button_event)
	elif event is InputEventJoypadMotion:
		_handle_joypad_motion(event)
		return true

	if direction == Vector2i.ZERO:
		return false

	_move_menu_focus(direction)
	return true


func _move_menu_focus(direction: Vector2i) -> void:
	var controls: Array[Control] = _get_active_menu_controls()
	if controls.is_empty():
		menu_focus_index = -1
		return

	if menu_focus_index >= 0 and menu_focus_index < controls.size() and direction.x != 0:
		var focused_control: Control = controls[menu_focus_index]
		if focused_control is HSlider:
			_adjust_focused_slider(focused_control, direction.x)
			return

	if menu_focus_index < 0 or menu_focus_index >= controls.size():
		menu_focus_index = 0
	else:
		var step: int = -1 if direction.y < 0 or direction.x < 0 else 1
		menu_focus_index = posmod(menu_focus_index + step, controls.size())

	controls[menu_focus_index].grab_focus()
	if audio_controller != null:
		audio_controller.play_menu_move()


func _sync_menu_focus(force_first: bool = false) -> void:
	var controls: Array[Control] = _get_active_menu_controls()
	if controls.is_empty():
		menu_focus_index = -1
		return

	if force_first or menu_focus_index < 0 or menu_focus_index >= controls.size():
		menu_focus_index = 0

	controls[menu_focus_index].grab_focus()


func _activate_focused_menu_button() -> void:
	var controls: Array[Control] = _get_active_menu_controls()
	if controls.is_empty():
		_handle_splash_action()
		return

	if menu_focus_index < 0 or menu_focus_index >= controls.size():
		menu_focus_index = 0

	var control: Control = controls[menu_focus_index]
	if control is Button:
		control.emit_signal("pressed")


func _get_active_menu_controls() -> Array[Control]:
	var controls: Array[Control] = []
	for control in [splash_action_button, splash_retry_button, splash_music_slider, splash_sfx_slider, splash_language_button, splash_invert_button, splash_end_run_button]:
		if control == null or not control.visible:
			continue
		if control is Button and control.disabled:
			continue
		controls.append(control)
	return controls


func _set_menu_focus_from_control(control: Control) -> void:
	var controls: Array[Control] = _get_active_menu_controls()
	menu_focus_index = controls.find(control)


func _adjust_focused_slider(slider: HSlider, horizontal_direction: int) -> void:
	var delta: float = slider.step if slider.step > 0.0 else 0.05
	slider.value = clampf(slider.value + float(horizontal_direction) * delta, slider.min_value, slider.max_value)
	if audio_controller != null:
		audio_controller.play_menu_move()


func _draw_background_glow(viewport_rect: Rect2) -> void:
	_draw_floating_background_circle(viewport_rect, Vector2(0.16, 0.16), 0.16, background_glow_color, 0.0, 0.03)
	_draw_floating_background_circle(viewport_rect, Vector2(0.86, 0.22), 0.12, secondary_glow_color, 1.7, 0.026)
	_draw_floating_background_circle(viewport_rect, Vector2(0.82, 0.84), 0.18, goal_color, 3.2, 0.034)
	if splash_mode == SplashMode.TITLE:
		_draw_floating_background_circle(viewport_rect, Vector2(0.38, 0.72), 0.1, retry_button_hover_color, 0.9, 0.04)
		_draw_floating_background_circle(viewport_rect, Vector2(0.68, 0.58), 0.08, player_color, 2.4, 0.045)


func _draw_floating_background_circle(viewport_rect: Rect2, anchor: Vector2, radius_scale: float, color: Color, time_offset: float, drift_scale: float) -> void:
	var min_size: float = minf(viewport_rect.size.x, viewport_rect.size.y)
	var time: float = pulse_time + time_offset
	var center: Vector2 = Vector2(
		viewport_rect.size.x * anchor.x + sin(time * 0.42) * viewport_rect.size.x * drift_scale,
		viewport_rect.size.y * anchor.y + cos(time * 0.36) * viewport_rect.size.y * drift_scale
	)
	var radius: float = min_size * radius_scale * (0.84 + (0.5 + 0.5 * sin(time * 0.78)) * 0.42)
	var hue_shift: float = 0.5 + 0.5 * sin(time * 0.22 + anchor.x * 7.0 + anchor.y * 5.0)
	var hue: float = fposmod(color.h + 0.18 * hue_shift, 1.0)
	var saturation: float = 0.32 + 0.12 * (0.5 + 0.5 * cos(time * 0.28 + time_offset))
	var value: float = 0.15 + 0.06 * (0.5 + 0.5 * sin(time * 0.24))
	if invert_colors_enabled:
		value += 0.12
	var bubble_color: Color = Color.from_hsv(hue, saturation, value, 0.14)
	draw_circle(center, radius, bubble_color)


func _draw_playfield_trim(draw_area: Rect2) -> void:
	draw_rect(draw_area.grow(2.0), _with_alpha(playfield_trim_color, 0.58), false, 3.0)


func _draw_grid_cells(origin: Vector2, cell_size: float) -> void:
	var line_width: float = clampf(cell_size * 0.04, 2.0, 5.0)
	var number_font_size: int = clampi(int(round(cell_size * 0.46)), 20, 60)
	var goal_font_size: int = clampi(int(round(cell_size * 0.38)), 18, 52)

	for y in range(grid_height):
		for x in range(grid_width):
			var cell: Vector2i = Vector2i(x, y)
			var base_rect: Rect2 = Rect2(origin + Vector2(x, y) * cell_size, Vector2.ONE * cell_size)
			var rect: Rect2 = _get_tile_draw_rect(base_rect, cell, cell_size)
			var fill_color: Color = _get_cell_fill_color(cell)
			_draw_tile_surface(rect, fill_color, line_width, _is_cell_available(cell))

			if cell == goal_cell:
				_draw_centered_text(rect, str(goal_target), goal_font_size, text_color, 4)
			else:
				_draw_centered_text(rect, str(_get_cell_value(cell)), number_font_size, text_color, 4)


func _draw_goal_overlay(cell_size: float) -> void:
	var fail_shake: Vector2 = _get_goal_fail_shake(cell_size)
	var center: Vector2 = _cell_to_screen(goal_cell) + fail_shake
	var radius: float = cell_size * 0.42 * _get_goal_clear_scale() * _get_goal_fail_scale()
	var pulse: float = 0.5 + 0.5 * sin(pulse_time * 2.6)
	var arc_color: Color = warning_color if _is_goal_fail_active() else goal_color
	var outer_alpha: float = 0.94 if not _is_goal_fail_active() else 0.98
	var inner_alpha: float = 0.42 if not _is_goal_fail_active() else 0.58
	draw_arc(center, radius * (1.16 + pulse * 0.1), 0.0, TAU, 40, _with_alpha(arc_color.lightened(0.16), outer_alpha), maxf(cell_size * 0.04, 2.0))
	draw_arc(center, radius * 0.82, 0.0, TAU, 32, _with_alpha(arc_color, inner_alpha), maxf(cell_size * 0.03, 2.0))
	if _is_goal_fail_active():
		draw_arc(center, radius * 1.34, PI * 0.08, PI * 0.92, 22, _with_alpha(warning_color.lightened(0.08), 0.84), maxf(cell_size * 0.035, 2.0))


func _draw_start_overlay(cell_size: float) -> void:
	return


func _draw_player_overlay(cell_size: float) -> void:
	var pulse: float = 0.5 + 0.5 * sin(pulse_time * 3.0)
	var player_radius: float = clampf(cell_size * 0.34, 17.0, 36.0)
	var player_intro_scale: float = _get_marker_intro_scale(player_radius)
	var player_clear_scale: float = _get_player_clear_scale()
	var player_fail_scale: float = _get_player_fail_scale()
	var player_move_scale: float = _get_player_move_scale()
	var player_total_scale: float = _get_player_total_bounce_scale()
	var fail_shake: Vector2 = _get_goal_fail_shake(cell_size)
	_draw_player_marker(_get_player_draw_position() + fail_shake, player_radius * player_intro_scale * player_clear_scale * player_fail_scale * player_move_scale * player_total_scale, pulse, cell_size)


func _draw_player_marker(center: Vector2, radius: float, pulse: float, cell_size: float) -> void:
	var ring_color: Color = warning_color if _is_goal_fail_active() else player_color.lightened(0.2)
	var outer_fill: Color = warning_color.lightened(0.24) if _is_goal_fail_active() else player_core_color
	var core_fill: Color = warning_color if _is_goal_fail_active() else player_color
	draw_circle(center, radius * (1.08 + pulse * 0.04), _with_alpha(ring_color, 0.18))
	draw_circle(center, radius, outer_fill)
	draw_circle(center, radius * 0.92, core_fill)
	var text_rect: Rect2 = Rect2(center - Vector2.ONE * radius * 0.92, Vector2.ONE * radius * 1.84)
	var total_text: String = str(player_total)
	var text_scale_factor: float = minf(0.46, 1.42 / maxf(float(total_text.length()), 2.0))
	var text_size: int = clampi(int(round(cell_size * text_scale_factor)), 12, 52)
	_draw_centered_text(text_rect, total_text, text_size, text_color, 4)


func _draw_centered_text(rect: Rect2, text: String, font_size: int, color: Color, outline_thickness: int = 2) -> void:
	if ui_font == null:
		return
	var text_size: Vector2 = ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var outline: Color = _get_text_outline_color(color)
	var baseline: Vector2 = Vector2(
		rect.position.x + (rect.size.x - text_size.x) * 0.5,
		rect.position.y + rect.size.y * 0.5 + ui_font.get_ascent(font_size) * 0.38
	)
	for offset_y in range(-outline_thickness, outline_thickness + 1):
		for offset_x in range(-outline_thickness, outline_thickness + 1):
			if offset_x == 0 and offset_y == 0:
				continue
			if absf(float(offset_x)) + absf(float(offset_y)) > float(outline_thickness) * 1.6:
				continue
			draw_string(ui_font, baseline + Vector2(offset_x, offset_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _with_alpha(outline, 0.95))
	draw_string(ui_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _get_cell_fill_color(cell: Vector2i) -> Color:
	if cell == goal_cell:
		return playfield_color.lerp(goal_color, 0.18)

	var value: int = _get_cell_value(cell)
	if tile_value_colors.has(value):
		return tile_value_colors[value]
	var value_ratio: float = clampf(float(value - 1) / maxf(float(max_cell_value - 1), 1.0), 0.0, 1.0)
	return playfield_color.lerp(playfield_trim_color, 0.12 + value_ratio * 0.28)


func _get_tile_draw_rect(base_rect: Rect2, cell: Vector2i, cell_size: float) -> Rect2:
	var center: Vector2 = base_rect.get_center()
	var scale_x: float = 0.9
	var scale_y: float = 0.9
	var offset_y: float = 0.0

	if _is_cell_available(cell):
		var available_pulse: float = 0.5 + 0.5 * sin(pulse_time * 4.4 + float(cell.x + cell.y))
		scale_x += 0.05 + available_pulse * 0.05
		scale_y += 0.05 + available_pulse * 0.05
		offset_y -= available_pulse * cell_size * 0.02

	if _is_landing_bounce_active() and cell == landing_bounce_cell:
		var progress: float = clampf(landing_bounce_elapsed / LANDING_BOUNCE_DURATION, 0.0, 1.0)
		var wave: float = sin(progress * PI)
		scale_x += wave * 0.08
		scale_y += wave * 0.12
		offset_y -= wave * cell_size * 0.14

	var size: Vector2 = base_rect.size * Vector2(scale_x, scale_y)
	return Rect2(center - size * 0.5 + Vector2(0.0, offset_y), size)


func _draw_tile_surface(rect: Rect2, fill_color: Color, line_width: float, is_available: bool) -> void:
	var corner_radius: float = rect.size.x * 0.18
	var display_color: Color = fill_color
	if is_available:
		var pulse: float = 0.5 + 0.5 * sin(pulse_time * 2.2 + float(rect.position.x + rect.position.y) * 0.02)
		var inverted: Color = Color(1.0 - fill_color.r, 1.0 - fill_color.g, 1.0 - fill_color.b, fill_color.a)
		display_color = fill_color.lerp(inverted, 0.38 + pulse * 0.62)
	var shell_color: Color = display_color.lightened(0.26)
	var core_color: Color = display_color.darkened(0.36)
	var face_color: Color = display_color.lightened(0.14)
	_draw_rounded_rect(rect, shell_color, corner_radius)
	var middle_rect: Rect2 = rect.grow(-line_width * 0.45)
	var middle_radius: float = maxf(corner_radius - line_width * 0.85, 3.0)
	_draw_rounded_rect(middle_rect, core_color, middle_radius)
	var face_rect: Rect2 = middle_rect.grow(-line_width * 0.62)
	var face_radius: float = maxf(middle_radius - line_width * 0.9, 2.0)
	_draw_rounded_rect(face_rect, face_color, face_radius)
	var top_glow_rect: Rect2 = Rect2(face_rect.position + Vector2(0.0, face_rect.size.y * 0.02), Vector2(face_rect.size.x, face_rect.size.y * 0.46))
	var bottom_shade_rect: Rect2 = Rect2(face_rect.position + Vector2(0.0, face_rect.size.y * 0.48), Vector2(face_rect.size.x, face_rect.size.y * 0.42))
	_draw_rounded_rect(top_glow_rect, _with_alpha(shell_color.lightened(0.18), 0.22), face_radius)
	_draw_rounded_rect(bottom_shade_rect, _with_alpha(core_color.darkened(0.12), 0.18), face_radius)
	_draw_corner_lights(face_rect, _with_alpha(Color.WHITE, 0.17), face_radius)
	_draw_rounded_rect_outline(face_rect, _with_alpha(Color.WHITE, 0.22), face_radius, maxf(1.0, line_width * 0.48))
	_draw_rounded_rect_outline(middle_rect, _with_alpha(core_color.darkened(0.3), 0.46), middle_radius, maxf(1.0, line_width * 0.45))
	_draw_rounded_rect_outline(rect, _with_alpha(shell_color.lightened(0.16), 0.62), corner_radius, maxf(1.0, line_width * 0.82))
	if is_available:
		var pulse_outline: float = 0.5 + 0.5 * sin(pulse_time * 2.2 + float(rect.position.x + rect.position.y) * 0.02)
		_draw_corner_lights(face_rect, _with_alpha(Color.WHITE, 0.18 + pulse_outline * 0.08), face_radius)
		_draw_rounded_rect_outline(rect, _with_alpha(player_core_color, 0.3 + pulse_outline * 0.35), corner_radius, maxf(2.0, line_width * 1.1))


func _draw_rounded_rect(rect: Rect2, color: Color, radius: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 1.0:
		draw_rect(rect, color, true)
		return
	draw_rect(Rect2(rect.position + Vector2(r, 0.0), Vector2(rect.size.x - r * 2.0, rect.size.y)), color, true)
	draw_rect(Rect2(rect.position + Vector2(0.0, r), Vector2(rect.size.x, rect.size.y - r * 2.0)), color, true)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)


func _draw_rounded_rect_outline(rect: Rect2, color: Color, radius: float, width: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 1.0:
		draw_rect(rect, color, false, width)
		return
	var top_left: Vector2 = rect.position + Vector2(r, r)
	var top_right: Vector2 = rect.position + Vector2(rect.size.x - r, r)
	var bottom_left: Vector2 = rect.position + Vector2(r, rect.size.y - r)
	var bottom_right: Vector2 = rect.position + Vector2(rect.size.x - r, rect.size.y - r)
	draw_arc(top_left, r, PI, PI * 1.5, 10, color, width)
	draw_arc(top_right, r, PI * 1.5, TAU, 10, color, width)
	draw_arc(bottom_right, r, 0.0, PI * 0.5, 10, color, width)
	draw_arc(bottom_left, r, PI * 0.5, PI, 10, color, width)
	draw_line(rect.position + Vector2(r, 0.0), rect.position + Vector2(rect.size.x - r, 0.0), color, width)
	draw_line(rect.position + Vector2(rect.size.x, r), rect.position + Vector2(rect.size.x, rect.size.y - r), color, width)
	draw_line(rect.position + Vector2(r, rect.size.y), rect.position + Vector2(rect.size.x - r, rect.size.y), color, width)
	draw_line(rect.position + Vector2(0.0, r), rect.position + Vector2(0.0, rect.size.y - r), color, width)


func _draw_corner_lights(rect: Rect2, color: Color, radius: float) -> void:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 1.0:
		return
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)


func _is_cell_available(cell: Vector2i) -> bool:
	if splash_mode != SplashMode.NONE or completed:
		return false
	if cell == player_cell:
		return false
	return _orthogonal_neighbors(player_cell).has(cell)


func _get_cell_text_color(fill_color: Color) -> Color:
	var luminance: float = fill_color.r * 0.299 + fill_color.g * 0.587 + fill_color.b * 0.114
	if luminance >= 0.54:
		return DARK_TEXT_COLOR
	return BRIGHT_TEXT_COLOR


func _get_text_outline_color(text_fill_color: Color) -> Color:
	if text_fill_color == DARK_TEXT_COLOR:
		return BRIGHT_TEXT_COLOR
	return outline_color


func _get_best_score_text() -> String:
	if best_run_score <= 0:
		return _loc("BEST_SCORE_NONE")
	return _loc("BEST_SCORE") % best_run_score


func _rebuild_tile_value_colors() -> void:
	tile_value_colors.clear()
	if cell_values.is_empty():
		return

	var unique_values: Array[int] = []
	for row in cell_values:
		for value in row:
			var typed_value: int = int(value)
			if typed_value <= 0:
				continue
			if unique_values.has(typed_value):
				continue
			unique_values.append(typed_value)

	unique_values.sort()
	if unique_values.is_empty():
		return

	var hue_span: float = 0.88
	var hue_start: float = 0.02
	var saturation: float = 0.38 if invert_colors_enabled else 0.62
	var brightness: float = 0.95 if invert_colors_enabled else 0.88
	var mix_amount: float = 0.76 if invert_colors_enabled else 0.68

	for index in range(unique_values.size()):
		var ratio: float = 0.0 if unique_values.size() == 1 else float(index) / float(unique_values.size() - 1)
		var hue: float = fposmod(hue_start + ratio * hue_span, 1.0)
		var hue_color: Color = Color.from_hsv(hue, saturation, brightness)
		var shaded_color: Color = playfield_color.lerp(hue_color, mix_amount)
		tile_value_colors[unique_values[index]] = shaded_color


func _orthogonal_neighbors(cell: Vector2i) -> Array[Vector2i]:
	return MazeGeneratorScript.orthogonal_neighbors(grid_width, grid_height, cell)


func _is_inside(cell: Vector2i) -> bool:
	return MazeGeneratorScript.is_inside(cell, grid_width, grid_height)


func _get_cell_value(cell: Vector2i) -> int:
	return int(cell_values[cell.y][cell.x])


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

extends Node2D

const GameConfig = preload("res://scripts/core/game_config.gd")
@export var heart_empty_texture: Texture2D
var game_mode: int = 1

@onready var landscape_a: Sprite2D = $Background/LandscapeA
@onready var landscape_b: Sprite2D = $Background/LandscapeB
@onready var clouds: Node2D = $Background/Clouds
@onready var plane: Node2D = $GameWorld/Plane
@onready var balloon_rows: Node2D = $GameWorld/BalloonRows

@onready var progress_label: Label = $UI/ProgressPanel/ProgressLabel
@onready var current_title: Label = $UI/CurrentPanel/CurrentTitle
@onready var current_value_label: Label = $UI/CurrentPanel/CurrentValue
@onready var goal_title: Label = $UI/GoalPanel/GoalTitle
@onready var goal_value_label: Label = $UI/GoalPanel/GoalValue
@onready var timer_title: Label = $UI/TimerPanel/TimerTitle
@onready var timer_value_label: Label = $UI/TimerPanel/TimerValue

@onready var heart1: TextureRect = $UI/LivesContainer/Heart1
@onready var heart2: TextureRect = $UI/LivesContainer/Heart2
@onready var heart3: TextureRect = $UI/LivesContainer/Heart3

@onready var gameplay_map_button: Button = $UI/BottomControls/MapButton
@onready var gameplay_restart_button: Button = $UI/BottomControls/RestartButton
@onready var gameplay_pause_button: Button = $UI/BottomControls/PauseButton
@onready var pause_overlay: Control = $UI/PauseOverlay
@onready var result_overlay: Control = $UI/ResultOverlay

const ProgressData = preload("res://scripts/core/progress_data.gd")
const BALLOON_SCENE: PackedScene = preload("res://scenes/gameplay/balloon.tscn")

const TEXT_NORMAL: Color = Color("#1E1E1E")
const CURRENT_HIGHLIGHT: Color = Color("#2E9E5B")
const ERROR_COLOR: Color = Color("#E53935")
const GOAL_COLOR: Color = Color("#2684D9")

const TOTAL_STEPS: int = 10
const MAX_LIVES: int = 3
const STAR_3_LIMIT: float = 120.0
const STAR_2_LIMIT: float = 150.0
const STAR_1_LIMIT: float = 180.0

const BACKGROUND_MOVE_DISTANCE: float = 220.0
const CLOUD_MOVE_DISTANCE: float = 70.0
const MOVE_TIME: float = 0.45
const EXPLORER_VERTICAL_MOVE_TIME: float = 0.12
const AUTO_VERTICAL_MOVE_TIME: float = 0.08
const SCREEN_WIDTH: float = 1600.0
const BACKGROUND_OVERLAP: float = 8.0

const ROW_POSITIONS: Array[float] = [240.0, 370.0, 500.0, 630.0]
const COLUMN_POSITIONS: Array[float] = [680.0, 900.0, 1120.0, 1340.0]
const COLUMN_DISTANCE: float = 220.0

const PILOT_SPEED: float = 105.0
const COMMANDER_SPEED: float = 220.0
const AUTO_HIT_X: float = 460.0
const AUTO_BACKGROUND_FACTOR: float = 0.55
const AUTO_CLOUD_FACTOR: float = 0.25

var world_key: String = "summer"
var operation_key: String = "sum"
var operation_symbol: String = "+"
var initial_value: int = 0
var targets: Array[int] = []

var heart_full_texture: Texture2D
var current_step: int = 1
var current_value: int = 0
var goal_value: int = 0
var current_row: int = 2
var lives: int = MAX_LIVES
var elapsed_time: float = 0.0
var final_stars: int = 0
var phase_completed: bool = false
var end_reason: String = ""
var is_moving: bool = false
var auto_collision_busy: bool = false
var plane_vertical_tween: Tween
var background_width: float = 0.0
var columns: Array[Node2D] = []
var column_serial: int = 0


func _ready() -> void:
	get_tree().paused = false
	load_season_config()
	setup_overlay_system()

	heart_full_texture = heart1.texture
	if heart_empty_texture == null:
		push_warning("Defina Heart Empty Texture no nó raiz da fase.")

	current_step = 1
	current_value = initial_value
	goal_value = targets[0]
	lives = MAX_LIVES
	elapsed_time = 0.0
	final_stars = 0
	phase_completed = false
	end_reason = ""

	apply_gameplay_background()
	plane.position.y = ROW_POSITIONS[current_row]

	setup_ui_alignment()
	reset_ui_colors()
	update_progress_ui()
	update_current_ui()
	update_goal_ui()
	update_lives_ui()
	update_timer_ui()
	create_initial_columns()
	call_deferred("animate_goal_intro")


func load_season_config() -> void:
	world_key = GameConfig.get_selected_season()
	GameConfig.set_difficulty(get_mode_key())
	var data: Dictionary = GameConfig.get_current_season_data()
	operation_key = str(data.get("operation", "sum"))
	operation_symbol = str(data.get("symbol", "+"))
	initial_value = int(data.get("initial_value", 0))

	targets.clear()
	var raw_targets: Array = data.get("targets", [])
	for value in raw_targets:
		targets.append(int(value))

	if targets.is_empty():
		targets = [6, 9, 12, 15, 11, 18, 14, 20, 17, 24]


func apply_gameplay_background() -> void:
	var data: Dictionary = GameConfig.get_current_season_data()
	var background_path: String = str(data.get("gameplay_background", "res://assets/images/gameplay/summer/background.png"))
	var background_texture: Texture2D = load(background_path) as Texture2D
	if background_texture != null:
		landscape_a.texture = background_texture
		landscape_b.texture = background_texture

	background_width = float(landscape_a.texture.get_width()) * absf(landscape_a.scale.x)
	landscape_a.position.x = background_width / 2.0
	landscape_b.position.x = landscape_a.position.x + background_width - BACKGROUND_OVERLAP
	landscape_b.position.y = landscape_a.position.y


func setup_overlay_system() -> void:
	pause_overlay.visible = false
	result_overlay.visible = false

	for button in [gameplay_map_button, gameplay_restart_button, gameplay_pause_button]:
		button.focus_mode = Control.FOCUS_NONE

	gameplay_map_button.pressed.connect(go_to_map)
	gameplay_restart_button.pressed.connect(restart_game)
	gameplay_pause_button.pressed.connect(open_pause_menu)
	pause_overlay.connect("continue_requested", Callable(self, "close_pause_menu"))
	pause_overlay.connect("restart_requested", Callable(self, "restart_game"))
	pause_overlay.connect("map_requested", Callable(self, "go_to_map"))
	result_overlay.connect("restart_requested", Callable(self, "restart_game"))
	result_overlay.connect("map_requested", Callable(self, "go_to_map"))


func open_pause_menu() -> void:
	if phase_completed:
		return
	pause_overlay.call("show_pause")
	get_tree().paused = true


func close_pause_menu() -> void:
	if phase_completed:
		return
	get_tree().paused = false
	pause_overlay.call("hide_pause")


func open_end_menu() -> void:
	result_overlay.call("show_result", end_reason, final_stars, elapsed_time, lives)
	get_tree().paused = true


func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func go_to_map() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/map_menu.tscn")


func _process(delta: float) -> void:
	if phase_completed or get_tree().paused:
		return

	if should_count_time():
		elapsed_time += delta
		update_timer_ui()

	if game_mode != 1:
		update_automatic_gameplay(delta)


func _unhandled_input(event: InputEvent) -> void:
	if phase_completed or get_tree().paused:
		return
	if not event is InputEventKey:
		return

	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo or is_moving:
		return

	if key_event.keycode == KEY_UP:
		move_plane_up()
	elif key_event.keycode == KEY_DOWN:
		move_plane_down()
	elif key_event.keycode == KEY_RIGHT and game_mode == 1:
		move_forward()


func setup_ui_alignment() -> void:
	progress_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	current_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func reset_ui_colors() -> void:
	for label in [current_title, current_value_label, goal_title, goal_value_label, timer_title, timer_value_label, progress_label]:
		label.add_theme_color_override("font_color", TEXT_NORMAL)


func update_progress_ui() -> void:
	progress_label.text = str(current_step) + "/" + str(TOTAL_STEPS)


func update_current_ui() -> void:
	current_value_label.text = str(current_value)


func update_goal_ui() -> void:
	goal_value_label.text = str(goal_value)


func update_timer_ui() -> void:
	timer_value_label.text = format_time(elapsed_time)


func format_time(seconds_value: float) -> String:
	var total_seconds: int = maxi(0, floori(seconds_value))
	var minutes: int = int(total_seconds / 60)
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func should_count_time() -> bool:
	if columns.is_empty():
		return false
	for child in columns[0].get_children():
		if child.has_method("get_is_blank") and not bool(child.call("get_is_blank")):
			return true
	return false


func update_lives_ui() -> void:
	set_heart_state(heart1, lives >= 1)
	set_heart_state(heart2, lives >= 2)
	set_heart_state(heart3, lives >= 3)


func set_heart_state(heart: TextureRect, is_full: bool) -> void:
	if is_full:
		heart.texture = heart_full_texture
		heart.modulate = Color.WHITE
	elif heart_empty_texture != null:
		heart.texture = heart_empty_texture
		heart.modulate = Color.WHITE
	else:
		heart.texture = heart_full_texture
		heart.modulate = Color(0.35, 0.35, 0.35, 0.45)


func animate_lost_heart(heart: TextureRect) -> void:
	heart.pivot_offset = heart.size / 2.0
	heart.scale = Vector2.ONE
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "scale", Vector2(1.30, 1.30), 0.08)
	tween.tween_property(heart, "scale", Vector2(0.75, 0.75), 0.08)
	await tween.finished
	update_lives_ui()
	heart.scale = Vector2.ONE


func get_lost_heart(previous_lives: int) -> TextureRect:
	if previous_lives == 3:
		return heart3
	if previous_lives == 2:
		return heart2
	return heart1


func move_plane_up() -> void:
	if current_row <= 0:
		return
	current_row -= 1
	move_plane_to_current_row()


func move_plane_down() -> void:
	if current_row >= ROW_POSITIONS.size() - 1:
		return
	current_row += 1
	move_plane_to_current_row()


func move_plane_to_current_row() -> void:
	if plane_vertical_tween != null and plane_vertical_tween.is_valid():
		plane_vertical_tween.kill()
	var move_time: float = EXPLORER_VERTICAL_MOVE_TIME if game_mode == 1 else AUTO_VERTICAL_MOVE_TIME
	plane_vertical_tween = create_tween()
	plane_vertical_tween.set_trans(Tween.TRANS_QUAD)
	plane_vertical_tween.set_ease(Tween.EASE_OUT)
	plane_vertical_tween.tween_property(plane, "position:y", ROW_POSITIONS[current_row], move_time)


func get_valid_options() -> Array[int]:
	var valid: Array[int] = []
	if operation_key == "multiply":
		if current_value <= 0 or goal_value % current_value != 0:
			return valid
		var remainder: int = int(goal_value / current_value)
		for number in range(2, 10):
			if remainder % number == 0:
				valid.append(number)
	else:
		var remaining: int = goal_value - current_value
		for number in range(1, 10):
			if number <= remaining:
				valid.append(number)
	return valid


func create_initial_columns() -> void:
	columns.clear()
	for i in range(COLUMN_POSITIONS.size()):
		var force_blank: bool = game_mode == 3 and i < 3
		var column: Node2D = create_balloon_column(COLUMN_POSITIONS[i], force_blank)
		columns.append(column)


func create_balloon_column(x_position: float, force_blank: bool = false) -> Node2D:
	var column: Node2D = Node2D.new()
	column.name = "BalloonColumn"
	balloon_rows.add_child(column)
	column.position.x = x_position

	var id: int = column_serial
	column_serial += 1
	var empty_row: int = id % 4
	var good_row: int = (id + 2) % 4
	var valid: Array[int] = get_valid_options()

	for row in range(4):
		var balloon: Node2D = BALLOON_SCENE.instantiate() as Node2D
		column.add_child(balloon)
		balloon.position = Vector2(0.0, ROW_POSITIONS[row])
		balloon.set_meta("row_index", row)

		if force_blank or row == empty_row:
			balloon.call("set_blank")
		elif row == good_row:
			var good_value: int = 1 if operation_key == "sum" else 2
			if not valid.is_empty():
				good_value = valid[id % valid.size()]
			balloon.call("set_operation", good_value, operation_symbol)
		else:
			var other_value: int = 1 + ((id * 3 + row * 2) % 9)
			if operation_key == "multiply":
				other_value = 2 + ((id + row) % 5)
			balloon.call("set_operation", other_value, operation_symbol)

	return column


func make_column_blank(column: Node2D) -> void:
	for child in column.get_children():
		child.call("set_blank")


func get_balloon_in_row(column: Node2D, row: int) -> Node2D:
	for child in column.get_children():
		if int(child.get_meta("row_index")) == row:
			return child as Node2D
	return null


func move_forward() -> void:
	if is_moving or columns.is_empty():
		return
	is_moving = true

	var first_column: Node2D = columns[0]
	var selected_balloon: Node2D = get_balloon_in_row(first_column, current_row)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(landscape_a, "position:x", landscape_a.position.x - BACKGROUND_MOVE_DISTANCE, MOVE_TIME)
	tween.parallel().tween_property(landscape_b, "position:x", landscape_b.position.x - BACKGROUND_MOVE_DISTANCE, MOVE_TIME)
	tween.parallel().tween_property(clouds, "position:x", clouds.position.x - CLOUD_MOVE_DISTANCE, MOVE_TIME)
	for column in columns:
		tween.parallel().tween_property(column, "position:x", column.position.x - COLUMN_DISTANCE, MOVE_TIME)
	await tween.finished
	await resolve_selected_balloon(selected_balloon)

	var exit_tween: Tween = create_tween()
	exit_tween.set_trans(Tween.TRANS_QUAD)
	exit_tween.set_ease(Tween.EASE_IN)
	exit_tween.tween_property(first_column, "position:x", -200.0, 0.18)
	await exit_tween.finished

	columns.erase(first_column)
	first_column.queue_free()

	if phase_completed:
		reposition_backgrounds()
		reposition_clouds()
		is_moving = false
		open_end_menu()
		return

	columns.append(create_balloon_column(COLUMN_POSITIONS[3]))
	reposition_backgrounds()
	reposition_clouds()
	is_moving = false


func update_automatic_gameplay(delta: float) -> void:
	var speed: float = PILOT_SPEED if game_mode == 2 else COMMANDER_SPEED
	landscape_a.position.x -= speed * AUTO_BACKGROUND_FACTOR * delta
	landscape_b.position.x -= speed * AUTO_BACKGROUND_FACTOR * delta
	clouds.position.x -= speed * AUTO_CLOUD_FACTOR * delta
	for column in columns:
		column.position.x -= speed * delta
	reposition_backgrounds()
	reposition_clouds()
	if not auto_collision_busy and not columns.is_empty() and columns[0].position.x <= AUTO_HIT_X:
		auto_collision_busy = true
		resolve_automatic_column(columns[0])


func resolve_automatic_column(first_column: Node2D) -> void:
	var selected_balloon: Node2D = get_balloon_in_row(first_column, current_row)
	var needs_bridge: bool = await resolve_selected_balloon(selected_balloon)
	columns.erase(first_column)
	first_column.queue_free()

	if phase_completed:
		auto_collision_busy = false
		open_end_menu()
		return

	if needs_bridge:
		apply_automatic_bridge()
	else:
		refill_automatic_columns()
	auto_collision_busy = false


func apply_operation(value: int) -> int:
	if operation_key == "multiply":
		return current_value * value
	return current_value + value


func is_bad_result(value_after: int) -> bool:
	if operation_key == "multiply":
		return value_after > goal_value or value_after <= 0 or goal_value % value_after != 0
	return value_after > goal_value


func resolve_selected_balloon(selected_balloon: Node2D) -> bool:
	if selected_balloon == null:
		return false
	if bool(selected_balloon.call("get_is_blank")):
		await pop_balloon(selected_balloon)
		return false

	var value: int = int(selected_balloon.call("get_operation"))
	var new_value: int = apply_operation(value)

	if is_bad_result(new_value):
		await pop_balloon(selected_balloon)
		handle_wrong_operation()
		return game_mode != 1

	if new_value == goal_value:
		current_value = initial_value
		current_value_label.text = str(initial_value)
		current_value_label.scale = Vector2.ONE
		current_value_label.add_theme_color_override("font_color", TEXT_NORMAL)
		advance_to_next_goal()
		await pop_balloon(selected_balloon)
		return game_mode != 1 and not phase_completed

	current_value = new_value
	animate_current_value(current_value)
	await pop_balloon(selected_balloon)
	return false


func refill_automatic_columns() -> void:
	var last_x: float = AUTO_HIT_X
	for column in columns:
		last_x = maxf(last_x, column.position.x)
	while columns.size() < COLUMN_POSITIONS.size():
		last_x += COLUMN_DISTANCE
		columns.append(create_balloon_column(last_x))


func apply_automatic_bridge() -> void:
	var blank_columns: int = 1 if game_mode == 2 else 2
	while columns.size() > blank_columns:
		var removed: Node2D = columns.pop_back()
		removed.queue_free()
	for column in columns:
		make_column_blank(column)
	refill_automatic_columns()


func get_mode_key() -> String:
	match game_mode:
		2:
			return "pilot"
		3:
			return "commander"
		_:
			return "explorer"


func animate_current_value(new_value: int) -> void:
	current_value_label.text = str(new_value)
	current_value_label.pivot_offset = current_value_label.size / 2.0
	current_value_label.scale = Vector2.ONE
	current_value_label.add_theme_color_override("font_color", CURRENT_HIGHLIGHT)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(current_value_label, "scale", Vector2(1.35, 1.35), 0.08)
	tween.tween_interval(0.04)
	tween.tween_property(current_value_label, "scale", Vector2.ONE, 0.09)
	tween.finished.connect(func() -> void: current_value_label.add_theme_color_override("font_color", TEXT_NORMAL))


func handle_wrong_operation() -> void:
	var previous_lives: int = lives
	var lost_heart: TextureRect = get_lost_heart(previous_lives)
	lives -= 1
	current_value = initial_value
	current_value_label.text = str(initial_value)
	current_value_label.pivot_offset = current_value_label.size / 2.0
	current_value_label.scale = Vector2.ONE
	current_value_label.add_theme_color_override("font_color", ERROR_COLOR)

	var zero_tween: Tween = create_tween()
	zero_tween.set_trans(Tween.TRANS_BACK)
	zero_tween.set_ease(Tween.EASE_OUT)
	zero_tween.tween_property(current_value_label, "scale", Vector2(1.45, 1.45), 0.08)
	zero_tween.tween_property(current_value_label, "scale", Vector2.ONE, 0.10)
	zero_tween.finished.connect(func() -> void: current_value_label.add_theme_color_override("font_color", TEXT_NORMAL))
	animate_lost_heart(lost_heart)

	if lives <= 0:
		update_lives_ui()
		phase_completed = true
		final_stars = 0
		end_reason = "lives"


func advance_to_next_goal() -> void:
	if current_step >= TOTAL_STEPS:
		current_value = initial_value
		current_value_label.text = str(initial_value)
		progress_label.text = "10/10"
		phase_completed = true
		final_stars = calculate_stars()
		ProgressData.save_best_stars(world_key, get_mode_key(), final_stars)
		end_reason = "victory" if final_stars > 0 else "time"
		return

	current_step += 1
	current_value = initial_value
	current_value_label.text = str(initial_value)
	current_value_label.scale = Vector2.ONE
	current_value_label.add_theme_color_override("font_color", TEXT_NORMAL)
	update_progress_ui()
	goal_value = targets[current_step - 1]
	animate_new_goal()


func animate_goal_intro() -> void:
	goal_value_label.text = str(goal_value)
	goal_value_label.pivot_offset = goal_value_label.size / 2.0
	goal_value_label.scale = Vector2(1.55, 1.55)
	goal_value_label.add_theme_color_override("font_color", GOAL_COLOR)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(goal_value_label, "scale", Vector2.ONE, 0.35)
	tween.finished.connect(func() -> void: goal_value_label.add_theme_color_override("font_color", TEXT_NORMAL))


func animate_new_goal() -> void:
	goal_value_label.text = str(goal_value)
	goal_value_label.pivot_offset = goal_value_label.size / 2.0
	goal_value_label.scale = Vector2(1.50, 1.50)
	goal_value_label.add_theme_color_override("font_color", GOAL_COLOR)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(goal_value_label, "scale", Vector2.ONE, 0.25)
	tween.finished.connect(func() -> void: goal_value_label.add_theme_color_override("font_color", TEXT_NORMAL))


func calculate_stars() -> int:
	var stars_by_time: int = 0
	if elapsed_time <= STAR_3_LIMIT:
		stars_by_time = 3
	elif elapsed_time <= STAR_2_LIMIT:
		stars_by_time = 2
	elif elapsed_time <= STAR_1_LIMIT:
		stars_by_time = 1
	return mini(stars_by_time, clampi(lives, 0, 3))


func pop_balloon(balloon: Node2D) -> void:
	var operation_text: String = ""
	if balloon.has_node("OperationLabel"):
		operation_text = str(balloon.get_node("OperationLabel").get("text"))
	var pop_position: Vector2 = balloon.global_position
	var original_scale: Vector2 = balloon.scale
	var tween: Tween = create_tween()
	tween.tween_property(balloon, "scale", original_scale * 1.15, 0.04)
	tween.parallel().tween_property(balloon, "modulate:a", 0.0, 0.05)
	await tween.finished
	balloon.visible = false
	create_pop_text(pop_position, operation_text)
	create_pop_sparks(pop_position)


func create_pop_text(pop_position: Vector2, text_value: String) -> void:
	if text_value == "":
		return
	var pop_label: Label = Label.new()
	pop_label.text = text_value
	pop_label.add_theme_font_size_override("font_size", 42)
	pop_label.add_theme_color_override("font_color", Color("#D98276"))
	pop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$GameWorld.add_child(pop_label)
	pop_label.z_index = 150
	pop_label.global_position = pop_position + Vector2(-35.0, -45.0)
	var tween: Tween = create_tween()
	tween.parallel().tween_property(pop_label, "position:y", pop_label.position.y - 25.0, 0.30)
	tween.parallel().tween_property(pop_label, "modulate:a", 0.0, 0.30)
	await tween.finished
	pop_label.queue_free()


func create_pop_sparks(pop_position: Vector2) -> void:
	var spark_count: int = 10
	var radius: float = 55.0
	for i in range(spark_count):
		var spark: Polygon2D = Polygon2D.new()
		spark.polygon = PackedVector2Array([Vector2(-4, -7), Vector2(4, -7), Vector2(4, 7), Vector2(-4, 7)])
		if i % 3 == 0:
			spark.color = Color("#F2A900")
		elif i % 3 == 1:
			spark.color = Color("#FFD37A")
		else:
			spark.color = Color("#E7B84A")
		$GameWorld.add_child(spark)
		spark.z_index = 140
		var angle: float = TAU * float(i) / float(spark_count)
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		spark.global_position = pop_position + direction * 15.0
		spark.rotation = angle
		var target_position: Vector2 = spark.position + direction * radius
		var spark_tween: Tween = create_tween()
		spark_tween.set_trans(Tween.TRANS_QUAD)
		spark_tween.set_ease(Tween.EASE_OUT)
		spark_tween.parallel().tween_property(spark, "position", target_position, 0.22)
		spark_tween.parallel().tween_property(spark, "rotation", spark.rotation + 1.2, 0.22)
		spark_tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.22)
		spark_tween.finished.connect(func() -> void: spark.queue_free())


func reposition_backgrounds() -> void:
	if landscape_a.position.x + background_width / 2.0 <= 0.0:
		landscape_a.position.x = landscape_b.position.x + background_width - BACKGROUND_OVERLAP
	if landscape_b.position.x + background_width / 2.0 <= 0.0:
		landscape_b.position.x = landscape_a.position.x + background_width - BACKGROUND_OVERLAP


func reposition_clouds() -> void:
	for child in clouds.get_children():
		if child is Sprite2D:
			var cloud: Sprite2D = child as Sprite2D
			if cloud.texture == null:
				continue
			var cloud_width: float = float(cloud.texture.get_width()) * absf(cloud.scale.x)
			var cloud_right_edge: float = cloud.position.x + clouds.position.x + cloud_width / 2.0
			if cloud_right_edge < 0.0:
				cloud.position.x += SCREEN_WIDTH + 400.0

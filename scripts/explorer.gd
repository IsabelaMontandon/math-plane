extends Node2D

@export var heart_empty_texture: Texture2D
@export_range(1, 3, 1) var game_mode: int = 1
@export var world_key: String = "summer"
@export var operation_type: String = "sum"

@onready var landscape_a = $Background/LandscapeA
@onready var landscape_b = $Background/LandscapeB
@onready var clouds = $Background/Clouds

@onready var plane = $GameWorld/Plane
@onready var balloon_rows = $GameWorld/BalloonRows

@onready var progress_label = $UI/ProgressPanel/ProgressLabel
@onready var current_title = $UI/CurrentPanel/CurrentTitle
@onready var current_value_label = $UI/CurrentPanel/CurrentValue
@onready var goal_title = $UI/GoalPanel/GoalTitle
@onready var goal_value_label = $UI/GoalPanel/GoalValue
@onready var timer_title = $UI/TimerPanel/TimerTitle
@onready var timer_value_label = $UI/TimerPanel/TimerValue

@onready var heart1 = $UI/LivesContainer/Heart1
@onready var heart2 = $UI/LivesContainer/Heart2
@onready var heart3 = $UI/LivesContainer/Heart3

@onready var gameplay_map_button = $UI/BottomControls/MapButton
@onready var gameplay_restart_button = $UI/BottomControls/RestartButton
@onready var gameplay_pause_button = $UI/BottomControls/PauseButton

@onready var pause_overlay = $UI/PauseOverlay
@onready var pause_panel = $UI/PauseOverlay/PausePanel
@onready var pause_center = $UI/PauseOverlay/PausePanel/CenterContainer
@onready var pause_vbox = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer
@onready var end_content = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/EndContent
@onready var end_title = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/EndContent/EndTitle
@onready var end_message = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/EndContent/EndMessage
@onready var end_time_label = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/EndContent/EndTimeLabel
@onready var end_lives_label = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/EndContent/EndLivesLabel
@onready var end_star1 = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/EndContent/StarsContainer/Star1
@onready var end_star2 = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/EndContent/StarsContainer/Star2
@onready var end_star3 = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/EndContent/StarsContainer/Star3
@onready var end_stars_container = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/EndContent/StarsContainer
@onready var pause_buttons_container = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/ButtonsContainer

@onready var pause_continue_button = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/ButtonsContainer/ContinueButton
@onready var pause_restart_button = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/ButtonsContainer/RestartButton
@onready var pause_map_button = $UI/PauseOverlay/PausePanel/CenterContainer/VBoxContainer/ButtonsContainer/MapButton

var balloon_scene = preload("res://scenes/gameplay/balloon.tscn")
const ProgressData = preload("res://scripts/progress_data.gd")
var star_full_texture = preload("res://assets/images/ui/star_full.png")
var star_empty_texture = preload("res://assets/images/ui/star_empty.png")
const PAUSE_PANEL_TEXTURE = preload("res://assets/images/ui/pause_panel.png")
const END_PANEL_TEXTURE = preload("res://assets/images/ui/end_panel.png")

var heart_full_texture: Texture2D

const TEXT_NORMAL = Color("#1E1E1E")
const CURRENT_HIGHLIGHT = Color("#2E9E5B")
const ERROR_COLOR = Color("#E53935")
const GOAL_COLOR = Color("#2684D9")

const SUM_TARGETS: Array[int] = [6, 9, 12, 15, 11, 18, 14, 20, 17, 24]
const MULTIPLY_TARGETS: Array[int] = [6, 8, 10, 12, 15, 18, 20, 24, 30, 36]
const TOTAL_STEPS = 10
const MAX_LIVES = 3

# Regra oficial atual: 3 estrelas até 2:00, 2 até 2:30, 1 até 3:00.
const STAR_3_LIMIT = 120.0
const STAR_2_LIMIT = 150.0
const STAR_1_LIMIT = 180.0

const BACKGROUND_MOVE_DISTANCE = 220.0
const CLOUD_MOVE_DISTANCE = 70.0
const MOVE_TIME = 0.45
const EXPLORER_VERTICAL_MOVE_TIME = 0.12
const AUTO_VERTICAL_MOVE_TIME = 0.08
const SCREEN_WIDTH = 1600.0
const BACKGROUND_OVERLAP = 8.0

const ROW_POSITIONS = [240.0, 370.0, 500.0, 630.0]
const COLUMN_POSITIONS = [680.0, 900.0, 1120.0, 1340.0]
const COLUMN_DISTANCE = 220.0

# Velocidades inspiradas diretamente no protótipo de Computação Gráfica.
const PILOT_SPEED = 105.0
const COMMANDER_SPEED = 220.0
const AUTO_HIT_X = 460.0
const AUTO_BACKGROUND_FACTOR = 0.55
const AUTO_CLOUD_FACTOR = 0.25

const PAUSE_PANEL_POSITION = Vector2(540.0, 320.0)
const PAUSE_PANEL_SIZE = Vector2(520.0, 260.0)
const END_PANEL_POSITION = Vector2(485.0, 240.0)
const END_PANEL_SIZE = Vector2(630.0, 420.0)

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

var background_width: float
var columns: Array[Node2D] = []
var column_serial: int = 0


func _ready() -> void:
	# Evita carregar uma nova partida ainda pausada.
	get_tree().paused = false

	setup_pause_system()
	configure_overlay_layout()

	heart_full_texture = heart1.texture
	if heart_empty_texture == null:
		push_warning("Defina Heart Empty Texture no nó raiz da fase.")

	current_step = 1
	current_value = get_initial_value()
	goal_value = get_targets()[0]
	lives = MAX_LIVES
	elapsed_time = 0.0
	final_stars = 0
	phase_completed = false
	end_reason = ""

	background_width = landscape_a.texture.get_width() * abs(landscape_a.scale.x)
	landscape_a.position.x = background_width / 2.0
	landscape_b.position.x = landscape_a.position.x + background_width - BACKGROUND_OVERLAP
	landscape_b.position.y = landscape_a.position.y

	plane.position.y = ROW_POSITIONS[current_row]

	setup_ui_alignment()
	reset_ui_colors()
	update_progress_ui()
	update_current_ui()
	update_goal_ui()
	update_lives_ui()
	update_timer_ui()

	create_initial_columns()

	# A primeira meta começa destacada para direcionar o olhar ao placar.
	call_deferred("animate_goal_intro")


func configure_overlay_layout() -> void:
	# Pausa e resultado final usam molduras diferentes para preservar a proporção da arte.
	pause_panel.texture = PAUSE_PANEL_TEXTURE
	pause_panel.position = PAUSE_PANEL_POSITION
	pause_panel.size = PAUSE_PANEL_SIZE

	pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_overlay_margins(false)

	pause_vbox.add_theme_constant_override("separation", 5)
	end_content.add_theme_constant_override("separation", 2)
	end_stars_container.add_theme_constant_override("separation", 8)
	pause_buttons_container.add_theme_constant_override("separation", 6)

	end_title.add_theme_font_size_override("font_size", 30)
	end_message.add_theme_font_size_override("font_size", 14)
	end_time_label.add_theme_font_size_override("font_size", 17)
	end_lives_label.add_theme_font_size_override("font_size", 17)
	end_message.custom_minimum_size = Vector2(420.0, 28.0)

	for star in [end_star1, end_star2, end_star3]:
		star.custom_minimum_size = Vector2(50.0, 50.0)

	# Os PNGs dos botões têm proporção próxima de 4,6:1.
	# Este tamanho evita o efeito "esticado" visto nas versões anteriores.
	for button in [pause_continue_button, pause_restart_button, pause_map_button]:
		button.custom_minimum_size = Vector2(235.0, 51.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func set_overlay_margins(is_end_screen: bool) -> void:
	if is_end_screen:
		pause_center.offset_left = 34.0
		pause_center.offset_top = 28.0
		pause_center.offset_right = -34.0
		pause_center.offset_bottom = -28.0
	else:
		pause_center.offset_left = 20.0
		pause_center.offset_top = 15.0
		pause_center.offset_right = -20.0
		pause_center.offset_bottom = -15.0


func setup_pause_system() -> void:
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	end_content.visible = false

	# Remove o foco do teclado para as setas controlarem somente o avião.
	for button in [
		gameplay_map_button,
		gameplay_restart_button,
		gameplay_pause_button,
		pause_continue_button,
		pause_restart_button,
		pause_map_button
	]:
		button.focus_mode = Control.FOCUS_NONE

	gameplay_map_button.pressed.connect(go_to_map)
	gameplay_restart_button.pressed.connect(restart_game)
	gameplay_pause_button.pressed.connect(open_pause_menu)
	pause_continue_button.pressed.connect(close_pause_menu)
	pause_restart_button.pressed.connect(restart_game)
	pause_map_button.pressed.connect(go_to_map)


func open_pause_menu() -> void:
	if phase_completed:
		return

	pause_panel.texture = PAUSE_PANEL_TEXTURE
	pause_panel.position = PAUSE_PANEL_POSITION
	pause_panel.size = PAUSE_PANEL_SIZE
	set_overlay_margins(false)
	end_content.visible = false
	pause_continue_button.visible = true
	pause_overlay.visible = true
	get_tree().paused = true


func open_end_menu() -> void:
	pause_panel.texture = END_PANEL_TEXTURE
	pause_panel.position = END_PANEL_POSITION
	pause_panel.size = END_PANEL_SIZE
	set_overlay_margins(true)
	pause_continue_button.visible = false
	end_content.visible = true
	update_end_menu()
	pause_overlay.visible = true
	get_tree().paused = true


func update_end_menu() -> void:
	if end_reason == "victory":
		end_title.text = "Vitória"
		end_message.text = ""
		end_message.visible = false
	elif end_reason == "time":
		end_title.text = "Derrota"
		end_message.text = "Você completou as contas, mas passou de 3:00 e ganhou 0 estrelas."
		end_message.visible = true
	else:
		end_title.text = "Derrota"
		end_message.text = "Você perdeu todas as vidas."
		end_message.visible = true

	end_time_label.text = "Tempo: " + format_time(elapsed_time)
	end_lives_label.text = "Vidas: " + str(lives)

	var stars = [end_star1, end_star2, end_star3]
	for i in range(3):
		stars[i].texture = star_full_texture if i < final_stars else star_empty_texture


func close_pause_menu() -> void:
	if phase_completed:
		return

	get_tree().paused = false
	pause_overlay.visible = false


func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func go_to_map() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/map_menu.tscn")


func _process(delta: float) -> void:
	if phase_completed or get_tree().paused:
		return

	# No protótipo de referência, o cronômetro só corre quando há uma coluna numerada ativa.
	if should_count_time():
		elapsed_time += delta
		update_timer_ui()

	if game_mode != 1:
		update_automatic_gameplay(delta)


func _unhandled_input(event: InputEvent) -> void:
	if phase_completed or get_tree().paused:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if is_moving:
		return

	if event.keycode == KEY_UP:
		move_plane_up()
	elif event.keycode == KEY_DOWN:
		move_plane_down()
	elif event.keycode == KEY_RIGHT and game_mode == 1:
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
	for label in [
		current_title,
		current_value_label,
		goal_title,
		goal_value_label,
		timer_title,
		timer_value_label,
		progress_label
	]:
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
	var total_seconds = maxi(0, floori(seconds_value))
	var minutes = int(total_seconds / 60)
	var seconds = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func should_count_time() -> bool:
	if columns.is_empty():
		return false

	for balloon in columns[0].get_children():
		if not balloon.get_is_blank():
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
		# Fallback caso o coração vazio não tenha sido configurado.
		heart.texture = heart_full_texture
		heart.modulate = Color(0.35, 0.35, 0.35, 0.45)


func animate_lost_heart(heart: TextureRect) -> void:
	heart.pivot_offset = heart.size / 2.0
	heart.scale = Vector2.ONE

	var tween = create_tween()
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
	# Interrompe a animação anterior para o avião responder imediatamente a uma nova seta.
	if plane_vertical_tween != null and plane_vertical_tween.is_valid():
		plane_vertical_tween.kill()

	var move_time = EXPLORER_VERTICAL_MOVE_TIME if game_mode == 1 else AUTO_VERTICAL_MOVE_TIME
	plane_vertical_tween = create_tween()
	plane_vertical_tween.set_trans(Tween.TRANS_QUAD)
	plane_vertical_tween.set_ease(Tween.EASE_OUT)
	plane_vertical_tween.tween_property(plane, "position:y", ROW_POSITIONS[current_row], move_time)


func get_targets() -> Array[int]:
	if operation_type == "multiply":
		return MULTIPLY_TARGETS
	return SUM_TARGETS


func get_initial_value() -> int:
	return 1 if operation_type == "multiply" else 0


func get_operation_symbol() -> String:
	return "×" if operation_type == "multiply" else "+"


func get_valid_options() -> Array[int]:
	var valid: Array[int] = []

	if operation_type == "multiply":
		if current_value <= 0 or goal_value % current_value != 0:
			return valid

		var quotient: int = int(goal_value / current_value)
		for number in range(2, 10):
			if quotient % number == 0:
				valid.append(number)
		return valid

	var remaining: int = goal_value - current_value
	for number in range(1, 10):
		if number <= remaining:
			valid.append(number)

	return valid


func get_alternative_value(id: int, row: int) -> int:
	if operation_type == "multiply":
		return 2 + ((id + row) % 5)
	return 1 + ((id * 3 + row * 2) % 9)


func apply_operation(value: int) -> int:
	if operation_type == "multiply":
		return current_value * value
	return current_value + value


func is_bad_result(value_after: int) -> bool:
	if operation_type == "multiply":
		return value_after > goal_value or goal_value % value_after != 0
	return value_after > goal_value


func create_initial_columns() -> void:
	columns.clear()

	for i in range(COLUMN_POSITIONS.size()):
		# O Comandante começa com três colunas vazias, como no protótipo de referência.
		var force_blank = game_mode == 3 and i < 3
		var column = create_balloon_column(COLUMN_POSITIONS[i], force_blank)
		columns.append(column)


func create_balloon_column(x_position: float, force_blank: bool = false) -> Node2D:
	var column = Node2D.new()
	column.name = "BalloonColumn"
	balloon_rows.add_child(column)
	column.position.x = x_position

	var id = column_serial
	column_serial += 1

	# Cada coluna normal tem um balão vazio e uma opção garantidamente possível.
	var empty_row = id % 4
	var good_row = (id + 2) % 4
	var valid: Array[int] = get_valid_options()

	for row in range(4):
		var balloon = balloon_scene.instantiate()
		column.add_child(balloon)
		balloon.position = Vector2(0.0, ROW_POSITIONS[row])
		balloon.set_meta("row_index", row)

		if force_blank or row == empty_row:
			balloon.set_blank()
		elif row == good_row:
			var value: int = 1
			if not valid.is_empty():
				value = valid[id % valid.size()]
			balloon.set_operation(value, get_operation_symbol())
		else:
			var value: int = get_alternative_value(id, row)
			balloon.set_operation(value, get_operation_symbol())

	return column


func make_column_blank(column: Node2D) -> void:
	for balloon in column.get_children():
		balloon.set_blank()


func get_balloon_in_row(column: Node2D, row: int) -> Node2D:
	for balloon in column.get_children():
		if balloon.get_meta("row_index") == row:
			return balloon
	return null


func move_forward() -> void:
	if is_moving or columns.is_empty():
		return

	is_moving = true
	var first_column = columns[0]
	var selected_balloon = get_balloon_in_row(first_column, current_row)

	# No Explorador o avião permanece no mesmo X; somente o mundo avança.
	# Isso deixa cada comando mais direto e remove a sensação de ida e volta.
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(landscape_a, "position:x", landscape_a.position.x - BACKGROUND_MOVE_DISTANCE, MOVE_TIME)
	tween.parallel().tween_property(landscape_b, "position:x", landscape_b.position.x - BACKGROUND_MOVE_DISTANCE, MOVE_TIME)
	tween.parallel().tween_property(clouds, "position:x", clouds.position.x - CLOUD_MOVE_DISTANCE, MOVE_TIME)

	for column in columns:
		tween.parallel().tween_property(column, "position:x", column.position.x - COLUMN_DISTANCE, MOVE_TIME)

	await tween.finished
	await resolve_selected_balloon(selected_balloon)

	var exit_tween = create_tween()
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

	# As três colunas restantes continuam; entra apenas uma nova pela direita.
	var new_column = create_balloon_column(COLUMN_POSITIONS[3])
	columns.append(new_column)

	reposition_backgrounds()
	reposition_clouds()
	is_moving = false


func update_automatic_gameplay(delta: float) -> void:
	var speed = PILOT_SPEED if game_mode == 2 else COMMANDER_SPEED

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
	var selected_balloon = get_balloon_in_row(first_column, current_row)
	var needs_bridge = await resolve_selected_balloon(selected_balloon)

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


func resolve_selected_balloon(selected_balloon: Node2D) -> bool:
	if selected_balloon == null:
		return false

	if selected_balloon.get_is_blank():
		await pop_balloon(selected_balloon)
		return false

	var value: int = selected_balloon.get_operation()
	var new_value: int = apply_operation(value)

	if is_bad_result(new_value):
		await pop_balloon(selected_balloon)
		handle_wrong_operation()
		return game_mode != 1

	if new_value == goal_value:
		current_value = get_initial_value()
		current_value_label.text = str(current_value)
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
	var last_x = AUTO_HIT_X
	for column in columns:
		last_x = maxf(last_x, column.position.x)

	while columns.size() < COLUMN_POSITIONS.size():
		last_x += COLUMN_DISTANCE
		columns.append(create_balloon_column(last_x))


func apply_automatic_bridge() -> void:
	# O protótipo mantém 1 coluna de respiro no Piloto e 2 no Comandante.
	var blank_columns = 1 if game_mode == 2 else 2

	while columns.size() > blank_columns:
		var removed = columns.pop_back()
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

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(current_value_label, "scale", Vector2(1.35, 1.35), 0.08)
	tween.tween_interval(0.04)
	tween.tween_property(current_value_label, "scale", Vector2.ONE, 0.09)
	tween.finished.connect(
		func():
			current_value_label.add_theme_color_override("font_color", TEXT_NORMAL)
	)


func handle_wrong_operation() -> void:
	var previous_lives = lives
	var lost_heart = get_lost_heart(previous_lives)
	lives -= 1

	# O valor incorreto não aparece: ATUAL volta direto ao valor inicial da operação.
	current_value = get_initial_value()
	current_value_label.text = str(current_value)
	current_value_label.pivot_offset = current_value_label.size / 2.0
	current_value_label.scale = Vector2.ONE
	current_value_label.add_theme_color_override("font_color", ERROR_COLOR)

	var zero_tween = create_tween()
	zero_tween.set_trans(Tween.TRANS_BACK)
	zero_tween.set_ease(Tween.EASE_OUT)
	zero_tween.tween_property(current_value_label, "scale", Vector2(1.45, 1.45), 0.08)
	zero_tween.tween_property(current_value_label, "scale", Vector2.ONE, 0.10)
	zero_tween.finished.connect(
		func():
			current_value_label.add_theme_color_override("font_color", TEXT_NORMAL)
	)

	# A animação do coração ocorre em paralelo para não travar os balões.
	animate_lost_heart(lost_heart)

	if lives <= 0:
		update_lives_ui()
		phase_completed = true
		final_stars = 0
		end_reason = "lives"


func advance_to_next_goal() -> void:
	if current_step >= TOTAL_STEPS:
		current_value = get_initial_value()
		current_value_label.text = str(current_value)
		progress_label.text = "10/10"
		phase_completed = true
		final_stars = calculate_stars()
		ProgressData.save_best_stars(world_key, get_mode_key(), final_stars)
		end_reason = "victory" if final_stars > 0 else "time"
		return

	current_step += 1
	current_value = get_initial_value()
	current_value_label.text = str(current_value)
	current_value_label.scale = Vector2.ONE
	current_value_label.add_theme_color_override("font_color", TEXT_NORMAL)
	update_progress_ui()

	goal_value = get_targets()[current_step - 1]
	animate_new_goal()


func animate_goal_intro() -> void:
	goal_value_label.text = str(goal_value)
	goal_value_label.pivot_offset = goal_value_label.size / 2.0
	goal_value_label.scale = Vector2(1.55, 1.55)
	goal_value_label.add_theme_color_override("font_color", GOAL_COLOR)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(goal_value_label, "scale", Vector2.ONE, 0.35)
	tween.finished.connect(
		func():
			goal_value_label.add_theme_color_override("font_color", TEXT_NORMAL)
	)


func animate_new_goal() -> void:
	goal_value_label.text = str(goal_value)
	goal_value_label.pivot_offset = goal_value_label.size / 2.0
	goal_value_label.scale = Vector2(1.50, 1.50)
	goal_value_label.add_theme_color_override("font_color", GOAL_COLOR)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(goal_value_label, "scale", Vector2.ONE, 0.25)
	tween.finished.connect(
		func():
			goal_value_label.add_theme_color_override("font_color", TEXT_NORMAL)
	)


func calculate_stars() -> int:
	var stars_by_time = 0

	if elapsed_time <= STAR_3_LIMIT:
		stars_by_time = 3
	elif elapsed_time <= STAR_2_LIMIT:
		stars_by_time = 2
	elif elapsed_time <= STAR_1_LIMIT:
		stars_by_time = 1

	# O resultado final nunca pode superar a quantidade de vidas restantes.
	return min(stars_by_time, clampi(lives, 0, 3))


func pop_balloon(balloon: Node2D) -> void:
	var operation_text = ""
	if balloon.has_node("OperationLabel"):
		operation_text = balloon.get_node("OperationLabel").text

	var pop_position = balloon.global_position
	var original_scale = balloon.scale
	var tween = create_tween()
	tween.tween_property(balloon, "scale", original_scale * 1.15, 0.04)
	tween.parallel().tween_property(balloon, "modulate:a", 0.0, 0.05)
	await tween.finished

	balloon.visible = false
	create_pop_text(pop_position, operation_text)
	create_pop_sparks(pop_position)


func create_pop_text(pop_position: Vector2, text_value: String) -> void:
	if text_value == "":
		return

	var pop_label = Label.new()
	pop_label.text = text_value
	pop_label.add_theme_font_size_override("font_size", 42)
	pop_label.add_theme_color_override("font_color", Color("#D98276"))
	pop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$GameWorld.add_child(pop_label)
	pop_label.z_index = 150
	pop_label.global_position = pop_position + Vector2(-35, -45)

	var tween = create_tween()
	tween.parallel().tween_property(pop_label, "position:y", pop_label.position.y - 25.0, 0.30)
	tween.parallel().tween_property(pop_label, "modulate:a", 0.0, 0.30)
	await tween.finished
	pop_label.queue_free()


func create_pop_sparks(pop_position: Vector2) -> void:
	var spark_count = 10
	var radius = 55.0

	for i in range(spark_count):
		var spark = Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(-4, -7),
			Vector2(4, -7),
			Vector2(4, 7),
			Vector2(-4, 7)
		])

		if i % 3 == 0:
			spark.color = Color("#F2A900")
		elif i % 3 == 1:
			spark.color = Color("#FFD37A")
		else:
			spark.color = Color("#E7B84A")

		$GameWorld.add_child(spark)
		spark.z_index = 140

		var angle = TAU * float(i) / float(spark_count)
		var direction = Vector2(cos(angle), sin(angle))
		spark.global_position = pop_position + direction * 15.0
		spark.rotation = angle
		var target_position = spark.position + direction * radius

		var spark_tween = create_tween()
		spark_tween.set_trans(Tween.TRANS_QUAD)
		spark_tween.set_ease(Tween.EASE_OUT)
		spark_tween.parallel().tween_property(spark, "position", target_position, 0.22)
		spark_tween.parallel().tween_property(spark, "rotation", spark.rotation + 1.2, 0.22)
		spark_tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.22)
		spark_tween.finished.connect(func(): spark.queue_free())


func reposition_backgrounds() -> void:
	if landscape_a.position.x + background_width / 2.0 <= 0:
		landscape_a.position.x = landscape_b.position.x + background_width - BACKGROUND_OVERLAP

	if landscape_b.position.x + background_width / 2.0 <= 0:
		landscape_b.position.x = landscape_a.position.x + background_width - BACKGROUND_OVERLAP


func reposition_clouds() -> void:
	for cloud in clouds.get_children():
		if cloud is Sprite2D:
			var cloud_width = cloud.texture.get_width() * abs(cloud.scale.x)
			var cloud_right_edge = cloud.position.x + clouds.position.x + cloud_width / 2.0

			if cloud_right_edge < 0:
				cloud.position.x += SCREEN_WIDTH + 400.0

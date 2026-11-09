extends Node2D


@onready var landscape_a = $Background/LandscapeA
@onready var landscape_b = $Background/LandscapeB
@onready var clouds = $Background/Clouds

@onready var plane = $GameWorld/Plane
@onready var balloon_rows = $GameWorld/BalloonRows

@onready var progress_label = $UI/ProgressPanel/ProgressLabel
@onready var current_value_label = $UI/CurrentPanel/CurrentValue
@onready var goal_value_label = $UI/GoalPanel/GoalValue


var balloon_scene = preload("res://scenes/gameplay/balloon.tscn")


# =========================
# CENÁRIO
# =========================

const BACKGROUND_MOVE_DISTANCE = 220.0
const CLOUD_MOVE_DISTANCE = 70.0
const MOVE_TIME = 0.45
const SCREEN_WIDTH = 1600.0


# =========================
# POSIÇÕES DAS 4 LINHAS
# =========================

const ROW_POSITIONS = [
	240.0,
	370.0,
	500.0,
	630.0
]

# =========================
# POSIÇÕES DAS 4 COLUNAS
# =========================

const COLUMN_POSITIONS = [
	700.0,
	920.0,
	1140.0,
	1360.0
]

const COLUMN_DISTANCE = 220.0


var current_row: int = 2

var is_moving: bool = false
var is_plane_moving: bool = false

var background_width: float

var columns: Array[Node2D] = []

const TOTAL_STEPS = 10

var current_step: int = 1
var current_value: int = 0
var goal_value: int = 0


func _ready() -> void:
	# Fundo infinito
	background_width = (
		landscape_a.texture.get_width()
		* abs(landscape_a.scale.x)
	)

	landscape_a.position.x = background_width / 2.0
	landscape_b.position.x = background_width * 1.5

	landscape_b.position.y = landscape_a.position.y

	# Avião começa na linha 3
	plane.position.y = ROW_POSITIONS[current_row]

	# Cria as quatro colunas iniciais
	create_initial_columns()

	goal_value = randi_range(25, 45)
	update_ui()


# =========================
# CONTROLES
# =========================

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	if is_moving:
		return

	if event.keycode == KEY_UP:
		move_plane_up()

	elif event.keycode == KEY_DOWN:
		move_plane_down()

	elif event.keycode == KEY_RIGHT:
		move_forward()


# =========================
# MOVIMENTO DO AVIÃO
# =========================

func move_plane_up() -> void:
	if is_plane_moving:
		return

	if current_row <= 0:
		return

	current_row -= 1
	move_plane_to_current_row()


func move_plane_down() -> void:
	if is_plane_moving:
		return

	if current_row >= ROW_POSITIONS.size() - 1:
		return

	current_row += 1
	move_plane_to_current_row()


func move_plane_to_current_row() -> void:
	is_plane_moving = true

	var tween = create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		plane,
		"position:y",
		ROW_POSITIONS[current_row],
		0.20
	)

	await tween.finished

	is_plane_moving = false


# =========================
# CRIAÇÃO DAS COLUNAS
# =========================

func create_initial_columns() -> void:
	columns.clear()

	for x_position in COLUMN_POSITIONS:
		var column = create_balloon_column(x_position)
		columns.append(column)


func create_balloon_column(x_position: float) -> Node2D:
	var column = Node2D.new()

	column.name = "BalloonColumn"

	balloon_rows.add_child(column)

	column.position.x = x_position

	# Em cada coluna, uma linha terá balão sem número
	var blank_row = randi_range(0, 3)

	for row in range(4):
		var balloon = balloon_scene.instantiate()

		column.add_child(balloon)

		balloon.position.x = 0
		balloon.position.y = ROW_POSITIONS[row]

		# Guarda qual linha pertence ao balão
		balloon.set_meta("row_index", row)

		if row == blank_row:
			balloon.set_blank()
		else:
			var value = randi_range(1, 9)
			balloon.set_operation(value)

	return column


func get_balloon_in_row(column: Node2D, row: int) -> Node2D:
	for balloon in column.get_children():

		if balloon.get_meta("row_index") == row:
			return balloon

	return null


# =========================
# AVANÇAR
# =========================

func move_forward() -> void:
	if is_moving or is_plane_moving:
		return

	if columns.is_empty():
		return

	is_moving = true

	# A primeira coluna é sempre a próxima do avião
	var first_column = columns[0]

	var selected_balloon = get_balloon_in_row(
		first_column,
		current_row
	)

	var original_plane_x = plane.position.x


	# =========================
	# PRIMEIRO MOVIMENTO
	# =========================

	var tween = create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)


	# Fundo
	tween.parallel().tween_property(
		landscape_a,
		"position:x",
		landscape_a.position.x - BACKGROUND_MOVE_DISTANCE,
		MOVE_TIME
	)

	tween.parallel().tween_property(
		landscape_b,
		"position:x",
		landscape_b.position.x - BACKGROUND_MOVE_DISTANCE,
		MOVE_TIME
	)


	# Nuvens
	tween.parallel().tween_property(
		clouds,
		"position:x",
		clouds.position.x - CLOUD_MOVE_DISTANCE,
		MOVE_TIME
	)


	# As quatro colunas andam juntas
	for column in columns:
		tween.parallel().tween_property(
			column,
			"position:x",
			column.position.x - COLUMN_DISTANCE,
			MOVE_TIME
		)


	# Pequeno impulso do avião
	tween.parallel().tween_property(
		plane,
		"position:x",
		original_plane_x + 30.0,
		MOVE_TIME
	)


	await tween.finished


	# =========================
	# BALÃO ESCOLHIDO
	# =========================

	if selected_balloon != null:

		if selected_balloon.get_is_blank():
			print("Balão sem número")
			print("Atual continua = ", current_value)

		else:
			var value = selected_balloon.get_operation()

			current_value += value

			update_ui()

			print("Somou +", value)
			print("Atual = ", current_value)

		await pop_balloon(selected_balloon)


	# =========================
	# PRIMEIRA COLUNA SAI
	# =========================

	var exit_tween = create_tween()

	exit_tween.set_trans(Tween.TRANS_QUAD)
	exit_tween.set_ease(Tween.EASE_IN)

	exit_tween.parallel().tween_property(
		first_column,
		"position:x",
		-200.0,
		0.25
	)

	exit_tween.parallel().tween_property(
		plane,
		"position:x",
		original_plane_x,
		0.20
	)

	await exit_tween.finished


	# Remove a primeira coluna
	columns.erase(first_column)
	first_column.queue_free()


	# =========================
	# NOVA QUARTA COLUNA
	# =========================

	var new_column = create_balloon_column(
		COLUMN_POSITIONS[3]
	)

	columns.append(new_column)


	# Fundo e nuvens continuam em loop
	reposition_backgrounds()
	reposition_clouds()

	is_moving = false


# =========================
# POP TEMPORÁRIO
# =========================

func pop_balloon(balloon: Node2D) -> void:
	var operation_text = ""

	# Guarda o texto antes de esconder o balão
	if balloon.has_node("OperationLabel"):
		operation_text = balloon.get_node("OperationLabel").text

	var pop_position = balloon.global_position

	# POP bem rápido
	var original_scale = balloon.scale

	var tween = create_tween()

	tween.tween_property(
		balloon,
		"scale",
		original_scale * 1.15,
		0.04
	)

	tween.parallel().tween_property(
		balloon,
		"modulate:a",
		0.0,
		0.05
	)

	await tween.finished

	balloon.visible = false

	# Cria o número flutuante e as partículas
	create_pop_text(pop_position, operation_text)
	create_pop_sparks(pop_position)

func create_pop_text(pop_position: Vector2, text_value: String) -> void:
	# Se for o balão sem número, não mostra texto
	if text_value == "":
		return

	var pop_label = Label.new()

	pop_label.text = text_value

	pop_label.add_theme_font_size_override(
		"font_size",
		42
	)

	pop_label.add_theme_color_override(
		"font_color",
		Color("#D98276")
	)

	pop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	$GameWorld.add_child(pop_label)

	pop_label.z_index = 150

	# Centraliza aproximadamente sobre onde estava o balão
	pop_label.global_position = (
		pop_position
		+ Vector2(-35, -45)
	)

	var tween = create_tween()

	# Sobe levemente
	tween.parallel().tween_property(
		pop_label,
		"position:y",
		pop_label.position.y - 25.0,
		0.30
	)

	# Vai desaparecendo
	tween.parallel().tween_property(
		pop_label,
		"modulate:a",
		0.0,
		0.30
	)

	await tween.finished

	pop_label.queue_free()

func create_pop_sparks(pop_position: Vector2) -> void:
	var spark_count = 10
	var radius = 55.0

	for i in range(spark_count):
		var spark = Polygon2D.new()

		# Pequeno retângulo, igual à sua referência
		spark.polygon = PackedVector2Array([
			Vector2(-4, -7),
			Vector2(4, -7),
			Vector2(4, 7),
			Vector2(-4, 7)
		])

		# Alterna tons
		if i % 3 == 0:
			spark.color = Color("#F2A900")
		elif i % 3 == 1:
			spark.color = Color("#FFD37A")
		else:
			spark.color = Color("#E7B84A")

		$GameWorld.add_child(spark)

		spark.z_index = 140

		var angle = TAU * float(i) / float(spark_count)

		var direction = Vector2(
			cos(angle),
			sin(angle)
		)

		# Começa perto do centro
		spark.global_position = (
			pop_position
			+ direction * 15.0
		)

		# Cada pedacinho já nasce rotacionado
		spark.rotation = angle

		var target_position = (
			spark.position
			+ direction * radius
		)

		var tween = create_tween()

		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)

		# Espalha
		tween.parallel().tween_property(
			spark,
			"position",
			target_position,
			0.22
		)

		# Gira um pouquinho
		tween.parallel().tween_property(
			spark,
			"rotation",
			spark.rotation + 1.2,
			0.22
		)

		# Desaparece
		tween.parallel().tween_property(
			spark,
			"modulate:a",
			0.0,
			0.22
		)

		tween.finished.connect(
			func():
				spark.queue_free()
		)

# =========================
# LOOP DO FUNDO
# =========================

func reposition_backgrounds() -> void:
	if landscape_a.position.x + background_width / 2.0 <= 0:
		landscape_a.position.x = (
			landscape_b.position.x + background_width
		)

	if landscape_b.position.x + background_width / 2.0 <= 0:
		landscape_b.position.x = (
			landscape_a.position.x + background_width
		)


# =========================
# LOOP DAS NUVENS
# =========================

func reposition_clouds() -> void:
	for cloud in clouds.get_children():

		if cloud is Sprite2D:
			var cloud_width = (
				cloud.texture.get_width()
				* abs(cloud.scale.x)
			)

			var cloud_right_edge = (
				cloud.position.x
				+ clouds.position.x
				+ cloud_width / 2.0
			)

			if cloud_right_edge < 0:
				cloud.position.x += SCREEN_WIDTH + 400.0

func update_ui() -> void:
	progress_label.text = str(current_step) + "/" + str(TOTAL_STEPS)
	current_value_label.text = str(current_value)
	goal_value_label.text = str(goal_value)

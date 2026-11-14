extends Node2D


# =========================================================
# CORAÇÃO VAZIO
# =========================================================

@export var heart_empty_texture: Texture2D


# =========================================================
# NÓS
# =========================================================

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

@onready var heart1 = $UI/LivesContainer/Heart1
@onready var heart2 = $UI/LivesContainer/Heart2
@onready var heart3 = $UI/LivesContainer/Heart3


var balloon_scene = preload(
	"res://scenes/gameplay/balloon.tscn"
)

var heart_full_texture: Texture2D


# =========================================================
# CORES
# =========================================================

const TEXT_NORMAL = Color("#1E1E1E")

# Soma normal
const CURRENT_HIGHLIGHT = Color("#2E9E5B")

# Erro
const ERROR_COLOR = Color("#E53935")

# Meta
const GOAL_COLOR = Color("#2684D9")


# =========================================================
# VERÃO / SOMA / EXPLORADOR
# =========================================================

const SUM_TARGETS = [
	6,
	9,
	12,
	15,
	11,
	18,
	14,
	20,
	17,
	24
]

const TOTAL_STEPS = 10
const MAX_LIVES = 3


# =========================================================
# ESTRELAS
# =========================================================

const STAR_3_LIMIT = 60.0
const STAR_2_LIMIT = 120.0
const STAR_1_LIMIT = 210.0


# =========================================================
# CENÁRIO
# =========================================================

const BACKGROUND_MOVE_DISTANCE = 220.0
const CLOUD_MOVE_DISTANCE = 70.0

const MOVE_TIME = 0.45

const SCREEN_WIDTH = 1600.0


# =========================================================
# LINHAS
# =========================================================

const ROW_POSITIONS = [
	240.0,
	370.0,
	500.0,
	630.0
]


# =========================================================
# COLUNAS
# =========================================================

const COLUMN_POSITIONS = [
	680.0,
	900.0,
	1120.0,
	1340.0
]

const COLUMN_DISTANCE = 220.0


# =========================================================
# ESTADO
# =========================================================

var current_step: int = 1
var current_value: int = 0
var goal_value: int = 0

var current_row: int = 2

var lives: int = MAX_LIVES

var elapsed_time: float = 0.0
var final_stars: int = 0

var phase_completed: bool = false

var is_moving: bool = false
var is_plane_moving: bool = false

var background_width: float

var columns: Array[Node2D] = []

var column_serial: int = 0


# =========================================================
# INÍCIO
# =========================================================

func _ready() -> void:

	heart_full_texture = heart1.texture


	if heart_empty_texture == null:
		push_warning(
			"Defina Heart Empty Texture no nó Explorer."
		)


	# -----------------------------------------------------
	# ESTADO INICIAL
	# -----------------------------------------------------

	current_step = 1
	current_value = 0
	goal_value = SUM_TARGETS[0]

	lives = MAX_LIVES

	elapsed_time = 0.0
	final_stars = 0

	phase_completed = false


	# -----------------------------------------------------
	# FUNDO
	# -----------------------------------------------------

	background_width = (
		landscape_a.texture.get_width()
		* abs(landscape_a.scale.x)
	)


	landscape_a.position.x = (
		background_width / 2.0
	)


	landscape_b.position.x = (
		background_width * 1.5
	)


	landscape_b.position.y = (
		landscape_a.position.y
	)


	# -----------------------------------------------------
	# AVIÃO
	# -----------------------------------------------------

	plane.position.y = (
		ROW_POSITIONS[current_row]
	)


	# -----------------------------------------------------
	# INTERFACE
	# -----------------------------------------------------

	setup_ui_alignment()

	reset_ui_colors()

	update_progress_ui()
	update_current_ui()
	update_goal_ui()
	update_lives_ui()


	# -----------------------------------------------------
	# BALÕES
	# -----------------------------------------------------

	create_initial_columns()


	# -----------------------------------------------------
	# PRIMEIRA META EM DESTAQUE
	# -----------------------------------------------------

	call_deferred(
		"animate_goal_intro"
	)


# =========================================================
# TEMPO
# =========================================================

func _process(delta: float) -> void:

	if phase_completed:
		return


	if get_tree().paused:
		return


	elapsed_time += delta


# =========================================================
# CENTRALIZAÇÃO
# =========================================================

func setup_ui_alignment() -> void:

	progress_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	current_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	current_value_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	goal_title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	goal_value_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


# =========================================================
# CORES NORMAIS
# =========================================================

func reset_ui_colors() -> void:

	current_title.add_theme_color_override(
		"font_color",
		TEXT_NORMAL
	)


	current_value_label.add_theme_color_override(
		"font_color",
		TEXT_NORMAL
	)


	goal_title.add_theme_color_override(
		"font_color",
		TEXT_NORMAL
	)


	goal_value_label.add_theme_color_override(
		"font_color",
		TEXT_NORMAL
	)


	progress_label.add_theme_color_override(
		"font_color",
		TEXT_NORMAL
	)


# =========================================================
# INTERFACE
# =========================================================

func update_progress_ui() -> void:

	progress_label.text = (
		str(current_step)
		+ "/"
		+ str(TOTAL_STEPS)
	)


func update_current_ui() -> void:

	current_value_label.text = (
		str(current_value)
	)


func update_goal_ui() -> void:

	goal_value_label.text = (
		str(goal_value)
	)


# =========================================================
# VIDAS
# =========================================================

func update_lives_ui() -> void:

	set_heart_state(
		heart1,
		lives >= 1
	)


	set_heart_state(
		heart2,
		lives >= 2
	)


	set_heart_state(
		heart3,
		lives >= 3
	)


func set_heart_state(
	heart: TextureRect,
	is_full: bool
) -> void:

	if is_full:

		heart.texture = heart_full_texture

		heart.modulate = Color.WHITE


	else:

		if heart_empty_texture != null:

			heart.texture = heart_empty_texture

			heart.modulate = Color.WHITE


		else:

			heart.texture = heart_full_texture

			heart.modulate = Color(
				0.35,
				0.35,
				0.35,
				0.45
			)


# =========================================================
# ANIMAÇÃO DO CORAÇÃO PERDIDO
# =========================================================

func animate_lost_heart(
	heart: TextureRect
) -> void:

	heart.pivot_offset = (
		heart.size / 2.0
	)


	heart.scale = Vector2.ONE


	var tween = create_tween()


	tween.set_trans(
		Tween.TRANS_BACK
	)


	tween.set_ease(
		Tween.EASE_OUT
	)


	tween.tween_property(
		heart,
		"scale",
		Vector2(1.30, 1.30),
		0.08
	)


	tween.tween_property(
		heart,
		"scale",
		Vector2(0.75, 0.75),
		0.08
	)


	await tween.finished


	update_lives_ui()


	heart.scale = Vector2.ONE


# =========================================================
# CORAÇÃO PERDIDO
# =========================================================

func get_lost_heart(
	previous_lives: int
) -> TextureRect:

	if previous_lives == 3:
		return heart3


	if previous_lives == 2:
		return heart2


	return heart1


# =========================================================
# CONTROLES
# =========================================================

func _unhandled_input(
	event: InputEvent
) -> void:

	if phase_completed:
		return


	if not event is InputEventKey:
		return


	if not event.pressed:
		return


	if event.echo:
		return


	if is_moving:
		return


	if event.keycode == KEY_UP:

		move_plane_up()


	elif event.keycode == KEY_DOWN:

		move_plane_down()


	elif event.keycode == KEY_RIGHT:

		move_forward()


# =========================================================
# MOVIMENTO VERTICAL
# =========================================================

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


	if current_row >= (
		ROW_POSITIONS.size() - 1
	):

		return


	current_row += 1


	move_plane_to_current_row()


func move_plane_to_current_row() -> void:

	is_plane_moving = true


	var tween = create_tween()


	tween.set_trans(
		Tween.TRANS_QUAD
	)


	tween.set_ease(
		Tween.EASE_OUT
	)


	tween.tween_property(
		plane,
		"position:y",
		ROW_POSITIONS[current_row],
		0.20
	)


	await tween.finished


	is_plane_moving = false


# =========================================================
# OPÇÕES VÁLIDAS
# =========================================================

func get_valid_sum_options() -> Array[int]:

	var valid: Array[int] = []


	var remaining = (
		goal_value
		- current_value
	)


	for number in range(1, 10):

		if number <= remaining:

			valid.append(
				number
			)


	return valid


# =========================================================
# CRIA AS COLUNAS INICIAIS
# =========================================================

func create_initial_columns() -> void:

	columns.clear()


	for x_position in COLUMN_POSITIONS:

		var column = (
			create_balloon_column(
				x_position
			)
		)


		columns.append(
			column
		)


# =========================================================
# CRIA UMA COLUNA
# =========================================================

func create_balloon_column(
	x_position: float
) -> Node2D:

	var column = Node2D.new()


	column.name = (
		"BalloonColumn"
	)


	balloon_rows.add_child(
		column
	)


	column.position.x = (
		x_position
	)


	var id = column_serial


	column_serial += 1


	var empty_row = (
		id % 4
	)


	var good_row = (
		(id + 2) % 4
	)


	var valid = (
		get_valid_sum_options()
	)


	for row in range(4):

		var balloon = (
			balloon_scene.instantiate()
		)


		column.add_child(
			balloon
		)


		balloon.position.x = 0


		balloon.position.y = (
			ROW_POSITIONS[row]
		)


		balloon.set_meta(
			"row_index",
			row
		)


		# ---------------------------------------------
		# BALÃO VAZIO
		# ---------------------------------------------

		if row == empty_row:

			balloon.set_blank()


		# ---------------------------------------------
		# CAMINHO POSSÍVEL
		# ---------------------------------------------

		elif row == good_row:

			var value = 1


			if not valid.is_empty():

				value = (
					valid[
						id % valid.size()
					]
				)


			balloon.set_operation(
				value
			)


		# ---------------------------------------------
		# OUTRAS OPÇÕES
		# ---------------------------------------------

		else:

			var value = (
				1
				+ (
					(
						id * 3
						+ row * 2
					)
					% 9
				)
			)


			balloon.set_operation(
				value
			)


	return column


# =========================================================
# ENCONTRA BALÃO DA LINHA
# =========================================================

func get_balloon_in_row(
	column: Node2D,
	row: int
) -> Node2D:

	for balloon in column.get_children():

		if balloon.get_meta(
			"row_index"
		) == row:

			return balloon


	return null


# =========================================================
# AVANÇAR
#
# IMPORTANTE:
#
# O movimento dos balões é SEMPRE o mesmo.
#
# - soma normal
# - bate meta
# - perde vida
# - balão vazio
#
# Nenhum desses casos recria as quatro colunas.
# =========================================================

func move_forward() -> void:

	if is_moving:
		return


	if is_plane_moving:
		return


	if columns.is_empty():
		return


	is_moving = true


	var first_column = columns[0]


	var selected_balloon = (
		get_balloon_in_row(
			first_column,
			current_row
		)
	)


	var original_plane_x = (
		plane.position.x
	)


	# =====================================================
	# MOVIMENTO NORMAL DO MUNDO
	# =====================================================

	var tween = create_tween()


	tween.set_trans(
		Tween.TRANS_QUAD
	)


	tween.set_ease(
		Tween.EASE_IN_OUT
	)


	# Fundo

	tween.parallel().tween_property(
		landscape_a,
		"position:x",
		landscape_a.position.x
		- BACKGROUND_MOVE_DISTANCE,
		MOVE_TIME
	)


	tween.parallel().tween_property(
		landscape_b,
		"position:x",
		landscape_b.position.x
		- BACKGROUND_MOVE_DISTANCE,
		MOVE_TIME
	)


	# Nuvens

	tween.parallel().tween_property(
		clouds,
		"position:x",
		clouds.position.x
		- CLOUD_MOVE_DISTANCE,
		MOVE_TIME
	)


	# Todas as colunas

	for column in columns:

		tween.parallel().tween_property(
			column,
			"position:x",
			column.position.x
			- COLUMN_DISTANCE,
			MOVE_TIME
		)


	# Avião

	tween.parallel().tween_property(
		plane,
		"position:x",
		original_plane_x + 30.0,
		MOVE_TIME
	)


	await tween.finished


	# =====================================================
	# RESULTADO DO BALÃO
	# =====================================================

	if selected_balloon != null:


		# -------------------------------------------------
		# BALÃO VAZIO
		# -------------------------------------------------

		if selected_balloon.get_is_blank():

			await pop_balloon(
				selected_balloon
			)


		# -------------------------------------------------
		# BALÃO COM OPERAÇÃO
		# -------------------------------------------------

		else:

			var value = (
				selected_balloon.get_operation()
			)


			var new_value = (
				current_value
				+ value
			)


			# =============================================
			# PASSOU DA META
			# =============================================

			if new_value > goal_value:

				# Explosão normal.

				await pop_balloon(
					selected_balloon
				)


				# Perde vida.
				#
				# NÃO aguardamos coração ou zero.
				# O movimento continua normalmente.

				handle_wrong_operation()


			# =============================================
			# BATEU A META
			# =============================================

			elif new_value == goal_value:

				# Não mostra o valor final.
				#
				# ATUAL vai direto para zero.

				current_value = 0


				current_value_label.text = (
					"0"
				)


				current_value_label.scale = (
					Vector2.ONE
				)


				current_value_label.add_theme_color_override(
					"font_color",
					TEXT_NORMAL
				)


				# Nova meta imediatamente.

				advance_to_next_goal()


				# POP normal.

				await pop_balloon(
					selected_balloon
				)


			# =============================================
			# SOMA NORMAL
			# =============================================

			else:

				current_value = (
					new_value
				)


				animate_current_value(
					current_value
				)


				await pop_balloon(
					selected_balloon
				)


	# =====================================================
	# AVIÃO VOLTA
	#
	# SEMPRE acontece do mesmo jeito.
	# =====================================================

	var return_tween = create_tween()


	return_tween.set_trans(
		Tween.TRANS_QUAD
	)


	return_tween.set_ease(
		Tween.EASE_OUT
	)


	return_tween.tween_property(
		plane,
		"position:x",
		original_plane_x,
		0.16
	)


	await return_tween.finished


	# =====================================================
	# PRIMEIRA COLUNA SAI
	#
	# Também SEMPRE acontece.
	#
	# Inclusive quando perdeu uma vida.
	# =====================================================

	var exit_tween = create_tween()


	exit_tween.set_trans(
		Tween.TRANS_QUAD
	)


	exit_tween.set_ease(
		Tween.EASE_IN
	)


	exit_tween.tween_property(
		first_column,
		"position:x",
		-200.0,
		0.18
	)


	await exit_tween.finished


	columns.erase(
		first_column
	)


	first_column.queue_free()


	# =====================================================
	# FIM DA FASE OU SEM VIDAS
	# =====================================================

	if phase_completed:

		reposition_backgrounds()

		reposition_clouds()


		is_moving = false


		return


	# =====================================================
	# NOVA QUARTA COLUNA
	#
	# As três anteriores continuam intactas.
	#
	# Isso acontece tanto em:
	#
	# - jogada normal
	# - meta batida
	# - vida perdida
	# =====================================================

	var new_column = (
		create_balloon_column(
			COLUMN_POSITIONS[3]
		)
	)


	columns.append(
		new_column
	)


	reposition_backgrounds()

	reposition_clouds()


	is_moving = false


# =========================================================
# SOMA NORMAL
# =========================================================

func animate_current_value(
	new_value: int
) -> void:

	current_value_label.text = (
		str(new_value)
	)


	current_value_label.pivot_offset = (
		current_value_label.size
		/ 2.0
	)


	current_value_label.scale = (
		Vector2.ONE
	)


	current_value_label.add_theme_color_override(
		"font_color",
		CURRENT_HIGHLIGHT
	)


	var tween = create_tween()


	tween.set_trans(
		Tween.TRANS_BACK
	)


	tween.set_ease(
		Tween.EASE_OUT
	)


	tween.tween_property(
		current_value_label,
		"scale",
		Vector2(1.35, 1.35),
		0.08
	)


	tween.tween_interval(
		0.04
	)


	tween.tween_property(
		current_value_label,
		"scale",
		Vector2.ONE,
		0.09
	)


	tween.finished.connect(
		func():

			current_value_label.add_theme_color_override(
				"font_color",
				TEXT_NORMAL
			)
	)


# =========================================================
# PERDA DE VIDA
#
# IMPORTANTE:
#
# Não há await aqui.
#
# Coração e ATUAL animam enquanto
# os balões continuam normalmente.
# =========================================================

func handle_wrong_operation() -> void:

	var previous_lives = (
		lives
	)


	var lost_heart = (
		get_lost_heart(
			previous_lives
		)
	)


	# =====================================================
	# PERDE VIDA
	# =====================================================

	lives -= 1


	# =====================================================
	# ATUAL DIRETO PARA ZERO
	# =====================================================

	current_value = 0


	current_value_label.text = (
		"0"
	)


	current_value_label.pivot_offset = (
		current_value_label.size
		/ 2.0
	)


	current_value_label.scale = (
		Vector2.ONE
	)


	current_value_label.add_theme_color_override(
		"font_color",
		ERROR_COLOR
	)


	# =====================================================
	# ANIMAÇÃO DO ZERO
	#
	# Não bloqueia o jogo.
	# =====================================================

	var zero_tween = create_tween()


	zero_tween.set_trans(
		Tween.TRANS_BACK
	)


	zero_tween.set_ease(
		Tween.EASE_OUT
	)


	zero_tween.tween_property(
		current_value_label,
		"scale",
		Vector2(1.45, 1.45),
		0.08
	)


	zero_tween.tween_property(
		current_value_label,
		"scale",
		Vector2.ONE,
		0.10
	)


	zero_tween.finished.connect(
		func():

			current_value_label.add_theme_color_override(
				"font_color",
				TEXT_NORMAL
			)
	)


	# =====================================================
	# CORAÇÃO
	#
	# Também acontece sem bloquear os balões.
	# =====================================================

	animate_lost_heart(
		lost_heart
	)


	# =====================================================
	# SEM VIDAS
	# =====================================================

	if lives <= 0:

		phase_completed = true

		final_stars = 0


		print(
			"FIM DE JOGO"
		)


		print(
			"Contas concluídas: ",
			current_step - 1,
			"/10"
		)


		print(
			"Tempo: ",
			elapsed_time
		)


		print(
			"Estrelas: 0"
		)


		return


	print(
		"Vida perdida."
	)


	print(
		"Vidas restantes: ",
		lives
	)


	print(
		"Meta continua sendo: ",
		goal_value
	)


# =========================================================
# PRÓXIMA META
# =========================================================

func advance_to_next_goal() -> void:

	print(
		"META ATINGIDA!"
	)


	# =====================================================
	# DÉCIMA CONTA
	# =====================================================

	if current_step >= TOTAL_STEPS:

		current_value = 0


		current_value_label.text = (
			"0"
		)


		progress_label.text = (
			"10/10"
		)


		phase_completed = true


		final_stars = (
			calculate_stars()
		)


		print(
			"FASE CONCLUÍDA!"
		)


		print(
			"Tempo: ",
			elapsed_time
		)


		print(
			"Vidas restantes: ",
			lives
		)


		print(
			"Estrelas: ",
			final_stars
		)


		return


	# =====================================================
	# PRÓXIMA CONTA
	# =====================================================

	current_step += 1


	# -----------------------------------------------------
	# ATUAL
	# -----------------------------------------------------

	current_value = 0


	current_value_label.text = (
		"0"
	)


	current_value_label.scale = (
		Vector2.ONE
	)


	current_value_label.add_theme_color_override(
		"font_color",
		TEXT_NORMAL
	)


	# -----------------------------------------------------
	# PROGRESSO
	# -----------------------------------------------------

	update_progress_ui()


	# -----------------------------------------------------
	# NOVA META
	# -----------------------------------------------------

	goal_value = (
		SUM_TARGETS[
			current_step - 1
		]
	)


	# Não bloqueia o jogo.

	animate_new_goal()


	print(
		"Nova conta: ",
		current_step,
		"/",
		TOTAL_STEPS
	)


	print(
		"Nova meta: ",
		goal_value
	)


# =========================================================
# PRIMEIRA META
# =========================================================

func animate_goal_intro() -> void:

	goal_value_label.text = (
		str(goal_value)
	)


	goal_value_label.pivot_offset = (
		goal_value_label.size
		/ 2.0
	)


	# Começa grande.

	goal_value_label.scale = (
		Vector2(1.55, 1.55)
	)


	# Começa azul.

	goal_value_label.add_theme_color_override(
		"font_color",
		GOAL_COLOR
	)


	var tween = create_tween()


	tween.set_trans(
		Tween.TRANS_BACK
	)


	tween.set_ease(
		Tween.EASE_OUT
	)


	tween.tween_property(
		goal_value_label,
		"scale",
		Vector2.ONE,
		0.35
	)


	tween.finished.connect(
		func():

			goal_value_label.add_theme_color_override(
				"font_color",
				TEXT_NORMAL
			)
	)


# =========================================================
# NOVA META
# =========================================================

func animate_new_goal() -> void:

	goal_value_label.text = (
		str(goal_value)
	)


	goal_value_label.pivot_offset = (
		goal_value_label.size
		/ 2.0
	)


	# Nasce grande.

	goal_value_label.scale = (
		Vector2(1.50, 1.50)
	)


	# Nasce azul.

	goal_value_label.add_theme_color_override(
		"font_color",
		GOAL_COLOR
	)


	var tween = create_tween()


	tween.set_trans(
		Tween.TRANS_BACK
	)


	tween.set_ease(
		Tween.EASE_OUT
	)


	tween.tween_property(
		goal_value_label,
		"scale",
		Vector2.ONE,
		0.25
	)


	tween.finished.connect(
		func():

			goal_value_label.add_theme_color_override(
				"font_color",
				TEXT_NORMAL
			)
	)


# =========================================================
# ESTRELAS
# =========================================================

func calculate_stars() -> int:

	var stars_by_time: int = 0


	if elapsed_time <= STAR_3_LIMIT:

		stars_by_time = 3


	elif elapsed_time <= STAR_2_LIMIT:

		stars_by_time = 2


	elif elapsed_time <= STAR_1_LIMIT:

		stars_by_time = 1


	else:

		stars_by_time = 0


	var life_limit = (
		clampi(
			lives,
			0,
			3
		)
	)


	return min(
		stars_by_time,
		life_limit
	)


# =========================================================
# POP DO BALÃO
# =========================================================

func pop_balloon(
	balloon: Node2D
) -> void:

	var operation_text = ""


	if balloon.has_node(
		"OperationLabel"
	):

		operation_text = (
			balloon
			.get_node("OperationLabel")
			.text
		)


	var pop_position = (
		balloon.global_position
	)


	var original_scale = (
		balloon.scale
	)


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


	create_pop_text(
		pop_position,
		operation_text
	)


	create_pop_sparks(
		pop_position
	)


# =========================================================
# TEXTO DO POP
# =========================================================

func create_pop_text(
	pop_position: Vector2,
	text_value: String
) -> void:

	if text_value == "":
		return


	var pop_label = Label.new()


	pop_label.text = (
		text_value
	)


	pop_label.add_theme_font_size_override(
		"font_size",
		42
	)


	pop_label.add_theme_color_override(
		"font_color",
		Color("#D98276")
	)


	pop_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)


	$GameWorld.add_child(
		pop_label
	)


	pop_label.z_index = 150


	pop_label.global_position = (
		pop_position
		+ Vector2(-35, -45)
	)


	var tween = create_tween()


	tween.parallel().tween_property(
		pop_label,
		"position:y",
		pop_label.position.y - 25.0,
		0.30
	)


	tween.parallel().tween_property(
		pop_label,
		"modulate:a",
		0.0,
		0.30
	)


	await tween.finished


	pop_label.queue_free()


# =========================================================
# PARTÍCULAS
# =========================================================

func create_pop_sparks(
	pop_position: Vector2
) -> void:

	var spark_count = 10

	var radius = 55.0


	for i in range(
		spark_count
	):

		var spark = Polygon2D.new()


		spark.polygon = PackedVector2Array([
			Vector2(-4, -7),
			Vector2(4, -7),
			Vector2(4, 7),
			Vector2(-4, 7)
		])


		if i % 3 == 0:

			spark.color = (
				Color("#F2A900")
			)


		elif i % 3 == 1:

			spark.color = (
				Color("#FFD37A")
			)


		else:

			spark.color = (
				Color("#E7B84A")
			)


		$GameWorld.add_child(
			spark
		)


		spark.z_index = 140


		var angle = (
			TAU
			* float(i)
			/ float(spark_count)
		)


		var direction = Vector2(
			cos(angle),
			sin(angle)
		)


		spark.global_position = (
			pop_position
			+ direction * 15.0
		)


		spark.rotation = (
			angle
		)


		var target_position = (
			spark.position
			+ direction * radius
		)


		var spark_tween = create_tween()


		spark_tween.set_trans(
			Tween.TRANS_QUAD
		)


		spark_tween.set_ease(
			Tween.EASE_OUT
		)


		spark_tween.parallel().tween_property(
			spark,
			"position",
			target_position,
			0.22
		)


		spark_tween.parallel().tween_property(
			spark,
			"rotation",
			spark.rotation + 1.2,
			0.22
		)


		spark_tween.parallel().tween_property(
			spark,
			"modulate:a",
			0.0,
			0.22
		)


		spark_tween.finished.connect(
			func():
				spark.queue_free()
		)


# =========================================================
# LOOP DO FUNDO
# =========================================================

func reposition_backgrounds() -> void:

	if (
		landscape_a.position.x
		+ background_width / 2.0
		<= 0
	):

		landscape_a.position.x = (
			landscape_b.position.x
			+ background_width
		)


	if (
		landscape_b.position.x
		+ background_width / 2.0
		<= 0
	):

		landscape_b.position.x = (
			landscape_a.position.x
			+ background_width
		)


# =========================================================
# LOOP DAS NUVENS
# =========================================================

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

				cloud.position.x += (
					SCREEN_WIDTH
					+ 400.0
				)

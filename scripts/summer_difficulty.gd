extends Control

const ProgressData = preload("res://scripts/progress_data.gd")
const STAR_FULL = preload("res://assets/images/ui/star_full.png")
const STAR_EMPTY = preload("res://assets/images/ui/star_empty.png")

@onready var explorer_play_button = $ExplorerPlayButton
@onready var pilot_play_button = $PilotPlayButton
@onready var commander_play_button = $CommanderPlayButton
@onready var back_button = $BackButton

@onready var explorer_stars = [
	$ExplorerStars/Star1,
	$ExplorerStars/Star2,
	$ExplorerStars/Star3
]

@onready var pilot_stars = [
	$PilotStars/Star1,
	$PilotStars/Star2,
	$PilotStars/Star3
]

@onready var commander_stars = [
	$CommanderStars/Star1,
	$CommanderStars/Star2,
	$CommanderStars/Star3
]


func _ready() -> void:
	prepare_hover(explorer_play_button)
	prepare_hover(pilot_play_button)
	prepare_hover(commander_play_button)
	prepare_hover(back_button)

	configure_star_layout()

	# Mostra sempre a melhor pontuação já obtida em cada dificuldade.
	update_best_stars()


func configure_star_layout() -> void:
	var containers = [explorer_stars[0].get_parent(), pilot_stars[0].get_parent(), commander_stars[0].get_parent()]
	var positions = [Vector2(285.0, 585.0), Vector2(715.0, 585.0), Vector2(1139.0, 585.0)]

	for i in range(3):
		containers[i].position = positions[i]
		containers[i].size = Vector2(190.0, 50.0)
		containers[i].add_theme_constant_override("separation", 8)

	for star_group in [explorer_stars, pilot_stars, commander_stars]:
		for star in star_group:
			star.custom_minimum_size = Vector2(48.0, 48.0)


func update_best_stars() -> void:
	set_stars(explorer_stars, ProgressData.get_best_stars("summer", "explorer"))
	set_stars(pilot_stars, ProgressData.get_best_stars("summer", "pilot"))
	set_stars(commander_stars, ProgressData.get_best_stars("summer", "commander"))


func set_stars(stars: Array, amount: int) -> void:
	for i in range(3):
		stars[i].texture = STAR_FULL if i < amount else STAR_EMPTY


func prepare_hover(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_exit.bind(button))


func _on_button_hover(button: TextureButton) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.15)


func _on_button_exit(button: TextureButton) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/map_menu.tscn")


func _on_explorer_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameplay/explorer.tscn")


func _on_pilot_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameplay/pilot.tscn")


func _on_commander_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameplay/commander.tscn")

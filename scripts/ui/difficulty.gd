extends Control

const GameConfig = preload("res://scripts/core/game_config.gd")
const ProgressData = preload("res://scripts/core/progress_data.gd")
const STAR_FULL: Texture2D = preload("res://assets/images/ui/star_full.png")
const STAR_EMPTY: Texture2D = preload("res://assets/images/ui/star_empty.png")

@onready var background: TextureRect = $Background
@onready var title: TextureRect = $Title
@onready var explorer_play_button: TextureButton = $ExplorerPlayButton
@onready var pilot_play_button: TextureButton = $PilotPlayButton
@onready var commander_play_button: TextureButton = $CommanderPlayButton
@onready var back_button: TextureButton = $BackButton

@onready var explorer_stars: Array[TextureRect] = [$ExplorerStars/Star1, $ExplorerStars/Star2, $ExplorerStars/Star3]
@onready var pilot_stars: Array[TextureRect] = [$PilotStars/Star1, $PilotStars/Star2, $PilotStars/Star3]
@onready var commander_stars: Array[TextureRect] = [$CommanderStars/Star1, $CommanderStars/Star2, $CommanderStars/Star3]


func _ready() -> void:
	apply_season_visuals()
	prepare_hover(explorer_play_button)
	prepare_hover(pilot_play_button)
	prepare_hover(commander_play_button)
	prepare_hover(back_button)
	update_best_stars()


func apply_season_visuals() -> void:
	var data: Dictionary = GameConfig.get_current_season_data()
	var background_path: String = str(data.get("difficulty_background", ""))
	var title_path: String = str(data.get("difficulty_title", ""))

	background.texture = load(background_path) as Texture2D
	title.texture = load(title_path) as Texture2D


func update_best_stars() -> void:
	var season: String = GameConfig.get_selected_season()
	set_stars(explorer_stars, ProgressData.get_best_stars(season, "explorer"))
	set_stars(pilot_stars, ProgressData.get_best_stars(season, "pilot"))
	set_stars(commander_stars, ProgressData.get_best_stars(season, "commander"))


func set_stars(stars: Array[TextureRect], amount: int) -> void:
	for i in range(3):
		stars[i].texture = STAR_FULL if i < amount else STAR_EMPTY


func prepare_hover(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2.0
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_exit.bind(button))


func _on_button_hover(button: TextureButton) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.15)


func _on_button_exit(button: TextureButton) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/map_menu.tscn")


func _on_explorer_play_button_pressed() -> void:
	GameConfig.set_difficulty("explorer")
	get_tree().change_scene_to_file("res://scenes/gameplay/explorer.tscn")


func _on_pilot_play_button_pressed() -> void:
	GameConfig.set_difficulty("pilot")
	get_tree().change_scene_to_file("res://scenes/gameplay/pilot.tscn")


func _on_commander_play_button_pressed() -> void:
	GameConfig.set_difficulty("commander")
	get_tree().change_scene_to_file("res://scenes/gameplay/commander.tscn")

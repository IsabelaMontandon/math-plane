extends Control

@onready var explorer_play_button = $ExplorerPlayButton
@onready var pilot_play_button = $PilotPlayButton
@onready var commander_play_button = $CommanderPlayButton
@onready var back_button = $BackButton


func _ready() -> void:
	prepare_hover(explorer_play_button)
	prepare_hover(pilot_play_button)
	prepare_hover(commander_play_button)
	prepare_hover(back_button)


func prepare_hover(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2

	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_exit.bind(button))


func _on_button_hover(button: TextureButton) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"scale",
		Vector2(1.08, 1.08),
		0.15
	)


func _on_button_exit(button: TextureButton) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"scale",
		Vector2(1.0, 1.0),
		0.12
	)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/map_menu.tscn")

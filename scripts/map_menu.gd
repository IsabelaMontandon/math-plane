extends Control

@onready var summer_island = $SummerIsland
@onready var back_button = $BackButton


func _ready() -> void:
	prepare_hover(summer_island)
	prepare_hover(back_button)


func prepare_hover(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2

	button.mouse_entered.connect(_on_hover.bind(button))
	button.mouse_exited.connect(_on_exit.bind(button))


func _on_hover(button: TextureButton) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"scale",
		Vector2(1.08, 1.08),
		0.15
	)


func _on_exit(button: TextureButton) -> void:
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
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_summer_island_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/summer_difficulty.tscn")

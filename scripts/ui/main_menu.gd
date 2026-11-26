extends Control

@onready var play_button = $PlayButton
@onready var hangar_button = $HangarButton
@onready var settings_button = $SettingsButton


func _ready() -> void:
	prepare_button(play_button)
	prepare_button(hangar_button)
	prepare_button(settings_button)


func prepare_button(button: TextureButton) -> void:
	# Faz o botão aumentar a partir do centro
	button.pivot_offset = button.size / 2

	# Detecta quando o mouse entra e sai
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


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/map_menu.tscn")
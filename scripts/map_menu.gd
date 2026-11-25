extends Control

const ProgressData = preload("res://scripts/progress_data.gd")

@onready var summer_island = $SummerIsland

@onready var autumn_island = $AutumnIsland
@onready var autumn_lock = $AutumnIsland/LockIcon

@onready var winter_island = $WinterIsland
@onready var winter_lock = $WinterIsland/LockIcon

@onready var spring_island = $SpringIsland
@onready var spring_lock = $SpringIsland/LockIcon

@onready var back_button = $BackButton

var autumn_locked: bool = true
var winter_locked: bool = true
var spring_locked: bool = true


func _ready() -> void:
	# Outono é liberado assim que qualquer dificuldade do Verão tiver pelo menos 1 estrela.
	autumn_locked = ProgressData.get_world_best_stars("summer") < 1

	prepare_hover(summer_island)
	prepare_hover(back_button)

	if autumn_locked:
		prepare_locked_hover(autumn_island, autumn_lock)
	else:
		prepare_hover(autumn_island)

	prepare_locked_hover(winter_island, winter_lock)
	prepare_locked_hover(spring_island, spring_lock)

	update_locks()


func prepare_hover(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2
	button.mouse_entered.connect(_on_hover.bind(button))
	button.mouse_exited.connect(_on_exit.bind(button))


func _on_hover(button: TextureButton) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.15)


func _on_exit(button: TextureButton) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12)


func prepare_locked_hover(island: TextureButton, lock_icon: TextureRect) -> void:
	lock_icon.pivot_offset = lock_icon.size / 2

	island.mouse_entered.connect(
		func():
			if lock_icon.visible:
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_BACK)
				tween.set_ease(Tween.EASE_OUT)
				tween.tween_property(lock_icon, "scale", Vector2(1.18, 1.18), 0.15)
	)

	island.mouse_exited.connect(
		func():
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(lock_icon, "scale", Vector2.ONE, 0.12)
	)


func update_locks() -> void:
	autumn_lock.visible = autumn_locked
	winter_lock.visible = winter_locked
	spring_lock.visible = spring_locked


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_summer_island_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/summer_difficulty.tscn")


func _on_autumn_island_pressed() -> void:
	if autumn_locked:
		return

	get_tree().change_scene_to_file("res://scenes/ui/autumn_difficulty.tscn")

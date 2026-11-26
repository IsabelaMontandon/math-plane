extends Control

signal continue_requested
signal restart_requested
signal map_requested

@onready var continue_button: TextureButton = $PausePanel/CenterContainer/ButtonsContainer/ContinueButton
@onready var restart_button: TextureButton = $PausePanel/CenterContainer/ButtonsContainer/RestartButton
@onready var map_button: TextureButton = $PausePanel/CenterContainer/ButtonsContainer/MapButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	for button in [continue_button, restart_button, map_button]:
		button.focus_mode = Control.FOCUS_NONE


func show_pause() -> void:
	visible = true


func hide_pause() -> void:
	visible = false


func _on_continue_button_pressed() -> void:
	continue_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _on_map_button_pressed() -> void:
	map_requested.emit()

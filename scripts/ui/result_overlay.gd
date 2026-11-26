extends Control

signal restart_requested
signal map_requested

const STAR_FULL: Texture2D = preload("res://assets/images/ui/star_full.png")
const STAR_EMPTY: Texture2D = preload("res://assets/images/ui/star_empty.png")

@onready var title_label: Label = $ResultPanel/CenterContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $ResultPanel/CenterContainer/VBoxContainer/MessageLabel
@onready var star1: TextureRect = $ResultPanel/CenterContainer/VBoxContainer/StarsContainer/Star1
@onready var star2: TextureRect = $ResultPanel/CenterContainer/VBoxContainer/StarsContainer/Star2
@onready var star3: TextureRect = $ResultPanel/CenterContainer/VBoxContainer/StarsContainer/Star3
@onready var time_label: Label = $ResultPanel/CenterContainer/VBoxContainer/TimeLabel
@onready var lives_label: Label = $ResultPanel/CenterContainer/VBoxContainer/LivesLabel
@onready var restart_button: TextureButton = $ResultPanel/CenterContainer/VBoxContainer/ButtonsContainer/RestartButton
@onready var map_button: TextureButton = $ResultPanel/CenterContainer/VBoxContainer/ButtonsContainer/MapButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	restart_button.focus_mode = Control.FOCUS_NONE
	map_button.focus_mode = Control.FOCUS_NONE


func show_result(reason: String, stars: int, elapsed_time: float, lives: int) -> void:
	if reason == "victory":
		title_label.text = "Vitória"
		message_label.text = ""
		message_label.visible = false
	elif reason == "time":
		title_label.text = "Derrota"
		message_label.text = "Você completou as contas, mas passou de 3:00 e ganhou 0 estrelas."
		message_label.visible = true
	else:
		title_label.text = "Derrota"
		message_label.text = "Você perdeu todas as vidas."
		message_label.visible = true

	time_label.text = "Tempo: " + format_time(elapsed_time)
	lives_label.text = "Vidas: " + str(lives)

	var star_nodes: Array[TextureRect] = [star1, star2, star3]
	for i in range(3):
		star_nodes[i].texture = STAR_FULL if i < stars else STAR_EMPTY

	visible = true


func format_time(seconds_value: float) -> String:
	var total_seconds: int = maxi(0, floori(seconds_value))
	var minutes: int = int(total_seconds / 60)
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _on_map_button_pressed() -> void:
	map_requested.emit()
